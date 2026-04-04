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
      final data = group.toJson();
      data.remove('transactions'); // Ensure transactions are NOT in the main doc
      await _firestore.collection('groups').doc(group.syncId).set(data, SetOptions(merge: true));
    } catch (e, s) {
      log.error("Firebase: pushUpdate error", e, s);
    }
  }

  /// Pushes a single transaction to the 'transactions' subcollection.
  Future<void> pushTransaction(String syncId, Transaction tx) async {
    try {
      final batch = _firestore.batch();
      final groupRef = _firestore.collection('groups').doc(syncId);
      final txRef = groupRef.collection('transactions').doc(tx.id);

      batch.set(txRef, tx.toJson());
      batch.update(groupRef, {'lastUpdate': FieldValue.serverTimestamp()});
      
      await batch.commit();
    } catch (e, s) {
      log.error("Firebase: pushTransaction error", e, s);
    }
  }

  /// Deletes a single transaction from the subcollection.
  Future<void> deleteTransaction(String syncId, String txId) async {
    try {
      await _firestore.collection('groups').doc(syncId).collection('transactions').doc(txId).delete();
    } catch (e, s) {
      log.error("Firebase: deleteTransaction error", e, s);
    }
  }

  /// Purges all transaction history (subcollection AND legacy array).
  Future<void> purgeTransactions(String syncId) async {
    try {
      final groupRef = _firestore.collection('groups').doc(syncId);
      
      // 1. Delete legacy 'transactions' array field
      await groupRef.update({'transactions': FieldValue.delete()});

      // 2. Delete all docs in subcollection using partition logic (batch)
      final snap = await groupRef.collection('transactions').get();
      if (snap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e, s) {
      log.error("Firebase: purgeTransactions error", e, s);
    }
  }

  /// Deletes an entire group document and its subcollections.
  Future<void> deleteCloudGroup(String syncId) async {
    try {
      final groupRef = _firestore.collection('groups').doc(syncId);
      final txSnap = await groupRef.collection('transactions').get();
      
      final batch = _firestore.batch();
      for (var d in txSnap.docs) {
        batch.delete(d.reference);
      }
      batch.delete(groupRef);
      await batch.commit();
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
      final doc = await _firestore.collection('groups').doc(inviteCode).get();
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        final txSnap = await _firestore.collection('groups').doc(inviteCode).collection('transactions').get();
        data['transactions'] = txSnap.docs.map((d) => d.data()).toList();
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
      final data = group.toJson();
      data['transactions'] = []; // Subcollection handles transactions
      final docRef = await _firestore.collection('groups').add(data);
      
      final syncId = docRef.id;
      // Update with own ID
      await docRef.update({'syncId': syncId});
      
      // Push existing transactions
      for (final tx in group.transactions) {
        await pushTransaction(syncId, tx);
      }
      return syncId;
    } catch (e, s) {
      log.error("Firebase: enableSync error", e, s);
      return null;
    }
  }

  /// Streams for real-time synchronization.
  Stream<DocumentSnapshot> getSyncStream(String syncId) => _firestore.collection('groups').doc(syncId).snapshots();
  Stream<QuerySnapshot> getTransactionsStream(String syncId) => 
      _firestore.collection('groups').doc(syncId).collection('transactions').orderBy('date', descending: true).snapshots();

  /// Fetches all groups where the user is a member.
  Future<List<Group>> fetchGroupsForUser(String uid) async {
    try {
      final snapshot = await _firestore.collection('groups').where('memberUids', arrayContains: uid).get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['transactions'] = []; // Transactions are handled via subcollections/streams
        return Group.fromJson(data);
      }).toList();
    } catch (e, s) {
      log.error("Firebase: fetchGroupsForUser error", e, s);
      return [];
    }
  }
}
