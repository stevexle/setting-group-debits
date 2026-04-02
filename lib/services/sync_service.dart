import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> pushUpdate(Group group) async {
    if (group.syncId == null) return;
    try {
      debugPrint("Firebase: Pushing update for group ${group.syncId}");
      await _firestore.collection('groups').doc(group.syncId).set(group.toJson());
    } catch (e) {
      debugPrint("Firebase: Push update error: $e");
    }
  }

  Future<String?> uploadAvatar(String localPath) async {
    if (localPath.isEmpty || localPath.startsWith('http')) return localPath;
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        debugPrint("Firebase: Local file does not exist at $localPath");
        return localPath;
      }

      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${localPath.split('/').last}";
      final ref = _storage.ref().child('avatars').child(fileName);
      
      debugPrint("Firebase: Uploading avatar to ${ref.fullPath} from $localPath (size: ${file.lengthSync()} bytes)...");
      
      final snapshot = await ref.putFile(file);
      debugPrint("Firebase: File uploaded to bucket ${snapshot.ref.bucket}. State: ${snapshot.state}");
      
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint("Firebase: Avatar uploaded successfully: $downloadUrl");
        return downloadUrl;
      } else {
        throw "Upload failed with state: ${snapshot.state}";
      }
    } catch (e) {
      debugPrint("Firebase: Avatar upload error detail: $e");
      if (e.toString().contains('object-not-found')) {
        debugPrint("Firebase TIP: Ensure your Storage is initialized in Firebase Console and rules allow access.");
      }
      return localPath;
    }
  }

  Future<String?> enableSync(Group group) async {
    try {
      debugPrint("Firebase: Enabling sync for ${group.name}...");
      final docRef = await _firestore.collection('groups').add(group.toJson());
      // Re-set with the newly generated ID
      final updatedGroup = group.copyWith(syncId: docRef.id);
      await _firestore.collection('groups').doc(docRef.id).set(updatedGroup.toJson());
      return docRef.id;
    } catch (e) {
      debugPrint("Firebase: Enable sync error: $e");
      return null;
    }
  }

  Future<Group?> fetchGroup(String inviteCode) async {
    try {
      final doc = await _firestore.collection('groups').doc(inviteCode).get();
      if (doc.exists) {
        return Group.fromJson(Map<String, dynamic>.from(doc.data()!));
      }
    } catch (e) {
      debugPrint("Firebase: Fetch group error: $e");
    }
    return null;
  }

  Stream<DocumentSnapshot> getSyncStream(String syncId) {
    return _firestore.collection('groups').doc(syncId).snapshots();
  }
}
