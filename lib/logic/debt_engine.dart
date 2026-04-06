import '../models.dart';

class DebtEngine {
  /// Calculates the optimal settlements to minimize transactions.
  static List<Settlement> settleDebts(List<Person> people, List<GroupTransaction> transactions) {
    if (people.isEmpty) return [];

    final netBalances = calculateBalances(people, transactions).netBalances;

    // Separate into creditors and debtors
    final List<MapEntry<String, double>> creditors = [];
    final List<MapEntry<String, double>> debtors = [];

    netBalances.forEach((id, balance) {
      // Small epsilon to avoid floating point issues
      if (balance > 0.01) {
        creditors.add(MapEntry(id, balance));
      } else if (balance < -0.01) {
        debtors.add(MapEntry(id, balance.abs()));
      }
    });

    // Greedy algorithm
    final List<Settlement> results = [];

    // Sort to handle larger amounts first (optimization for fewer transactions)
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    int i = 0; // index for creditors
    int j = 0; // index for debtors

    while (i < creditors.length && j < debtors.length) {
      final creditor = creditors[i];
      final debtor = debtors[j];

      final amountToTransfer = _min(creditor.value, debtor.value);
      
      results.add(Settlement(
        fromId: debtor.key,
        toId: creditor.key,
        amount: amountToTransfer,
      ));

      // Update remaining amounts
      creditors[i] = MapEntry(creditor.key, creditor.value - amountToTransfer);
      debtors[j] = MapEntry(debtor.key, debtor.value - amountToTransfer);

      if (creditors[i].value < 0.01) i++;
      if (debtors[j].value < 0.01) j++;
    }

    return results;
  }

  static double _min(double a, double b) => a < b ? a : b;

  static BalanceResults calculateBalances(
      List<Person> people, List<GroupTransaction> transactions) {
    final Map<String, double> netBalances = {for (var p in people) p.id: 0.0};
    final Map<String, double> paidAmounts = {for (var p in people) p.id: 0.0};
    final Map<String, double> shareAmounts = {for (var p in people) p.id: 0.0};

    for (var tx in transactions) {
      if (tx.status == TransactionStatus.rejected) continue;
      if (tx.participants.isEmpty) continue;

      final currentNet = netBalances[tx.payerId];
      if (currentNet != null) {
        netBalances[tx.payerId] = currentNet + tx.amount;
        paidAmounts[tx.payerId] = (paidAmounts[tx.payerId] ?? 0.0) + tx.amount;
      }

      if (tx.customAmounts != null) {
        for (final pid in tx.participants) {
          final pNet = netBalances[pid];
          if (pNet != null) {
            final amt = tx.customAmounts![pid] ?? 0.0;
            netBalances[pid] = pNet - amt;
            shareAmounts[pid] = (shareAmounts[pid] ?? 0.0) + amt;
          }
        }
      } else {
        final split = tx.amount / tx.participants.length;
        for (final pid in tx.participants) {
          final pNet = netBalances[pid];
          if (pNet != null) {
            netBalances[pid] = pNet - split;
            shareAmounts[pid] = (shareAmounts[pid] ?? 0.0) + split;
          }
        }
      }
    }
    return BalanceResults(netBalances, paidAmounts, shareAmounts);
  }
}

class BalanceResults {
  final Map<String, double> netBalances;
  final Map<String, double> paidAmounts;
  final Map<String, double> shareAmounts;

  BalanceResults(this.netBalances, this.paidAmounts, this.shareAmounts);
}
