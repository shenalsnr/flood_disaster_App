import 'package:flood_disaster/core/services/offline_sync.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Saves the logged-in camp leader's editable details to the shared `users`
/// collection (the same document the login screen reads).
class CampLeaderProfileService {
  CampLeaderProfileService._();

  static Future<void> saveDetails({
    required String email,
    required String fullName,
    required String phoneNumber,
    required String floodZone,
  }) async {
    final id = email.toLowerCase().trim();
    await FirebaseFirestore.instance.collection('users').doc(id).set({
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'floodZone': floodZone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).queued();
  }
}
