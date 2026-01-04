import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LocaleProvider extends ChangeNotifier {
  Locale _locale;
  static const String _prefKey = 'selected_locale';

  LocaleProvider(SharedPreferences prefs) : _locale = const Locale('en') {
    _initLocale(prefs);
  }

  Locale get locale => _locale;

  void _initLocale(SharedPreferences prefs) {
    final String? localeCode = prefs.getString(_prefKey);
    if (localeCode != null) {
      final parts = localeCode.split('_');
      if (parts.length == 2) {
        _locale = Locale(parts[0], parts[1]);
      } else {
        _locale = Locale(parts[0]);
      }
    } else {
      _locale = _supportedLocaleFromSystem();
    }
  }

  Locale _supportedLocaleFromSystem() {
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    if (systemLocale.languageCode == 'zh') {
      if (systemLocale.scriptCode == 'Hant' ||
          systemLocale.countryCode == 'TW' ||
          systemLocale.countryCode == 'HK' ||
          systemLocale.countryCode == 'MO') {
        return const Locale('zh', 'TW');
      } else {
        return const Locale('zh', 'CN');
      }
    }
    return const Locale('en');
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
