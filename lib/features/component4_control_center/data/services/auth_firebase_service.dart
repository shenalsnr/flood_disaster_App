import 'package:flood_disaster/core/services/offline_sync.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/responder_models.dart';

class AuthFirebaseService {
  static final AuthFirebaseService _instance =
      AuthFirebaseService._internal();
  factory AuthFirebaseService() => _instance;

  AuthFirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Local cache (bootstrap administrators only); real accounts come from Firestore
  final Map<String, Map<String, dynamic>> _offlineFallbackCache = {
    // Bootstrap administrator: always able to sign in so the first staff
    // accounts can be created. Change this password before real use.
    'admin@wesafe.gov.lk': {
      'uid': 'admin@wesafe.gov.lk',
      'fullName': 'System Administrator',
      'email': 'admin@wesafe.gov.lk',
      'phoneNumber': '',
      'nic': '',
      'floodZone': 'National Control',
      'role': 'admin',
      'password': 'Admin@2026',
    },
    // Second bootstrap administrator (demo / coursework login).
    'admin@gmail.com': {
      'uid': 'admin@gmail.com',
      'fullName': 'Administrator',
      'email': 'admin@gmail.com',
      'phoneNumber': '',
      'nic': '',
      'floodZone': 'National Control',
      'role': 'admin',
      'password': 'admin123',
    },
  };

  static const Set<String> _bootstrapAdmins = {
    'admin@wesafe.gov.lk',
    'admin@gmail.com',
  };

  /// Save new user registration details to Cloud Firestore & in-memory cache
  Future<UserProfile> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String nic,
    required String floodZone,
    required String password,
    required String role,
    String district = '',
    String city = '',
  }) async {
    final cleanEmail = email.toLowerCase().trim();

    final userData = {
      'uid': cleanEmail,
      'fullName': fullName.trim(),
      'email': cleanEmail,
      'phoneNumber': phoneNumber.trim(),
      'nic': nic.trim(),
      'floodZone': floodZone.trim(),
      'district': district.trim(),
      'city': city.trim(),
      'role': role,
      'password': password,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Cache locally immediately to ensure zero latency / offline support
    _offlineFallbackCache[cleanEmail] = {
      ...userData,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await _firestore
          .collection('users')
          .doc(cleanEmail)
          .set(userData, SetOptions(merge: true));
      debugPrint('✅ Cloud Firestore: User "$cleanEmail" successfully registered in database');
    } catch (e) {
      debugPrint('⚠️ Firestore register warning: $e');
      // If Firestore fails (e.g. offline/rules), local fallback is preserved
    }

    return UserProfile(
      uid: cleanEmail,
      fullName: fullName.trim(),
      email: cleanEmail,
      phoneNumber: phoneNumber.trim(),
      nic: nic.trim(),
      floodZone: floodZone.trim(),
      role: role,
    );
  }

  /// Verify credentials from Cloud Firestore and return logged-in UserProfile
  Future<UserProfile> loginUser({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.toLowerCase().trim();

    Map<String, dynamic>? data;
    var firestoreReachable = false;

    try {
      final doc = await _firestore.collection('users').doc(cleanEmail).get();
      firestoreReachable = true;
      if (doc.exists && doc.data() != null) {
        data = doc.data()!;
        _offlineFallbackCache[cleanEmail] = data; // Keep cache in sync
        debugPrint('✅ Cloud Firestore: Retrieved user profile for "$cleanEmail"');
      }
    } catch (e) {
      debugPrint('⚠️ Firestore read warning: $e. Using local cache.');
    }

    // Local cache is only used when Firestore could not be reached (offline),
    // or for the bootstrap admin. This way an account the admin deleted
    // from Firestore can no longer sign in.
    if (data == null &&
        (!firestoreReachable || _bootstrapAdmins.contains(cleanEmail))) {
      data = _offlineFallbackCache[cleanEmail];
    }

    if (data == null) {
      throw Exception(
          'No account found with this email ($cleanEmail). Please complete registration first.');
    }

    if (data['isActive'] == false) {
      throw Exception(
          'This account has been disabled by the administrator. Please contact your administrator.');
    }

    final storedPassword = data['password'] as String? ?? '';
    if (storedPassword != password) {
      throw Exception('Incorrect password for $cleanEmail. Please try again or use Reset PIN.');
    }

    debugPrint('✅ User "$cleanEmail" authenticated successfully');
    return UserProfile.fromMap(data, cleanEmail);
  }

  /// Loads an existing account without a password (used to restore a
  /// remembered sign-in). Throws when the account is missing or disabled.
  Future<UserProfile> loadUserByEmail(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    Map<String, dynamic>? data;
    var reachable = false;
    try {
      final doc = await _firestore.collection('users').doc(cleanEmail).get();
      reachable = true;
      if (doc.exists && doc.data() != null) {
        data = doc.data()!;
        _offlineFallbackCache[cleanEmail] = data;
      }
    } catch (e) {
      debugPrint('loadUserByEmail read warning: $e');
    }
    if (data == null &&
        (!reachable || _bootstrapAdmins.contains(cleanEmail))) {
      data = _offlineFallbackCache[cleanEmail];
    }
    if (data == null) throw Exception('Account not found.');
    if (data['isActive'] == false) {
      throw Exception('This account has been disabled by the administrator.');
    }
    return UserProfile.fromMap(data, cleanEmail);
  }

  /// Update password in Cloud Firestore during Reset PIN / OTP flow
  Future<void> updatePassword({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.toLowerCase().trim();

    if (_offlineFallbackCache.containsKey(cleanEmail)) {
      _offlineFallbackCache[cleanEmail]!['password'] = newPassword;
    }

    try {
      await _firestore.collection('users').doc(cleanEmail).update({
        'password': newPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      }).queued();
      debugPrint('✅ Cloud Firestore: Password for "$cleanEmail" updated in database');
    } catch (e) {
      debugPrint('⚠️ Firestore password update warning: $e');
    }
  }

  /// Update user profile photo in Cloud Firestore and local cache
  Future<void> updateProfilePhoto({
    required String email,
    required String photoUrl,
  }) async {
    final cleanEmail = email.toLowerCase().trim();

    if (_offlineFallbackCache.containsKey(cleanEmail)) {
      _offlineFallbackCache[cleanEmail]!['photoUrl'] = photoUrl;
    }

    try {
      await _firestore.collection('users').doc(cleanEmail).set({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).queued();
      debugPrint('✅ Cloud Firestore: Profile photo updated for "$cleanEmail"');
    } catch (e) {
      debugPrint('⚠️ Firestore update photo warning: $e');
    }
  }
}
