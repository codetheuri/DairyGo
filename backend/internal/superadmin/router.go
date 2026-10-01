package superadmin

import (
	"github.com/codetheuri/tusk/internal/finance"
	"github.com/codetheuri/tusk/internal/payout"
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/internal/auth"
	"github.com/codetheuri/tusk/internal/jobs"
	"github.com/codetheuri/tusk/internal/member"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/logger"
)

const tag = "Platform Console"

// RegisterRoutes wires the platform console endpoints. Onboarding, editing and
// suspending Saccos use the existing /api/v1/admin/saccos endpoints.
func RegisterRoutes(api huma.API, db *gorm.DB, cfg *config.Config, log logger.Logger, runner *jobs.Runner) {
	service := NewService(
		NewRepository(db),
		member.NewService(member.NewRepository(db)),
		auth.NewService(auth.NewRepository(db, log), cfg),
	)
	h := NewHandler(service)
	jh := &JobsHandler{runner: runner}
	mh := &MoneyHandler{
		payouts: payout.NewService(payout.NewRepository(db), nil, nil),
		finance: finance.NewService(finance.NewRepository(db)),
	}
	guard := authz.NewGuard(api, db)

	op := func(id, method, path, summary, description string) huma.Operation {
		return guard.Protected(huma.Operation{
			OperationID: id, Method: method, Path: path, Summary: summary,
			Description: description, Tags: []string{tag},
		}, PermPlatformManage)
	}

	huma.Register(api, op("platform-overview", http.MethodGet, "/api/v1/admin/overview",
		"Platform overview", "Totals across all Saccos plus one row per Sacco (farmers, staff, month litres and revenue, receivables, last collection)."), h.Overview)

	huma.Register(api, op("platform-sacco-staff", http.MethodGet, "/api/v1/admin/saccos/{id}/users",
		"Sacco staff accounts", "Lists a Sacco's users with role, active flag and lockout state."), h.Staff)
	huma.Register(api, op("platform-add-staff", http.MethodPost, "/api/v1/admin/saccos/{id}/users",
		"Add Sacco staff", "Creates a staff account in the Sacco with role 1, 2 or 3."), h.AddStaff)
	huma.Register(api, op("platform-user-status", http.MethodPatch, "/api/v1/admin/users/{id}/status",
		"Activate / deactivate a Sacco user", "Deactivation takes effect immediately and ends the user's sessions."), h.SetUserStatus)
	huma.Register(api, op("platform-user-role", http.MethodPut, "/api/v1/admin/users/{id}/role",
		"Change a Sacco user's role", "Makes the user an administrator, collector or board member. A Sacco's only administrator cannot be demoted."), h.ChangeRole)
	huma.Register(api, op("platform-remove-user", http.MethodDelete, "/api/v1/admin/users/{id}",
		"Remove a Sacco user", "The user is signed out at once and cannot sign in. Records they made keep their name. A Sacco's only administrator cannot be removed."), h.RemoveUser)
	huma.Register(api, op("platform-unlock-user", http.MethodPost, "/api/v1/admin/users/{id}/unlock",
		"Unlock a Sacco user", "Clears a lockout caused by repeated wrong passwords."), h.UnlockUser)
	huma.Register(api, op("platform-reset-password", http.MethodPost, "/api/v1/admin/users/{id}/reset-password",
		"Reset a Sacco user's password", "Sets a new password, clears any lockout and ends existing sessions."), h.ResetPassword)

	huma.Register(api, op("platform-sacco-members", http.MethodGet, "/api/v1/admin/saccos/{id}/members",
		"Sacco farmers", "Lists and searches a Sacco's farmers."), h.Members)
	huma.Register(api, op("platform-add-member", http.MethodPost, "/api/v1/admin/saccos/{id}/members",
		"Register a farmer for a Sacco", "Registers a farmer on the Sacco's behalf, with the same rules as a Sacco admin."), h.AddMember)
	huma.Register(api, op("platform-member-status", http.MethodPatch, "/api/v1/admin/saccos/{id}/members/{member_id}/status",
		"Change a farmer's status", "Makes a farmer active, inactive or suspended, with the same rules as a Sacco admin (a suspension needs a reason)."), h.SetMemberStatus)

	huma.Register(api, op("platform-sacco-money", http.MethodGet, "/api/v1/admin/saccos/{id}/money",
		"Sacco pay runs and money", "Read-only, for support: the Sacco's pay runs, accounts with balances, and income and expenditure for a period (default this month)."), mh.Money)

	huma.Register(api, op("platform-audit-logs", http.MethodGet, "/api/v1/admin/audit-logs",
		"Audit trail", "Who changed what across all Saccos, newest first."), h.AuditLogs)
	huma.Register(api, op("platform-error-logs", http.MethodGet, "/api/v1/admin/error-logs",
		"Failed requests", "Every API request that ended with status 400 or above (kept 30 days)."), h.SystemLogs)
	huma.Register(api, op("platform-sms-logs", http.MethodGet, "/api/v1/admin/sms-logs",
		"SMS logs", "SMS messages sent by all Saccos, with delivery status."), h.SMSLogs)

	huma.Register(api, op("platform-jobs", http.MethodGet, "/api/v1/admin/jobs",
		"Background jobs", "The API's scheduled jobs: what each does, how often, whether it is running, its last run and next run."), jh.List)
	huma.Register(api, op("platform-job-runs", http.MethodGet, "/api/v1/admin/jobs/{name}/runs",
		"A job's recent runs", "The latest runs of a job, newest first (kept 90 days)."), jh.Runs)
	huma.Register(api, op("platform-run-job", http.MethodPost, "/api/v1/admin/jobs/{name}/run",
		"Run a job now", "Starts the job now, in the background; the run appears in its history. Refused (409) while it is running."), jh.RunNow)
}
