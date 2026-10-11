import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide Dark / Light mode. One switch controls every component and the
/// choice is remembered after the app is closed.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'wesafe_light_mode';

  bool _light = false;
  bool get isLight => _light;
  ThemeMode get mode => _light ? ThemeMode.light : ThemeMode.dark;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _light = p.getBool(_key) ?? false;
    } catch (_) {
      _light = false;
    }
    _applyStatusBar();
  }

  Future<void> setLight(bool value) async {
    if (_light == value) return;
    _light = value;
    _applyStatusBar();
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key, value);
    } catch (_) {
      // Not saved - the choice still applies for this session.
    }
  }

  void _applyStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _light ? Brightness.dark : Brightness.light,
        statusBarBrightness: _light ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            _light ? const Color(0xFFF1F5F9) : const Color(0xFF070B14),
        systemNavigationBarIconBrightness:
            _light ? Brightness.dark : Brightness.light,
      ),
    );
  }
}
