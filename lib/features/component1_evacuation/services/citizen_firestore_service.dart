import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CitizenFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Uses actual logged-in user ID, falls back to 'mock_user_123' if testing without login
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? 'mock_user_123';

  // ===========================================================================
  // 3. Citizen Profile & Safe Arrival Status
  // ===========================================================================

  /// Create: Initialize a citizen profile document upon registration
  Future<void> createCitizenProfile(String name) async {
    await _db.collection('users').doc(currentUserId).set({
      'name': name,
      'evacuationStatus': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Read: Fetch the citizen's profile details
  Stream<DocumentSnapshot> getCitizenProfile() {
    return _db.collection('users').doc(currentUserId).snapshots();
  }

  /// Update: "Mark as Safe" function that updates the evacuationStatus field
  Future<void> markAsSafe() async {
    await _db.collection('users').doc(currentUserId).update({
      'evacuationStatus': 'Safe',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete: Delete the user's profile document
  Future<void> deleteCitizenProfile() async {
    await _db.collection('users').doc(currentUserId).delete();
  }

  // ===========================================================================
  // 1. Evacuation Checklist (Full CRUD)
  // ===========================================================================

  /// Create: Add a new item to the checklist sub-collection
  Future<void> addChecklistItem(String itemName) async {
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('checklist')
        .add({
      'itemName': itemName,
      'isPacked': false,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Read: Fetch checklist items in real-time
  Stream<QuerySnapshot> getChecklistItems() {
    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('checklist')
        .orderBy('addedAt', descending: false)
        .snapshots();
  }

  /// Update: Toggle the isPacked boolean
  Future<void> toggleChecklistItem(String docId, bool currentStatus) async {
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('checklist')
        .doc(docId)
        .update({'isPacked': !currentStatus});
  }

  /// Delete: Remove the item's document
  Future<void> deleteChecklistItem(String docId) async {
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('checklist')
        .doc(docId)
        .delete();
  }

  // ===========================================================================
  // 2. Personal Emergency Contacts (Full CRUD)
  // ===========================================================================

  /// Create: Add a new contact to the contacts sub-collection
  Future<void> addEmergencyContact(String name, String phoneNumber) async {
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .add({
      'name': name,
      'phoneNumber': phoneNumber,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Read: Fetch the contacts in real-time
  Stream<QuerySnapshot> getEmergencyContacts() {
    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .orderBy('addedAt', descending: false)
        .snapshots();
  }

  /// Update: Update the phoneNumber or name of a specific contact
  Future<void> updateEmergencyContact(String docId, String newName, String newPhone) async {
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .doc(docId)
        .update({
      'name': newName,
      'phoneNumber': newPhone,
    });
  }

  /// Delete: Delete the contact document
  Future<void> deleteEmergencyContact(String docId) async {
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .doc(docId)
        .delete();
  }
}
