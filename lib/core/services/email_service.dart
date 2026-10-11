import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sends the "your WeSafe account" email to a newly created staff member.
///
/// Uses EmailJS (https://www.emailjs.com), which sends the mail from your own
/// Gmail without a server. Fill the three values below once. While they are
/// still the placeholders, the app falls back to opening the phone's email app
/// with the message already written (the admin just taps Send).
///
/// EmailJS setup (5 minutes):
///  1. Sign up, then "Email Services" -> Add service -> Gmail -> note the
///     Service ID.
///  2. "Email Templates" -> Create template. Set "To email" to {{to_email}}.
///     Subject:  Your WeSafe account
///     Body (use these variables):
///        Hello {{to_name}},
///        An administrator created a {{role}} account for you in WeSafe.
///        Sign-in email: {{to_email}}
///        Password: {{password}}
///        Assigned camp: {{camp}}
///        Please change your password after the first sign in.
///     Note the Template ID.
///  3. "Account" -> General -> Public Key.
///  4. "Account" -> Security -> turn ON "Allow EmailJS API for non-browser
///     applications" (needed for mobile apps).
class EmailService {
  EmailService._();

  static const String serviceId = 'service_j0t9424';
  static const String templateId = 'template_xzc9kgo';
  static const String publicKey = 'htha41UXnoAF7xMX3';

  static bool get isConfigured =>
      !serviceId.startsWith('YOUR_') &&
      !templateId.startsWith('YOUR_') &&
      !publicKey.startsWith('YOUR_');

  /// Emails the account details. Returns null on success, or a readable error.
  static Future<String?> sendStaffAccount({
    required String toEmail,
    required String toName,
    required String role,
    required String camp,
    required String password,
  }) async {
    if (!isConfigured) return 'Email is not set up yet.';
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client
          .postUrl(Uri.parse('https://api.emailjs.com/api/v1.0/email/send'))
          .timeout(const Duration(seconds: 10));
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('origin', 'http://localhost');
      req.add(utf8.encode(jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': toEmail,
          'to_name': toName,
          'role': role,
          'camp': camp.isEmpty ? '-' : camp,
          'password': password,
          'app_name': 'WeSafe',
        },
      })));
      final res = await req.close().timeout(const Duration(seconds: 15));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode == 200) return null;
      debugPrint('EmailJS error ${res.statusCode}: $body');
      return 'Email service said: $body';
    } catch (e) {
      return 'Could not send the email (check the internet): $e';
    } finally {
      client.close();
    }
  }

  /// Fallback: opens the phone's email app with the message already written.
  static Future<bool> openEmailApp({
    required String toEmail,
    required String toName,
    required String role,
    required String camp,
    required String password,
  }) {
    final body = 'Hello $toName,\n\n'
        'An administrator created a $role account for you in WeSafe.\n\n'
        'Sign-in email: $toEmail\n'
        'Password: $password\n'
        '${camp.isEmpty ? '' : 'Assigned camp: $camp\n'}\n'
        'Please change your password after the first sign in.';
    final uri = Uri(
      scheme: 'mailto',
      path: toEmail,
      query: 'subject=${Uri.encodeComponent('Your WeSafe account')}'
          '&body=${Uri.encodeComponent(body)}',
    );
    return launchUrl(uri);
  }
}
