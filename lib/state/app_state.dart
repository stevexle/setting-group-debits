import 'dart:convert';
import 'package:setting_group_debits/services/log_service.dart';
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
  final List<Account> _accounts = [];
  final List<BudgetPlan> _plans = [];
  String? _activeGroupId;
  bool _isLoading = true;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Group? _cachedActiveGroup;
  String? _fcmToken;
  User? _currentUser;
  final List<PersonalTransaction> _personalTransactions = [];
  bool _isInitializing = false;

  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();
  StreamSubscription<DocumentSnapshot>? _syncSubscription;
  StreamSubscription<QuerySnapshot>? _groupTxSubscription;
  StreamSubscription<QuerySnapshot>? _personalTxSubscription;
  StreamSubscription<QuerySnapshot>? _accSubscription;

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
      if (user != null) {
        log.setUserIdentifier(user.uid);
        _setupAccSync();
        _setupPersonalTxSync();
        if (_activeGroupId != null) {
          _autoClaimMe();
        }
      } else {
        _accSubscription?.cancel();
        _personalTxSubscription?.cancel();
      }
    });
  }

  Future<void> _autoClaimMe() async {
    if (_currentUser == null || _activeGroupId == null) return;
    final group = _activeGroup;
    if (group == null) return;

    final prefs = await SharedPreferences.getInstance();
    final localClaimedId = prefs.getString('claimedPersonId_$_activeGroupId');

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

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<BudgetPlan> get plans => List.unmodifiable(_plans);
  String get groupName => _activeGroup?.name ?? 'No Group';
  List<Person> get people => _activeGroup?.people ?? const [];
  
  List<GroupTransaction> get groupTransactions => _activeGroup?.groupTransactions ?? const [];
  List<PersonalTransaction> get personalTransactions => List.unmodifiable(_personalTransactions);
  
  List<BaseTransaction> get allTransactions {
    final all = <BaseTransaction>[...groupTransactions, ..._personalTransactions];
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  // Support legacy UI that expects 'transactions'
  List<BaseTransaction> get transactions => allTransactions;

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

      final accountsJson = prefs.getString('accounts');
      if (accountsJson != null) {
        final List decode = jsonDecode(accountsJson);
        _accounts.clear();
        _accounts.addAll(decode.map((a) => Account.fromJson(Map<String, dynamic>.from(a))));
      }

      final plansJson = prefs.getString('plans');
      if (plansJson != null) {
        final List decode = jsonDecode(plansJson);
        _plans.clear();
        _plans.addAll(decode.map((p) => BudgetPlan.fromJson(Map<String, dynamic>.from(p))));
      }

      _activeGroupId ??= prefs.getString('activeGroupId') ?? (_groups.isNotEmpty ? _groups.first.id : null);

      final personalTxsJson = prefs.getString('personal_transactions');
      if (personalTxsJson != null) {
        final List decode = jsonDecode(personalTxsJson);
        _personalTransactions.clear();
        _personalTransactions.addAll(decode.map((t) => PersonalTransaction.fromJson(Map<String, dynamic>.from(t))));
      }

      if (_activeGroupId != null) {
        _setupSync();
        _setupNotifications();
      }
    } catch (e, s) {
      log.error("AppState: Load state error", e, s);
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      await _autoClaimMe();
      _isInitializing = false;
    }
  }

  Future<void> _saveState() async {
    if (!_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = jsonEncode(_groups.map((g) => g.toJson()).toList());
      await prefs.setString('groups_v2', groupsJson);
      
      final accountsJson = jsonEncode(_accounts.map((a) => a.toJson()).toList());
      await prefs.setString('accounts', accountsJson);

      final plansJson = jsonEncode(_plans.map((p) => p.toJson()).toList());
      await prefs.setString('plans', plansJson);

      final personalTxsJson = jsonEncode(_personalTransactions.map((t) => t.toJson()).toList());
      await prefs.setString('personal_transactions', personalTxsJson);

      if (_activeGroupId != null) await prefs.setString('activeGroupId', _activeGroupId!);

      if (!_isInitializing) {
        final group = _activeGroup;
        if (group?.syncId != null) {
          await _syncService.pushUpdate(group!);
        }
      }
    } catch (e, s) {
      log.error("AppState: Save state error", e, s);
    }
  }

  Future<void> _setupNotifications() async {
    final ns = NotificationService();
    final group = _activeGroup;
    if (group?.syncId != null) await ns.subscribeToGroup(group!.syncId!);

    _fcmToken = await ns.getToken();
    if (_fcmToken != null && _activeGroupId != null) {
      final prefs = await SharedPreferences.getInstance();
      final claimedId = prefs.getString('claimedPersonId_$activeGroupId');
      if (claimedId != null) await claimPerson(claimedId);
    }
  }

  void _setupSync() {
    _syncSubscription?.cancel();
    _groupTxSubscription?.cancel();
    final group = _activeGroup;
    if (group?.syncId != null) {
      final syncId = group!.syncId!;

      _syncSubscription = _syncService.getSyncStream(syncId).listen((doc) {
        if (doc.exists) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          final remoteGroup = Group.fromJson(data);
          final idx = _groups.indexWhere((g) => g.id == group.id);
          if (idx != -1) {
            _groups[idx] = remoteGroup.copyWith(groupTransactions: _groups[idx].groupTransactions);
            _cachedActiveGroup = _groups[idx];
            _saveState(); 
            notifyListeners();
          }
        }
      });

      _groupTxSubscription = _syncService.getGroupTransactionsStream(syncId).listen((snap) {
        final List<GroupTransaction> remoteTxs = snap.docs
            .map((d) => GroupTransaction.fromJson(Map<String, dynamic>.from(d.data() as Map<String, dynamic>)))
            .toList();

        final idx = _groups.indexWhere((g) => g.id == group.id);
        if (idx != -1) {
          _groups[idx] = _groups[idx].copyWith(groupTransactions: remoteTxs);
          _cachedActiveGroup = _groups[idx];
          _saveState(); 
          notifyListeners();
        }
      });
    }
    _setupPersonalTxSync();
  }

  void _setupPersonalTxSync() {
    _personalTxSubscription?.cancel();
    if (_currentUser == null) return;

    _personalTxSubscription = _syncService.getPersonalTransactionsStream(_currentUser!.uid).listen((snap) {
      final List<PersonalTransaction> remoteTxs = snap.docs
          .map((d) => PersonalTransaction.fromJson(Map<String, dynamic>.from(d.data() as Map<String, dynamic>)))
          .toList();

      _personalTransactions.clear();
      _personalTransactions.addAll(remoteTxs);
      _saveState();
      notifyListeners();
    });
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
        await prefs.setString('claimedPersonId_$_activeGroupId', personId);
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

  Future<void> createGroup(String name, {GroupType type = GroupType.settlement}) async {
    if (name.isEmpty) return;
    Group newGroup = Group(name: name, type: type);

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
    return groupTransactions.any((t) => t.payerId == id || t.participants.contains(id));
  }

  bool removePerson(String id) {
    if (id == me?.id) return false;
    if (isPersonInvolvedInTransactions(id)) return false;
    
    _updateActiveGroup((g) {
      final updatedPeople = g.people.where((p) => p.id != id).toList();
      return g.copyWith(people: updatedPeople);
    });
    return true;
  }

  Future<void> addGroupTransaction(GroupTransaction tx) async {
    final group = _activeGroup;
    if (group == null) return;
    _updateActiveGroup((g) => g.copyWith(groupTransactions: [tx, ...g.groupTransactions]));
    if (group.syncId != null) await _syncService.pushGroupTransaction(group.syncId!, tx);
    
    // Adjust account balance
    await _adjustAccountBalance(tx.sourceAccountId, tx.isPayment ? tx.amount : -tx.amount);
    
    notifyListeners();
  }

  Future<void> addPersonalTransaction(PersonalTransaction tx) async {
    _personalTransactions.insert(0, tx);
    if (_currentUser != null) await _syncService.pushPersonalTransaction(_currentUser!.uid, tx);
    
    // Adjust account balance
    await _adjustAccountBalance(tx.sourceAccountId, tx.isPayment ? tx.amount : -tx.amount);
    
    await _saveState();
    notifyListeners();
  }

  Future<void> removeGroupTransaction(String id) async {
    final group = _activeGroup;
    final txIdx = group?.groupTransactions.indexWhere((t) => t.id == id) ?? -1;
    if (txIdx != -1) {
      final tx = group!.groupTransactions[txIdx];
      _updateActiveGroup((g) => g.copyWith(groupTransactions: g.groupTransactions.where((t) => t.id != id).toList()));
      if (group.syncId != null) await _syncService.deleteGroupTransaction(group.syncId!, id);
      
      // Revert account balance shift
      await _adjustAccountBalance(tx.sourceAccountId, tx.isPayment ? -tx.amount : tx.amount);
    }
    notifyListeners();
  }

  Future<void> removePersonalTransaction(String id) async {
    final pIdx = _personalTransactions.indexWhere((t) => t.id == id);
    if (pIdx != -1) {
      final tx = _personalTransactions[pIdx];
      _personalTransactions.removeAt(pIdx);
      if (_currentUser != null) await _syncService.deletePersonalTransaction(_currentUser!.uid, id);
      
      // Revert account balance shift
      await _adjustAccountBalance(tx.sourceAccountId, tx.isPayment ? -tx.amount : tx.amount);
      
      await _saveState();
      notifyListeners();
    }
  }

  Future<void> editGroupTransaction(String id, GroupTransaction newTx) async {
    final group = _activeGroup;
    final tIdx = group?.groupTransactions.indexWhere((t) => t.id == id) ?? -1;
    if (tIdx == -1) return;
    
    final oldTx = group!.groupTransactions[tIdx];
    
    _updateActiveGroup((g) {
      final updatedTxs = [...g.groupTransactions];
      updatedTxs[tIdx] = newTx.copyWith(
        updatedAt: (oldTx.amount != newTx.amount) ? DateTime.now() : oldTx.updatedAt,
        amountChanged: (oldTx.amount != newTx.amount) || oldTx.amountChanged,
      );
      return g.copyWith(groupTransactions: updatedTxs);
    });

    if (group.syncId != null) {
      final updatedTx = groupTransactions.firstWhere((t) => t.id == id);
      await _syncService.pushGroupTransaction(group.syncId!, updatedTx);
    }

    // Adjust balance: Revert old, Apply new
    await _adjustAccountBalance(oldTx.sourceAccountId, oldTx.isPayment ? -oldTx.amount : oldTx.amount);
    await _adjustAccountBalance(newTx.sourceAccountId, newTx.isPayment ? newTx.amount : -newTx.amount);

    notifyListeners();
  }

  Future<void> editPersonalTransaction(String id, PersonalTransaction newTx) async {
    final tIdx = _personalTransactions.indexWhere((t) => t.id == id);
    if (tIdx != -1) {
      final oldTx = _personalTransactions[tIdx];
      _personalTransactions[tIdx] = newTx.copyWith(updatedAt: DateTime.now());
      if (_currentUser != null) await _syncService.pushPersonalTransaction(_currentUser!.uid, _personalTransactions[tIdx]);
      
      // Adjust balance: Revert old, Apply new
      await _adjustAccountBalance(oldTx.sourceAccountId, oldTx.isPayment ? -oldTx.amount : oldTx.amount);
      await _adjustAccountBalance(newTx.sourceAccountId, newTx.isPayment ? newTx.amount : -newTx.amount);

      await _saveState();
      notifyListeners();
    }
  }

  Future<void> _adjustAccountBalance(String? accountId, double delta) async {
    if (accountId == null || delta == 0) return;
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      final updatedAccount = _accounts[idx].copyWith(
        currentBalance: _accounts[idx].currentBalance + delta,
      );
      await updateAccount(updatedAccount);
    }
  }

  Future<void> clearAll() async {
    final syncId = _activeGroup?.syncId;
    if (syncId != null) await _syncService.purgeTransactions(syncId);
    final currentUserPerson = people.where((p) => p.userId == _currentUser?.uid).firstOrNull;
    final updatedPeople = currentUserPerson != null ? [currentUserPerson] : <Person>[];
    _updateActiveGroup((g) => g.copyWith(groupTransactions: [], people: updatedPeople));
    
    _personalTransactions.clear();
    if (_currentUser != null) {
      // Purge cloud personal txs? For now just local
    }
    await _saveState();
    notifyListeners();
  }

  Future<void> clearExpenses() async {
    final group = _activeGroup;
    if (group?.syncId != null) await _syncService.purgeTransactions(group!.syncId!);
    _updateActiveGroup((g) => g.copyWith(groupTransactions: []));
    notifyListeners();
  }

  // Account & Plan Management
  Future<void> addAccount(Account account) async {
    _accounts.add(account);
    if (_currentUser != null) {
      await _syncService.pushAccount(_currentUser!.uid, account);
    }
    await _saveState();
    notifyListeners();
  }

  Future<void> removeAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    if (_currentUser != null) {
      await _syncService.deleteAccount(_currentUser!.uid, id);
    }
    await _saveState();
    notifyListeners();
  }

  Future<void> updateAccount(Account account) async {
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      _accounts[idx] = account;
      if (_currentUser != null) {
        await _syncService.pushAccount(_currentUser!.uid, account);
      }
      await _saveState();
      notifyListeners();
    }
  }

  void _setupAccSync() {
    _accSubscription?.cancel();
    if (_currentUser == null) return;
    
    _accSubscription = _syncService.getAccountsStream(_currentUser!.uid).listen((snap) {
      final cloudAccs = snap.docs.map((d) => Account.fromJson(Map<String, dynamic>.from(d.data() as Map))).toList();
      
      // Merge logic: simpler is to just replace for now if synced
      if (cloudAccs.isNotEmpty) {
        _accounts.clear();
        _accounts.addAll(cloudAccs);
        _saveState();
        notifyListeners();
      }
    });
  }

  Future<void> addPlan(BudgetPlan plan) async {
    _plans.add(plan);
    await _saveState();
    notifyListeners();
  }

  Future<void> removePlan(String id) async {
    _plans.removeWhere((p) => p.id == id);
    await _saveState();
    notifyListeners();
  }

  Future<void> updatePlan(BudgetPlan plan) async {
    final idx = _plans.indexWhere((p) => p.id == plan.id);
    if (idx != -1) {
      _plans[idx] = plan;
      await _saveState();
      notifyListeners();
    }
  }

  double get totalNetWorth => _accounts.fold(0.0, (sum, a) => sum + a.currentBalance);

  // Personal Statistics
  double get weeklyPersonalTotal {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _personalTransactions.where((t) => !t.isPayment && t.date.isAfter(weekAgo)).fold(0.0, (total, t) => total + t.amount);
  }

  double get monthlyPersonalTotal {
    final now = DateTime.now();
    return _personalTransactions.where((t) => !t.isPayment && t.date.month == now.month && t.date.year == now.year).fold(0.0, (total, t) => total + t.amount);
  }

  // Group Statistics
  double get weeklyGroupTotal {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return groupTransactions.where((t) => !t.isPayment && t.date.isAfter(weekAgo)).fold(0.0, (total, t) => total + t.amount);
  }

  double get monthlyGroupTotal {
    final now = DateTime.now();
    return groupTransactions.where((t) => !t.isPayment && t.date.month == now.month && t.date.year == now.year).fold(0.0, (total, t) => total + t.amount);
  }

  bool get hasSettlements => groupTransactions.any((t) => t.isPayment || t.description.startsWith('Settle:'));
  List<Settlement> get settlements => _cachedSettlements ??= DebtEngine.settleDebts(people, groupTransactions);
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
    
    for (final tx in groupTransactions) {
      paidMap[tx.payerId] = (paidMap[tx.payerId] ?? 0) + tx.amount;
      netMap[tx.payerId] = (netMap[tx.payerId] ?? 0) + tx.amount;
      if (tx.customAmounts != null) {
        for (final pid in tx.participants) {
          final val = tx.customAmounts![pid] ?? 0;
          shareMap[pid] = (shareMap[pid] ?? 0) + val;
          netMap[pid] = (netMap[pid] ?? 0) - val;
        }
      } else if (tx.participants.isNotEmpty) {
        final share = tx.amount / tx.participants.length;
        for (final pid in tx.participants) {
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
    for (final tx in inGroup.groupTransactions) {
      if (tx.payerId == personId) net += tx.amount;
      if (tx.participants.contains(personId)) {
        if (tx.customAmounts != null) {
          net -= (tx.customAmounts![personId] ?? 0);
        } else {
          net -= (tx.amount / tx.participants.length);
        }
      }
    }
    return net;
  }

  Map<Category, double> get categorySpend {
    final map = <Category, double>{};
    for (final tx in allTransactions) {
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    return map;
  }

  void settleDebt(String fromId, String toId, double amount, {String? sourceAccountId, bool shouldClear = false}) {
    if (amount <= 0) return;
    final pFrom = people.firstWhere((p) => p.id == fromId);
    final pTo = people.firstWhere((p) => p.id == toId);
    final tx = GroupTransaction(
      description: "Settle: ${pFrom.name} ➔ ${pTo.name}", 
      amount: amount, 
      payerId: fromId, 
      participants: [toId], 
      isPayment: true,
      sourceAccountId: sourceAccountId,
    );
    if (shouldClear) clearExpenses();
    
    // Add transaction
    _updateActiveGroup((g) => g.copyWith(groupTransactions: [tx, ...g.groupTransactions]));
    if (_activeGroup?.syncId != null) _syncService.pushGroupTransaction(_activeGroup!.syncId!, tx);
    
    // Adjust account balance (Inflow if receiving, outflow if paying)
    if (sourceAccountId != null) {
      final isReceiving = toId == me?.id;
      _adjustAccountBalance(sourceAccountId, isReceiving ? amount : -amount);
    }
    
    notifyListeners();
  }

  void linkGroupTransactionToWallet(String groupTxId, String accountId) {
    if (me == null) return;
    final group = _activeGroup;
    if (group == null) return;

    final txIdx = group.groupTransactions.indexWhere((t) => t.id == groupTxId);
    if (txIdx == -1) return;

    final originalTx = group.groupTransactions[txIdx];
    final myUid = me!.id;

    // Check if already linked
    if (originalTx.participantBalances?.containsKey(myUid) ?? false) return;

    final updatedBalances = Map<String, String>.from(originalTx.participantBalances ?? {});
    updatedBalances[myUid] = accountId;

    final updatedTx = originalTx.copyWith(participantBalances: updatedBalances);

    // Update locally
    final updatedTxs = [...group.groupTransactions];
    updatedTxs[txIdx] = updatedTx;
    _updateActiveGroup((g) => g.copyWith(groupTransactions: updatedTxs));

    // Update cloud
    if (group.syncId != null) {
      _syncService.pushGroupTransaction(group.syncId!, updatedTx);
    }

    // Adjust balance for incoming payments
    if (originalTx.isPayment && originalTx.participants.contains(myUid)) {
      _adjustAccountBalance(accountId, originalTx.amount);
    }
    
    _saveState();
    notifyListeners();
  }

  Future<void> remindPerson(String personId, double amount) async {
    final person = people.firstWhere((p) => p.id == personId);
    if (person.fcmToken != null) log.info('Firebase: Reminder to ${person.name} (${person.fcmToken}) for $amount');
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _groupTxSubscription?.cancel();
    _personalTxSubscription?.cancel();
    _accSubscription?.cancel();
    super.dispose();
  }
}
