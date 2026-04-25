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

part 'parts/app_state_auth.dart';
part 'parts/app_state_groups.dart';
part 'parts/app_state_transactions.dart';
part 'parts/app_state_finance.dart';
part 'parts/app_state_sync.dart';
part 'parts/app_state_stats.dart';

class AppState extends ChangeNotifier {
  final List<Group> _groups = [];
  final List<Account> _accounts = [];
  final List<BudgetPlan> _plans = [];
  String? _activeGroupId;
  String? _billShareGroupId; // Last selected settlement group
  String? _planningGroupId; // Last selected planning group
  bool _isLoading = true;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Group? _cachedActiveGroup;
  String? _fcmToken;
  List<Group>? _cachedFilteredGroups;
  User? _currentUser;
  UserProfile? _userProfile;
  final List<PersonalTransaction> _personalTransactions = [];
  bool _isInitializing = false;

  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();
  UserProfile? get userProfile => _userProfile;
  StreamSubscription<DocumentSnapshot>? _syncSubscription;
  StreamSubscription<QuerySnapshot>? _groupTxSubscription;
  StreamSubscription<QuerySnapshot>? _groupPlanSubscription;
  StreamSubscription<QuerySnapshot>? _personalTxSubscription;
  StreamSubscription<QuerySnapshot>? _accSubscription;
  StreamSubscription<QuerySnapshot>? _groupsSubscription;
  StreamSubscription? _authSub;
  bool _isLoadingAuth = false;

  // Performance Cache
  List<Settlement>? _cachedSettlements;
  Map<String, double>? _cachedNetBalances;
  Map<String, double>? _cachedPA;
  Map<String, double>? _cachedSA;
  Map<Category, double>? _cachedCategorySpend;
  List<BaseTransaction>? _cachedAllTransactions;
  double? _cachedTotalNetWorth;
  double? _cachedWeeklyPersonal;
  double? _cachedMonthlyPersonal;
  double? _cachedWeeklyGroup;
  double? _cachedMonthlyGroup;
  final Map<String, bool> _balancedCache = {};

  AppState() {
    _initAuth();
    _loadState();
  }

  void _clearCache() {
    _cachedSettlements = null;
    _cachedNetBalances = null;
    _cachedPA = null;
    _cachedSA = null;
    _cachedCategorySpend = null;
    _cachedAllTransactions = null;
    _cachedTotalNetWorth = null;
    _cachedWeeklyPersonal = null;
    _cachedMonthlyPersonal = null;
    _cachedWeeklyGroup = null;
    _cachedMonthlyGroup = null;
    _cachedFilteredGroups = null;
    _balancedCache.clear();
  }

  @override
  void notifyListeners() {
    _clearCache();
    super.notifyListeners();
  }

  // Basic Getters
  bool get isLoading => _isLoading;
  String? get activeGroupId => _activeGroupId;
  String? get billShareGroupId => _billShareGroupId;
  String? get planningGroupId => _planningGroupId;

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<BudgetPlan> get plans => List.unmodifiable(_plans);
  
  String get groupName => _activeGroup?.name ?? 'No Group';
  List<Person> get people => _activeGroup?.people ?? const [];
  List<GroupTransaction> get groupTransactions =>
      _activeGroup?.groupTransactions ?? const [];

  // Module Specific Getters
  Group? get activeSettlementGroup {
    if (_billShareGroupId != null) {
      final idx = _groups.indexWhere((g) => g.id == _billShareGroupId);
      if (idx != -1 && _groups[idx].type == GroupType.settlement) return _groups[idx];
    }
    try {
      return _groups.firstWhere((g) => g.type == GroupType.settlement);
    } catch (_) {
      return _activeGroup;
    }
  }

  Group? get activePlanningGroup {
    if (_planningGroupId != null) {
      final idx = _groups.indexWhere((g) => g.id == _planningGroupId);
      if (idx != -1 && _groups[idx].type == GroupType.planning) return _groups[idx];
    }
    try {
      return _groups.firstWhere((g) => g.type == GroupType.planning);
    } catch (_) {
      return _activeGroup;
    }
  }

  List<PersonalTransaction> get personalTransactions =>
      List.unmodifiable(_personalTransactions);

  List<BaseTransaction> get allTransactions {
    if (_cachedAllTransactions != null) return _cachedAllTransactions!;
    final List<BaseTransaction> all = [];
    final myPersonIdsList = myPersonIds;

    // Add relevant GroupTransactions from ALL groups
    for (final group in _groups) {
      for (final gTx in group.groupTransactions) {
        final isMyOutflow = myPersonIdsList.contains(gTx.payerId);
        final isMyInflow = gTx.isPayment &&
            gTx.participants.any((pId) => myPersonIdsList.contains(pId));

        if (isMyOutflow || isMyInflow) {
          // Tag with group name for UI if needed, or just add
          all.add(gTx);
        }
      }
    }

    // Add only non-linked PersonalTransactions (to avoid duplicates)
    for (final pTx in _personalTransactions) {
      // A personal transaction is linked if it has a groupId and its ID starts with p_
      final isLinked = pTx.id.startsWith('p_') && pTx.groupId != null;
      if (!isLinked) {
        all.add(pTx);
      }
    }

    all.sort((a, b) => b.date.compareTo(a.date));
    _cachedAllTransactions = all;
    return all;
  }

  List<BaseTransaction> get transactions => allTransactions;

  bool get isSynced => _activeGroup?.syncId != null;
  String? get syncCode => _activeGroup?.syncId;

  // Auth Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoadingAuth => _isLoadingAuth;

  Person? get me => getMeForGroup(_activeGroup);

  Person? getMeForGroup(Group? group) {
    if (_currentUser == null || group == null) return null;
    try {
      return group.people.firstWhere((p) =>
          p.userId == _currentUser!.uid ||
          (p.email != null && p.email == _currentUser!.email));
    } catch (_) {
      return null;
    }
  }

  Future<void> signInWithGoogle() => _signInWithGoogle();
  Future<void> signOut() => _signOut();

  bool get isOwner {
    final group = _activeGroup;
    if (group == null || group.syncId == null) return true;
    return group.ownerId == _currentUser?.uid;
  }

  void _removeLocalGroup(String? syncId, String? groupId) {
    if (syncId == null && groupId == null) return;
    _groups.removeWhere((g) => (syncId != null && g.syncId == syncId) || (groupId != null && g.id == groupId));
    if (_activeGroupId == groupId || (syncId != null && _activeGroup?.syncId == syncId)) {
      _activeGroupId = _groups.isNotEmpty ? _groups.first.id : null;
      _cachedActiveGroup = null;
    }
    _saveState();
    notifyListeners();
  }
  
  bool get hasAnyPendingTransactions {
    return groupTransactions.any((t) => t.status == TransactionStatus.pending);
  }

  bool get hasPendingConfirmations {
    final meId = me?.id;
    if (meId == null) return false;
    return groupTransactions.any((t) =>
        t.isPayment &&
        t.status == TransactionStatus.pending &&
        t.participants.contains(meId));
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

  // Core Persistence
  Future<void> _loadState() async {
    _isInitializing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = prefs.getString('groups_v2');
      if (groupsJson != null) {
        final List decode = jsonDecode(groupsJson);
        _groups.clear();
        _groups.addAll(
            decode.map((g) => Group.fromJson(Map<String, dynamic>.from(g))));
      } else {
        _activeGroupId = null;
      }

      final accountsJson = prefs.getString('accounts');
      if (accountsJson != null) {
        final List decode = jsonDecode(accountsJson);
        _accounts.clear();
        _accounts.addAll(
            decode.map((a) => Account.fromJson(Map<String, dynamic>.from(a))));
      }

      final plansJson = prefs.getString('plans');
      if (plansJson != null) {
        final List decode = jsonDecode(plansJson);
        _plans.clear();
        _plans.addAll(
            decode.map((p) => BudgetPlan.fromJson(Map<String, dynamic>.from(p))));
      }

      _activeGroupId ??= prefs.getString('activeGroupId') ??
          (_groups.isNotEmpty ? _groups.first.id : null);
      _billShareGroupId = prefs.getString('billShareGroupId');
      _planningGroupId = prefs.getString('planningGroupId');

      final personalTxsJson = prefs.getString('personal_transactions');
      if (personalTxsJson != null) {
        final List decode = jsonDecode(personalTxsJson);
        _personalTransactions.clear();
        _personalTransactions.addAll(decode.map((t) =>
            PersonalTransaction.fromJson(Map<String, dynamic>.from(t))));
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

      final accountsJson =
          jsonEncode(_accounts.map((a) => a.toJson()).toList());
      await prefs.setString('accounts', accountsJson);

      final plansJson = jsonEncode(_plans.map((p) => p.toJson()).toList());
      await prefs.setString('plans', plansJson);

      final personalTxsJson =
          jsonEncode(_personalTransactions.map((t) => t.toJson()).toList());
      await prefs.setString('personal_transactions', personalTxsJson);

      if (_activeGroupId != null) {
        await prefs.setString('activeGroupId', _activeGroupId!);
      }
      if (_billShareGroupId != null) {
        await prefs.setString('billShareGroupId', _billShareGroupId!);
      }
      if (_planningGroupId != null) {
        await prefs.setString('planningGroupId', _planningGroupId!);
      }
    } catch (e, s) {
      log.error("AppState: Save state error", e, s);
    }
  }

  void _notify() {
    _cachedSettlements = null;
    _cachedNetBalances = null;
    _cachedPA = null;
    _cachedSA = null;
    _cachedCategorySpend = null;
    _cachedFilteredGroups = null;
    _balancedCache.clear();
    notifyListeners();
  }

  Future<void> _updateActiveGroup(Group Function(Group) updater,
      {bool syncMetadata = false}) async {
    final idx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (idx != -1) {
      _groups[idx] = updater(_groups[idx]);
      _cachedActiveGroup = _groups[idx];
      await _saveState();
      if (syncMetadata) await _syncGroupMetadata();
      _notify(); // Use the optimized notify
    }
  }

  List<String> get myPersonIds {
    if (_currentUser == null) return [];
    final ids = <String>[];
    for (final g in _groups) {
      for (final p in g.people) {
        if (p.userId == _currentUser!.uid ||
            (p.email != null && p.email == _currentUser!.email)) {
          ids.add(p.id);
        }
      }
    }
    return ids;
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _groupTxSubscription?.cancel();
    _groupPlanSubscription?.cancel();
    _personalTxSubscription?.cancel();
    _accSubscription?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
