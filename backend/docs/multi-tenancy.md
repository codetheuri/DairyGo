# Multi-Tenant Architecture & Isolation Guide

The Dairy Cooperative Platform uses a **Shared Database / Shared Schema** multi-tenant model.

---

## Key Principles

1. **Tenant Identifier**:
   - Every business resource belongs to exactly one Sacco tenant and has a `sacco_id` UUID column.
2. **Platform Super Users**:
   - Platform Super Users have `is_super_user = true` **and** a `NULL` `sacco_id` in the `users` table, and possess cross-tenant capabilities (provisioning and managing Saccos).
   - `middleware.HumaAuthenticate` ignores `is_super_user` on any account that has a `sacco_id`. A Sacco-bound account can therefore never act across tenants, even if the flag is set by mistake.
3. **Tenant Sacco Users**:
   - All Sacco Administrators, Collectors, and Board Members have a non-null `sacco_id` foreign key referencing `saccos(id)`.
   - Their access comes only from their role (`1` Sacco Administrator, `2` Milk Collector, `3` Board Member / Executive), never from the super-user bypass.
   - When a Sacco is provisioned (`POST /api/v1/admin/saccos`), its first admin is created as a regular role `1` user.
4. **Context Injection**:
   - `sacco_id` is automatically parsed from verified JWT claims in `internal/middleware/jwt.go` and injected into `context.Context`.
   - Clients CANNOT manually specify or override another tenant's `sacco_id` via HTTP headers or body payload parameters.
   - Staff registration (`POST /api/v1/auth/register`) always places the new user in the caller's own Sacco and accepts only roles `1`, `2` or `3`. Only a Platform Super User may pass `sacco_id` to place a user in a specific Sacco.

---

## Endpoints That Are Not Tenant-Scoped

The `saccos` table has no `sacco_id` column, so the `/api/v1/admin/saccos` endpoints cannot use `TenantScope`. Each of their handlers must check `middleware.IsSuperUser(ctx)` explicitly. Roles and permissions are also global (shared by all Saccos), so never grant `roles.*` or `users.roles.manage` to a Sacco role.

---

## Repository Isolation Scoping (`TenantScope`)

To enforce strict tenant isolation across database queries and prevent data leaks between Saccos, all GORM queries on tenant-owned entities MUST apply `query.TenantScope(ctx)`:

```go
func (r *Repository) ListMembers(ctx context.Context, q query.Query) ([]Member, query.Meta, error) {
    var members []Member
    db := r.db.WithContext(ctx).Model(&Member{}).Scopes(query.TenantScope(ctx))
    
    // ... apply filters, pagination, and query execution ...
    return members, meta, nil
}
```

### How `TenantScope` Operates

- **Platform Super User Context**: Skips mandatory `sacco_id` filtering unless a specific `sacco_id` filter is present in context.
- **Tenant User Context**: Automatically injects `.Where("sacco_id = ?", saccoID)`.
- **Invalid / Missing Context Failsafe**: If a non-super user context lacks a valid `sacco_id`, `TenantScope` injects `.Where("1 = 0")`, forcing 0 records to be returned and preventing data leakage.
