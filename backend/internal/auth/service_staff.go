package auth

import (
	"context"
	"fmt"
	"strings"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// auditEntityUser is the entity_type of staff account audit entries.
const auditEntityUser = "user"

// staffForChange loads a staff account of the Sacco in ctx and checks that the
// caller may change it. The Sacco always comes from the context, never from
// the request, so an administrator only reaches their own Sacco's staff.
func (s *Service) staffForChange(ctx context.Context, userID uint, keepsAdmin bool) (*StaffAccount, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok {
		return nil, fmt.Errorf("%w: sacco context is required to manage staff", ErrStaffForbidden)
	}
	target, err := s.repo.FindStaff(ctx, saccoID, userID)
	if err != nil {
		return nil, err
	}
	otherAdmins, err := s.repo.CountOtherAdmins(ctx, saccoID, target.ID)
	if err != nil {
		return nil, fmt.Errorf("could not check the Sacco's administrators: %w", err)
	}
	if err := canChangeStaff(middleware.GetUserID(ctx), *target, keepsAdmin, otherAdmins); err != nil {
		return nil, err
	}
	return target, nil
}

// ChangeStaffRole gives a staff account of the caller's Sacco a different
// Sacco role. It replaces the role they had and applies to their next request.
func (s *Service) ChangeStaffRole(ctx context.Context, userID, roleID uint, reason *string) (*User, error) {
	if !IsSaccoRole(roleID) {
		return nil, fmt.Errorf("role_id must be %d (Sacco Administrator), %d (Milk Collector) or %d (Board Member / Executive)",
			RoleSaccoAdmin, RoleCollector, RoleExecutive)
	}
	target, err := s.staffForChange(ctx, userID, roleID == RoleSaccoAdmin)
	if err != nil {
		return nil, err
	}
	if target.RoleID == roleID {
		return nil, fmt.Errorf("%s is already a %s", target.Username, SaccoRoleName(roleID))
	}

	entry := audit.Entry{
		SaccoID: target.SaccoID, EntityType: auditEntityUser, EntityID: fmt.Sprint(target.ID),
		Action: audit.ActionUpdate, ActorID: middleware.GetUserID(ctx), Reason: cleanReason(reason),
		OldValues: map[string]any{"role": target.RoleName},
		NewValues: map[string]any{"change": "role changed", "role": SaccoRoleName(roleID)},
	}
	if err := s.repo.SetStaffRole(ctx, target.ID, roleID, entry); err != nil {
		return nil, fmt.Errorf("failed to change role: %w", err)
	}
	return s.repo.FindByID(ctx, target.ID)
}

// RemoveStaff removes a staff account of the caller's Sacco: they are signed
// out at once and cannot sign in again. What they recorded is kept under
// their name, and their username, email and phone can be used for a new
// account.
func (s *Service) RemoveStaff(ctx context.Context, userID uint, reason *string) error {
	target, err := s.staffForChange(ctx, userID, false)
	if err != nil {
		return err
	}
	actorID := middleware.GetUserID(ctx)
	entry := audit.Entry{
		SaccoID: target.SaccoID, EntityType: auditEntityUser, EntityID: fmt.Sprint(target.ID),
		Action: audit.ActionDelete, ActorID: actorID, Reason: cleanReason(reason),
		OldValues: map[string]any{"username": target.Username, "role": target.RoleName},
		NewValues: map[string]any{"change": "removed"},
	}
	if err := s.repo.RemoveStaff(ctx, target.ID, actorID, entry); err != nil {
		return fmt.Errorf("failed to remove staff: %w", err)
	}
	return nil
}

// cleanReason trims an optional reason; a blank one is stored as none.
func cleanReason(reason *string) *string {
	if reason == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*reason)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}
