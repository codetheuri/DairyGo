# Platform Console

A web console for the people who run DairyGo (platform operators), served by the
API itself at **`/platform`** (e.g. `https://apis.dairy.urizon.co.ke/platform`).
It is plain HTML/CSS/JS embedded in the Go binary (`web/platform`), so there is
nothing extra to build or host.

## Who can sign in

Only **platform super users**: `is_super_user = true` and no `sacco_id`. Sacco
staff who try are told to use the mobile app, and every console endpoint also
requires the `platform.manage` permission, which no Sacco role has. To check who
has access:

```sql
SELECT id, username FROM users WHERE is_super_user = true AND sacco_id IS NULL;
```

## What it does

| Page | Actions |
| :--- | :--- |
| **Overview** | Saccos by status, active farmers, staff, milk today/this month, sales, owed to farmers, what customers owe, failed requests and server errors in the last 24h; one row per Sacco |
| **Saccos** | Search, onboard a Sacco with its first admin |
| **Sacco → Staff** | Add staff (roles 1/2/3), change role, deactivate/reactivate, unlock after failed logins, reset password, remove (see [staff-management.md](staff-management.md)) |
| **Roles & permissions** | What each Sacco role may do, as tick boxes; applies at once in every Sacco and is audited (see [authorization.md](authorization.md)) |
| **Sacco → Farmers** | Search farmers, register a farmer on the Sacco's behalf (same rules as the Sacco admin) |
| **Sacco → Late entries** | Enter a forgotten milk intake, sale, spoilage or transfer for an earlier day, with a reason, for the collector it belongs to; list of everything entered late (Sacco staff record only today; see [collections-and-pricing.md](collections-and-pricing.md)) |
| **Sacco → Activity / Errors** | That Sacco's audit trail and failed requests |
| **Sacco actions** | Edit details, suspend, deactivate, reactivate (with a reason, kept in the audit trail) |
| **Audit trail** | Every create, edit, status change and void across all Saccos, with before/after values |
| **Errors** | Every API request that failed (status ≥ 400), with user, Sacco, message and timing |
| **SMS logs** | Messages sent by all Saccos, with delivery status |

API: `/api/v1/admin/overview`, `/admin/saccos/{id}/users`, `/admin/saccos/{id}/members`,
`/admin/users/{id}/status|unlock|reset-password|role`, `DELETE /admin/users/{id}`, `/admin/audit-logs`,
`/admin/error-logs`, `/admin/sms-logs`, plus the existing `/admin/saccos` endpoints.
See `/docs` under **Platform Console**.

## Account enforcement

- **Suspending or deactivating a Sacco** signs out all of its staff at once. Every
  request checks the Sacco's status, and login and token refresh refuse them
  with "your Sacco account is suspended". Their data is untouched.
- **Deactivating a user** takes effect at once for the same reason; their refresh
  tokens are revoked.
- **Resetting a password** also clears any lockout and ends existing sessions.
- Platform accounts cannot be changed from the console.

## Error log

`middleware.RecordFailures` stores every `/api/...` request that ends with status
400 or above in `system_logs`: method, path, query, status, the error message
returned, request ID, user and Sacco (from the token), duration, IP and client.
**Request bodies are never stored**, so passwords cannot leak into logs. Saving
happens in the background and never slows the response. Entries older than 30
days are deleted daily.

- `ERROR` (5xx) means something broke on the server and needs attention.
- `WARN` (4xx) shows what users struggled with: validation errors, locked
  records, failed logins.

## Security notes

- The console is served with a strict Content-Security-Policy (own scripts,
  styles and API only; no inline code; no framing).
- All data is rendered with `textContent`, never `innerHTML`, so names typed by
  users cannot inject markup.
- The session token lives in `sessionStorage` and ends when the tab closes.
