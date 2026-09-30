# Changelog

All notable changes to the **Tusk** framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **Farmer status rules** (migration `00018`):
  - suspended farmers cannot supply milk (`409`);
  - inactive farmers can, and become active when they do;
  - active farmers with no milk for the Sacco's period become inactive automatically (daily). The period is `sacco_settings.inactive_after_days`: 60 by default, 0 = never, and changeable in the app, the console (`PUT /api/v1/admin/saccos/{id}/settings`) or the API.
  - Status changes (`PATCH /sacco/members/{id}/status`, now with `reason`, required to suspend) are recorded in the farmer's history, and the console can change a farmer's status.
  - `GET /sacco/members?can_supply=true` lists farmers whose milk may be taken.

  See [docs/farmer-status.md](docs/farmer-status.md).

### Changed
- Collection errors no longer start with `locked: `, `forbidden: ` or `not found: `; the message is a plain sentence for the user.
- The console shows a rule the server refused as a plain sentence ("Give a reason for suspending the farmer").
- **Import a Sacco's farmer register** (`dairy-cli members import`): loads farmers from CSV, checking the whole file first; `--replace` (with `--confirm <code>`) first clears that Sacco's test farmers, milk records, customers and their history, keeping staff, settings and prices; `--dry-run` reports without changing anything; all in one transaction. See [docs/importing-farmers.md](docs/importing-farmers.md).

### Changed
- **Farmers registered without a membership number continue the Sacco's own numbering** (after `150` comes `151`, at least three digits) instead of `MEM-0001`, and a number is never given out twice, even after farmers are removed.

### Added
- **App updates with one tap** (mobile): on Wi-Fi a new version downloads by itself and the app offers **Restart**; the install uses Android's `PackageInstaller`, so on Android 12+ updates after the first install without Android's "Update?" question, and the app asks to reopen after updating. On mobile data the user still starts the download. See `mobile/docs/releases.md`.
- **Edit a farmer's details and see who changed them**: `PUT /sacco/members/{id}` validates names, phone and M-Pesa number, clears an optional field sent empty, and records every change (old and new values) in the audit trail; `GET /sacco/members/{id}/history` lists them. Payout details decide where money goes, so their changes are always traceable.
- `TestAllRoutesRegister` registers every module's routes in a test, so a start-up panic (e.g. two response types with the same schema name) is caught before deploy.

### Fixed
- **The Docker image built each command from its `main.go` only**, so a command split over several files (the CLI's `members import`) failed to build. It now builds each command's package.
- **`ship.sh` reported "Shipped" when the server's build failed**: the old container kept running and passed the health check. It now stops with the build's error.
- **In-app updates were never offered** by apps 1.4.0 and 1.4.1: they compared Android's `versionCode` (build + 2000 on arm64) with the published build. `GET /api/v1/app/version` now answers apps that send no `scheme` in that scale; fixed apps send `scheme=2`.

### Added
- **Next of kin for farmers** (migration `00017`): name, relationship and phone are required when registering a farmer (`POST /sacco/members`, and the console). Farmers registered earlier have none until edited; editing any of the three must leave all three complete.
- **Role permissions are data**: the console has a **Roles & permissions** page; changes apply on the next request, in every Sacco, and are audited. Login, refresh and `/auth/me` return the user's `permissions` for the app. Platform-only permissions cannot be given to Sacco roles. `GET /auth/permissions` now returns `name`/`description` in lower case.
- **`milk.records.read_all`** replaces the check on the role's name for who sees every collector's records (granted to administrators and board members by migration `00017`).
- **Permissions sync at start-up** (with `AUTO_MIGRATE=true`): permissions added in code appear in the database without running `auth sync` by hand.
- **Migrations on start-up**: with `AUTO_MIGRATE=true` (set in `docker-compose.yml`) the API applies pending migrations before it serves, and refuses to start if one fails. A deploy is now `git pull` and `docker compose up -d --build dairy-api`. See [docs/deployment.md](docs/deployment.md).
- **Change a staff member's role and remove staff** (migration `00016`): `PUT /api/v1/auth/users/{user_id}/role` and `DELETE /api/v1/auth/users/{user_id}` for Sacco administrators (own Sacco only), and `PUT /api/v1/admin/users/{id}/role`, `DELETE /api/v1/admin/users/{id}` plus buttons in the platform console. You cannot change your own account, and a Sacco's only administrator cannot be demoted or removed. Removal is a soft delete: the person is signed out at once, their records keep their name, and their username, email and phone can be reused. Both are audited. See [docs/staff-management.md](docs/staff-management.md).
- The role used for "sees everyone's records" checks is read from the database on every request instead of the token, so a role change applies immediately.
- **Milk transfers between collectors** (`/api/v1/sacco/milk-transfers`, migration `00015`): a collector hands milk to another; it counts at once for both (`collected + received − sold − transferred out − spoiled = unaccounted`). Same-day correction or cancellation by the sender, any time by admins with a reason, full history. Reconciliation, collector audit, ledger and dashboards include the figures. See [docs/milk-transfers.md](docs/milk-transfers.md).
- **App releases (`internal/appupdate`)**: `GET /api/v1/app/version` for the in-app updater (with `min_build` to force an update), resumable APK downloads at `/app/download/{arm64,armv7}` served as Android packages, and a download page at `/app` to share instead of APK files. Releases are read from `APP_RELEASES_DIR` (`./releases` in Docker). See [docs/app-releases.md](docs/app-releases.md).
- Response writers in the logger, failure recorder and idempotency middleware implement `Unwrap()`, so `http.ResponseController` works through them.
- **`make env`** (`scripts/init-env.sh`): creates `.env` with a random `JWT_SECRET`, or replaces a missing or weak one; never changes a good secret or prints it. Safe on every deploy.
- The collector audit report returns `tolerance_litres` (per collector per day), so clients can balance each day of a period by the same rule.
- **Safe retries (`internal/idempotency`)**: writes with an `Idempotency-Key` header run once per user and key; retries get the stored response (`Idempotent-Replayed: true`), so a lost response on a slow connection or a double tap never records a sale, payment or collection twice. Migration `00014`. See [docs/sessions-and-idempotency.md](docs/sessions-and-idempotency.md).
- **Sessions that follow activity**: access tokens last `ACCESS_TOKEN_TTL` (default 1h) and are refreshed silently; each refresh extends the session by `SESSION_IDLE_TIMEOUT` (default 720h), so users are signed out only after 30 days without using the app. Login and refresh return `access_expires_at` and `session_expires_at`.
- **Refresh token rotation with a 2-minute grace period and reuse detection**: a lost refresh response no longer signs the user out; reuse of an old token after the grace period revokes every session of that user.
- **Daily cleanup** of idempotency keys (48h) and ended sessions (7 days).

### Security
- The API refuses to start with an empty `JWT_SECRET`, the public example value from `docker-compose.yml`, or (in production) a secret shorter than 32 characters. `docker-compose.yml` now requires `JWT_SECRET` to be set.
- **Compressed responses**: JSON and console assets are gzip-compressed (`chi` `Compress`, outside `RecordFailures`); API responses shrink by about 85%, which matters on the slow connections collectors use.
- **Collections carry farmer names**: list rows include `member_name` and `membership_number`, so the app no longer downloads the farmer directory to label them.
- **Search collections by farmer**: `search` on `/sacco/milk-collections` matches the farmer's name and membership number, not only notes.
- **Full-name farmer search**: `search` on `/sacco/members` also matches "first last", so "John Kamau" finds him.
- **Platform console** at `/platform` (`internal/superadmin`, `web/platform`): overview across all Saccos, onboarding, suspend/reactivate, Sacco staff management (add, deactivate, unlock, reset password), registering farmers for a Sacco, and cross-Sacco audit trail, error log and SMS logs. See [docs/platform-console.md](docs/platform-console.md).
- **Error log**: every failed API request (status ≥ 400) is stored in `system_logs` without request bodies, kept 30 days (migration `00013`).
- **Sacco onboarding and status changes are audited**, with an optional reason.
- **Code-First RBAC Engine (`pkg/authz`)**: Multi-tenant-ready Role-Based Access Control system with permission constants, global registry, and runtime GORM DB synchronization.
- **Huma v2 Integration**: Strongly-typed HTTP API framework built on Chi with automated OpenAPI 3.0 specification (`/openapi.json`) and interactive documentation UI (`/docs`).
- **Permission Sync CLI (`tusk auth sync`)**: CLI tool with `--prune` option to sync code-declared permissions directly to runtime database tables.
- **Unified Querying Engine (`pkg/query`)**: Standardized query struct for pagination, field sorting, keyword searching, and response metadata (`query.Meta`).
- **Standardized API Envelope (`pkg/response`)**: Uniform JSON envelope structure (`success`, `message`, `data`, `errors`) across all endpoints.
- **Technical Documentation Suite (`docs/`)**: Comprehensive technical guides covering Architecture, Routing, Authorization, Database Migrations, Querying, and API Responses.
- **Contribution Guidelines (`CONTRIBUTING.md`)**: Architectural conventions and contribution rules for extending Tusk.

### Changed
- **Router Tagging & Schema Refinement**: Standardized Huma API operation tags and route descriptions across authentication and authorization endpoints.
- **Updated CI Pipelines**: Refreshed `.github/workflows/go.yml` to support Go 1.24.x and updated action versions.

### Added
- **Collection audit history**: every create, edit and status change of a milk collection is stored in the new generic `audit_logs` table (`pkg/audit`) in the same transaction, with actor, reason and before/after values. `GET /api/v1/sacco/milk-collections/{id}/history` returns it. See [docs/collections-and-pricing.md](docs/collections-and-pricing.md).

- **Customers & customer ledger** (`internal/customer`): coolers, processors, hotels, shops and individuals are customers; collectors add them on the spot while selling. Admins record and void customer payments; admins and board members see statements (running balance) and who owes what. See [docs/customers-and-ledger.md](docs/customers-and-ledger.md). Migrations `00010` (tables, backfill of existing sales) and `00011` (permissions).
- **Sale corrections and voids**: `PUT /milk-sales/{id}` (same edit rules as collections), `POST /milk-sales/{id}/void` (admin, reason required), `GET /milk-sales/{id}/history`.

- **Real milk reconciliation** (`pkg/reconcile`): `unaccounted = collected − sold − spoiled`, flagged `BALANCED`, `MISSING` or `OVERSOLD` within a per-Sacco tolerance (`reconciliation_tolerance_litres`, migration `00012`). Reports and dashboards add sales by customer type, cash vs credit, gross margin and receivables. See [docs/reconciliation-and-dashboards.md](docs/reconciliation-and-dashboards.md).

### Changed
- **Breaking: reconciliation fields.** `net_delivered_litres`, `net_coolant_station_litres`, `today_net_coolant_station_litres`, `net_coolant_litres`, `today_net_station_delivery_litres` and `discrepancy_litres` are replaced by `unaccounted_litres`, `balance_status`, `is_balanced` and `allowance_litres`. Ledger fields `total_field_sales_*` are renamed to `total_sold_litres` and `total_sales_revenue_kes`.
- **Dashboards and reports no longer run N+1 queries.** The executive dashboard runs 7 queries for any trend length (it was about 90 for 30 days); the collector audit runs 3 regardless of collector count. Date filters no longer wrap indexed columns in `DATE()`.
- **Breaking: sales belong to a customer.** `POST /milk-sales` takes `customer_id`, optional `unit_price` (defaults to the customer's agreed price) and `amount_paid`; `buyer_name`, `buyer_phone` and `payment_status` are no longer accepted, and `payment_status` is derived (`PAID`, `PARTIAL`, `CREDIT`). Ship the matching mobile release together with this backend.
- **Voided sales are excluded** from reconciliation, dashboards and reports.
- **List search is case-insensitive** on every database (Postgres `LIKE` was case-sensitive, so farmer and customer search missed differently-cased names).
- **Prices follow their effective date.** A collection is priced at the latest price effective on or before its date, so backdated collections get the correct historical rate and future-dated prices start automatically. Setting a price no longer deactivates older ones (migration `00009` reactivates existing rows).
- **Collections require an ACTIVE farmer from the caller's Sacco.**
- **Collection edit rules.** Collectors edit only their own `SUBMITTED` records on the day they were recorded; admins edit `SUBMITTED`/`ADJUSTED` records with a reason, and their edits mark the record `ADJUSTED`. `VERIFIED`/`REJECTED` records are locked (`409`) until reopened as `ADJUSTED`. Status changes follow a defined flow and `REJECTED`/`ADJUSTED` need a reason; the status reason no longer overwrites the collection's notes.

### Security
- **Suspended Saccos and deactivated users are locked out immediately.** Previously their access tokens kept working until expiry and suspension did not block login at all. Every request now checks the user is active and their Sacco is `ACTIVE`, and login and token refresh refuse them.
- **Sacco admins no longer act as platform super users.** The admin created during Sacco onboarding was flagged `is_super_user`, letting any Sacco admin list, edit, suspend and create Saccos across the platform. Onboarded admins are now role `1` (Sacco Administrator), and the auth middleware ignores `is_super_user` on any account with a `sacco_id`.
- **Staff registration is locked to the caller's Sacco.** `POST /api/v1/auth/register` previously trusted `sacco_id` from the request body, allowing accounts to be created inside another Sacco. Non-platform callers now always register into their own Sacco, with role `1`, `2` or `3` only.
- **Collectors can only view their own reconciliation.**
- Migration `00008` converts existing Sacco-bound super users to role `1` and grants Sacco roles the permissions they previously reached only through the super-user bypass (verify collections, edit farmers, reconciliation, SMS, settings).

### Removed
- **Scaffolding Tool (`cmd/genmodule`)**: Removed obsolete CLI code generator in favor of explicit, clean module composition.
- **Deployment Workflow (`deploy.yml`)**: Removed unused VPS SSH deployment GitHub action.
