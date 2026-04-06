part of '../app_state.dart';

extension AppStateTransactions on AppState {
  Future<void> addGroupTransaction(GroupTransaction tx) async {
    final group = _activeGroup;
    if (group == null) return;
    
    // Ensure tx has an ID and creatorId before pushing
    var finalTx = tx.copyWith(
      id: tx.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : tx.id,
      creatorId: tx.creatorId ?? me?.id,
    );

    // Auto-confirm if paying to a phantom member (no app account/userId)
    if (finalTx.isPayment && finalTx.participants.isNotEmpty) {
      final recipientId = finalTx.participants.first;
      final recipient = people.firstWhere((p) => p.id == recipientId,
          orElse: () => Person(name: '?'));
      if (recipient.userId == null) {
        finalTx = finalTx.copyWith(status: TransactionStatus.confirmed);
      }
    }

    await _updateActiveGroup(
        (g) => g.copyWith(groupTransactions: [finalTx, ...g.groupTransactions]));
    
    if (group.syncId != null) {
      await _syncService.pushGroupTransaction(group.syncId!, finalTx);
    }

    // If I am the payer, add to personal history (records balance adjustment & cloud sync)
    if (finalTx.payerId == me?.id && finalTx.sourceAccountId != null) {
      await addPersonalTransaction(PersonalTransaction(
        id: "p_${finalTx.id}", // Link with prefix
        description: finalTx.description,
        amount: finalTx.amount,
        date: finalTx.date,
        isPayment: false, // Always Expense for the person paying
        sourceAccountId: finalTx.sourceAccountId,
        category: finalTx.category,
        planId: finalTx.planId,
        payerId: finalTx.payerId,
        groupId: group.id,
        isShared: true,
      ));
    }

    // Update plan spending
    if (!finalTx.isPayment) {
      await _updatePlanSpent(finalTx.planId, finalTx.amount);
    }
  }

  Future<void> addPersonalTransaction(PersonalTransaction tx) async {
    _personalTransactions.insert(0, tx);
    if (_currentUser != null) {
      await _syncService.pushPersonalTransaction(_currentUser!.uid, tx);
    }

    // Adjust account balance
    await _adjustAccountBalance(
        tx.sourceAccountId, tx.isPayment ? tx.amount : -tx.amount);

    await _saveState();
    notifyListeners();
  }

  Future<void> removeGroupTransaction(String id) async {
    final group = _activeGroup;
    final txIdx = group?.groupTransactions.indexWhere((t) => t.id == id) ?? -1;
    if (txIdx != -1) {
      final tx = group!.groupTransactions[txIdx];
      await _updateActiveGroup((g) => g.copyWith(
          groupTransactions: g.groupTransactions.where((t) => t.id != id).toList()));
      
      if (group.syncId != null) {
        await _syncService.deleteGroupTransaction(group.syncId!, id);
      }

      // If I am the payer, remove linked personal history
      if (tx.payerId == me?.id) {
        final pId = "p_$id";
        final pIdx = _personalTransactions.indexWhere((t) => t.id == pId);
        if (pIdx != -1) {
          _personalTransactions.removeAt(pIdx);
          if (_currentUser != null) {
            await _syncService.deletePersonalTransaction(_currentUser!.uid, pId);
          }
        }

        // Revert account balance shift
        await _adjustAccountBalance(
            tx.sourceAccountId, tx.isPayment ? -tx.amount : tx.amount);

        // Update plan spending
        if (!tx.isPayment) {
          await _updatePlanSpent(tx.planId, -tx.amount);
        }
      }
    }
  }

  Future<void> removePersonalTransaction(String id) async {
    final pIdx = _personalTransactions.indexWhere((t) => t.id == id);
    if (pIdx != -1) {
      final tx = _personalTransactions[pIdx];
      _personalTransactions.removeAt(pIdx);
      if (_currentUser != null) {
        await _syncService.deletePersonalTransaction(_currentUser!.uid, id);
      }

      // Revert account balance shift
      await _adjustAccountBalance(
          tx.sourceAccountId, tx.isPayment ? -tx.amount : tx.amount);

      await _saveState();
      notifyListeners();
    }
  }

  Future<void> editGroupTransaction(String id, GroupTransaction newTx) async {
    final group = _activeGroup;
    final tIdx = group?.groupTransactions.indexWhere((t) => t.id == id) ?? -1;
    if (tIdx == -1) return;

    final oldTx = group!.groupTransactions[tIdx];

    await _updateActiveGroup((g) {
      final updatedTxs = [...g.groupTransactions];
      updatedTxs[tIdx] = newTx.copyWith(
        creatorId: oldTx.creatorId,
        updatedAt:
            (oldTx.amount != newTx.amount) ? DateTime.now() : oldTx.updatedAt,
        amountChanged: (oldTx.amount != newTx.amount) || oldTx.amountChanged,
      );
      return g.copyWith(groupTransactions: updatedTxs);
    });

    if (group.syncId != null) {
      final updatedTx = groupTransactions.firstWhere((t) => t.id == id);
      await _syncService.pushGroupTransaction(group.syncId!, updatedTx);
    }

    // Determine my role in this transaction (linked p_ record exists)
    final pId = "p_$id";
    final pIdx = _personalTransactions.indexWhere((t) => t.id == pId);

    if (pIdx != -1) {
      final oldPTx = _personalTransactions[pIdx];
      // Revert old balance effect
      await _adjustAccountBalance(oldPTx.sourceAccountId, oldPTx.isPayment ? -oldPTx.amount : oldTx.amount);
      
      // Update entry
      final newPTx = oldPTx.copyWith(
        description: newTx.description,
        amount: newTx.amount,
        date: newTx.date,
        sourceAccountId: (newTx.payerId == me?.id) ? newTx.sourceAccountId : oldPTx.sourceAccountId,
        category: newTx.category,
        isPayment: (newTx.payerId == me?.id) ? newTx.isPayment : oldPTx.isPayment,
        payerId: newTx.payerId,
        groupId: group.id,
        isShared: true,
      );
      
      _personalTransactions[pIdx] = newPTx;
      // Apply new balance effect
      await _adjustAccountBalance(newPTx.sourceAccountId, newPTx.isPayment ? newPTx.amount : -newPTx.amount);

      if (_currentUser != null) {
        await _syncService.pushPersonalTransaction(_currentUser!.uid, newPTx);
      }
    } else if (newTx.payerId == me?.id) {
      // New link for me as payer (wasn't linked before or payer changed to me)
      final newPTx = PersonalTransaction(
        id: pId,
        description: newTx.description,
        amount: newTx.amount,
        date: newTx.date,
        category: newTx.category,
        sourceAccountId: newTx.sourceAccountId,
        isPayment: newTx.isPayment,
        planId: newTx.planId,
        payerId: newTx.payerId,
      );
      _personalTransactions.insert(0, newPTx);
      await _adjustAccountBalance(newPTx.sourceAccountId, newPTx.isPayment ? newPTx.amount : -newPTx.amount);
      if (_currentUser != null) {
        await _syncService.pushPersonalTransaction(_currentUser!.uid, newPTx);
      }
    }

    // Update plan spending (if payer)
    if (oldTx.payerId == me?.id) {
       await _updatePlanSpent(oldTx.planId, -oldTx.amount);
    }
    if (newTx.payerId == me?.id) {
       await _updatePlanSpent(newTx.planId, newTx.amount);
    }
  }

  Future<void> editPersonalTransaction(
      String id, PersonalTransaction newTx) async {
    final tIdx = _personalTransactions.indexWhere((t) => t.id == id);
    if (tIdx != -1) {
      final oldTx = _personalTransactions[tIdx];
      _personalTransactions[tIdx] = newTx.copyWith(updatedAt: DateTime.now());
      if (_currentUser != null) {
        await _syncService.pushPersonalTransaction(
            _currentUser!.uid, _personalTransactions[tIdx]);
      }

      // Adjust balance: Revert old, Apply new
      await _adjustAccountBalance(
          oldTx.sourceAccountId, oldTx.isPayment ? -oldTx.amount : oldTx.amount);
      await _adjustAccountBalance(
          newTx.sourceAccountId, newTx.isPayment ? newTx.amount : -newTx.amount);

      await _saveState();
      notifyListeners();
    }
  }

  Future<void> settleDebt(String fromId, String toId, double amount,
      {bool shouldClear = true, String? sourceAccountId}) async {
    final group = _activeGroup;
    if (group == null) return;

    final recipient = people.firstWhere((p) => p.id == toId,
        orElse: () => Person(name: '?'));
    final status = (recipient.userId == null)
        ? TransactionStatus.confirmed
        : TransactionStatus.pending;

    final s = GroupTransaction(
      description: 'Settlement: To ${recipient.name}',
      payerId: fromId,
      amount: amount,
      participants: [toId],
      isPayment: true,
      date: DateTime.now(),
      status: status,
      sourceAccountId: sourceAccountId,
    );

    await _updateActiveGroup(
        (g) => g.copyWith(groupTransactions: [s, ...g.groupTransactions]));
    if (group.syncId != null) {
      await _syncService.pushGroupTransaction(group.syncId!, s);
    }

    // Adjust account balance and add to history (Outflow immediately for payer)
    if (sourceAccountId != null && fromId == me?.id) {
      await addPersonalTransaction(PersonalTransaction(
        description: 'Settlement: To ${people.firstWhere((p) => p.id == toId).name}',
        amount: amount,
        date: DateTime.now(),
        isPayment: false, // Expense
        sourceAccountId: sourceAccountId,
        category: Category.other,
        groupId: group.id,
        isShared: true,
      ));
    }

    notifyListeners();
  }

  Future<void> confirmSettlement(String txId, {String? targetAccountId}) async {
    final group = _activeGroup;
    if (group == null) return;
    final txIdx = group.groupTransactions.indexWhere((t) => t.id == txId);
    if (txIdx == -1) return;

    final tx = group.groupTransactions[txIdx];
    if (tx.status != TransactionStatus.pending) return;

    final updatedTx = tx.copyWith(status: TransactionStatus.confirmed);

    await _updateActiveGroup((g) {
      final updated = [...g.groupTransactions];
      updated[txIdx] = updatedTx;
      return g.copyWith(groupTransactions: updated);
    });

    if (group.syncId != null) {
      await _syncService.pushGroupTransaction(group.syncId!, updatedTx);
    }

    // If I am the receiver, increment my balance and add to history
    if (targetAccountId != null && tx.participants.contains(me?.id)) {
      await addPersonalTransaction(PersonalTransaction(
        id: "p_$txId",
        description: 'Settlement: From ${people.firstWhere((p) => p.id == tx.payerId).name}',
        amount: tx.amount,
        date: DateTime.now(),
        isPayment: true, // Income
        sourceAccountId: targetAccountId,
        category: Category.other,
        payerId: tx.payerId,
        groupId: group.id,
        isShared: true,
      ));
    }

    notifyListeners();
  }

  Future<void> rejectSettlement(String txId) async {
    final group = _activeGroup;
    if (group == null) return;
    final txIdx = group.groupTransactions.indexWhere((t) => t.id == txId);
    if (txIdx == -1) return;

    final tx = group.groupTransactions[txIdx];
    if (tx.status != TransactionStatus.pending) return;

    final updatedTx = tx.copyWith(status: TransactionStatus.rejected);

    await _updateActiveGroup((g) {
      final updated = [...g.groupTransactions];
      updated[txIdx] = updatedTx;
      return g.copyWith(groupTransactions: updated);
    });

    if (group.syncId != null) {
      await _syncService.pushGroupTransaction(group.syncId!, updatedTx);
    }

    _notify(); // Use the optimized notify instead of redundant notifyListeners()
  }


  Future<void> clearExpenses() async {
    final group = _activeGroup;
    if (group?.syncId != null) {
      await _syncService.purgeTransactions(group!.syncId!);
    }
    _updateActiveGroup((g) => g.copyWith(groupTransactions: []));
    notifyListeners();
  }

  Future<void> linkGroupTransactionToWallet(
      String txId, String accountId) async {
    final group = _activeGroup;
    if (group == null) return;
    final idx = group.groupTransactions.indexWhere((t) => t.id == txId);
    if (idx != -1) {
      final oldTx = group.groupTransactions[idx];
      final updatedTx = oldTx.copyWith(sourceAccountId: accountId);

      await _updateActiveGroup((g) {
        final updated = [...g.groupTransactions];
        updated[idx] = updatedTx;
        return g.copyWith(groupTransactions: updated);
      });

      if (group.syncId != null) {
        await _syncService.pushGroupTransaction(group.syncId!, updatedTx);
      }
      notifyListeners();
    }
  }

  Future<void> remindPerson(String personId, double amount) async {}
}
