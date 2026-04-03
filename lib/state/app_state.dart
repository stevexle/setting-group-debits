import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models.dart';
import '../logic/debt_engine.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

class AppState extends ChangeNotifier {
  final List<Group> _groups = [];
  String? _activeGroupId;
  bool _isLoading = true;
  Group? _cachedActiveGroup;
  String? _fcmToken;
  User? _currentUser;
  bool _isInitializing = false;

  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();
  StreamSubscription<DocumentSnapshot>? _syncSubscription;
  StreamSubscription<QuerySnapshot>? _txSubscription;

  // Performance Cache
  List<Settlement>? _cachedSettlements;
  Map<String, double>? _cachedNetBalances;
  Map<String, double>? _cachedPaidAmounts;
  Map<String, double>? _cachedShareAmounts;

  AppState() {
    _initAuth();
    _loadState();
  }

  void _initAuth() {
    _authService.user.listen((user) {
      _currentUser = user;
      notifyListeners();
      if (user != null && _activeGroupId != null) {
        _autoClaimMe();
      }
    });
  }

  Future<void> _autoClaimMe() async {
    if (_currentUser == null || _activeGroupId == null) return;
    final group = _activeGroup;
    if (group == null) return;

    final prefs = await SharedPreferences.getInstance();
    final localClaimedId = prefs.getString('claimedPersonId_${_activeGroupId}');

    int personIdx = -1;
    if (localClaimedId != null) {
      personIdx = group.people.indexWhere((p) => p.id == localClaimedId);
    }

    if (personIdx == -1) {
      personIdx = group.people.indexWhere((p) =>
          p.userId == _currentUser!.uid ||
          (p.email != null && p.email!.toLowerCase() == _currentUser!.email?.toLowerCase()));
    }

    if (personIdx == -1) {
      final googleName = _currentUser!.displayName;
      if (googleName != null) {
        personIdx = group.people.indexWhere((p) =>
            p.userId == null &&
            p.email == null &&
            p.name.toLowerCase() == googleName.toLowerCase());
      }
    }

    if (personIdx == -1) {
      await addPerson(
        _currentUser!.displayName ?? 'Me',
        avatarUrl: _currentUser!.photoURL,
        userId: _currentUser!.uid,
        email: _currentUser!.email,
      );
    } else {
      final person = group.people[personIdx];
      bool needsUpdate = false;
      String? newUserId, newEmail, newAvatar;

      if (person.userId == null) {
        newUserId = _currentUser!.uid;
        needsUpdate = true;
      }
      if (person.email == null) {
        newEmail = _currentUser!.email;
        needsUpdate = true;
      }
      if (person.avatarUrl.isEmpty && _currentUser!.photoURL != null) {
        newAvatar = _currentUser!.photoURL;
        needsUpdate = true;
      }

      if (needsUpdate) {
        await updatePerson(person.id, userId: newUserId, email: newEmail, avatarUrl: newAvatar);
      }
      if (person.fcmToken == null && _fcmToken != null) {
        await claimPerson(person.id);
      }
    }
  }

  void _clearCache() {
    _cachedSettlements = null;
    _cachedNetBalances = null;
    _cachedPaidAmounts = null;
    _cachedShareAmounts = null;
  }

  @override
  void notifyListeners() {
    _clearCache();
    super.notifyListeners();
  }

  // Getters
  bool get isLoading => _isLoading;
  List<Group> get groups {
    if (_currentUser == null) return List.unmodifiable(_groups);
    return List.unmodifiable(_groups.where((g) => g.people.any((p) => p.userId == _currentUser!.uid)).toList());
  }

  String? get activeGroupId => _activeGroupId;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Person? get me {
    if (_currentUser == null) return null;
    try {
      return people.firstWhere((p) => p.userId == _currentUser!.uid || (p.email != null && p.email == _currentUser!.email));
    } catch (_) { return null; }
  }

  Group? get _activeGroup {
    if (_activeGroupId == null || _groups.isEmpty) return null;
    if (_cachedActiveGroup?.id == _activeGroupId) return _cachedActiveGroup;
    try {
      _cachedActiveGroup = _groups.firstWhere((g) => g.id == _activeGroupId);
    } catch (_) {
      if (_groups.isNotEmpty) {
        _cachedActiveGroup = _groups.first;
        _activeGroupId = _cachedActiveGroup?.id;
      }
    }
    return _cachedActiveGroup;
  }

  String get groupName => _activeGroup?.name ?? 'No Group';
  List<Person> get people => _activeGroup?.people ?? const [];
  List<Transaction> get transactions => _activeGroup?.transactions ?? const [];
  bool get isSynced => _activeGroup?.syncId != null;
  String? get syncCode => _activeGroup?.syncId;

  // Persistence
  Future<void> _loadState() async {
    _isInitializing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = prefs.getString('groups_v2');
      if (groupsJson != null) {
        final List decode = jsonDecode(groupsJson);
        _groups.clear();
        _groups.addAll(decode.map((g) => Group.fromJson(Map<String, dynamic>.from(g))));
      } else {
        final gName = prefs.getString('groupName') ?? 'My First Group';
        final defaultGroup = Group(name: gName);
        _groups.add(defaultGroup);
        _activeGroupId = defaultGroup.id;
      }
      _activeGroupId ??= prefs.getString('activeGroupId') ?? (_groups.isNotEmpty ? _groups.first.id : null);

      if (_activeGroupId != null) {
        _setupSync();
        _setupNotifications();
      }
    } catch (e) {
      debugPrint("AppState: Load state error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
      await _autoClaimMe();
      _isInitializing = false;
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = jsonEncode(_groups.map((g) => g.toJson()).toList());
      await prefs.setString('groups_v2', groupsJson);
      if (_activeGroupId != null) await prefs.setString('activeGroupId', _activeGroupId!);

      if (!_isInitializing) {
        final group = _activeGroup;
        if (group?.syncId != null) {
          await _syncService.pushUpdate(group!);
        }
      }
    } catch (e) {
      debugPrint("AppState: Save state error: $e");
    }
  }

  Future<void> _setupNotifications() async {
    final ns = NotificationService();
    final group = _activeGroup;
    if (group?.syncId != null) await ns.subscribeToGroup(group!.syncId!);

    _fcmToken = await ns.getToken();
    if (_fcmToken != null && _activeGroupId != null) {
      final prefs = await SharedPreferences.getInstance();
      final claimedId = prefs.getString('claimedPersonId_${_activeGroupId}');
      if (claimedId != null) await claimPerson(claimedId);
    }
  }

  void _setupSync() {
    _syncSubscription?.cancel();
    _txSubscription?.cancel();
    final group = _activeGroup;
    if (group?.syncId != null) {
      final syncId = group!.syncId!;

      _syncSubscription = _syncService.getSyncStream(syncId).listen((doc) {
        if (doc.exists) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          final remoteGroup = Group.fromJson(data);
          final idx = _groups.indexWhere((g) => g.id == group.id);
          if (idx != -1) {
            _groups[idx] = remoteGroup.copyWith(transactions: _groups[idx].transactions);
            _cachedActiveGroup = _groups[idx];
            _saveState(); // Persist remote metadata change locally
            notifyListeners();
          }
        }
      });

      _txSubscription = _syncService.getTransactionsStream(syncId).listen((snap) {
        final List<Transaction> remoteTxs = snap.docs
            .map((d) => Transaction.fromJson(Map<String, dynamic>.from(d.data() as Map<String, dynamic>)))
            .toList();

        final idx = _groups.indexWhere((g) => g.id == group.id);
        if (idx != -1) {
          _groups[idx] = _groups[idx].copyWith(transactions: remoteTxs);
          _cachedActiveGroup = _groups[idx];
          _saveState(); // Persist remote transaction change locally
          notifyListeners();
        }
      });
    }
  }

  Future<void> enableSync() async {
    final group = _activeGroup;
    if (group == null || group.syncId != null) return;

    final syncId = await _syncService.enableSync(group);
    if (syncId != null) {
      final updated = group.copyWith(syncId: syncId);
      final idx = _groups.indexWhere((g) => g.id == group.id);
      _groups[idx] = updated;
      _cachedActiveGroup = updated;
      
      _setupSync();
      _setupNotifications();
      await _saveState();
      notifyListeners();
    }
  }

  Future<void> joinSyncGroup(String inviteCode) async {
    final remoteGroup = await _syncService.fetchGroup(inviteCode);
    if (remoteGroup != null) {
      _groups.removeWhere((g) => g.syncId == inviteCode);
      _groups.add(remoteGroup);
      _activeGroupId = remoteGroup.id;
      _cachedActiveGroup = remoteGroup;
      await _saveState();
      await _autoClaimMe();
      _setupSync();
      _setupNotifications();
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
    if (_currentUser != null) {
      final cloudGroups = await _syncService.fetchGroupsForUser(_currentUser!.uid);
      for (final cg in cloudGroups) {
        final idx = _groups.indexWhere((g) => g.syncId == cg.syncId);
        if (idx == -1) {
          _groups.add(cg);
        } else {
          _groups[idx] = cg;
        }
      }
      await _saveState();
      _autoClaimMe();
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _groups.clear();
    _activeGroupId = null;
    _cachedActiveGroup = null;
    await _loadState();
    notifyListeners();
  }

  Future<void> claimPerson(String personId) async {
    final gIdx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (gIdx != -1) {
      final pIdx = _groups[gIdx].people.indexWhere((p) => p.id == personId);
      if (pIdx != -1) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('claimedPersonId_${_activeGroupId}', personId);
        final ns = NotificationService();
        _fcmToken = await ns.getToken();

        if (_fcmToken != null) {
          final updatedPeople = [..._groups[gIdx].people];
          updatedPeople[pIdx] = updatedPeople[pIdx].copyWith(fcmToken: _fcmToken);
          _groups[gIdx] = _groups[gIdx].copyWith(people: updatedPeople);
          _cachedActiveGroup = _groups[gIdx];
          await _saveState();
          notifyListeners();
        }
      }
    }
  }

  Future<void> createGroup(String name) async {
    if (name.isEmpty) return;
    Group newGroup = Group(name: name);

    if (isAuthenticated) {
      final syncId = await _syncService.enableSync(newGroup);
      if (syncId != null) newGroup = newGroup.copyWith(syncId: syncId);
    }

    _groups.add(newGroup);
    _activeGroupId = newGroup.id;
    _cachedActiveGroup = newGroup;

    if (_currentUser != null) _autoClaimMe();

    await _saveState();
    _setupSync();
    _setupNotifications();
    notifyListeners();
  }

  void switchGroup(String id) {
    if (_groups.any((g) => g.id == id)) {
      _activeGroupId = id;
      _cachedActiveGroup = null;
      _saveState();
      _setupSync();
      _setupNotifications();
      _autoClaimMe();
      notifyListeners();
    }
  }

  bool isGroupBalanced(String groupId) {
    final group = _groups.firstWhere((g) => g.id == groupId, orElse: () => _groups.first);
    if (group.people.isEmpty) return true;
    if (group.id == _activeGroupId) return netBalances.values.every((v) => v.abs() < 0.01);
    for (final person in group.people) {
      if (getPersonNetBalance(person.id, inGroup: group).abs() > 0.01) return false;
    }
    return true;
  }

  Future<void> deleteGroup(String id) async {
    if (_groups.length <= 1 || !isGroupBalanced(id)) return;
    final targetIdx = _groups.indexWhere((g) => g.id == id);
    if (targetIdx != -1) {
      final syncId = _groups[targetIdx].syncId;
      if (syncId != null) await _syncService.deleteCloudGroup(syncId);
    }
    _groups.removeWhere((g) => g.id == id);
    if (_activeGroupId == id) {
      _activeGroupId = _groups.isNotEmpty ? _groups.first.id : null;
      _cachedActiveGroup = null;
    }
    await _saveState();
    notifyListeners();
  }

  void _updateActiveGroup(Group Function(Group) updater) {
    final idx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (idx != -1) {
      _groups[idx] = updater(_groups[idx]);
      _cachedActiveGroup = _groups[idx];
      _saveState();
      notifyListeners();
    }
  }

  Future<void> addPerson(String name, {int? colorIndex, String? avatarUrl, String? userId, String? email}) async {
    if (name.trim().isEmpty || _activeGroupId == null) return;
    final person = Person(name: name, colorIndex: colorIndex, avatarUrl: avatarUrl ?? '', userId: userId, email: email);
    _updateActiveGroup((g) => g.copyWith(people: [...g.people, person]));

    if (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
      final cloudUrl = await _syncService.uploadAvatar(avatarUrl);
      if (cloudUrl != null && cloudUrl != avatarUrl) updatePerson(person.id, avatarUrl: cloudUrl);
    }
  }

  Future<void> updatePerson(String id, {String? name, int? colorIndex, String? avatarUrl, String? userId, String? email}) async {
    _updateActiveGroup((g) {
      final pIdx = g.people.indexWhere((p) => p.id == id);
      if (pIdx == -1) return g;
      final updatedPeople = [...g.people];
      updatedPeople[pIdx] = updatedPeople[pIdx].copyWith(name: name, colorIndex: colorIndex, avatarUrl: avatarUrl, userId: userId, email: email);
      return g.copyWith(people: updatedPeople);
    });

    final person = people.any((p) => p.id == id) ? people.firstWhere((p) => p.id == id) : null;
    if (person != null && person.userId != null && person.userId == _currentUser?.uid) {
      for (int i = 0; i < _groups.length; i++) {
        if (_groups[i].id == _activeGroupId) continue;
        final pIdx = _groups[i].people.indexWhere((p) => p.userId == person.userId);
        if (pIdx != -1) {
          final updatedPeople = [..._groups[i].people];
          updatedPeople[pIdx] = updatedPeople[pIdx].copyWith(avatarUrl: avatarUrl ?? person.avatarUrl, colorIndex: colorIndex ?? person.colorIndex, email: email ?? person.email);
          _groups[i] = _groups[i].copyWith(people: updatedPeople);
          if (_groups[i].syncId != null) _syncService.pushUpdate(_groups[i]);
        }
      }
    }
    await _saveState();
    notifyListeners();
  }

  bool isPersonInvolvedInTransactions(String id) {
    return transactions.any((t) => t.payerId == id || t.participantIds.contains(id));
  }

  bool removePerson(String id) {
    if (isPersonInvolvedInTransactions(id)) return false;
    
    _updateActiveGroup((g) {
      final updatedPeople = g.people.where((p) => p.id != id).toList();
      return g.copyWith(people: updatedPeople);
    });
    return true;
  }

  Future<void> addTransaction(Transaction tx) async {
    final group = _activeGroup;
    if (group == null) return;
    _updateActiveGroup((g) => g.copyWith(transactions: [tx, ...g.transactions]));
    if (group.syncId != null) await _syncService.pushTransaction(group.syncId!, tx);
    notifyListeners();
  }

  Future<void> removeTransaction(String id) async {
    final group = _activeGroup;
    if (group == null) return;
    _updateActiveGroup((g) => g.copyWith(transactions: g.transactions.where((t) => t.id != id).toList()));
    if (group.syncId != null) await _syncService.deleteTransaction(group.syncId!, id);
    notifyListeners();
  }

  Future<void> editTransaction(String id, Transaction newTx) async {
    _updateActiveGroup((g) {
      final tIdx = g.transactions.indexWhere((t) => t.id == id);
      if (tIdx == -1) return g;
      final updatedTxs = [...g.transactions];
      updatedTxs[tIdx] = newTx.copyWith(updatedAt: DateTime.now());
      return g.copyWith(transactions: updatedTxs);
    });

    final group = _activeGroup;
    if (group?.syncId != null) await _syncService.pushTransaction(group!.syncId!, newTx);
    notifyListeners();
  }

  Future<void> clearAll() async {
    final syncId = _activeGroup?.syncId;
    if (syncId != null) await _syncService.purgeTransactions(syncId);
    final currentUserPerson = people.where((p) => p.userId == _currentUser?.uid).firstOrNull;
    final updatedPeople = currentUserPerson != null ? [currentUserPerson] : <Person>[];
    _updateActiveGroup((g) => g.copyWith(transactions: [], people: updatedPeople));
    notifyListeners();
  }

  Future<void> clearExpenses() async {
    final group = _activeGroup;
    if (group?.syncId != null) await _syncService.purgeTransactions(group!.syncId!);
    _updateActiveGroup((g) => g.copyWith(transactions: []));
    notifyListeners();
  }

  // Financial Calculations
  double get weeklyTotal {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return transactions.where((t) => !t.isPayment && t.date.isAfter(weekAgo)).fold(0, (sum, t) => sum + t.amount);
  }

  double get monthlyTotal {
    final now = DateTime.now();
    return transactions.where((t) => !t.isPayment && t.date.month == now.month && t.date.year == now.year).fold(0, (sum, t) => sum + t.amount);
  }

  bool get hasSettlements => transactions.any((t) => t.isPayment || t.description.startsWith('Settle:'));
  List<Settlement> get settlements => _cachedSettlements ??= DebtEngine.settleDebts(people, transactions);
  Map<String, double> get netBalances => _getFinancialMaps().net;
  Map<String, double> get paidBalances => _getFinancialMaps().paid;
  Map<String, double> get shareBalances => _getFinancialMaps().share;

  ({Map<String, double> net, Map<String, double> paid, Map<String, double> share}) _getFinancialMaps() {
    if (_cachedNetBalances != null && _cachedPaidAmounts != null && _cachedShareAmounts != null) {
      return (net: _cachedNetBalances!, paid: _cachedPaidAmounts!, share: _cachedShareAmounts!);
    }
    final netMap = <String, double>{for (var p in people) p.id: 0.0};
    final paidMap = <String, double>{for (var p in people) p.id: 0.0};
    final shareMap = <String, double>{for (var p in people) p.id: 0.0};
    for (final tx in transactions) {
      paidMap[tx.payerId] = (paidMap[tx.payerId] ?? 0) + tx.amount;
      netMap[tx.payerId] = (netMap[tx.payerId] ?? 0) + tx.amount;
      if (tx.customAmounts != null) {
        for (final pid in tx.participantIds) {
          final val = tx.customAmounts![pid] ?? 0;
          shareMap[pid] = (shareMap[pid] ?? 0) + val;
          netMap[pid] = (netMap[pid] ?? 0) - val;
        }
      } else if (tx.participantIds.isNotEmpty) {
        final share = tx.amount / tx.participantIds.length;
        for (final pid in tx.participantIds) {
          shareMap[pid] = (shareMap[pid] ?? 0) + share;
          netMap[pid] = (netMap[pid] ?? 0) - share;
        }
      }
    }
    _cachedNetBalances = netMap;
    _cachedPaidAmounts = paidMap;
    _cachedShareAmounts = shareMap;
    return (net: netMap, paid: paidMap, share: shareMap);
  }

  double getPersonNetBalance(String personId, {Group? inGroup}) {
    if (inGroup == null || inGroup.id == _activeGroupId) return netBalances[personId] ?? 0.0;
    double net = 0;
    for (final tx in inGroup.transactions) {
      if (tx.payerId == personId) net += tx.amount;
      if (tx.participantIds.contains(personId)) {
        if (tx.customAmounts != null) {
          net -= (tx.customAmounts![personId] ?? 0);
        } else {
          net -= (tx.amount / tx.participantIds.length);
        }
      }
    }
    return net;
  }

  Map<Category, double> get categorySpend {
    final map = <Category, double>{};
    for (final tx in transactions) map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    return map;
  }

  void settleDebt(String fromId, String toId, double amount, {bool shouldClear = false}) {
    if (amount <= 0) return;
    final pFrom = people.firstWhere((p) => p.id == fromId);
    final pTo = people.firstWhere((p) => p.id == toId);
    final tx = Transaction(description: "Settle: ${pFrom.name} ➔ ${pTo.name}", amount: amount, payerId: fromId, participantIds: [toId], isPayment: true);
    if (shouldClear) clearExpenses();
    addTransaction(tx);
  }

  Future<void> remindPerson(String personId, double amount) async {
    final person = people.firstWhere((p) => p.id == personId);
    if (person.fcmToken != null) debugPrint('Firebase: Reminder to ${person.name} (${person.fcmToken}) for $amount');
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _txSubscription?.cancel();
    super.dispose();
  }
}
