# MPOS Knowledge Base

This knowledge base explains how the MPOS Flutter app is organized, how it boots, how users move through authentication and shells, and where integrations and runtime configuration live.

## App At A Glance
- Product: mobile point-of-sale app for owners, managers, cashiers, and waiters.
- Stack: Flutter, `flutter_bloc`, `get_it`, `go_router`, `shared_preferences`, `http`, `supabase_flutter`.
- Platforms wired in repo: Android, iOS, web, Windows, macOS, and Linux.

## Repository Map
- `lib/app`: app composition, router, navigator keys, shell scaffolding.
- `lib/core`: config, networking, storage, locale, theme, device, media, and shared utilities.
- `lib/features`: feature-first modules such as auth, onboarding, POS, admin, account, and splash.
- `lib/shared`: reusable UI widgets and helpers.
- `assets`: shared static assets.
- `android`, `ios`, `web`, `windows`, `macos`, `linux`: platform runners and native wrappers.

## Recommended Reading Order
1. [`shared-system-overview.md`](shared-system-overview.md) for the cross-repo system map (API, web, mobile).
2. [`architecture.md`](architecture.md) for the high-level structure and dependency graph.
3. [`app-flow.md`](app-flow.md) for startup, auth, onboarding, and shell routing.
4. [`features.md`](features.md) for the feature-by-feature map.
5. [`integrations.md`](integrations.md) for APIs, mock mode, media upload, and external service touchpoints.
6. [`configuration.md`](configuration.md) for `--dart-define` flags and platform asset generation.

## Important Source Files
- `lib/main.dart`
- `lib/app/mpos_app.dart`
- `lib/app/di/injection.dart`
- `lib/core/config/mpos_config.dart`
- `lib/core/network/mpos_api_client.dart`
- `lib/features/auth/presentation/bloc/auth_bloc.dart`
- `lib/features/auth/domain/entities/auth_session_entity.dart`
- `lib/features/auth/domain/rbac.dart`

## What To Keep In Mind
- Routing is auth-state driven, not deep-link driven first.
- `MposConfig.mockMode` changes the app meaningfully by swapping the full data layer and media service.
- The admin and POS experiences are separate tab shells selected from the current session role.
- Some areas are clearly demo-friendly placeholders in mock mode, especially admin data and media upload.
