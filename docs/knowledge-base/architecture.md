# Architecture

The app follows a feature-first Flutter structure with lightweight clean-architecture layering inside major features.

## Main Building Blocks
- `lib/app`: startup composition, global providers, route table, and shell layout.
- `lib/core`: cross-cutting infrastructure such as configuration, networking, persistence, theme, locale, media, and device helpers.
- `lib/features`: business modules split into `data`, `domain`, and `presentation`.
- `lib/shared`: reusable widgets used by multiple features.

## Layering Pattern
Most larger features use the same shape:
- `data`: datasource interfaces, fake/remote implementations, mappers, repository implementations.
- `domain`: entities, repository contracts, use cases, and RBAC helpers.
- `presentation`: screens, blocs/cubits, and UI helpers.

This is visible in `auth`, `admin`, `onboarding`, and `pos`.

## App Composition
`lib/main.dart` performs bootstrapping and hands control to `MposApp`.

`lib/app/di/injection.dart` is the composition root:
- registers `SharedPreferences` and `SessionStorage`
- chooses mock or remote datasources from `MposConfig.mockMode`
- registers repositories and use cases
- registers global state objects such as `ThemeCubit`, `LocaleCubit`, `AuthBloc`, and `PosBloc`

Dependency injection is handled through `get_it`, which keeps creation logic centralized instead of scattering service construction through widgets.

## State Management
The app uses `flutter_bloc`.

Global state objects created near app startup:
- `ThemeCubit`
- `LocaleCubit`
- `AuthBloc`
- `PosBloc`

Patterns used in practice:
- `AuthBloc` decides whether the user is unauthenticated, needs onboarding, or is ready for a shell.
- `PosBloc` drives POS cart/order behavior and can trigger navigation side effects through shell listeners.
- smaller screens may create local cubits, such as the admin dashboard state for setup progress and KPIs.

## Routing Model
Routing is centralized in `lib/app/mpos_app.dart` using `go_router`.

There are three route groups:
- unauthenticated routes: `/splash`, `/landing`, `/phone-login`, `/shift-login`
- onboarding route: `/onboarding`
- shell routes:
  - POS shell rooted around `/home`, `/menu`, `/orders`, `/account`
  - admin shell rooted around `/admin/dashboard`, `/admin/menu`, `/admin/orders`, `/admin/staff`, `/admin/more`

The app uses `StatefulShellRoute.indexedStack` so tab state can survive tab switches.

## Role-Based Shell Split
`AuthSessionEntity` holds the active organization and branch context plus the current org role and branch role.

`lib/features/auth/domain/rbac.dart` defines higher-level checks such as:
- `canManageOrganization`
- `canManageBranchResources`
- `canManageStaff`
- `canViewOrdersHistory`
- `usesAdminShell`

Role outcome:
- owners, org admins, and branch managers enter the admin shell
- cashiers and waiters enter the POS shell
- users without an organization membership enter onboarding

## Persistence
`SessionStorage` persists the serialized auth session in `SharedPreferences`.

Other persisted settings include:
- selected theme
- selected locale
- generated device id

## Integration Boundary
The app talks to backend APIs through `MposApiClient` and feature-specific remote datasources.

Notable boundary decisions:
- mock mode swaps the full data layer to in-memory fakes
- menu image upload bypasses the MPOS API and goes directly to Supabase Storage
- only image public URLs are saved into item payloads
