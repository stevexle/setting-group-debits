part of '../app_state.dart';

extension AppStateAuth on AppState {
  void _initAuth() {
    _authSub = _authService.user.listen((user) {
      _currentUser = user;
      notifyListeners();
      if (user != null) {
        log.setUserIdentifier(user.uid);
        _setupAccSync();
        _setupPersonalTxSync();
        _setupGroupsSync();
        if (_activeGroupId != null) {
          _autoClaimMe();
        }
      } else {
        _accSubscription?.cancel();
        _personalTxSubscription?.cancel();
        _groupsSubscription?.cancel();
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

      if (needsUpdate) {
        await updatePerson(person.id,
            userId: newUserId, email: newEmail, avatarUrl: newAvatar);
      }
      if (person.fcmToken == null && _fcmToken != null) {
        await claimPerson(person.id);
      }
    }
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Person? get me {
    if (_currentUser == null) return null;
    try {
      return people.firstWhere((p) =>
          p.userId == _currentUser!.uid ||
          (p.email != null && p.email == _currentUser!.email));
    } catch (_) {
      return null;
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _currentUser = null;
      _groups.clear();
      _activeGroupId = null;
      _cachedActiveGroup = null;
      await _saveState();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
