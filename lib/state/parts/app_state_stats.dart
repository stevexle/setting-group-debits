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
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    for (var tx in _personalTransactions) {
      if (tx.date.isAfter(weekStart) && !tx.isPayment) total += tx.amount;
    }
    _cachedWeeklyPersonal = total;
    return total;
  }

  double get monthlyPersonalTotal {
    if (_cachedMonthlyPersonal != null) return _cachedMonthlyPersonal!;
    double total = 0;
    final now = DateTime.now();
    for (var tx in _personalTransactions) {
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
    for (var tx in groupTransactions) {
      if (!tx.isPayment && !tx.date.isBefore(weekStart)) {
        total += tx.amount;
      }
    }
    _cachedWeeklyGroup = total;
    return total;
  }

  double get monthlyGroupTotal {
    if (_cachedMonthlyGroup != null) return _cachedMonthlyGroup!;
    double total = 0;
    final now = DateTime.now();
    for (var tx in groupTransactions) {
      if (tx.date.month == now.month &&
          tx.date.year == now.year &&
          !tx.isPayment) {
        total += tx.amount;
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
