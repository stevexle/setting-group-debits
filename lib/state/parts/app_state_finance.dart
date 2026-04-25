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
    if (plan.linkedGroupId != null) {
      final idx = _groups.indexWhere((g) => g.id == plan.linkedGroupId);
      if (idx != -1) {
        final group = _groups[idx];
        _groups[idx] = group.copyWith(plans: [...group.plans, plan]);
        if (group.syncId != null) {
          await _syncService.pushGroupPlan(group.syncId!, plan);
        }
      }
    } else {
      _plans.add(plan);
    }
    await _saveState();
    _notify();
  }

  Future<void> updatePlan(BudgetPlan plan) async {
    // 1. Find the plan's current location and remove it
    
    // Check root
    final rootIdx = _plans.indexWhere((p) => p.id == plan.id);
    if (rootIdx != -1) {
      _plans.removeAt(rootIdx);
    }
    
    // Check groups
    for (int i = 0; i < _groups.length; i++) {
      final g = _groups[i];
      final pIdx = g.plans.indexWhere((p) => p.id == plan.id);
      if (pIdx != -1) {
        final updatedPlans = [...g.plans];
        updatedPlans.removeAt(pIdx);
        _groups[i] = g.copyWith(plans: updatedPlans);
        
        // If it was synced, we might need a delete push if it's moving
        if (g.syncId != null && plan.linkedGroupId != g.id) {
           await _syncService.deleteGroupPlan(g.syncId!, plan.id);
        }
        break; 
      }
    }

    // 2. Add it to its new location
    if (plan.linkedGroupId != null) {
      final newGroupIdx = _groups.indexWhere((g) => g.id == plan.linkedGroupId);
      if (newGroupIdx != -1) {
        final targetGroup = _groups[newGroupIdx];
        final updatedPlans = [...targetGroup.plans, plan];
        _groups[newGroupIdx] = targetGroup.copyWith(plans: updatedPlans);
        if (targetGroup.syncId != null) {
          await _syncService.pushGroupPlan(targetGroup.syncId!, plan);
        }
      } else {
        // Fallback to root if group ID is invalid
        _plans.add(plan);
      }
    } else {
      _plans.add(plan);
    }

    await _saveState();
    _notify();
  }

  Future<void> removePlan(String id) async {
    // Remove from root
    _plans.removeWhere((p) => p.id == id);
    
    // Remove from groups
    for (int i = 0; i < _groups.length; i++) {
      final g = _groups[i];
      if (g.plans.any((p) => p.id == id)) {
        final updated = g.plans.where((p) => p.id != id).toList();
        _groups[i] = g.copyWith(plans: updated);
        if (g.syncId != null) {
          await _syncService.deleteGroupPlan(g.syncId!, id);
        }
      }
    }
    await _saveState();
    _notify();
  }

  Future<void> _updatePlanSpent(String? planId, double delta) async {
    if (planId == null || delta == 0) return;
    final group = _activeGroup;
    if (group == null) return;
    final plansList = group.plans;
    final planIdx = plansList.indexWhere((p) => p.id == planId);
    if (planIdx != -1) {
      final plan = plansList[planIdx];
      await updatePlan(plan.copyWith(currentSpent: plan.currentSpent + delta));
    }
  }

  // --- Itinerary Management ---
  Future<void> addItineraryItem(String planId, PlanItineraryItem item) async {
    final plan = _findPlanById(planId);
    if (plan != null) {
      final updatedItinerary = [...plan.itinerary, item];
      await updatePlan(plan.copyWith(itinerary: updatedItinerary));
    }
  }

  Future<void> updateItineraryItem(String planId, PlanItineraryItem item) async {
    final plan = _findPlanById(planId);
    if (plan != null) {
      final updatedItinerary = plan.itinerary.map((i) => i.id == item.id ? item : i).toList();
      await updatePlan(plan.copyWith(itinerary: updatedItinerary));
    }
  }

  Future<void> removeItineraryItem(String planId, String itemId) async {
    final plan = _findPlanById(planId);
    if (plan != null) {
      final updatedItinerary = plan.itinerary.where((i) => i.id != itemId).toList();
      await updatePlan(plan.copyWith(itinerary: updatedItinerary));
    }
  }

  // --- Checklist Management ---
  Future<void> addPlanTask(String planId, PlanTask task) async {
    final plan = _findPlanById(planId);
    if (plan != null) {
      final updatedChecklist = [...plan.checklist, task];
      await updatePlan(plan.copyWith(checklist: updatedChecklist));
    }
  }

  Future<void> updatePlanTask(String planId, PlanTask task) async {
    final plan = _findPlanById(planId);
    if (plan != null) {
      final updatedChecklist = plan.checklist.map((t) => t.id == task.id ? task : t).toList();
      await updatePlan(plan.copyWith(checklist: updatedChecklist));
    }
  }

  Future<void> removePlanTask(String planId, String taskId) async {
    final plan = _findPlanById(planId);
    if (plan != null) {
      final updatedChecklist = plan.checklist.where((t) => t.id != taskId).toList();
      await updatePlan(plan.copyWith(checklist: updatedChecklist));
    }
  }

  // Helper to find plan across all possible storages
  BudgetPlan? _findPlanById(String id) {
    // Check root
    try {
      return _plans.firstWhere((p) => p.id == id);
    } catch (_) {}

    // Check all groups
    for (final g in _groups) {
      try {
        return g.plans.firstWhere((p) => p.id == id);
      } catch (_) {}
    }
    return null;
  }
}
