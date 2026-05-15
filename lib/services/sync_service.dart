import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import 'storage_service.dart';

class SyncService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = StorageService();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference? get _userDoc {
    if (_uid == null) return null;
    return _firestore.collection('users').doc(_uid);
  }

  // Lokal → Firestore
  Future<bool> uploadToCloud() async {
    if (_userDoc == null) return false;
    try {
      final groups = await _storage.loadGroups();
      final defaultGroupId = await _storage.getDefaultGroupId();

      await _userDoc!.set({
        'groups': groups.map((g) => g.toJson()).toList(),
        'defaultGroupId': defaultGroupId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Firestore → Lokal
  Future<bool> downloadFromCloud() async {
    if (_userDoc == null) return false;
    try {
      final doc = await _userDoc!.get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;

      final groupList = (data['groups'] as List<dynamic>)
          .map((g) => Group.fromJson(g as Map<String, dynamic>))
          .toList();
      await _storage.saveGroups(groupList);

      final defaultGroupId = data['defaultGroupId'] as String?;
      if (defaultGroupId != null) {
        await _storage.setDefaultGroupId(defaultGroupId);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}