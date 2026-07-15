import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mpos_mobile/core/constants/app_constants.dart';
import 'package:mpos_mobile/core/theme/app_theme.dart';
import 'package:mpos_mobile/core/theme/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._prefs) : super(_buildState(_prefs));

  final SharedPreferences _prefs;

  static ThemeState _buildState(SharedPreferences prefs) {
    final isLight = prefs.getString(AppConstants.selectedBrightnessKey) != 'dark';

    return ThemeState(
      isLight: isLight,
      themeData: AppTheme().init(brightness: isLight ? Brightness.light : Brightness.dark),
    );
  }

  Future<void> setLightMode(bool isLight) async {
    await _prefs.setString(AppConstants.selectedBrightnessKey, isLight ? 'light' : 'dark');

    emit(
      ThemeState(
        isLight: isLight,
        themeData: AppTheme().init(brightness: isLight ? Brightness.light : Brightness.dark),
      ),
    );
  }
}
