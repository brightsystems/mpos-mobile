import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mpos_mobile/core/constants/app_constants.dart';
import 'package:mpos_mobile/core/locale/app_locale.dart';

/// Holds and persists the selected UI language.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._prefs) : super(AppLocale.localeForCode(_prefs.getString(AppConstants.selectedLocaleKey)));

  final SharedPreferences _prefs;

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == state.languageCode) {
      return;
    }
    await _prefs.setString(AppConstants.selectedLocaleKey, locale.languageCode);
    emit(locale);
  }
}
