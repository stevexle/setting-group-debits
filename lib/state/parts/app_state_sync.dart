part of '../app_state.dart';

extension AppStateSync on AppState {
  Future<void> _syncGroupMetadata() async {
    if (!_isInitialized || _isInitializing) return;
    final group = _activeGroup;
    if (group?.syncId != null) {
      await _syncService.pushUpdate(group!);
    }
  }

  Future<void> _setupNotifications() async {
    final ns = NotificationService();
    final group = _activeGroup;
    if (group?.syncId != null) await ns.subscribeToGroup(group!.syncId!);

    _fcmToken = await ns.getToken();
    if (_fcmToken != null && _activeGroupId != null) {
      final prefs = await SharedPreferences.getInstance();
      final claimedId = prefs.getString('claimedPersonId_$activeGroupId');
      if (claimedId != null) await claimPerson(claimedId);
    }
  }

  void _setupSync() {
    _syncSubscription?.cancel();
    _groupTxSubscription?.cancel();
    _groupPlanSubscription?.cancel();
    final group = _activeGroup;
    if (group?.syncId != null) {
      final syncId = group!.syncId!;

      _syncSubscription = _syncService.getSyncStream(syncId).listen((doc) {
        if (doc.exists) {
          final data =
              Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          
          // Check for membership kick-out
          final List memberUids = List.from(data['memberUids'] ?? []);
          if (_currentUser != null && !memberUids.contains(_currentUser!.uid)) {
            // Force user out of this group!
            final idx = _groups.indexWhere((g) => g.syncId == syncId);
            if (idx != -1) _groups.removeAt(idx);
            
            if (_activeGroupId == group.id) {
               _activeGroupId = null;
               _cachedActiveGroup = null;
            }
            
            _saveState();
            notifyListeners();
            return;
          }

          final remoteGroup = Group.fromJson(data);
          final idx = _groups.indexWhere((g) => g.id == group.id);
          if (idx != -1) {
            _groups[idx] = remoteGroup.copyWith(
                groupTransactions: _groups[idx].groupTransactions,
                plans: _groups[idx].plans);
            _cachedActiveGroup = _groups[idx];
            _saveState();
            notifyListeners();
          }
        }
      });

      _groupTxSubscription =
          _syncService.getGroupTransactionsStream(syncId).listen((snap) async {
        final List<GroupTransaction> remoteTxs = snap.docs
            .map((d) => GroupTransaction.fromJson(
                Map<String, dynamic>.from(d.data() as Map<String, dynamic>)))
            .toList();

        final idx = _groups.indexWhere((g) => g.id == group.id);
        if (idx != -1) {
          final oldTxs = _groups[idx].groupTransactions;

          // Check for rejected settlements to revert balance
          for (final nTx in remoteTxs) {
            if (nTx.status == TransactionStatus.rejected &&
                nTx.payerId == me?.id) {
              final oTx =
                  oldTxs.firstWhere((o) => o.id == nTx.id, orElse: () => nTx);
              if (oTx.status == TransactionStatus.pending) {
                // It was pending locally and is now rejected. Revert and sync.
                await addPersonalTransaction(PersonalTransaction(
                  description: 'Refund (Rejected: ${nTx.description})',
                  amount: nTx.amount,
                  date: DateTime.now(),
                  isPayment: true, // Income
                  sourceAccountId: nTx.sourceAccountId,
                  category: Category.other,
                ));
              }
            }
          }

          _groups[idx] = _groups[idx].copyWith(groupTransactions: remoteTxs);
          _balancedCache.remove(group.id);
          _cachedActiveGroup = _groups[idx];
          _saveState();
          notifyListeners();
        }
      });

      _groupPlanSubscription =
          _syncService.getGroupPlansStream(syncId).listen((snap) {
        final List<BudgetPlan> remotePlans = snap.docs
            .map((d) => BudgetPlan.fromJson(
                Map<String, dynamic>.from(d.data() as Map<String, dynamic>)))
            .toList();

        final idx = _groups.indexWhere((g) => g.id == group.id);
        if (idx != -1) {
          _groups[idx] = _groups[idx].copyWith(plans: remotePlans);
          _cachedActiveGroup = _groups[idx];
          _saveState();
          notifyListeners();
        }
      });
    }
    _setupPersonalTxSync();
  }

  void _setupPersonalTxSync() {
    _personalTxSubscription?.cancel();
    if (_currentUser == null) return;

    _personalTxSubscription = _syncService
        .getPersonalTransactionsStream(_currentUser!.uid)
        .listen((snap) {
      final List<PersonalTransaction> remoteTxs = snap.docs
          .map((d) => PersonalTransaction.fromJson(
              Map<String, dynamic>.from(d.data() as Map<String, dynamic>)))
          .toList();

      _personalTransactions.clear();
      _personalTransactions.addAll(remoteTxs);
      _saveState();
      notifyListeners();
    });
  }

  void _setupAccSync() {
    _accSubscription?.cancel();
    if (_currentUser == null) return;

    _accSubscription =
        _syncService.getAccountsStream(_currentUser!.uid).listen((snap) {
      final cloudAccs = snap.docs
          .map((d) => Account.fromJson(Map<String, dynamic>.from(d.data() as Map)))
          .toList();

      // Merge logic: simpler is to just replace for now if synced
      if (cloudAccs.isNotEmpty) {
        _accounts.clear();
        _accounts.addAll(cloudAccs);
        _saveState();
        notifyListeners();
      }
    });
  }
  void _setupGroupsSync() {
    _groupsSubscription?.cancel();
    if (_currentUser == null) return;
    _groupsSubscription =
        _syncService.getGroupsForUserStream(_currentUser!.uid).listen((snap) {
      final List<Group> cloudGroups = snap.docs.map((doc) {
        final data =
            Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        return Group.fromJson(data);
      }).toList();

      // Only perform replacement if there's a difference to avoid notify cycle
      // (Simple check: compare IDs)
      final cloudIds = cloudGroups.map((g) => g.syncId).toSet();
      final localSyncedIds = _groups.where((g) => g.syncId != null).map((g) => g.syncId).toSet();

      bool changed = cloudIds.length != localSyncedIds.length ||
          cloudIds.any((id) => !localSyncedIds.contains(id));

      if (changed) {
        // Keep local-only groups (syncId == null)
        final localOnly = _groups.where((g) => g.syncId == null).toList();
        _groups.clear();
        _groups.addAll(localOnly);
        _groups.addAll(cloudGroups);
        
        // If the active group was REMOVED from cloud, reset it
        if (_activeGroupId != null) {
           final stillExists = _groups.any((g) => g.id == _activeGroupId);
           if (!stillExists) {
             _activeGroupId = null;
             _cachedActiveGroup = null;
           }
        }

        _saveState();
        notifyListeners();
      }
    });
  }
}
