import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/responder_models.dart';

class AuthFirebaseService {
  static final AuthFirebaseService _instance =
      AuthFirebaseService._internal();
  factory AuthFirebaseService() => _instance;

  AuthFirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Local fallback cache pre-seeded with demo roles and syncing live with Firestore
  final Map<String, Map<String, dynamic>> _offlineFallbackCache = {
    'n.perera@dispatched.gov.lk': {
      'uid': 'n.perera@dispatched.gov.lk',
      'fullName': 'Nadeeka Perera',
      'email': 'n.perera@dispatched.gov.lk',
      'phoneNumber': '+94 77 482 1029',
      'nic': '982341092V',
      'floodZone': 'Colombo Sector 4 (Low-Lying Area)',
      'role': 'responder',
      'password': 'Disaster@2026',
    },
    'chamara.d@gmail.com': {
      'uid': 'chamara.d@gmail.com',
      'fullName': 'Chamara Dissanayake',
      'email': 'chamara.d@gmail.com',
      'phoneNumber': '+94 71 234 5678',
      'nic': '982341092V',
      'floodZone': 'Colombo Low-Lying Area (Kelani Bank Zone)',
      'role': 'citizen',
      'password': 'Secure@1234',
    },
    'volunteer.kapila@dmc.org': {
      'uid': 'volunteer.kapila@dmc.org',
      'fullName': 'Kapila Wijesinghe',
      'email': 'volunteer.kapila@dmc.org',
      'phoneNumber': '+94 70 331 4455',
      'nic': '891234567V',
      'floodZone': 'Colombo Sector 2 (Outer Ring)',
      'role': 'volunteer',
      'password': 'Report@2026',
    },
    'leader.rohan@relief.gov.lk': {
      'uid': 'leader.rohan@relief.gov.lk',
      'fullName': 'Rohan Gunasekara',
      'email': 'leader.rohan@relief.gov.lk',
      'phoneNumber': '+94 77 901 2345',
      'nic': '751234567V',
      'floodZone': 'Kelani Basin Camp 01',
      'role': 'campLeader',
      'password': 'Camp@2026',
    },
  };

  /// Save new user registration details to Cloud Firestore & in-memory cache
  Future<UserProfile> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String nic,
    String district = '',
    String city = '',
    required String floodZone,
    required String password,
    required String role,
  }) async {
    final cleanEmail = email.toLowerCase().trim();

    final userData = {
      'uid': cleanEmail,
      'fullName': fullName.trim(),
      'email': cleanEmail,
      'phoneNumber': phoneNumber.trim(),
      'nic': nic.trim(),
      'district': district.trim(),
      'city': city.trim(),
      'floodZone': floodZone.trim(),
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
      district: district.trim(),
      city: city.trim(),
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

    try {
      final doc = await _firestore.collection('users').doc(cleanEmail).get();
      if (doc.exists && doc.data() != null) {
        data = doc.data()!;
        _offlineFallbackCache[cleanEmail] = data; // Keep cache in sync
        debugPrint('✅ Cloud Firestore: Retrieved user profile for "$cleanEmail"');
      }
    } catch (e) {
      debugPrint('⚠️ Firestore read warning: $e. Using local cache.');
    }

    // Check offline fallback cache if Firestore document wasn't fetched
    data ??= _offlineFallbackCache[cleanEmail];

    if (data == null) {
      throw Exception(
          'No account found with this email ($cleanEmail). Please complete registration first.');
    }

    final storedPassword = data['password'] as String? ?? '';
    if (storedPassword != password) {
      throw Exception('Incorrect password for $cleanEmail. Please try again or use Reset PIN.');
    }

    debugPrint('✅ User "$cleanEmail" authenticated successfully');
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
      });
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
      }, SetOptions(merge: true));
      debugPrint('✅ Cloud Firestore: Profile photo updated for "$cleanEmail"');
    } catch (e) {
      debugPrint('⚠️ Firestore update photo warning: $e');
    }
  }
}
