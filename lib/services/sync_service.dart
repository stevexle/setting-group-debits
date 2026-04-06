import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:setting_group_debits/services/log_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Pushes metadata updates (name, people) to the main group document.
  Future<void> pushUpdate(Group group) async {
    if (group.syncId == null) return;
    try {
      final data = group.toFirestoreMetadata();
      
      // Cleanup legacy fields if they exist
      data['transactions'] = FieldValue.delete();
      data['plans'] = FieldValue.delete();

      await _firestore.collection('groups').doc(group.syncId).update(data);
    } catch (e, s) {
      log.error("Firebase: pushUpdate error", e, s);
    }
  }

  /// Pushes a single group transaction.
  Future<void> pushGroupTransaction(String syncId, GroupTransaction tx) async {
    try {
      final batch = _firestore.batch();
      final groupRef = _firestore.collection('groups').doc(syncId);
      final txRef = groupRef.collection('group_transactions').doc(tx.id);

      batch.set(txRef, tx.toJson());
      batch.update(groupRef, {'lastUpdate': FieldValue.serverTimestamp()});
      
      await batch.commit();
    } catch (e, s) {
      log.error("Firebase: pushGroupTransaction error", e, s);
    }
  }

  /// Pushes a single group plan.
  Future<void> pushGroupPlan(String syncId, BudgetPlan plan) async {
    try {
      await _firestore.collection('groups').doc(syncId).collection('group_plans').doc(plan.id).set(plan.toJson());
    } catch (e, s) {
      log.error("Firebase: pushGroupPlan error", e, s);
    }
  }

  /// Deletes a group plan.
  Future<void> deleteGroupPlan(String syncId, String planId) async {
    try {
      await _firestore.collection('groups').doc(syncId).collection('group_plans').doc(planId).delete();
    } catch (e, s) {
      log.error("Firebase: deleteGroupPlan error", e, s);
    }
  }

  /// Pushes a single personal transaction.
  Future<void> pushPersonalTransaction(String uid, PersonalTransaction tx) async {
    try {
      await _firestore.collection('users').doc(uid).collection('personal_transactions').doc(tx.id).set(tx.toJson());
    } catch (e, s) {
      log.error("Firebase: pushPersonalTransaction error", e, s);
    }
  }

  /// Deletes a group transaction.
  Future<void> deleteGroupTransaction(String syncId, String txId) async {
    try {
      await _firestore.collection('groups').doc(syncId).collection('group_transactions').doc(txId).delete();
    } catch (e, s) {
      log.error("Firebase: deleteGroupTransaction error", e, s);
    }
  }

  /// Deletes a personal transaction.
  Future<void> deletePersonalTransaction(String uid, String txId) async {
    try {
      await _firestore.collection('users').doc(uid).collection('personal_transactions').doc(txId).delete();
    } catch (e, s) {
      log.error("Firebase: deletePersonalTransaction error", e, s);
    }
  }

  /// Purges all transaction history (subcollection AND legacy array).
  Future<void> purgeTransactions(String syncId) async {
    try {
      final groupRef = _firestore.collection('groups').doc(syncId);
      
      // 1. Delete legacy 'transactions' array field
      await groupRef.update({'transactions': FieldValue.delete()});

      // 2. Delete all docs in subcollection using chunked batches
      final snap = await groupRef.collection('group_transactions').get();
      if (snap.docs.isNotEmpty) {
        await _batchDelete(snap.docs.map((d) => d.reference).toList());
      }
    } catch (e, s) {
      log.error("Firebase: purgeTransactions error", e, s);
    }
  }

  /// Removes a user from a sync group (leaves it).
  Future<void> leaveGroup(String syncId, String userId) async {
    try {
      final docRef = _firestore.collection('groups').doc(syncId);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final List peopleJson = List.from(data['people'] ?? []);
        final updatedPeople = peopleJson.where((p) => p['userId'] != userId).toList();
        final List memberUids = List.from(data['memberUids'] ?? []);
        memberUids.remove(userId);
        
        await docRef.update({
          'people': updatedPeople,
          'memberUids': memberUids,
        });
      }
    } catch (e, s) {
      log.error("Firebase: leaveGroup error", e, s);
    }
  }

  /// Deletes an entire group document and its subcollections (transactions AND plans).
  Future<void> deleteCloudGroup(String syncId) async {
    try {
      final groupRef = _firestore.collection('groups').doc(syncId);
      final txSnap = await groupRef.collection('group_transactions').get();
      final planSnap = await groupRef.collection('group_plans').get();
      
      final List<DocumentReference> refsToDelete = [];
      for (var d in txSnap.docs) {
        refsToDelete.add(d.reference);
      }
      for (var d in planSnap.docs) {
        refsToDelete.add(d.reference);
      }
      refsToDelete.add(groupRef);

      await _batchDelete(refsToDelete);
    } catch (e, s) {
      log.error("Firebase: deleteCloudGroup error", e, s);
    }
  }

  /// Uploads an avatar image to Firebase Storage and returns the download URL.
  Future<String?> uploadAvatar(String localPath) async {
    if (localPath.isEmpty || localPath.startsWith('http')) return localPath;
    try {
      final file = File(localPath);
      if (!file.existsSync()) return localPath;

      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${localPath.split('/').last}";
      final ref = _storage.ref().child('avatars').child(fileName);

      final snapshot = await ref.putFile(file);
      if (snapshot.state == TaskState.success) {
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e, s) {
      log.error("Firebase: uploadAvatar error", e, s);
    }
    return localPath;
  }

  /// Fetches a group by ID (Invite Code).
  Future<Group?> fetchGroup(String inviteCode) async {
    try {
      final groupRef = _firestore.collection('groups').doc(inviteCode);
      final results = await Future.wait([
        groupRef.get(),
        groupRef.collection('group_transactions').get(),
        groupRef.collection('group_plans').get(),
      ]);

      final doc = results[0] as DocumentSnapshot;
      final txSnap = results[1] as QuerySnapshot;
      final planSnap = results[2] as QuerySnapshot;

      if (doc.exists) {
        final data =
            Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['groupTransactions'] = txSnap.docs.map((d) => d.data()).toList();
        data['plans'] = planSnap.docs.map((d) => d.data()).toList();

        return Group.fromJson(data);
      }
    } catch (e, s) {
      log.error("Firebase: fetchGroup error", e, s);
    }
    return null;
  }

  /// Enables cloud sync for a local group.
  Future<String?> enableSync(Group group) async {
    try {
      final data = group.toFirestoreMetadata();
      
      final docRef = await _firestore.collection('groups').add(data);
      
      final syncId = docRef.id;
      await docRef.update({'syncId': syncId});
      
      // Parallelize uploads for faster initial sync
      final List<Future> uploads = [];
      for (final tx in group.groupTransactions) {
        uploads.add(pushGroupTransaction(syncId, tx));
      }
      for (final plan in group.plans) {
        uploads.add(pushGroupPlan(syncId, plan));
      }
      await Future.wait(uploads);
      return syncId;
    } catch (e, s) {
      log.error("Firebase: enableSync error", e, s);
      return null;
    }
  }

  /// Streams for real-time synchronization.
  Stream<DocumentSnapshot> getSyncStream(String syncId) => _firestore.collection('groups').doc(syncId).snapshots();
  
  Stream<QuerySnapshot> getGroupTransactionsStream(String syncId) => 
      _firestore.collection('groups').doc(syncId).collection('group_transactions').orderBy('date', descending: true).snapshots();

  Stream<QuerySnapshot> getGroupPlansStream(String syncId) =>
      _firestore.collection('groups').doc(syncId).collection('group_plans').snapshots();

  Stream<QuerySnapshot> getGroupsForUserStream(String uid) =>
      _firestore.collection('groups').where('memberUids', arrayContains: uid).snapshots();

  Stream<QuerySnapshot> getPersonalTransactionsStream(String uid) =>
      _firestore.collection('users').doc(uid).collection('personal_transactions').orderBy('date', descending: true).snapshots();

  /// Fetches all groups where the user is a member.
  Future<List<Group>> fetchGroupsForUser(String uid) async {
    try {
      final snapshot = await _firestore.collection('groups').where('memberUids', arrayContains: uid).get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['groupTransactions'] = []; 
        data['plans'] = []; 
        return Group.fromJson(data);
      }).toList();
    } catch (e, s) {
      log.error("Firebase: fetchGroupsForUser error", e, s);
      return [];
    }
  }

  // --- Account Sync (User Specific) ---

  Future<void> pushAccount(String uid, Account acc) async {
    try {
      await _firestore.collection('users').doc(uid).collection('accounts').doc(acc.id).set(acc.toJson());
    } catch (e, s) {
      log.error("Firebase: pushAccount error", e, s);
    }
  }

  Future<void> deleteAccount(String uid, String accId) async {
    try {
      await _firestore.collection('users').doc(uid).collection('accounts').doc(accId).delete();
    } catch (e, s) {
      log.error("Firebase: deleteAccount error", e, s);
    }
  }

  Stream<QuerySnapshot> getAccountsStream(String uid) =>
      _firestore.collection('users').doc(uid).collection('accounts').snapshots();

  /// Internal helper to handle chunked batch deletions (max 500 per batch)
  Future<void> _batchDelete(List<DocumentReference> refs) async {
    for (var i = 0; i < refs.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < refs.length) ? i + 500 : refs.length;
      for (var j = i; j < end; j++) {
        batch.delete(refs[j]);
      }
      await batch.commit();
    }
  }
}
