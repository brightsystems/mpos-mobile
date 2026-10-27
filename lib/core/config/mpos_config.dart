import 'package:flutter/foundation.dart';

class MposConfig {
  MposConfig._();

  static const bool enabled = bool.fromEnvironment('MPOS_MODE', defaultValue: true);

  /// When true, all API calls are handled by in-memory fakes (no network).
  /// Defaults to false — use the real API. Opt in with `--dart-define=MPOS_MOCK_MODE=true`.
  static const bool mockMode = bool.fromEnvironment('MPOS_MOCK_MODE', defaultValue: false);

  /// API server (the prefix below is appended). Defaults to the hosted API; point a dev build at a
  /// local API with `--dart-define=MPOS_API_URL=http://<host>:5150`.
  static const String baseUrl = String.fromEnvironment('MPOS_API_URL', defaultValue: 'https://posapi.kefta-ticket.com');

  static const String apiPrefix = '/api/v1';

  static const String appId = String.fromEnvironment('MPOS_APP_ID', defaultValue: 'mobile-pos');

  static const String _appSecret = String.fromEnvironment('MPOS_APP_SECRET');

  /// Release builds get the secret only from `--dart-define=MPOS_APP_SECRET=...` (no secret is
  /// compiled into the app); debug builds fall back to the local API's development value.
  static const String appSecret = _appSecret != ''
      ? _appSecret
      : kReleaseMode
      ? ''
      : 'dev-mobile-pos-secret-change-me';
}
