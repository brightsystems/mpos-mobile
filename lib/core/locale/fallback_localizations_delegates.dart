import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter's bundled `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations`
/// do not ship Tigrinya (ti) or Afaan Oromo (om). Without a fallback, showing
/// the app in those locales throws because Material widgets require a
/// `MaterialLocalizations`. These delegates report support for every locale and
/// serve the English localizations, so the framework strings (date pickers,
/// tooltips, etc.) stay functional while our own strings are translated.
class FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  static const Locale _fallback = Locale('en');

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) => GlobalMaterialLocalizations.delegate.load(_fallback);

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  static const Locale _fallback = Locale('en');

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) => GlobalCupertinoLocalizations.delegate.load(_fallback);

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

class FallbackWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  static const Locale _fallback = Locale('en');

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) => GlobalWidgetsLocalizations.delegate.load(_fallback);

  @override
  bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
}
