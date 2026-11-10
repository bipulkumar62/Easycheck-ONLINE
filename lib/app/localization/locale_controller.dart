import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the patient/clinic language choice and rebuilds the app when it
/// changes. English is the safe fallback when storage or the platform locale is
/// unavailable (for example in widget tests).
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();
  static const String _storageKey = 'easycheck_language_code';

  Locale _locale = const Locale('en');
  bool _loaded = false;

  Locale get locale => _locale;
  bool get isHindi => _locale.languageCode == 'hi';
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored == 'hi' || stored == 'en') {
        _locale = Locale(stored!);
      } else {
        final systemCode =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        _locale = systemCode == 'hi' ? const Locale('hi') : const Locale('en');
      }
    } catch (_) {
      // Keep English when preferences are unavailable.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'hi' ? 'hi' : 'en';
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, code);
    } catch (_) {
      // The in-memory choice still applies for this session.
    }
  }

  Future<void> toggle() {
    return setLocale(isHindi ? const Locale('en') : const Locale('hi'));
  }
}
