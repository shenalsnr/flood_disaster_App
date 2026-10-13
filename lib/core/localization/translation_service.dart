import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'language_controller.dart';

/// Translates TEXT THAT PEOPLE WRITE (warnings, chat, hazard reports ...)
/// into the language the viewer picked. Fixed app text uses tr() instead.
///
/// Uses the Google Cloud Translation API (supports Sinhala + Tamil).
/// Put your key in ONE place - run/build the app with:
///
///   flutter run --dart-define=TRANSLATE_API_KEY=YOUR_KEY
///
/// (or set [TranslationService.apiKey] in code). With NO key the app still
/// works - posted text is just shown in its original language.
class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  /// Google Cloud Translation API key (v2).
  static String apiKey = const String.fromEnvironment('TRANSLATE_API_KEY');

  bool get isConfigured => apiKey.isNotEmpty;

  final Map<String, _Result> _cache = {};
  final Map<String, Future<_Result>> _inFlight = {};

  /// Translate [text] into [to] (default: the viewer's current language).
  /// Never throws: on any problem the original text is returned.
  Future<String> translate(String text, {AppLang? to}) async {
    final r = await _run(text, (to ?? LanguageController.instance.lang).code);
    return r.text;
  }

  /// True when [text] is already written in the viewer's language
  /// (so a "translated" badge is not needed).
  Future<bool> isSameLanguage(String text, {AppLang? to}) async {
    final r = await _run(text, (to ?? LanguageController.instance.lang).code);
    return r.same;
  }

  /// WRITE-TIME helper for official content: call once when saving, store the
  /// three versions next to the original, e.g.
  ///   final t = await TranslationService.instance.translateAll(msg);
  ///   doc.set({'message': msg, 'message_en': t['en'], 'message_si': t['si'],
  ///            'message_ta': t['ta']});
  /// Readers then use [pickLocalized] - no API call, works offline.
  Future<Map<String, String>> translateAll(String text) async {
    final out = <String, String>{};
    for (final l in AppLang.values) {
      out[l.code] = (await _run(text, l.code)).text;
    }
    return out;
  }

  /// Read a field saved with [translateAll]. Falls back to the original.
  static String pickLocalized(Map<String, dynamic> data, String field) {
    final code = LanguageController.instance.code;
    final v = data['${field}_$code'];
    if (v is String && v.trim().isNotEmpty) return v;
    final o = data[field];
    return o is String ? o : '';
  }

  /// The translated text if it is already cached (instant, no network).
  String? cached(String text, {AppLang? to}) {
    final code = (to ?? LanguageController.instance.lang).code;
    return _cache['$code|$text']?.text;
  }

  Future<_Result> _run(String text, String target) {
    final clean = text.trim();
    if (clean.isEmpty || !isConfigured) {
      return Future.value(_Result(text, true));
    }
    final key = '$target|$text';
    final hit = _cache[key];
    if (hit != null) return Future.value(hit);
    return _inFlight[key] ??= _fetch(text, target).then((r) {
      _cache[key] = r;
      _inFlight.remove(key);
      if (_cache.length > 600) _cache.remove(_cache.keys.first);
      return r;
    });
  }

  Future<_Result> _fetch(String text, String target) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.parse(
          'https://translation.googleapis.com/language/translate/v2?key=$apiKey');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'q': text, 'target': target, 'format': 'text'}));
      final res = await req.close().timeout(const Duration(seconds: 12));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        debugPrint('Translate HTTP ${res.statusCode}');
        return _Result(text, true);
      }
      final t = (jsonDecode(body)['data']['translations'] as List).first
          as Map<String, dynamic>;
      final detected = t['detectedSourceLanguage'] as String?;
      final same = detected == target;
      return _Result(same ? text : _unescape(t['translatedText'] as String), same);
    } catch (e) {
      debugPrint('Translate error: $e');
      return _Result(text, true); // offline / no key -> show original
    } finally {
      client.close(force: true);
    }
  }

  static String _unescape(String s) => s
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

class _Result {
  _Result(this.text, this.same);
  final String text;
  final bool same;
}
