package auth

import (
	"context"
	"fmt"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/audit"
)

// FindStaff loads a staff account of saccoID that has not been removed.
func (r *Repository) FindStaff(ctx context.Context, saccoID string, userID uint) (*StaffAccount, error) {
	var rows []StaffAccount
	err := r.db.WithContext(ctx).Table("users u").
		Select("u.id, u.sacco_id, u.username, u.is_active, COALESCE(MIN(ro.id), 0) AS role_id, COALESCE(MIN(ro.name), '') AS role_name").
		Joins("LEFT JOIN user_roles ur ON ur.user_id = u.id").
		Joins("LEFT JOIN roles ro ON ro.id = ur.role_id").
		Where("u.id = ? AND u.sacco_id = ? AND u.deleted_at IS NULL", userID, saccoID).
		Group("u.id").
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return nil, fmt.Errorf("%w in this Sacco", ErrStaffNotFound)
	}
	return &rows[0], nil
}

// CountOtherAdmins counts the Sacco's active administrators other than exceptID.
func (r *Repository) CountOtherAdmins(ctx context.Context, saccoID string, exceptID uint) (int64, error) {
	var n int64
	err := r.db.WithContext(ctx).Table("users u").
		Joins("JOIN user_roles ur ON ur.user_id = u.id AND ur.role_id = ?", RoleSaccoAdmin).
		Where("u.sacco_id = ? AND u.id <> ? AND u.is_active = ? AND u.deleted_at IS NULL", saccoID, exceptID, true).
		Count(&n).Error
	return n, err
}

// SetStaffRole makes roleID the user's only role and records entry, in one
// transaction.
func (r *Repository) SetStaffRole(ctx context.Context, userID, roleID uint, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("user_id = ?", userID).Delete(&UserRole{}).Error; err != nil {
			return err
		}
		if err := tx.Create(&UserRole{UserID: userID, RoleID: roleID}).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// RemoveStaff marks the account removed, ends its sessions and records entry,
// in one transaction. The row and its role stay, so history keeps the name.
func (r *Repository) RemoveStaff(ctx context.Context, userID, actorID uint, entry audit.Entry) error {
	now := time.Now()
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		res := tx.Table("users").Where("id = ? AND deleted_at IS NULL", userID).Updates(map[string]any{
			"deleted_at": now, "deleted_by_id": actorID, "is_active": false, "updated_at": now,
		})
		if res.Error != nil {
			return res.Error
		}
		if res.RowsAffected == 0 {
			return ErrStaffNotFound
		}
		if err := tx.Model(&RefreshToken{}).Where("user_id = ? AND revoked_at IS NULL", userID).
			Update("revoked_at", now).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// RecordAudit stores an audit entry for a change that has no transaction of
// its own.
func (r *Repository) RecordAudit(ctx context.Context, entry audit.Entry) error {
	return audit.Record(r.db.WithContext(ctx), entry)
}
