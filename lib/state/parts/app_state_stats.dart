part of '../app_state.dart';

extension AppStateStats on AppState {
  double get totalNetWorth {
    if (_cachedTotalNetWorth != null) return _cachedTotalNetWorth!;
    double total = 0;
    for (var acc in _accounts) {
      total += acc.currentBalance;
    }
    _cachedTotalNetWorth = total;
    return total;
  }

  double get weeklyPersonalTotal {
    if (_cachedWeeklyPersonal != null) return _cachedWeeklyPersonal!;
    double total = 0;
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    for (var tx in allTransactions) {
      if (!tx.isPayment && !tx.date.isBefore(weekStart)) total += tx.amount;
    }
    _cachedWeeklyPersonal = total;
    return total;
  }

  double get monthlyPersonalTotal {
    if (_cachedMonthlyPersonal != null) return _cachedMonthlyPersonal!;
    double total = 0;
    final now = DateTime.now();
    for (var tx in allTransactions) {
      if (tx.date.month == now.month &&
          tx.date.year == now.year &&
          !tx.isPayment) {
        total += tx.amount;
      }
    }
    _cachedMonthlyPersonal = total;
    return total;
  }

  double get weeklyGroupTotal {
    if (_cachedWeeklyGroup != null) return _cachedWeeklyGroup!;
    double total = 0;
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    
    final myPersonIdsList = myPersonIds;
    for (final group in _groups) {
      for (var tx in group.groupTransactions) {
        if (!tx.isPayment && !tx.date.isBefore(weekStart)) {
          // If I'm the payer, it's my group spending
          if (myPersonIdsList.contains(tx.payerId)) {
            total += tx.amount;
          }
        }
      }
    }
    _cachedWeeklyGroup = total;
    return total;
  }

  double get monthlyGroupTotal {
    if (_cachedMonthlyGroup != null) return _cachedMonthlyGroup!;
    double total = 0;
    final now = DateTime.now();
    
    final myPersonIdsList = myPersonIds;
    for (final group in _groups) {
      for (var tx in group.groupTransactions) {
        if (tx.date.month == now.month &&
            tx.date.year == now.year &&
            !tx.isPayment) {
          if (myPersonIdsList.contains(tx.payerId)) {
            total += tx.amount;
          }
        }
      }
    }
    _cachedMonthlyGroup = total;
    return total;
  }

  bool get hasSettlements => settlements.isNotEmpty;

  List<Settlement> get settlements {
    if (_cachedSettlements != null) return _cachedSettlements!;
    if (people.isEmpty || groupTransactions.isEmpty) return [];

    _cachedSettlements = DebtEngine.settleDebts(people, groupTransactions);
    return _cachedSettlements!;
  }

  Map<String, double> get netBalances {
    if (_cachedNetBalances != null) return _cachedNetBalances!;
    _getFinancialMaps();
    return _cachedNetBalances!;
  }

  Map<String, double> get paidBalances {
    if (_cachedPA != null) return _cachedPA!;
    _getFinancialMaps();
    return _cachedPA!;
  }

  Map<String, double> get shareBalances {
    if (_cachedSA != null) return _cachedSA!;
    _getFinancialMaps();
    return _cachedSA!;
  }

  void _getFinancialMaps() {
    final results = DebtEngine.calculateBalances(people, groupTransactions);
    _cachedNetBalances = results.netBalances;
    _cachedPA = results.paidAmounts;
    _cachedSA = results.shareAmounts;
  }

  List<Settlement> getSettlementsForGroup(Group? group) {
    if (group == null ||
        group.people.isEmpty ||
        group.groupTransactions.isEmpty) {
      return [];
    }
    return DebtEngine.settleDebts(group.people, group.groupTransactions);
  }

  Map<String, double> getNetBalancesForGroup(Group? group) {
    if (group == null) {
      return {};
    }
    return DebtEngine.calculateBalances(group.people, group.groupTransactions)
        .netBalances;
  }

  Map<String, double> getPaidBalancesForGroup(Group? group) {
    if (group == null) return {};
    return DebtEngine.calculateBalances(group.people, group.groupTransactions)
        .paidAmounts;
  }

  Map<String, double> getShareBalancesForGroup(Group? group) {
    if (group == null) return {};
    return DebtEngine.calculateBalances(group.people, group.groupTransactions)
        .shareAmounts;
  }

  double getWeeklyGroupTotalForGroup(Group? group) {
    if (group == null) return 0;
    double total = 0;
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final myPersonIdsList = myPersonIds;
    for (var tx in group.groupTransactions) {
      if (!tx.isPayment && !tx.date.isBefore(weekStart)) {
        if (myPersonIdsList.contains(tx.payerId)) {
          total += tx.amount;
        }
      }
    }
    return total;
  }

  double getMonthlyGroupTotalForGroup(Group? group) {
    if (group == null) return 0;
    double total = 0;
    final now = DateTime.now();

    final myPersonIdsList = myPersonIds;
    for (var tx in group.groupTransactions) {
      if (tx.date.month == now.month &&
          tx.date.year == now.year &&
          !tx.isPayment) {
        if (myPersonIdsList.contains(tx.payerId)) {
          total += tx.amount;
        }
      }
    }
    return total;
  }

  bool hasPendingConfirmationsForGroup(Group? group) {
    if (group == null) return false;
    final meId = getMeForGroup(group)?.id;
    if (meId == null) return false;
    return group.groupTransactions.any((t) =>
        t.isPayment &&
        t.status == TransactionStatus.pending &&
        t.participants.contains(meId));
  }

  double getPersonNetBalance(String personId, {Group? inGroup}) {
    if (inGroup == null) return netBalances[personId] ?? 0;
    return DebtEngine.calculateBalances(inGroup.people, inGroup.groupTransactions)
            .netBalances[personId] ??
        0;
  }

  Map<Category, double> get categorySpend {
    if (_cachedCategorySpend != null) return _cachedCategorySpend!;
    final Map<Category, double> result = {};
    for (var tx in transactions) {
      if (tx.isPayment) continue;
      result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
    }
    _cachedCategorySpend = result;
    return result;
  }
}
