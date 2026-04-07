part of '../app_state.dart';

extension AppStateGroups on AppState {
  List<Group> get groups {
    if (_cachedFilteredGroups != null) return _cachedFilteredGroups!;
    if (_currentUser == null) {
      _cachedFilteredGroups = List.unmodifiable(_groups);
    } else {
      _cachedFilteredGroups = List.unmodifiable(_groups
          .where((g) => g.people.any((p) => p.userId == _currentUser!.uid))
          .toList());
    }
    return _cachedFilteredGroups!;
  }

  Group? get activeGroup => _activeGroup;

  Future<void> enableSync() async {
    final group = _activeGroup;
    if (group == null || group.syncId != null || _currentUser == null) return;

    final syncId =
        await _syncService.enableSync(group.copyWith(ownerId: _currentUser!.uid));
    if (syncId != null) {
      final updated = group.copyWith(syncId: syncId, ownerId: _currentUser!.uid);
      final idx = _groups.indexWhere((g) => g.id == group.id);
      _groups[idx] = updated;
      _cachedActiveGroup = updated;

      _setupSync();
      _setupNotifications();
      await _saveState();
      _notify(); // Use the optimized notify
    }
  }

  Future<void> joinSyncGroup(String inviteCode) async {
    final remoteGroup = await _syncService.fetchGroup(inviteCode);
    if (remoteGroup != null) {
      _groups.removeWhere((g) => g.syncId == inviteCode);
      _groups.add(remoteGroup);
      _activeGroupId = remoteGroup.id;
      _cachedActiveGroup = remoteGroup;
      await _saveState();
      await _autoClaimMe();
      _setupSync();
      _setupNotifications();
      _notify(); // Use the optimized notify
    } else {
      throw Exception("Group not found");
    }
  }

  Future<void> claimPerson(String personId) async {
    final idx = _groups.indexWhere((g) => g.id == _activeGroupId);
    if (idx != -1) {
      final pIdx = _groups[idx].people.indexWhere((p) => p.id == personId);
      if (pIdx != -1) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('claimedPersonId_$_activeGroupId', personId);
        final ns = NotificationService();
        _fcmToken = await ns.getToken();

        await _updateActiveGroup((g) {
          final updatedPeople = [...g.people];
          updatedPeople[pIdx] = updatedPeople[pIdx].copyWith(
            userId: _currentUser?.uid,
            email: _currentUser?.email,
            fcmToken: _fcmToken,
          );
          return g.copyWith(people: updatedPeople);
        }, syncMetadata: true);
      }
    }
  }

  Future<void> createGroup(String name,
      {GroupType type = GroupType.settlement}) async {
    if (name.isEmpty) return;
    Group newGroup = Group(name: name, type: type, ownerId: _currentUser?.uid);

    if (isAuthenticated) {
      final syncId = await _syncService.enableSync(newGroup);
      if (syncId != null) newGroup = newGroup.copyWith(syncId: syncId);
    }

    _groups.add(newGroup);
    _activeGroupId = newGroup.id;
    _cachedActiveGroup = newGroup;

    if (_currentUser != null) _autoClaimMe();

    await _saveState();
    _setupSync();
    _setupNotifications();
    _notify();
  }

  void switchGroup(String id) {
    if (_groups.any((g) => g.id == id)) {
      _activeGroupId = id;
      _cachedActiveGroup = null;
      _saveState();
      _setupSync();
      _setupNotifications();
      _autoClaimMe();
      _notify(); // Use the optimized notify
    }
  }

  bool isGroupBalanced(String groupId) {
    if (_balancedCache.containsKey(groupId)) return _balancedCache[groupId]!;

    if (_groups.isEmpty) return true;

    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return true;

    final group = _groups[groupIndex];
    if (group.people.isEmpty) return true;

    bool result;
    if (group.id == _activeGroupId) {
      result = netBalances.values.every((v) => v.abs() < 0.01);
    } else {
      result = group.people.every(
          (p) => getPersonNetBalance(p.id, inGroup: group).abs() < 0.01);
    }

    _balancedCache[groupId] = result;
    return result;
  }

  Future<void> deleteGroup(String id) async {
    if (!isGroupBalanced(id)) return;
    final targetIdx = _groups.indexWhere((g) => g.id == id);
    if (targetIdx == -1) return;

    final group = _groups[targetIdx];
    final syncId = group.syncId;
    final isOwner = _currentUser != null && group.ownerId == _currentUser!.uid;

    if (syncId != null) {
      try {
        if (isOwner) {
          // Owner delete: remove for everyone
          await _syncService.deleteCloudGroup(syncId);
        } else if (_currentUser != null) {
          // Member delete: just leave
          await _syncService.leaveGroup(syncId, _currentUser!.uid);
        }
      } catch (e) {
        debugPrint("Cloud delete/leave failed, probably already gone: $e");
        // We continue to local removal anyway
      }
    }

    // Re-verify the list hasn't changed during awaits
    _groups.removeWhere((g) => g.id == id);
    if (_activeGroupId == id) {
      _activeGroupId = _groups.isNotEmpty ? _groups.first.id : null;
      _cachedActiveGroup = null;
    }
    await _saveState();
    _notify();
  }

  Future<void> addPerson(String name,
      {int? colorIndex,
      String? avatarUrl,
      String? userId,
      String? email,
      String? bankId,
      String? accountNo,
      String? bankQrUrl}) async {
    if (name.trim().isEmpty || _activeGroupId == null) return;
    final person = Person(
        name: name,
        colorIndex: colorIndex,
        avatarUrl: avatarUrl ?? '',
        userId: userId,
        email: email,
        bankId: bankId,
        accountNo: accountNo,
        bankQrUrl: bankQrUrl);
    await _updateActiveGroup((g) => g.copyWith(people: [...g.people, person]),
        syncMetadata: true);

    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        !avatarUrl.startsWith('http')) {
      final cloudUrl = await _syncService.uploadAvatar(avatarUrl);
      if (cloudUrl != null && cloudUrl != avatarUrl) {
        updatePerson(person.id, avatarUrl: cloudUrl);
      }
    }

    if (bankQrUrl != null &&
        bankQrUrl.isNotEmpty &&
        !bankQrUrl.startsWith('http')) {
      final cloudUrl = await _syncService.uploadBankQr(bankQrUrl);
      if (cloudUrl != null && cloudUrl != bankQrUrl) {
        updatePerson(person.id, bankQrUrl: cloudUrl);
      }
    }
  }

  Future<void> updatePerson(String id,
      {String? name,
      int? colorIndex,
      String? avatarUrl,
      String? userId,
      String? email,
      String? bankId,
      String? accountNo,
      String? bankQrUrl}) async {
    String finalAvatar = avatarUrl ?? '';
    String finalQr = bankQrUrl ?? '';
    final group = _activeGroup;
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        !avatarUrl.startsWith('http') &&
        group?.syncId != null) {
      final cloudUrl = await _syncService.uploadAvatar(avatarUrl);
      if (cloudUrl != null) finalAvatar = cloudUrl;
    }
    if (bankQrUrl != null &&
        bankQrUrl.isNotEmpty &&
        !bankQrUrl.startsWith('http') &&
        group?.syncId != null) {
      final cloudUrl = await _syncService.uploadBankQr(bankQrUrl);
      if (cloudUrl != null) finalQr = cloudUrl;
    }

    await _updateActiveGroup((g) {
      final pIdx = g.people.indexWhere((p) => p.id == id);
      if (pIdx == -1) return g;
      final updatedPeople = [...g.people];
      updatedPeople[pIdx] = updatedPeople[pIdx].copyWith(
          name: name,
          colorIndex: colorIndex,
          avatarUrl: finalAvatar.isNotEmpty ? finalAvatar : null,
          userId: userId,
          email: email,
          bankId: bankId,
          accountNo: accountNo,
          bankQrUrl: finalQr.isNotEmpty ? finalQr : null);
      return g.copyWith(people: updatedPeople);
    }, syncMetadata: true);

    final person =
        people.any((p) => p.id == id) ? people.firstWhere((p) => p.id == id) : null;
    if (person != null &&
        person.userId != null &&
        person.userId == _currentUser?.uid) {
      for (int i = 0; i < _groups.length; i++) {
        if (_groups[i].id == _activeGroupId) continue;
        final pIdx =
            _groups[i].people.indexWhere((p) => p.userId == person.userId);
        if (pIdx != -1) {
          final updatedPeople = [..._groups[i].people];
          updatedPeople[pIdx] = updatedPeople[pIdx].copyWith(
              avatarUrl: avatarUrl ?? person.avatarUrl,
              colorIndex: colorIndex ?? person.colorIndex,
              email: email ?? person.email);
          _groups[i] = _groups[i].copyWith(people: updatedPeople);
          if (_groups[i].syncId != null) _syncService.pushUpdate(_groups[i]);
        }
      }
    }
    await _saveState();
    _notify();
  }

  bool isPersonInvolvedInTransactions(String id) {
    return groupTransactions
        .any((t) => t.payerId == id || t.participants.contains(id));
  }

  Future<bool> removePerson(String id) async {
    if (id == me?.id) return false;
    if (isPersonInvolvedInTransactions(id)) return false;

    await _updateActiveGroup((g) {
      final updatedPeople = g.people.where((p) => p.id != id).toList();
      return g.copyWith(people: updatedPeople);
    }, syncMetadata: true);
    return true;
  }

  bool canEditPerson(Person target) {
    // 1. Always allow editing own profile
    final isMe = target.userId != null && target.userId == _currentUser?.uid;
    if (isMe) return true;

    // 2. Owners can edit phantom members (userId == null)
    if (isOwner && target.userId == null) {
      return true;
    }

    return false;
  }
}
