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
