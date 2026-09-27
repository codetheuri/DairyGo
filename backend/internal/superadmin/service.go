package superadmin

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/auth"
	"github.com/codetheuri/tusk/internal/member"
	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/query"
)

// Domain errors, mapped to HTTP status codes by the handler.
var (
	ErrForbidden = errors.New("forbidden")
	ErrNotFound  = errors.New("not found")
)

const auditEntityUser = "user"

// Service implements the platform console. It reuses the member and auth
// services for Sacco-level work instead of duplicating their rules.
type Service struct {
	repo    *Repository
	members *member.Service
	users   *auth.Service
}

// NewService creates the platform console service.
func NewService(repo *Repository, members *member.Service, users *auth.Service) *Service {
	return &Service{repo: repo, members: members, users: users}
}

// requirePlatform refuses anyone who is not a platform super user. Routes are
// also guarded by platform.manage; this keeps the rule true if a route is
// ever registered without the guard.
func requirePlatform(ctx context.Context) error {
	if !middleware.IsSuperUser(ctx) {
		return fmt.Errorf("%w: platform operators only", ErrForbidden)
	}
	return nil
}

// inSacco runs Sacco-scoped services on behalf of the chosen Sacco: tenant
// scoping and sacco_id resolution read the Sacco from the context.
func inSacco(ctx context.Context, saccoID string) context.Context {
	ctx = context.WithValue(ctx, middleware.ContextKeySaccoID, saccoID)
	return context.WithValue(ctx, "sacco_id", saccoID)
}

// Overview returns platform totals and one row per Sacco.
func (s *Service) Overview(ctx context.Context) (*Overview, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, err
	}
	return s.repo.Overview(ctx)
}

// Staff lists a Sacco's user accounts.
func (s *Service) Staff(ctx context.Context, saccoID string) ([]StaffUser, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, err
	}
	if _, err := s.repo.SaccoStatus(ctx, saccoID); err != nil {
		return nil, err
	}
	return s.repo.StaffUsers(ctx, saccoID)
}

// AddStaff creates a staff account in a Sacco with one of the Sacco roles.
func (s *Service) AddStaff(ctx context.Context, saccoID string, req *AddStaffRequest) (*auth.User, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, err
	}
	if _, err := s.repo.SaccoStatus(ctx, saccoID); err != nil {
		return nil, err
	}
	if !auth.IsSaccoRole(req.RoleID) {
		return nil, fmt.Errorf("role_id must be %d (Sacco Administrator), %d (Milk Collector) or %d (Board Member / Executive)",
			auth.RoleSaccoAdmin, auth.RoleCollector, auth.RoleExecutive)
	}
	roleID := req.RoleID
	return s.users.Register(ctx, &auth.RegisterRequest{
		Username:        strings.TrimSpace(req.Username),
		Email:           strings.TrimSpace(req.Email),
		Phone:           req.Phone,
		Password:        req.Password,
		PasswordConfirm: req.Password,
		FirstName:       req.FirstName,
		LastName:        req.LastName,
		RoleID:          &roleID,
		SaccoID:         &saccoID,
	})
}

// SetUserActive activates or deactivates a Sacco user. Deactivation ends all
// their sessions immediately.
func (s *Service) SetUserActive(ctx context.Context, userID uint, active bool, reason *string) error {
	updates := map[string]any{"is_active": active}
	action := "activated"
	if !active {
		action = "deactivated"
	}
	return s.changeUser(ctx, userID, updates, !active, action, reason)
}

// UnlockUser clears a login lockout caused by repeated wrong passwords.
func (s *Service) UnlockUser(ctx context.Context, userID uint) error {
	updates := map[string]any{"failed_login_attempts": 0, "locked_until": nil}
	return s.changeUser(ctx, userID, updates, false, "unlocked", nil)
}

// ResetPassword sets a new password for a Sacco user, clears any lockout and
// ends their existing sessions.
func (s *Service) ResetPassword(ctx context.Context, userID uint, newPassword string) error {
	if len(newPassword) < 8 {
		return fmt.Errorf("new password must be at least 8 characters")
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to process password: %w", err)
	}
	updates := map[string]any{"password": string(hash), "failed_login_attempts": 0, "locked_until": nil}
	return s.changeUser(ctx, userID, updates, true, "password reset", nil)
}

// changeUser applies an account change to a Sacco user and records it in the
// Sacco's audit trail. Platform accounts cannot be changed from the console.
func (s *Service) changeUser(ctx context.Context, userID uint, updates map[string]any, revokeSessions bool, what string, reason *string) error {
	if err := requirePlatform(ctx); err != nil {
		return err
	}
	id, saccoID, err := s.repo.FindStaffUser(ctx, userID)
	if err != nil {
		return err
	}

	summary := map[string]any{"change": what}
	if v, ok := updates["is_active"]; ok {
		summary["is_active"] = v
	}
	entry := audit.Entry{
		SaccoID: saccoID, EntityType: auditEntityUser, EntityID: fmt.Sprint(id),
		Action: audit.ActionUpdate, ActorID: middleware.GetUserID(ctx), Reason: reason, NewValues: summary,
	}
	return s.repo.UpdateUser(ctx, id, updates, revokeSessions, func(tx *gorm.DB) error {
		return audit.Record(tx, entry)
	})
}

// Members lists a Sacco's farmers.
func (s *Service) Members(ctx context.Context, saccoID string, q query.Query) ([]member.Member, query.Meta, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, query.Meta{}, err
	}
	if _, err := s.repo.SaccoStatus(ctx, saccoID); err != nil {
		return nil, query.Meta{}, err
	}
	return s.members.ListMembers(inSacco(ctx, saccoID), q)
}

// AddMember registers a farmer in a Sacco on its behalf, with the same rules
// as a Sacco admin registering one (membership numbers, validation).
func (s *Service) AddMember(ctx context.Context, saccoID string, req *member.CreateMemberRequest) (*member.Member, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, err
	}
	if _, err := s.repo.SaccoStatus(ctx, saccoID); err != nil {
		return nil, err
	}
	return s.members.CreateMember(inSacco(ctx, saccoID), req)
}

// AuditLogs lists audit entries across Saccos.
func (s *Service) AuditLogs(ctx context.Context, f LogFilter) ([]AuditEntry, query.Meta, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, query.Meta{}, err
	}
	return s.repo.AuditLogs(ctx, f)
}

// SystemLogs lists failed API requests.
func (s *Service) SystemLogs(ctx context.Context, f LogFilter) ([]SystemLog, query.Meta, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, query.Meta{}, err
	}
	return s.repo.SystemLogs(ctx, f)
}

// SMSLogs lists SMS messages across Saccos.
func (s *Service) SMSLogs(ctx context.Context, f LogFilter) ([]SMSEntry, query.Meta, error) {
	if err := requirePlatform(ctx); err != nil {
		return nil, query.Meta{}, err
	}
	return s.repo.SMSLogs(ctx, f)
}

// RunLogRetention deletes failed-request logs older than keep, once at start
// and then daily, until ctx is cancelled.
func RunLogRetention(ctx context.Context, repo *Repository, keep time.Duration, onError func(error)) {
	purge := func() {
		if _, err := repo.PurgeSystemLogs(ctx, time.Now().Add(-keep)); err != nil && ctx.Err() == nil {
			onError(err)
		}
	}
	purge()
	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			purge()
		}
	}
}
