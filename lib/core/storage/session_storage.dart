import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

class SessionStorage {
  SessionStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _sessionKey = 'mpos_session';

  Future<void> saveSession(AuthSessionEntity session) async {
    await _prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<AuthSessionEntity?> loadSession() async {
    final raw = _prefs.getString(_sessionKey);

    if (raw == null) {
      return null;
    }

    return AuthSessionEntity.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
  }
}
