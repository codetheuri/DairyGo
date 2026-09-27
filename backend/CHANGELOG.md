# Changelog

All notable changes to the **Tusk** framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
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

### Changed
- **Prices follow their effective date.** A collection is priced at the latest price effective on or before its date, so backdated collections get the correct historical rate and future-dated prices start automatically. Setting a price no longer deactivates older ones (migration `00009` reactivates existing rows).
- **Collections require an ACTIVE farmer from the caller's Sacco.**
- **Collection edit rules.** Collectors edit only their own `SUBMITTED` records on the day they were recorded; admins edit `SUBMITTED`/`ADJUSTED` records with a reason, and their edits mark the record `ADJUSTED`. `VERIFIED`/`REJECTED` records are locked (`409`) until reopened as `ADJUSTED`. Status changes follow a defined flow and `REJECTED`/`ADJUSTED` need a reason; the status reason no longer overwrites the collection's notes.

### Security
- **Sacco admins no longer act as platform super users.** The admin created during Sacco onboarding was flagged `is_super_user`, letting any Sacco admin list, edit, suspend and create Saccos across the platform. Onboarded admins are now role `1` (Sacco Administrator), and the auth middleware ignores `is_super_user` on any account with a `sacco_id`.
- **Staff registration is locked to the caller's Sacco.** `POST /api/v1/auth/register` previously trusted `sacco_id` from the request body, allowing accounts to be created inside another Sacco. Non-platform callers now always register into their own Sacco, with role `1`, `2` or `3` only.
- **Collectors can only view their own reconciliation.**
- Migration `00008` converts existing Sacco-bound super users to role `1` and grants Sacco roles the permissions they previously reached only through the super-user bypass (verify collections, edit farmers, reconciliation, SMS, settings).

### Removed
- **Scaffolding Tool (`cmd/genmodule`)**: Removed obsolete CLI code generator in favor of explicit, clean module composition.
- **Deployment Workflow (`deploy.yml`)**: Removed unused VPS SSH deployment GitHub action.
