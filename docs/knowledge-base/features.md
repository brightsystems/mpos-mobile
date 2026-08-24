# Features

This page maps the main feature areas and what each one owns.

## Auth
Path: `lib/features/auth`

Responsibilities:
- restore and persist sessions
- phone OTP login
- shift QR login
- session role classification
- logout

Important parts:
- `presentation/bloc/auth_bloc.dart`: main auth state machine
- `presentation/screens/landing_screen.dart`: entry options
- `presentation/screens/phone_login_screen.dart`: phone OTP flow
- `presentation/screens/shift_qr_scan_screen.dart`: shift QR flow
- `domain/entities/auth_session_entity.dart`: active session and membership context
- `domain/rbac.dart`: capability checks and shell selection
- `data/datasources/fake` and `data/datasources/remote`: fake vs API-backed auth

## Onboarding
Path: `lib/features/onboarding`

Responsibilities:
- create the first business and branch for users who have no organization membership

Important parts:
- `presentation/screens/onboarding_screen.dart`: business setup form
- `data/datasources/remote/onboarding_remote_datasource.dart`: calls `/onboarding/business`
- fake datasource returns a demo session that moves the user into the admin shell after setup

## POS
Path: `lib/features/pos`

Responsibilities:
- branch menu sync
- open orders and ticket lifecycle
- cart line quantity updates
- table assignment
- settlement and invoice polling

Important parts:
- `presentation/bloc/pos_bloc.dart`: core POS workflow state
- `domain/usecases/menu_usecases.dart`: menu sync
- `domain/usecases/order_usecases.dart`: ticket and order operations
- `domain/usecases/invoice_usecases.dart`: invoice submission and polling
- remote and fake datasources for menu, order, and invoice flows

## Menu Browse
Path: `lib/features/menu`

Responsibilities:
- read-only menu browsing experience used inside the POS shell

This is separate from admin menu management. The POS user browses menu data; admin users configure it elsewhere.

## Orders
Path: `lib/features/orders`

Responsibilities:
- present order and table state for the POS side

This complements `PosBloc` rather than replacing it.

## Admin
Path: `lib/features/admin`

Responsibilities:
- organization setup and maintenance
- branch setup
- taxes
- payment gateway settings
- MOR settings
- bank settlement info
- staff assignment and shift QR generation
- menu/category/item management
- order history and summaries

Main screens:
- `presentation/dashboard/admin_dashboard_screen.dart`
- `presentation/menu/menu_management_screen.dart`
- `presentation/orders/orders_history_screen.dart`
- `presentation/staff/staff_screen.dart`
- `presentation/shell/admin_more_screen.dart`
- `presentation/organization/organization_screen.dart`
- `presentation/branches/branches_screen.dart`
- `presentation/taxes/taxes_screen.dart`
- `presentation/payments/payment_gateways_screen.dart`
- `presentation/mor/mor_settings_screen.dart`
- `presentation/bank/bank_account_screen.dart`

The admin feature is broad and is currently organized around a single `AdminRepository` contract.

## Account
Path: `lib/features/account`

Responsibilities:
- expose account/session-facing UI inside the POS shell
- provide a dashboard/account surface tied to the current user context

## Splash
Path: `lib/features/splash`

Responsibilities:
- show the initial branded loading state while auth is being resolved

## Shared And Core
- `lib/shared`: common widgets like buttons, snack bars, fields, and selectors
- `lib/core`: technical foundations used across all features

## Cross-Cutting Data Patterns
Several modules follow the same pattern:
- datasource interface
- fake implementation for offline/demo mode
- remote implementation for API mode
- repository implementation that wraps results/errors
- presentation layer consuming repositories or use cases

This pattern is most visible in:
- auth
- onboarding
- POS
- admin
