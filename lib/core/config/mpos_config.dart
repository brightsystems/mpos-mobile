class MposConfig {
  MposConfig._();

  static const bool enabled = bool.fromEnvironment('MPOS_MODE', defaultValue: true);

  /// When true, all API calls are handled by in-memory fakes (no network).
  /// Defaults to false — use the real API. Opt in with `--dart-define=MPOS_MOCK_MODE=true`.
  static const bool mockMode = bool.fromEnvironment('MPOS_MOCK_MODE', defaultValue: false);

  static const String baseUrl = String.fromEnvironment('MPOS_API_URL', defaultValue: 'http://192.168.1.7:5150');
  
  static const String apiPrefix = '/api/v1';

  static const String appId = String.fromEnvironment('MPOS_APP_ID', defaultValue: 'mobile-pos');

  static const String appSecret = String.fromEnvironment(
    'MPOS_APP_SECRET',
    defaultValue: 'dev-mobile-pos-secret-change-me',
  );

  /// Supabase Storage for menu images (mirrors mpos-web `environment.supabase`).
  /// Only the public URL is stored on `MenuItem.ImageUrl`; image bytes never
  /// pass through the MPOS API.
  static const String supabaseUrl = String.fromEnvironment('MPOS_SUPABASE_URL', defaultValue: '');

  static const String supabaseAnonKey = String.fromEnvironment('MPOS_SUPABASE_ANON_KEY', defaultValue: '');

  static const String supabaseMenuBucket = String.fromEnvironment(
    'MPOS_SUPABASE_MENU_BUCKET',
    defaultValue: 'menu-images',
  );

  static bool get supabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
