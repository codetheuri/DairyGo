# Staff Management

A Sacco's staff are user accounts with one of three roles: `1` Sacco
Administrator, `2` Milk Collector, `3` Board Member / Executive.

| Action | Sacco administrator (app) | Platform operator (console) |
| :--- | :--- | :--- |
| List staff | `GET /api/v1/auth/users` (`users.read`) | `GET /api/v1/admin/saccos/{id}/users` |
| Add staff | `POST /api/v1/auth/register` (`users.create`) | `POST /api/v1/admin/saccos/{id}/users` |
| Change role | `PUT /api/v1/auth/users/{user_id}/role` (`users.update`) | `PUT /api/v1/admin/users/{id}/role` |
| Remove | `DELETE /api/v1/auth/users/{user_id}` (`users.delete`) | `DELETE /api/v1/admin/users/{id}` |

Role change takes `{"role_id": 1|2|3, "reason": "optional"}`; removal takes an
optional `?reason=`. The console endpoints run the same service
(`auth.Service.ChangeStaffRole` / `RemoveStaff`) in the chosen Sacco's context,
so the rules below are the same for both.

## Rules (`internal/auth/staff_rules.go`)

- **Own Sacco only.** The Sacco comes from the caller's session, never from the
  request. Another Sacco's user, a platform account or a removed account is
  `404`.
- **Not your own account** (`403`). Another administrator changes it, so nobody
  locks themselves out by mistake.
- **A Sacco keeps an administrator** (`400`). Its only active administrator
  cannot be demoted or removed; make someone else an administrator first.
- Only roles 1, 2 and 3 can be assigned. `users.update` and `users.delete` are
  granted to role 1 only. Do not grant Sacco roles `roles.*` or
  `users.roles.manage`: those endpoints are not limited to one Sacco.

## Changing a role

The new role replaces the old one (one role per staff member). It applies to
the user's **next request**: permissions are read from the database, and the
middleware also reads the role name from the database instead of the token.
The app asks for the profile again when it is opened or brought back to the
foreground, and then shows the new role's menus.

## Removing a staff member

Removal is a soft delete (`users.deleted_at`, `deleted_by_id`; migration
`00016`):

- They are signed out at once (every request checks the account; refresh
  tokens are revoked) and cannot sign in.
- They leave staff lists, the transfer recipients list and staff counts.
- **Their records stay**: collections, sales, transfers and audit entries keep
  their name, and reports still show them for past periods.
- Their username, email and phone can be used for a new account: uniqueness
  applies only to accounts that still exist (partial unique indexes).
- It cannot be undone. To let the person back in, add a new account.

To stop someone signing in for a while without removing them, the platform
console's **Deactivate** is the reversible option.

## Audit

Both actions are written to `audit_logs` (`entity_type = user`) in the same
transaction: role changes as `UPDATE` with the old and new role, removals as
`DELETE`, each with the actor and the optional reason. They appear in the
console under **Audit trail** and the Sacco's **Activity** tab.
