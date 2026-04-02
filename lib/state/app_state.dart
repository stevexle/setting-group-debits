import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../logic/debt_engine.dart';

class AppState extends ChangeNotifier {
  final List<Group> _groups = [];
  String? _activeGroupId;
  bool _isLoading = true;
  Group? _cachedActiveGroup;

  AppState() {
    _loadState();
  }

  bool get isLoading => _isLoading;
  List<Group> get groups => List.unmodifiable(_groups);
  String? get activeGroupId => _activeGroupId;

  Group? get _activeGroup {
    if (_activeGroupId == null || _groups.isEmpty) return null;
    if (_cachedActiveGroup?.id == _activeGroupId) return _cachedActiveGroup;
    try {
      _cachedActiveGroup = _groups.firstWhere((g) => g.id == _activeGroupId);
    } catch (_) {
      _cachedActiveGroup = _groups.first;
      _activeGroupId = _cachedActiveGroup?.id;
    }
    return _cachedActiveGroup;
  }

  String get groupName => _activeGroup?.name ?? 'No Group';
  List<Person> get people => _activeGroup?.people ?? const [];
  List<Transaction> get transactions => _activeGroup?.transactions ?? const [];

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = prefs.getString('groups_v2');
      if (groupsJson != null) {
        final List decode = jsonDecode(groupsJson);
        _groups.clear();
        _groups.addAll(decode.map((g) => Group.fromJson(g)));
      } else {
        final pJson = prefs.getString('people');
        final tJson = prefs.getString('transactions');
        final gName = prefs.getString('groupName') ?? 'My First Group';
        List<Person> pList = [];
        List<Transaction> tList = [];
        if (pJson != null) pList = (jsonDecode(pJson) as List).map((p) => Person.fromJson(p)).toList();
        if (tJson != null) tList = (jsonDecode(tJson) as List).map((t) => Transaction.fromJson(t)).toList();
        final defaultGroup = Group(name: gName, people: pList, transactions: tList);
        _groups.add(defaultGroup);
        _activeGroupId = defaultGroup.id;
        _saveState();
      }
      _activeGroupId ??= prefs.getString('activeGroupId') ?? (_groups.isNotEmpty ? _groups.first.id : null);
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
    } catch (e) {
      debugPrint("Error saving state: $e");
    }
  }

  void createGroup(String name) {
    final newGroup = Group(name: name);
    _groups.add(newGroup);
    _activeGroupId = newGroup.id;
    _cachedActiveGroup = newGroup;
    _saveState();
    notifyListeners();
  }

  void switchGroup(String id) {
    if (_groups.any((g) => g.id == id)) {
      _activeGroupId = id;
      _cachedActiveGroup = null;
      _saveState();
      notifyListeners();
    }
  }

  bool isGroupBalanced(String groupId) {
    final group = _groups.firstWhere((g) => g.id == groupId, orElse: () => _groups.first);
    if (group.people.isEmpty) return true;
    for (final person in group.people) {
      final pid = person.id;
      double net = 0;
      for (final tx in group.transactions) {
        if (tx.payerId == pid) net += tx.amount;
        if (tx.participantIds.contains(pid)) {
          if (tx.customAmounts != null) {
            net -= (tx.customAmounts![pid] ?? 0);
          } else {
            net -= (tx.amount / tx.participantIds.length);
          }
        }
      }
      if (net.abs() > 0.01) return false;
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

  void setGroupName(String id, String name) {
    final idx = _groups.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _groups[idx] = _groups[idx].copyWith(name: name);
      if (_activeGroupId == id) _cachedActiveGroup = _groups[idx];
      _saveState();
      notifyListeners();
    }
  }

  void addPerson(String name, {int? colorIndex, String? avatarUrl}) {
    if (name.trim().isEmpty || _activeGroupId == null) return;
    final idx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (idx != -1) {
      final updatedPeople = [..._groups[idx].people, Person(name: name, colorIndex: colorIndex, avatarUrl: avatarUrl ?? '')];
      _groups[idx] = _groups[idx].copyWith(people: updatedPeople);
      _cachedActiveGroup = _groups[idx];
      _saveState();
      notifyListeners();
    }
  }

  void updatePerson(String id, {String? name, int? colorIndex, String? avatarUrl}) {
    final gIdx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (gIdx != -1) {
      final pIdx = _groups[gIdx].people.indexWhere((p) => p.id == id);
      if (pIdx != -1) {
        final updatedPeople = [..._groups[gIdx].people];
        updatedPeople[pIdx] = updatedPeople[pIdx].copyWith(name: name, colorIndex: colorIndex, avatarUrl: avatarUrl);
        _groups[gIdx] = _groups[gIdx].copyWith(people: updatedPeople);
        _cachedActiveGroup = _groups[gIdx];
        _saveState();
        notifyListeners();
      }
    }
  }

  void removePerson(String id) {
    final gIdx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (gIdx != -1) {
      final updatedPeople = _groups[gIdx].people.where((p) => p.id != id).toList();
      final updatedTxs = _groups[gIdx].transactions.where((t) => t.payerId != id && !t.participantIds.contains(id)).toList();
      _groups[gIdx] = _groups[gIdx].copyWith(people: updatedPeople, transactions: updatedTxs);
      _cachedActiveGroup = _groups[gIdx];
      _saveState();
      notifyListeners();
    }
  }

  void addTransaction(Transaction tx) {
    final idx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (idx != -1) {
      final updatedTxs = [..._groups[idx].transactions, tx];
      _groups[idx] = _groups[idx].copyWith(transactions: updatedTxs);
      _cachedActiveGroup = _groups[idx];
      _saveState();
      notifyListeners();
    }
  }

  void editTransaction(String id, Transaction newTx) {
    final gIdx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (gIdx != -1) {
      final tIdx = _groups[gIdx].transactions.indexWhere((t) => t.id == id);
      if (tIdx != -1) {
        final updatedTxs = [..._groups[gIdx].transactions];
        updatedTxs[tIdx] = newTx;
        _groups[gIdx] = _groups[gIdx].copyWith(transactions: updatedTxs);
        _cachedActiveGroup = _groups[gIdx];
        _saveState();
        notifyListeners();
      }
    }
  }

  void removeTransaction(String id) {
    final gIdx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (gIdx != -1) {
      final updatedTxs = _groups[gIdx].transactions.where((t) => t.id != id).toList();
      _groups[gIdx] = _groups[gIdx].copyWith(transactions: updatedTxs);
      _cachedActiveGroup = _groups[gIdx];
      _saveState();
      notifyListeners();
    }
  }

  void clearAll() {
    final gIdx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (gIdx != -1) {
      _groups[gIdx] = _groups[gIdx].copyWith(people: [], transactions: []);
      _cachedActiveGroup = _groups[gIdx];
      _saveState();
      notifyListeners();
    }
  }

  void clearExpenses() {
    final gIdx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (gIdx != -1) {
      _groups[gIdx] = _groups[gIdx].copyWith(transactions: []);
      _cachedActiveGroup = _groups[gIdx];
      _saveState();
      notifyListeners();
    }
  }

  double get weeklyTotal {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    double sum = 0;
    for (final t in transactions) { if (!t.isPayment && t.date.isAfter(weekAgo)) sum += t.amount; }
    return sum;
  }

  double get monthlyTotal {
    final now = DateTime.now();
    double sum = 0;
    for (final t in transactions) { if (!t.isPayment && t.date.month == now.month && t.date.year == now.year) sum += t.amount; }
    return sum;
  }

  bool get hasSettlements => transactions.any((t) => t.isPayment || t.description.startsWith('Settle:'));
  List<Settlement> get settlements => DebtEngine.settleDebts(people, transactions);

  double getPersonSpent(String personId) {
    double sum = 0;
    for (final tx in transactions) { if (tx.payerId == personId) sum += tx.amount; }
    return sum;
  }

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

  double getPersonNetBalance(String personId) {
    double net = 0;
    for (final tx in transactions) {
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
    if (amount <= 0 || _activeGroupId == null) return;
    final pFrom = people.firstWhere((p) => p.id == fromId);
    final pTo = people.firstWhere((p) => p.id == toId);
    final tx = Transaction(description: "Settle: ${pFrom.name} ➔ ${pTo.name}", amount: amount, payerId: fromId, participantIds: [toId], date: DateTime.now(), isPayment: true);
    if (shouldClear) clearExpenses();
    addTransaction(tx);
    if (settlements.isEmpty) clearExpenses();
  }
}
