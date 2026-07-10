import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia del idioma elegido por el usuario. No es dato sensible, por
/// eso usa SharedPreferences en vez de FlutterSecureStorage.
class LocaleStorage {
  static const _languageCodeKey = 'bm_locale_language_code';

  Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);
  }

  Future<Locale?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_languageCodeKey);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }
}
