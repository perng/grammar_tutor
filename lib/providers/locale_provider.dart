import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale;
  static const String _prefKey = 'selected_locale';

  LocaleProvider() : _locale = const Locale('en') {
    _loadLocale();
  }

  Locale get locale => _locale;

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localeCode = prefs.getString(_prefKey);
    if (localeCode != null) {
      final parts = localeCode.split('_');
      if (parts.length == 2) {
        _locale = Locale(parts[0], parts[1]);
      } else {
        _locale = Locale(parts[0]);
      }
      notifyListeners();
    }
  }

  void setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String code = locale.languageCode;
    if (locale.countryCode != null) {
      code += '_${locale.countryCode}';
    }
    await prefs.setString(_prefKey, code);
  }
}
