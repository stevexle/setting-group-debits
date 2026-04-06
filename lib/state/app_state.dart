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
  bool _isLoading = true;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Group? _cachedActiveGroup;
  String? _fcmToken;
  List<Group>? _cachedFilteredGroups;
  User? _currentUser;
  final List<PersonalTransaction> _personalTransactions = [];
  bool _isInitializing = false;

  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();
  StreamSubscription<DocumentSnapshot>? _syncSubscription;
  StreamSubscription<QuerySnapshot>? _groupTxSubscription;
  StreamSubscription<QuerySnapshot>? _groupPlanSubscription;
  StreamSubscription<QuerySnapshot>? _personalTxSubscription;
  StreamSubscription<QuerySnapshot>? _accSubscription;
  StreamSubscription<QuerySnapshot>? _groupsSubscription;
  StreamSubscription? _authSub;

  // Performance Cache
  List<Settlement>? _cachedSettlements;
  Map<String, double>? _cachedNetBalances;
  Map<String, double>? _cachedPA;
  Map<String, double>? _cachedSA;
  Map<Category, double>? _cachedCategorySpend;
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
  }

  @override
  void notifyListeners() {
    _clearCache();
    super.notifyListeners();
  }

  // Basic Getters
  bool get isLoading => _isLoading;
  String? get activeGroupId => _activeGroupId;
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<BudgetPlan> get plans => List.unmodifiable(_plans);
  String get groupName => _activeGroup?.name ?? 'No Group';
  List<Person> get people => _activeGroup?.people ?? const [];
  List<GroupTransaction> get groupTransactions =>
      _activeGroup?.groupTransactions ?? const [];
  List<PersonalTransaction> get personalTransactions =>
      List.unmodifiable(_personalTransactions);

  List<BaseTransaction> get allTransactions {
    final all = <BaseTransaction>[..._personalTransactions];
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  List<BaseTransaction> get transactions => allTransactions;

  bool get isSynced => _activeGroup?.syncId != null;
  String? get syncCode => _activeGroup?.syncId;

  bool get isOwner {
    final group = _activeGroup;
    if (group == null || group.syncId == null) return true;
    return group.ownerId == _currentUser?.uid;
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
    _cachedFilteredGroups = null; // Important for groups list performance
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
