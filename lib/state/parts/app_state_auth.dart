part of '../app_state.dart';

extension AppStateAuth on AppState {
  void _initAuth() {
    _authSub = _authService.user.listen((user) async {
      _currentUser = user;
      _notify();
      if (user != null) {
        log.setUserIdentifier(user.uid);
        _userProfile = await _syncService.fetchUserProfile(user.uid);
        if (_userProfile == null) {
          _userProfile = UserProfile(
            uid: user.uid,
            name: user.displayName ?? 'New User',
            email: user.email,
            avatarUrl: user.photoURL,
          );
          _syncService.pushUserProfile(_userProfile!);
        }
        _notify();
        _setupAccSync();
        _setupPersonalTxSync();
        _setupGroupsSync();
        if (_activeGroupId != null) {
          _autoClaimMe();
        }
      } else {
        _userProfile = null;
        _accSubscription?.cancel();
        _personalTxSubscription?.cancel();
        _groupsSubscription?.cancel();
        _notify();
      }
    });
  }

  Future<void> _autoClaimMe() async {
    if (_currentUser == null || _activeGroupId == null) return;
    final group = _activeGroup;
    if (group == null) return;

    final prefs = await SharedPreferences.getInstance();
    final localClaimedId = prefs.getString('claimedPersonId_$_activeGroupId');

    int personIdx = -1;
    if (localClaimedId != null) {
      personIdx = group.people.indexWhere((p) => p.id == localClaimedId);
    }

    if (personIdx == -1) {
      personIdx = group.people.indexWhere((p) =>
          p.userId == _currentUser!.uid ||
          (p.email != null &&
              p.email!.toLowerCase() == _currentUser!.email?.toLowerCase()));
    }

    if (personIdx == -1) {
      final googleName = _currentUser!.displayName;
      if (googleName != null) {
        personIdx = group.people.indexWhere((p) =>
            p.userId == null &&
            p.email == null &&
            p.name.toLowerCase() == googleName.toLowerCase());
      }
    }

    if (personIdx == -1) {
      await addPerson(
        _currentUser!.displayName ?? 'Me',
        avatarUrl: _currentUser!.photoURL,
        userId: _currentUser!.uid,
        email: _currentUser!.email,
        bankId: _userProfile?.bankId,
        accountNo: _userProfile?.accountNo,
        bankQrUrl: _userProfile?.bankQrUrl,
      );
    } else {
      final person = group.people[personIdx];
      bool needsUpdate = false;
      String? newUserId, newEmail, newAvatar;

      if (person.userId == null) {
        newUserId = _currentUser!.uid;
        needsUpdate = true;
      }
      if (person.email == null) {
        newEmail = _currentUser!.email;
        needsUpdate = true;
      }
      if (person.avatarUrl.isEmpty && _currentUser!.photoURL != null) {
        newAvatar = _currentUser!.photoURL;
        needsUpdate = true;
      }
      
      // Auto-populate banking if missing in this group but present globally
      String? newBankId, newAccNo, newQr;
      if (person.bankId == null && _userProfile?.bankId != null) {
        newBankId = _userProfile!.bankId;
        needsUpdate = true;
      }
      if (person.accountNo == null && _userProfile?.accountNo != null) {
        newAccNo = _userProfile!.accountNo;
        needsUpdate = true;
      }
      if (person.bankQrUrl == null && _userProfile?.bankQrUrl != null) {
        newQr = _userProfile!.bankQrUrl;
        needsUpdate = true;
      }

      if (needsUpdate) {
        await updatePerson(person.id,
            userId: newUserId, 
            email: newEmail, 
            avatarUrl: newAvatar,
            bankId: newBankId,
            accountNo: newAccNo,
            bankQrUrl: newQr);
      }
      if (person.fcmToken == null && _fcmToken != null) {
        await claimPerson(person.id);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    _isLoadingAuth = true;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
      if (_currentUser != null) {
        final cloudGroups =
            await _syncService.fetchGroupsForUser(_currentUser!.uid);
        for (final cg in cloudGroups) {
          final idx = _groups.indexWhere((g) => g.syncId == cg.syncId);
          if (idx == -1) {
            _groups.add(cg);
          } else {
            _groups[idx] = cg;
          }
        }
        await _saveState();
        _autoClaimMe();
      }
      } finally {
      _isLoadingAuth = false;
      _notify();
    }
  }

  Future<void> _signOut() async {
    _isLoadingAuth = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _currentUser = null;
      _userProfile = null;
      _groups.clear();
      _activeGroupId = null;
      _cachedActiveGroup = null;
      await _saveState();
      } finally {
      _isLoadingAuth = false;
      _notify();
    }
  }

  Future<void> updateGlobalUserProfile({
    String? name,
    String? bankId,
    String? accountNo,
    String? bankQrUrl,
  }) async {
    if (_currentUser == null || _userProfile == null) return;
    
    final updated = _userProfile!.copyWith(
      name: name,
      bankId: bankId,
      accountNo: accountNo,
      bankQrUrl: bankQrUrl,
    );
    
    // Quick out if nothing changed
    if (updated == _userProfile) return;
    
    _userProfile = updated;
    _notify();
    
    // Auto-upload QR if it's a local path
    if (bankQrUrl != null && !bankQrUrl.startsWith('http')) {
      final cloudUrl = await _syncService.uploadBankQr(bankQrUrl);
      if (cloudUrl != null) {
        _userProfile = _userProfile!.copyWith(bankQrUrl: cloudUrl);
        _notify();
      }
    }
    
    await _syncService.pushUserProfile(_userProfile!);
    
    // Propagate to current groups if mapped
    for (int i = 0; i < _groups.length; i++) {
      final pIdx = _groups[i].people.indexWhere((p) => p.userId == _currentUser!.uid);
      if (pIdx != -1) {
        final person = _groups[i].people[pIdx];
        final updatedPerson = person.copyWith(
          name: name,
          bankId: bankId,
          accountNo: accountNo,
          bankQrUrl: _userProfile!.bankQrUrl, // use the potentially uploaded one
        );
        final updatedPeople = [..._groups[i].people];
        updatedPeople[pIdx] = updatedPerson;
        _groups[i] = _groups[i].copyWith(people: updatedPeople);
        if (_groups[i].syncId != null) _syncService.pushUpdate(_groups[i]);
      }
    }
    await _saveState();
  }
}
