import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The three languages WeSafe supports.
enum AppLang {
  en('en', 'English', 'English'),
  si('si', 'සිංහල', 'Sinhala'),
  ta('ta', 'தமிழ்', 'Tamil');

  const AppLang(this.code, this.nativeName, this.englishName);
  final String code;
  final String nativeName;
  final String englishName;

  static AppLang fromCode(String? code) =>
      AppLang.values.firstWhere((l) => l.code == code, orElse: () => AppLang.en);
}

/// App-wide language. One switch changes every screen, and the choice is
/// remembered after the app is closed (same idea as ThemeController).
class LanguageController extends ChangeNotifier {
  LanguageController._();
  static final LanguageController instance = LanguageController._();

  static const _key = 'wesafe_language';

  AppLang _lang = AppLang.en;
  bool _chosen = false;

  AppLang get lang => _lang;
  String get code => _lang.code;

  /// False the very first time the app is opened (language picker is shown).
  bool get hasChosen => _chosen;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getString(_key);
      _chosen = saved != null;
      _lang = AppLang.fromCode(saved);
    } catch (_) {
      _chosen = false;
      _lang = AppLang.en;
    }
  }

  Future<void> set(AppLang value) async {
    final changed = _lang != value;
    _lang = value;
    _chosen = true;
    if (changed) notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, value.code);
    } catch (_) {
      // Not saved - the choice still applies for this session.
    }
  }
}
