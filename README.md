# MPOS Mobile

Flutter floor POS: shift QR login, menu sync, cash / Chapa / Telebirr checkout.

## Run (live API)

Start [mpos-api](https://github.com/brightsystems/mpos-api) first, then:

```bash
# Desktop / iOS simulator
flutter run --dart-define=MPOS_API_URL=http://localhost:5150

# Android emulator
flutter run --dart-define=MPOS_API_URL=http://10.0.2.2:5150

# Physical phone (same Wi‑Fi as API host)
flutter run --dart-define=MPOS_API_URL=http://192.168.x.x:5150
```

Optional mock (no API): `flutter run --dart-define=MPOS_MOCK_MODE=true`

Without `MPOS_API_URL` the app uses the hosted API (`https://posapi.kefta-ticket.com`).
Plain `http://` URLs only work in **debug** builds; release and profile builds are HTTPS-only
(`android/app/src/main/res/xml/network_security_config.xml`).

## Release builds

Release builds are signed with the upload key, never the debug key. The keystore and its
passwords stay out of git (`key.properties`, `*.jks` and `*.keystore` are ignored).

1. Create the upload keystore once and keep it (and its passwords) in the team's secret store:

   ```bash
   keytool -genkeypair -v -keystore ~/mpos-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:

   ```properties
   storeFile=C:/path/to/mpos-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

3. Build (obfuscated, debug symbols kept outside the app for crash decoding):

   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
   ```

Without `android/key.properties` a release build stops with "Release signing is not configured".
Losing the upload key means asking Google Play for an upload key reset, so back it up.

## Documentation

| Doc | What it covers |
|-----|----------------|
| [Shared system overview](./docs/knowledge-base/shared-system-overview.md) | Cross-repo map: how API, web, and mobile fit together |
| [Mobile knowledge base](./docs/knowledge-base/README.md) | App structure, auth/shells, features, integrations, config |

## Related repos

| Repo | Role |
|------|------|
| [mpos-api](https://github.com/brightsystems/mpos-api) | Backend |
| [mpos-web](https://github.com/brightsystems/mpos-web) | Admin (shift QR, menu) |
| [mpos-mobile](https://github.com/brightsystems/mpos-mobile) | This app |
