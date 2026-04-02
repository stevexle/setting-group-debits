import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models.dart';
import '../logic/debt_engine.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  final List<Group> _groups = [];
  String? _activeGroupId;
  bool _isLoading = true;
  Group? _cachedActiveGroup;
  String? _fcmToken;

  StreamSubscription<DocumentSnapshot>? _syncSubscription;
  final SyncService _syncService = SyncService();

  // Optimized Cache
  List<Settlement>? _cachedSettlements;
  Map<String, double>? _cachedNetBalances;

  AppState() {
    _loadState();
  }

  void _clearCache() {
    _cachedSettlements = null;
    _cachedNetBalances = null;
  }

  @override
  void notifyListeners() {
    _clearCache();
    super.notifyListeners();
  }

  // Getters
  bool get isLoading => _isLoading;
  List<Group> get groups => List.unmodifiable(_groups);
  String? get activeGroupId => _activeGroupId;

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
      debugPrint("Error loading state: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = jsonEncode(_groups.map((g) => g.toJson()).toList());
      await prefs.setString('groups_v2', groupsJson);
      if (_activeGroupId != null) await prefs.setString('activeGroupId', _activeGroupId!);

      final group = _activeGroup;
      if (group?.syncId != null) {
        await _syncService.pushUpdate(group!);
      }
    } catch (e) {
      debugPrint("Firebase: Error saving state: $e");
    }
  }

  Future<void> _setupNotifications() async {
    final ns = NotificationService();
    final group = _activeGroup;
    if (group?.syncId != null) {
      // Unsubscribe from all previous group topics if needed, 
      // or just ensure current one is active.
      await ns.subscribeToGroup(group!.syncId!);
    }
    
    _fcmToken = await ns.getToken();
    // Auto-update fcmToken for the claimed person if they exist
    if (_fcmToken != null && _activeGroupId != null) {
      final prefs = await SharedPreferences.getInstance();
      final claimedId = prefs.getString('claimedPersonId_${_activeGroupId}');
      if (claimedId != null) {
        await claimPerson(claimedId);
      }
    }
  }

  // Sync logic
  void _setupSync() {
    _syncSubscription?.cancel();
    final group = _activeGroup;
    if (group?.syncId != null) {
      _syncSubscription = _syncService.getSyncStream(group!.syncId!)
          .listen((doc) {
        if (doc.exists) {
          final remoteGroup = Group.fromJson(Map<String, dynamic>.from(doc.data() as Map<String, dynamic>));
          final idx = _groups.indexWhere((g) => g.id == group.id);
          if (idx != -1) {
            _groups[idx] = remoteGroup;
            _cachedActiveGroup = remoteGroup;
            notifyListeners();
          }
        }
      }, onError: (e) => debugPrint("Firebase: Sync error: $e"));
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
      await _saveState();
      _setupSync();
      _setupNotifications();
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
      _setupSync();
      _setupNotifications();
      notifyListeners();
    }
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
        }
        notifyListeners();
      }
    }
  }

  // Group Management
  void createGroup(String name) {
    if (name.isEmpty) return;
    final newGroup = Group(name: name);
    _groups.add(newGroup);
    _activeGroupId = newGroup.id;
    _cachedActiveGroup = newGroup;
    _saveState();
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
      notifyListeners();
    }
  }

  bool isGroupBalanced(String groupId) {
    final group = _groups.firstWhere((g) => g.id == groupId, orElse: () => _groups.first);
    if (group.people.isEmpty) return true;
    
    if (group.id == _activeGroupId) {
       final balances = _getNetBalances();
       return balances.values.every((v) => v.abs() < 0.01);
    }

    for (final person in group.people) {
      if (getPersonNetBalance(person.id, inGroup: group).abs() > 0.01) return false;
    }
    return true;
  }

  void deleteGroup(String id) {
    if (_groups.length <= 1 || !isGroupBalanced(id)) return;
    _groups.removeWhere((g) => g.id == id);
    if (_activeGroupId == id) {
      _activeGroupId = _groups.isNotEmpty ? _groups.first.id : null;
      _cachedActiveGroup = null;
    }
    _saveState();
    notifyListeners();
  }

  void _updateActiveGroup(Group Function(Group) updater) {
    final idx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (idx != -1) {
      final updated = updater(_groups[idx]);
      _groups[idx] = updated;
      _cachedActiveGroup = updated;
      _saveState();
      notifyListeners();
    }
  }

  void setGroupName(String id, String name) {
    final idx = _groups.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _groups[idx] = _groups[idx].copyWith(name: name);
      if (_activeGroupId == id) _cachedActiveGroup = _groups[idx];
      _saveState();
      notifyListeners();
    }
  }

  // Member Management
  Future<void> addPerson(String name,
      {int? colorIndex, String? avatarUrl}) async {
    if (name.trim().isEmpty || _activeGroupId == null) return;

    final person =
        Person(name: name, colorIndex: colorIndex, avatarUrl: avatarUrl ?? '');
    _updateActiveGroup((g) {
      final updatedPeople = [...g.people, person];
      return g.copyWith(people: updatedPeople);
    });

    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        !avatarUrl.startsWith('http')) {
      final cloudUrl = await _syncService.uploadAvatar(avatarUrl);
      if (cloudUrl != null && cloudUrl != avatarUrl) {
        updatePerson(person.id, avatarUrl: cloudUrl);
      }
    }
  }

  Future<void> updatePerson(String id,
      {String? name, int? colorIndex, String? avatarUrl}) async {
    _updateActiveGroup((g) {
      final pIdx = g.people.indexWhere((p) => p.id == id);
      if (pIdx == -1) return g;
      final updatedPeople = [...g.people];
      updatedPeople[pIdx] = updatedPeople[pIdx]
          .copyWith(name: name, colorIndex: colorIndex, avatarUrl: avatarUrl);
      return g.copyWith(people: updatedPeople);
    });

    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        !avatarUrl.startsWith('http')) {
      final cloudUrl = await _syncService.uploadAvatar(avatarUrl);
      if (cloudUrl != null && cloudUrl != avatarUrl) {
        updatePerson(id, avatarUrl: cloudUrl);
      }
    }
  }

  void removePerson(String id) {
    _updateActiveGroup((g) {
      final updatedPeople = g.people.where((p) => p.id != id).toList();
      final updatedTxs = g.transactions
          .where((t) => t.payerId != id && !t.participantIds.contains(id))
          .toList();
      return g.copyWith(people: updatedPeople, transactions: updatedTxs);
    });
  }

  // Transaction Management
  void addTransaction(Transaction tx) {
    _updateActiveGroup((g) => g.copyWith(transactions: [...g.transactions, tx]));
  }

  void editTransaction(String id, Transaction newTx) {
    _updateActiveGroup((g) {
      final tIdx = g.transactions.indexWhere((t) => t.id == id);
      if (tIdx == -1) return g;
      final updatedTxs = [...g.transactions];
      updatedTxs[tIdx] = newTx;
      return g.copyWith(transactions: updatedTxs);
    });
  }

  void removeTransaction(String id) {
    _updateActiveGroup((g) =>
        g.copyWith(transactions: g.transactions.where((t) => t.id != id).toList()));
  }

  void clearAll() {
    _updateActiveGroup((g) => g.copyWith(people: [], transactions: []));
  }

  void clearExpenses() {
    _updateActiveGroup((g) => g.copyWith(transactions: []));
  }

  // Calculations
  double get weeklyTotal {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return transactions
        .where((t) => !t.isPayment && t.date.isAfter(weekAgo))
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get monthlyTotal {
    final now = DateTime.now();
    return transactions
        .where((t) => !t.isPayment && t.date.month == now.month && t.date.year == now.year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  bool get hasSettlements => transactions.any((t) => t.isPayment || t.description.startsWith('Settle:'));
  List<Settlement> get settlements => _cachedSettlements ??= DebtEngine.settleDebts(people, transactions);

  double getPersonSpent(String personId) =>
      transactions.where((tx) => tx.payerId == personId).fold(0, (sum, tx) => sum + tx.amount);

  double getPersonShare(String personId) {
    double sum = 0;
    for (final tx in transactions) {
      if (tx.participantIds.contains(personId)) {
        if (tx.customAmounts != null) {
          sum += (tx.customAmounts![personId] ?? 0);
        } else {
          sum += (tx.amount / tx.participantIds.length);
        }
      }
    }
    return sum;
  }

  Map<String, double> _getNetBalances() {
    if (_cachedNetBalances != null) return _cachedNetBalances!;
    final map = <String, double>{for (var p in people) p.id: 0.0};
    for (final tx in transactions) {
      map[tx.payerId] = (map[tx.payerId] ?? 0) + tx.amount;
      if (tx.customAmounts != null) {
        for (final pid in tx.participantIds) {
          map[pid] = (map[pid] ?? 0) - (tx.customAmounts![pid] ?? 0);
        }
      } else if (tx.participantIds.isNotEmpty) {
        final share = tx.amount / tx.participantIds.length;
        for (final pid in tx.participantIds) {
          map[pid] = (map[pid] ?? 0) - share;
        }
      }
    }
    return _cachedNetBalances = map;
  }

  double getPersonNetBalance(String personId, {Group? inGroup}) {
    if (inGroup == null || inGroup.id == _activeGroupId) {
      return _getNetBalances()[personId] ?? 0.0;
    }
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
    for (final tx in transactions) { map[tx.category] = (map[tx.category] ?? 0) + tx.amount; }
    return map;
  }

  void settleDebt(String fromId, String toId, double amount, {bool shouldClear = false}) {
    if (amount <= 0) return;
    final pFrom = people.firstWhere((p) => p.id == fromId);
    final pTo = people.firstWhere((p) => p.id == toId);
    final tx = Transaction(
        description: "Settle: ${pFrom.name} ➔ ${pTo.name}",
        amount: amount,
        payerId: fromId,
        participantIds: [toId],
        isPayment: true);
    if (shouldClear) clearExpenses();
    addTransaction(tx);
    if (settlements.isEmpty) clearExpenses();
  }

  Future<void> remindPerson(String personId, double amount) async {
    final person = people.firstWhere((p) => p.id == personId);
    if (person.fcmToken == null) return;
    
    debugPrint('Firebase: Simulating sending reminder to ${person.name} (${person.fcmToken}) for ${amount}');
    // Ideally this would call a Cloud Function or FCM API directly if Server Key is used.
    // For now, we simulate the action and prompt users to finish server setup.
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}
