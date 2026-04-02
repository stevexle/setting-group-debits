import '../models.dart';

class DebtEngine {
  /// Calculates the optimal settlements to minimize transactions.
  static List<Settlement> settleDebts(List<Person> people, List<Transaction> transactions) {
    if (people.isEmpty) return [];

    // Map to store net balance of each person
    // Balance = amount paid - amount owed
    final Map<String, double> netBalances = {
      for (var p in people) p.id: 0.0,
    };

    // Calculate net balances
    for (var tx in transactions) {
      if (tx.participantIds.isEmpty) continue;

      // The payer gets "credited" for what they paid
      netBalances[tx.payerId] = (netBalances[tx.payerId] ?? 0.0) + tx.amount;

      // Each participant owes an equal split OR a custom amount
      if (tx.customAmounts != null) {
        for (final participantId in tx.participantIds) {
          final amt = tx.customAmounts![participantId] ?? 0.0;
          netBalances[participantId] = (netBalances[participantId] ?? 0.0) - amt;
        }
      } else {
        final splitAmount = tx.amount / tx.participantIds.length;
        for (final participantId in tx.participantIds) {
          netBalances[participantId] = (netBalances[participantId] ?? 0.0) - splitAmount;
        }
      }
    }

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
}
