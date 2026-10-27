import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

/// The signed-in session, including the access and refresh tokens, kept in the platform's secure
/// storage (Android Keystore-backed encryption, iOS Keychain), never in plain SharedPreferences
/// (INSA audit 4.4/4.6). Sessions saved by older versions in SharedPreferences are moved over
/// once and deleted there.
class SessionStorage {
  SessionStorage(this._prefs, {FlutterSecureStorage? secureStorage})
    : _secure = secureStorage ?? const FlutterSecureStorage();

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const _sessionKey = 'mpos_session';

  /// Read once per app run: secure storage is slower and the session is read on most API calls.
  AuthSessionEntity? _cached;
  bool _loaded = false;

  Future<void> saveSession(AuthSessionEntity session) async {
    await _secure.write(key: _sessionKey, value: jsonEncode(session.toJson()));
    _cached = session;
    _loaded = true;
  }

  Future<AuthSessionEntity?> loadSession() async {
    if (_loaded) {
      return _cached;
    }

    var raw = await _secure.read(key: _sessionKey);

    // Move a session saved by an older version out of SharedPreferences.
    final legacy = _prefs.getString(_sessionKey);
    if (legacy != null) {
      raw ??= legacy;
      await _secure.write(key: _sessionKey, value: raw);
      await _prefs.remove(_sessionKey);
    }

    _cached = raw == null ? null : AuthSessionEntity.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _loaded = true;
    return _cached;
  }

  Future<void> clearSession() async {
    await _secure.delete(key: _sessionKey);
    await _prefs.remove(_sessionKey);
    _cached = null;
    _loaded = true;
  }
}
