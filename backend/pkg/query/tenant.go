package query

import (
	"context"

	"github.com/codetheuri/tusk/internal/middleware"
	"gorm.io/gorm"
)

// TenantScope returns a GORM scope function that automatically enforces tenant isolation
// via `sacco_id = ?` unless the authenticated request is executing under a Platform Super User context.
func TenantScope(ctx context.Context) func(db *gorm.DB) *gorm.DB {
	return func(db *gorm.DB) *gorm.DB {
		if ctx == nil {
			return db
		}

		if middleware.IsSuperUser(ctx) {
			// Platform Super Users have cross-tenant capability,
			// but if a specific sacco_id is attached to context, filter by it.
			if saccoID, ok := middleware.GetSaccoID(ctx); ok && saccoID != "" {
				return db.Where("sacco_id = ?", saccoID)
			}
			return db
		}

		if saccoID, ok := middleware.GetSaccoID(ctx); ok && saccoID != "" {
			return db.Where("sacco_id = ?", saccoID)
		}

		// Failsafe: Non-super user without a sacco_id in context receives zero records.
		return db.Where("1 = 0")
	}
}
