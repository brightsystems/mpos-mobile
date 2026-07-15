import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocale {
  AppLocale._();

  static const Locale defaultLocale = Locale('en', 'ET');
  static const String defaultCurrencyCode = 'ETB';

  static const List<Locale> supportedLocales = [Locale('en', 'ET')];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}
