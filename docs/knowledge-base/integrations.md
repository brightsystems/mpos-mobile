# Integrations

This page explains how the app reaches backend services and where it deliberately uses local fakes instead.

## API Client
`lib/core/network/mpos_api_client.dart` is the shared HTTP entrypoint for remote datasources.

Behavior:
- builds URLs from `MposConfig.baseUrl + MposConfig.apiPrefix`
- adds `X-App-Id` and `X-App-Secret` to all requests
- adds `Authorization`, `X-Organization-Id`, and `X-Branch-Id` for authenticated calls
- retries one time on `401` by calling `/auth/refresh`
- clears the saved session if token refresh fails

## Auth Endpoints
Used from `lib/features/auth/data/datasources/remote/auth_remote_datasource.dart`:
- `POST /auth/otp/request`
- `POST /auth/otp/verify`
- `POST /auth/shift/login`
- `POST /auth/refresh`

The remote auth datasource maps backend auth payloads into `AuthSessionEntity`.

## Onboarding Endpoint
Used from `lib/features/onboarding/data/datasources/remote/onboarding_remote_datasource.dart`:
- `POST /onboarding/business`

This endpoint returns auth payload data that is converted into a new session, which lets onboarding immediately hand the user into the admin flow.

## Admin Data Surface
`lib/features/admin/domain/repositories/admin_repository.dart` shows the breadth of the admin integration surface:
- organization profile
- bank account
- taxes
- payment settings
- MOR settings
- branches
- branch and organization members
- shift QR generation
- branch menu and categories
- order history, order summary, and order detail

## Mock Mode
`MposConfig.mockMode` is a major runtime switch, not just a flag for one screen.

When mock mode is on:
- auth uses `FakeAuthDatasource`
- onboarding uses `FakeOnboardingDatasource`
- POS menu/orders/invoices use fake datasources
- admin uses `FakeAdminDatasource`
- media upload uses `FakeMediaService`

This means the app can run in a demo environment with no backend.

## Fake Behavior To Remember
Mock mode tries to preserve flow realism without real infrastructure:
- fake auth maps certain phone numbers to different roles
- fake onboarding returns a session with business membership
- fake admin stores its data in memory for the current app run
- fake media upload returns a demo public image URL instead of storing a file

These are helpful for UI work, but they are not production behavior.

## Media Upload
Menu images are handled by `lib/core/media/media_service.dart`.

Two implementations exist:
- `FakeMediaService`: instant demo URL behavior
- `SupabaseMediaService`: uploads image bytes to Supabase Storage and returns a public URL

Important design choice:
- image bytes do not pass through the MPOS API
- only the final public URL is stored with the menu item payload

`SupabaseMediaService` also enforces:
- image-only content types
- a 5 MB maximum file size
- per-organization object paths in the configured bucket

## External Service Touchpoints
Visible in the current codebase:
- Supabase Storage for menu images
- Telebirr settings in admin
- Chapa toggle/config presence in admin
- MOR e-invoice settings and tax mapping support
- QR flows for shift login
- `SharedPreferences` for session, theme, locale, and device state

## Operational Caveats
- The default API URL targets a local network server, so device and backend must usually share the same network in remote mode.
- Saved config does not always mean verified integration health; some admin settings screens are configuration-oriented rather than test-oriented.
- Because the app can run entirely in mock mode, contributors should always confirm which mode they are testing before drawing conclusions about backend behavior.
