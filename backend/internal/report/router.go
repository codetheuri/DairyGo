package report

import (
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/logger"
)

func RegisterRoutes(api huma.API, db *gorm.DB, cfg *config.Config, log logger.Logger) {
	repo := NewRepository(db)
	service := NewService(repo)
	handler := NewHandler(service, log)

	guard := authz.NewGuard(api, db)

	// -------------------------------------------------------------
	// REPORTING & RECONCILIATION LEDGER ENDPOINTS
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-farmer-payout-report",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/reports/farmer-payout",
		Summary:     "Farmer Payroll & Payout Statement Report",
		Description: "Generates itemized farmer payroll statements, gross payout liability, average buying rates, and total litres per member for a date range.",
		Tags:        []string{"Reports & Reconciliation"},
	}, PermReportsPayoutRead), handler.GetFarmerPayoutReport)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-reconciliation-ledger-report",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/reports/reconciliation",
		Summary:     "Sacco Balancing Reconciliation Ledger",
		Description: "Generates complete Sacco-wide mathematical balancing statement verifying Intake = Direct Sales + Spoilage + Net Coolant Station Intake.",
		Tags:        []string{"Reports & Reconciliation"},
	}, PermReportsReconciliationRead), handler.GetReconciliationLedger)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-collector-audit-report",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/reports/collector-audit",
		Summary:     "Collector Performance & Audit Report",
		Description: "Generates collector field performance, transit sales revenue, spoilage logs, and coolant station delivery ratios.",
		Tags:        []string{"Reports & Reconciliation"},
	}, PermReportsCollectorRead), handler.GetCollectorAuditReport)
}
