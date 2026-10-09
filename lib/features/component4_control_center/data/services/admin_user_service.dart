import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  final _camps = FirebaseFirestore.instance.collection('camps');

  /// Same rule the Relief Tracker uses to turn a camp name into its data id
  /// ("Camp Nēraya" -> camp_neraya), so spelling variants map to one camp.
  static String campIdFromName(String name) {
    const map = {
      'ā': 'a', 'ē': 'e', 'ī': 'i', 'ō': 'o', 'ū': 'u',
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
    };
    final b = StringBuffer();
    for (final ch in name.trim().toLowerCase().split('')) {
      b.write(map[ch] ?? ch);
    }
    final slug = b
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'camp' : slug;
  }

  /// Camps the admin can assign leaders to (Firestore `camps` collection).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchCamps() =>
      _camps.snapshots();

  /// Tries a real server read and explains in plain words what is wrong.
  Future<String> diagnose() async {
    try {
      await _camps
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 12));
      return 'OK: connected to Firestore. If the screen still shows offline, '
          'pull back and reopen the Admin Panel.';
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'unavailable':
          return 'Cannot reach Firestore (unavailable).\n\n'
              '1. Open Chrome inside the emulator and load any website. If it '
              'does not load, the emulator has no internet: restart it with '
              'Cold Boot Now, turn off any VPN, or start it with '
              '"-dns-server 8.8.8.8".\n'
              '2. Make sure the emulator date and time are correct.\n'
              '3. In Firebase Console > Firestore Database, check the database '
              'exists (press "Create database" if not).';
        case 'permission-denied':
          return 'Connected, but the Firestore rules block this app (permission-denied).\n\n'
              'Firebase Console > Firestore Database > Rules: allow read and '
              'write on the "users" and "camps" collections.';
        case 'not-found':
        case 'failed-precondition':
          return 'The Firestore database does not exist in this Firebase '
              'project (${e.code}).\n\nFirebase Console > Firestore Database > '
              'Create database, then try again.';
        default:
          return 'Firestore error: ${e.code}\n${e.message ?? ''}';
      }
    } on TimeoutException {
      return 'No answer from Firestore within 12 seconds. The connection is '
          'very slow or blocked. Check the emulator internet / VPN.';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  Future<void> addCamp(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) throw StateError('Enter the camp name.');
    await _camps.doc(campIdFromName(clean)).set({
      'name': clean,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Removes a camp. Leaders listed in [unassignEmails] are left without a
  /// camp.
  Future<void> deleteCamp(String name,
      {List<String> unassignEmails = const []}) {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.delete(_camps.doc(campIdFromName(name)));
    for (final e in unassignEmails) {
      batch.set(
          _users.doc(e.toLowerCase().trim()),
          {'floodZone': '', 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
    }
    return batch.commit();
  }

  /// Renames a camp and moves its leaders ([leaderEmails]) to the new name.
  Future<void> renameCamp(String oldName, String newName,
      {List<String> leaderEmails = const []}) {
    final clean = newName.trim();
    if (clean.isEmpty) throw StateError('Enter the camp name.');
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.delete(_camps.doc(campIdFromName(oldName)));
    batch.set(_camps.doc(campIdFromName(clean)), {
      'name': clean,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    for (final e in leaderEmails) {
      batch.set(
          _users.doc(e.toLowerCase().trim()),
          {'floodZone': clean, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
    }
    return batch.commit();
  }

  /// Roles an admin can assign. key = value stored in Firestore.
  static const Map<String, String> staffRoles = {
    'responder': 'Responder (Control Center)',
    'campLeader': 'Camp Leader (Relief Tracker)',
    'dmcOfficer': 'DMC Officer (Supply Admin)',
    'volunteer': 'Volunteer (Hazard Reporting)',
    'admin': 'Administrator',
  };

  /// Older accounts stored free-text roles such as "Relief Camp Triage
  /// Leader". Map them onto the role keys so lists, filters and menus work.
  /// (The login screen already routes these the same way.)
  static String normalizeRole(String raw) {
    final r = raw.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    if (r.isEmpty) return 'citizen';
    if (r.contains('admin')) return 'admin';
    if (r.contains('dmc')) return 'dmcOfficer';
    if (r.contains('citizen')) return 'citizen';
    if (r.contains('volunteer')) return 'volunteer';
    if (r.contains('camp') || r.contains('leader')) return 'campLeader';
    if (r.contains('responder')) return 'responder';
    return raw;
  }

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
    try {
      final existing = await _users.doc(id).get(const GetOptions(source: Source.server));
      if (existing.exists) {
        throw StateError('An account with $id already exists.');
      }
    } on FirebaseException catch (e) {
      debugPrint('createStaff check failed: ${e.code}');
      if (e.code == 'unavailable') {
        throw StateError(
            'Cannot reach the database. Check that the phone/emulator has '
            'internet and that Firestore is created in the Firebase project.');
      }
      rethrow;
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
