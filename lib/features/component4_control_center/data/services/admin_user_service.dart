import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin-side user management on the Firestore `users` collection.
///
/// Documents are keyed by lower-case email. Besides the profile fields written
/// at registration, the admin tools use:
///   isActive   - false = account disabled (cannot sign in)
///   createdBy  - email of the admin who created a staff account
class AdminUserService {
  AdminUserService._();
  static final AdminUserService instance = AdminUserService._();

  final _users = FirebaseFirestore.instance.collection('users');

  /// Roles an admin can assign. key = value stored in Firestore.
  static const Map<String, String> staffRoles = {
    'responder': 'Responder (Control Center)',
    'campLeader': 'Camp Leader (Relief Tracker)',
    'dmcOfficer': 'DMC Officer (Supply Admin)',
    'volunteer': 'Volunteer (Hazard Reporting)',
    'admin': 'Administrator',
  };

  static String roleLabel(String role) =>
      staffRoles[role] ?? (role == 'citizen' ? 'Citizen' : role);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() =>
      _users.snapshots();

  /// Creates a staff account. Throws if the email is already registered.
  Future<void> createStaff({
    required String fullName,
    required String email,
    required String phone,
    required String role,
    required String area,
    required String password,
    required String createdBy,
  }) async {
    final id = email.toLowerCase().trim();
    final existing = await _users.doc(id).get();
    if (existing.exists) {
      throw StateError('An account with $id already exists.');
    }
    await _users.doc(id).set({
      'uid': id,
      'fullName': fullName.trim(),
      'email': id,
      'phoneNumber': phone.trim(),
      'nic': '',
      'floodZone': area.trim(),
      'role': role,
      'password': password,
      'isActive': true,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActive(String email, bool active) => _users
      .doc(email.toLowerCase().trim())
      .set({'isActive': active, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  Future<void> changeRole(String email, String role) => _users
      .doc(email.toLowerCase().trim())
      .set({'role': role, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  /// Camp (camp leaders) or zone (responders) the person is assigned to.
  Future<void> setArea(String email, String area) => _users
      .doc(email.toLowerCase().trim())
      .set({'floodZone': area.trim(), 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  Future<void> resetPassword(String email, String password) => _users
      .doc(email.toLowerCase().trim())
      .set({'password': password, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  Future<void> deleteUser(String email) =>
      _users.doc(email.toLowerCase().trim()).delete();
}
