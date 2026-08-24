# Configuration

This page collects the main runtime switches and setup assumptions visible in the codebase.

## Dart Defines
`lib/core/config/mpos_config.dart` reads the following values:

- `MPOS_MOCK_MODE`
  - when `true`, the app uses in-memory fake datasources and fake media upload
- `MPOS_API_URL`
  - backend base URL
- `MPOS_APP_ID`
  - app identifier header sent to the backend
- `MPOS_APP_SECRET`
  - app secret header sent to the backend
- `MPOS_SUPABASE_URL`
  - Supabase project URL for storage uploads
- `MPOS_SUPABASE_ANON_KEY`
  - Supabase anon key
- `MPOS_SUPABASE_MENU_BUCKET`
  - storage bucket name for menu images

Other config details:
- API prefix is fixed as `/api/v1`
- the default API URL points to `http://192.168.1.4:5150`
- Supabase is treated as optional until the URL and anon key are both present

## Mock Mode
Mock mode is intended for local UI and flow work without a backend.

Effects:
- no real API dependency for auth, onboarding, admin, menu, orders, or invoices
- media uploads return demo URLs
- session and role behavior are simulated

Use this mode when:
- backend APIs are unavailable
- working on presentation logic
- testing role-specific UI quickly

Do not use this mode to validate:
- real API contracts
- token refresh behavior against a server
- real integration credentials

## Session And Local Persistence
The app stores local state with `SharedPreferences`.

Persisted examples:
- auth session
- selected locale
- selected theme
- generated device id

## Supabase Initialization
`lib/main.dart` only initializes Supabase when both conditions are true:
- `MPOS_MOCK_MODE` is false
- Supabase URL and anon key are configured

If those settings are missing, the rest of the app can still run, but real menu image upload will not.

## Platform Asset Generation
`pubspec.yaml` shows that launcher icons and native splash assets are generated from `assets/images/app_icon.png`.

Configured tools:
- `flutter_launcher_icons`
- `flutter_native_splash`

Commands noted in the file:
- `dart run flutter_launcher_icons`
- `dart run flutter_native_splash:create`

The repo currently contains generated asset changes across Android, iOS, web, Windows, and macOS, which suggests branding assets are part of the normal workflow.

## Practical Contributor Notes
- Remote mode assumes the device can reach the backend base URL.
- If the app cannot contact the backend, `MposApiClient` returns user-facing connectivity messages that point back to the configured base URL.
- If authenticated requests receive `401`, the client attempts one refresh before failing the request path.
