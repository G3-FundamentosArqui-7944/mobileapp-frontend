import 'package:flutter/material.dart';

import '../data/storage/locale_storage.dart';

/// Idioma activo de la app. Inglés es el default; el usuario lo cambia en
/// tiempo de ejecución desde ProfileView. Persiste vía [LocaleStorage].
class LocaleController extends ChangeNotifier {
  static const List<Locale> supportedLocales = [Locale('en'), Locale('es')];
  static const Locale defaultLocale = Locale('en');

  final LocaleStorage _storage;
  Locale _locale = defaultLocale;

  LocaleController({LocaleStorage? storage}) : _storage = storage ?? LocaleStorage();

  Locale get locale => _locale;

  /// Código intl para DateFormat (distinto del código ARB: 'es' -> 'es_PE').
  String get intlLocaleCode => _locale.languageCode == 'es' ? 'es_PE' : 'en_US';

  /// Debe llamarse (y esperarse) antes de runApp() para que el idioma
  /// guardado ya esté activo en el primer frame.
  Future<void> loadSaved() async {
    final saved = await _storage.getLocale();
    if (saved != null && supportedLocales.contains(saved)) {
      _locale = saved;
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await _storage.saveLocale(locale);
  }
}
