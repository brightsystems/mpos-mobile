import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:mpos_mobile/core/locale/app_localizations.dart';
import 'package:mpos_mobile/core/locale/fallback_localizations_delegates.dart';

/// A selectable app language, shown in its own native script.
class AppLanguage {
  const AppLanguage({required this.locale, required this.nativeName, required this.englishName});

  final Locale locale;
  final String nativeName;
  final String englishName;

  String get code => locale.languageCode;
}

class AppLocale {
  AppLocale._();

  static const Locale defaultLocale = Locale('en');

  /// Locale used for number/currency formatting (kept as Ethiopian English so
  /// currency rendering is stable regardless of the selected UI language).
  static const Locale formattingLocale = Locale('en', 'ET');
  static const String defaultCurrencyCode = 'ETB';

  static const List<AppLanguage> languages = [
    AppLanguage(locale: Locale('en'), nativeName: 'English', englishName: 'English'),
    AppLanguage(locale: Locale('am'), nativeName: 'አማርኛ', englishName: 'Amharic'),
    AppLanguage(locale: Locale('ti'), nativeName: 'ትግርኛ', englishName: 'Tigrinya'),
    AppLanguage(locale: Locale('om'), nativeName: 'Afaan Oromoo', englishName: 'Afaan Oromo'),
  ];

  static List<Locale> get supportedLocales => languages.map((l) => l.locale).toList();

  static Locale localeForCode(String? code) {
    return languages
            .firstWhere(
              (l) => l.code == code,
              orElse: () => languages.first,
            )
            .locale;
  }

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    // Catch-all for locales Flutter doesn't bundle (ti, om).
    FallbackMaterialLocalizationsDelegate(),
    FallbackCupertinoLocalizationsDelegate(),
    FallbackWidgetsLocalizationsDelegate(),
  ];
}
