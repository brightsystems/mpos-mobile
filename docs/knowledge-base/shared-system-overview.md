# MPOS Shared Knowledge Base

This document connects the three MPOS repositories so future work can start from the system view before dropping into repo-specific details.

## System Overview

MPOS is split into three apps that work together:

- `mpos-api`: the backend system of record for auth, tenancy, catalog, inventory, orders, payments, and MoR fiscal compliance.
- `mpos-mobile`: the Flutter app used for floor operations and mobile admin tasks, including OTP login, shift QR login, order taking, checkout, and branch-level management.
- `mpos-web`: the Angular admin console used for organization setup, branch management, staff assignment, menu setup, taxes, payout settings, and operational review.

The normal flow is:

1. admins or managers configure the business in `mpos-web` or the admin area of `mpos-mobile`
2. floor staff authenticate in `mpos-mobile`
3. the client app calls `mpos-api` with app credentials, auth tokens, and tenant context
4. orders, payments, invoices, and branch operations are persisted and enforced by `mpos-api`

## Repository Responsibilities

### `mpos-api`

Primary purpose:

- central business logic and persistence
- tenant and branch access control
- OTP and shift-based authentication
- menu, inventory, order, and settlement workflows
- payment provider integration for Chapa and Telebirr
- MoR invoice and receipt submission

Architecture:

- `src/MposApi.Api`: controllers, middleware, host startup
- `src/MposApi.Application`: use-case services and business rules
- `src/MposApi.Domain`: entities and enums
- `src/MposApi.Infrastructure`: EF Core, repositories, integrations, auth plumbing
- `src/MposApi.Contracts`: DTOs and shared API constants

### `mpos-mobile`

Primary purpose:

- mobile POS runtime for cashiers and waiters
- phone OTP login and shift QR login
- branch menu sync, cart, table/ticket workflows, checkout, and invoice viewing
- mobile admin flows for owners, org admins, and branch managers
- offline-friendly and demo-friendly operation through mock mode

Architecture:

- `lib/app`: app composition, DI, routing, shells
- `lib/core`: config, API client, storage, theme, locale, media
- `lib/features`: auth, onboarding, POS, admin, account, splash
- `lib/shared`: shared UI widgets

Start here for repo-specific mobile details:

- `README.md`
- `docs/knowledge-base/README.md`

### `mpos-web`

Primary purpose:

- browser-based admin and back-office experience
- business onboarding and operational setup
- branch, staff, taxes, menu, payment settings, bank account, and MoR settings management
- dashboard and order visibility for admins and managers

Architecture:

- `src/app/core/services`: API and data access layer
- `src/app/pages/mpos`: business/admin pages
- `src/app/layout`: shell and sidebar
- `src/environments`: local config template

## Shared Contracts Between Apps

These concepts show up in all three repos and are the fastest way to align changes:

- tenant model: organization -> branch -> members
- auth model: OTP login, refresh tokens, shift QR login
- role model: owners, org admins, branch managers, cashiers, waiters
- branch context: active organization and branch are carried by headers and/or session state
- catalog model: categories, menu items, taxes, branch overrides, inventory state
- sales model: draft orders, line items, payments, invoices, settlements
- compliance model: payment gateways plus MoR configuration and fiscal submission

## Important Integration Notes

- `mpos-api` is the only source of truth for business records and operational workflows.
- `mpos-mobile` and `mpos-web` both behave like first-party clients and must provide app credentials.
- Supabase is used for menu/media file storage in the client apps, while record ownership remains API-driven.
- Chapa, Telebirr, and MoR integrations are implemented behind `mpos-api`, not directly in the clients.

## Development Mental Model

When a feature changes:

- start in `mpos-api` if the change affects validation, persistence, permissions, payments, or invoices
- start in `mpos-web` if the change is about business setup or desktop admin workflows
- start in `mpos-mobile` if the change is about selling flow, shift login, field usage, or handheld UX

For most product changes, expect impact in more than one repo:

- backend contract or permission change in `mpos-api`
- admin setup or management UI change in `mpos-web`
- runtime selling or mobile admin behavior change in `mpos-mobile`

## Recommended Reading Order

1. this file for the system map
2. `docs/knowledge-base/README.md` for mobile depth
3. `../mpos-api/docs/repo-knowledge-base.md` in the API repo for backend depth
4. `../mpos-web/README.md` plus `docs/menu-images-supabase.md` in the web repo for admin-app specifics
