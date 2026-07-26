# Multi-Tenant Architecture & Isolation Guide

The Dairy Cooperative Platform uses a **Shared Database / Shared Schema** multi-tenant model.

---

## Key Principles

1. **Tenant Identifier**:
   - Every business resource belongs to exactly one Sacco tenant and has a `sacco_id` UUID column.
2. **Platform Super Users**:
   - Platform Super Users have a `NULL` `sacco_id` in the `users` table and possess cross-tenant capabilities.
3. **Tenant Sacco Users**:
   - All Sacco Administrators, Collectors, and Board Members have a non-null `sacco_id` foreign key referencing `saccos(id)`.
4. **Context Injection**:
   - `sacco_id` is automatically parsed from verified JWT claims in `internal/middleware/jwt.go` and injected into `context.Context`.
   - Clients CANNOT manually specify or override another tenant's `sacco_id` via HTTP headers or body payload parameters.

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
