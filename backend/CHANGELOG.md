# Changelog

All notable changes to the **Tusk** framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
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
