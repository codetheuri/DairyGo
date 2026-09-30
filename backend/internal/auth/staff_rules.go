package auth

import (
	"errors"
	"fmt"
)

// Staff management errors, mapped to HTTP status codes by handlers.
var (
	ErrStaffNotFound  = errors.New("staff not found")
	ErrStaffForbidden = errors.New("not allowed")
)

// StaffAccount is a Sacco staff account as needed to decide whether it may be
// changed or removed.
type StaffAccount struct {
	ID       uint
	SaccoID  string
	Username string
	RoleID   uint
	RoleName string
	IsActive bool
}

// canChangeStaff decides whether actorID may change target's role or remove
// the account. keepsAdmin is true when target stays a Sacco administrator
// after the change; otherAdmins counts the Sacco's other active administrators.
//
// Nobody changes their own account, so an administrator cannot lock themselves
// out by mistake, and a Sacco never loses its last active administrator.
func canChangeStaff(actorID uint, target StaffAccount, keepsAdmin bool, otherAdmins int64) error {
	if actorID == target.ID {
		return fmt.Errorf("%w: you cannot change or remove your own account; ask another administrator", ErrStaffForbidden)
	}
	losesAdmin := target.RoleID == RoleSaccoAdmin && target.IsActive && !keepsAdmin
	if losesAdmin && otherAdmins == 0 {
		return fmt.Errorf("%s is the Sacco's only administrator; make someone else an administrator first", target.Username)
	}
	return nil
}
