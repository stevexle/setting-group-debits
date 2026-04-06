part of '../app_state.dart';

extension AppStateFinance on AppState {
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
      _notify();
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

  Future<void> addPlan(BudgetPlan plan) async {
    final group = _activeGroup;
    if (group != null) {
      await _updateActiveGroup((g) => g.copyWith(plans: [...g.plans, plan]));
      if (group.syncId != null) {
        await _syncService.pushGroupPlan(group.syncId!, plan);
      }
      _notify();
    }
  }

  Future<void> updatePlan(BudgetPlan plan) async {
    final group = _activeGroup;
    if (group != null) {
      await _updateActiveGroup((g) {
        final idx = g.plans.indexWhere((p) => p.id == plan.id);
        if (idx == -1) return g;
        final updated = [...g.plans];
        updated[idx] = plan;
        return g.copyWith(plans: updated);
      });
      if (group.syncId != null) {
        await _syncService.pushGroupPlan(group.syncId!, plan);
      }
      _notify();
    }
  }

  Future<void> removePlan(String id) async {
    final group = _activeGroup;
    if (group != null) {
      await _updateActiveGroup((g) {
        final updated = g.plans.where((p) => p.id != id).toList();
        return g.copyWith(plans: updated);
      });
      if (group.syncId != null) {
        await _syncService.deleteGroupPlan(group.syncId!, id);
      }
      _notify();
    }
  }

  Future<void> _updatePlanSpent(String? planId, double delta) async {
    if (planId == null || delta == 0) return;
    final planIdx = plans.indexWhere((p) => p.id == planId);
    if (planIdx != -1) {
      final plan = plans[planIdx];
      await updatePlan(plan.copyWith(currentSpent: plan.currentSpent + delta));
    }
  }
}
