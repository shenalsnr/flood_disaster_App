import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers who is signed in ("Remember credentials") so the app can open
/// straight to that person's dashboard. Only the email is stored, never the
/// password. Logging out clears it.
class SessionService {
  SessionService._();

  static const _key = 'signed_in_email';

  static Future<void> save(String email) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, email.toLowerCase().trim());
    } catch (e) {
      debugPrint('Session save failed: $e');
    }
  }

  static Future<String?> read() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(_key);
      return (v == null || v.isEmpty) ? null : v;
    } catch (e) {
      debugPrint('Session read failed: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_key);
    } catch (e) {
      debugPrint('Session clear failed: $e');
    }
  }
}
