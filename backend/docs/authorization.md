# Code-First RBAC Authorization

Tusk features a **code-first, registry-driven Role-Based Access Control (RBAC)** package (`pkg/authz`).

---

## Architectural Concept

1. **Code-Declared Permissions**: Permissions are defined as immutable code constants inside domain modules.
2. **Global Permission Registry**: Modules register permissions during package initialization (`init()`).
3. **Database Synchronization**: A CLI tool (`tusk auth sync`) syncs code-declared permissions into the database `permissions` table cleanly and idempotently.
4. **Role & Permission Management**: Administrators assign permissions to roles, and roles to users, via API endpoints.
5. **Route Guard Middleware**: HTTP routes specify required permission strings to enforce authorization automatically.

---

## 1. Declaring & Registering Permissions

Permissions are defined in domain packages (e.g. `internal/auth/permissions.go`):

```go
package auth

import "github.com/codetheuri/tusk/pkg/authz"

const (
    PermUsersRead   = "users.read"
    PermUsersCreate = "users.create"
    PermRolesRead   = "roles.read"
    PermRolesCreate = "roles.create"
)

var Permissions = []authz.Permission{
    {
        Name:        PermUsersRead,
        Description: "Allows viewing user accounts and profiles",
    },
    {
        Name:        PermUsersCreate,
        Description: "Allows registering and creating new user accounts",
    },
}

func init() {
    authz.Register(Permissions...)
}
```

---

## 2. Synchronizing Permissions to Database

Permissions registered in code are synchronized to runtime database tables (`permissions`, `roles`, `role_permissions`, `user_roles`) using the Tusk CLI tool.

### Syncing Registered Permissions

```bash
make auth-sync
# OR
go run ./cmd/tusk/main.go auth sync
```

### Syncing and Pruning Obsolete Database Permissions

To automatically delete permissions from the database that no longer exist in code:

```bash
make auth-sync-prune
# OR
go run ./cmd/tusk/main.go auth sync --prune
```

---

## 3. Protecting Routes with Permission Guards

Routes specify required permissions using the `guard.Protected(...)` helper:

```go
huma.Register(api, guard.Protected(huma.Operation{
    OperationID: "auth-list-users",
    Method:      http.MethodGet,
    Path:        "/api/v1/auth/users",
    Summary:     "List users",
    Tags:        []string{"Authentication"},
}, PermUsersRead), handler.ListUsers)
```

If the authenticated user lacks the `users.read` permission (and is not a superuser), the middleware returns `403 Forbidden`.

---

## 4. Superuser Bypass

Platform Super Users automatically bypass all RBAC permission checks, ensuring platform operators always maintain full access.

A user counts as a Platform Super User only when `is_super_user = true` **and** their `sacco_id` is `NULL`. The flag is ignored on Sacco-bound accounts (see `middleware.HumaAuthenticate`), so Sacco Administrators get their access from role `1` like any other staff member. See [Multi-Tenancy](multi-tenancy.md).

### Seeded Sacco Roles

| Role ID | Name | Typical access |
| :--- | :--- | :--- |
| `1` | Sacco Administrator | Pricing, staff, farmers (incl. edit/status), verify collections, reconciliation, reports, settings, SMS |
| `2` | Milk Collector | Record intake, sales and spoilage; register farmers; own dashboard and own reconciliation |
| `3` | Board Member / Executive | Read-only dashboards, reports, reconciliation and settings |

Grants live in migrations `00007` and `00008`. Use the constants `auth.RoleSaccoAdmin`, `auth.RoleCollector` and `auth.RoleExecutive` rather than bare numbers.

---

## 5. Authorization API Endpoints

Tusk provides endpoints to manage security roles and permission assignments:

- `GET /api/v1/auth/permissions`: List all registered system permissions.
- `GET /api/v1/auth/roles`: List all security roles with their attached permissions.
- `POST /api/v1/auth/roles`: Create a new security role.
- `POST /api/v1/auth/roles/{id}/permissions`: Attach a permission to a role.
- `DELETE /api/v1/auth/roles/{id}/permissions/{permission_name}`: Detach a permission from a role.
- `POST /api/v1/auth/users/{user_id}/roles`: Assign a role to a user.
- `DELETE /api/v1/auth/users/{user_id}/roles/{role_id}`: Revoke a role from a user.


---

## DairyGo: what a role may do is data, not code

The three Sacco roles (1 Sacco Administrator, 2 Milk Collector, 3 Board Member /
Executive) are rows in `roles`; what each may do is rows in `role_permissions`.
Neither the API nor the mobile app decides anything from a role's *name*.

**Changing it needs no code and no deploy.** A platform operator uses the
console's **Roles & permissions** page (a tick box per role and permission), or:

```
POST   /api/v1/auth/roles/{id}/permissions        {"permission_name": "reports.collector.read"}
DELETE /api/v1/auth/roles/{id}/permissions/{permission_name}
```

- **The server applies it on the user's next request**: guards read
  `role_permissions` every time.
- **The app follows**: login, refresh and `GET /auth/me` return the user's
  `permissions`, and screens ask `user.can(...)` (see `user_entity.dart`). The
  app re-reads the profile when opened or brought to the front, then shows or
  hides the matching menus and buttons.
- **Every change is audited** (`entity_type = role`).
- Roles are shared by all Saccos, so a change applies to every Sacco.

### Guardrails

- `platform.manage`, `roles.*`, `users.roles.manage` and `permissions.read`
  cannot be given to a Sacco role: those endpoints reach across Saccos.
- Only platform operators can change role permissions; Sacco administrators
  cannot (they have no `roles.permissions.manage`).

### Seeing everyone's records

`milk.records.read_all` decides whether a user sees every collector's
collections, sales, spoilage, transfers and reconciliation, or only their own
(`middleware.SeesAllRecords`). Administrators and board members hold it by
default.

### Adding a permission in code

1. Add the constant and description in the module's `permissions.go`.
2. Guard the route with it.
3. That is enough for it to appear: the API syncs code permissions into the
   database at start-up (with `AUTO_MIGRATE=true`), so it shows in the console.
4. Write a migration **only** if a role should hold it from day one; otherwise
   tick it in the console.
