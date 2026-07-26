package dashboard

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
	// EXECUTIVE & MOBILE DASHBOARD ENDPOINTS
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-executive-dashboard",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/dashboard/summary",
		Summary:     "Sacco Executive Overview Dashboard",
		Description: "Returns real-time summary cards (today & month-to-date) and intake vs sales vs spoilage daily trend time series charts for Sacco Admins & Board Members.",
		Tags:        []string{"Executive & Mobile Dashboards"},
	}, PermDashboardExecutiveRead), handler.GetExecutiveDashboard)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-collector-dashboard",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/dashboard/collector",
		Summary:     "Collector Mobile Field Shift Overview",
		Description: "Returns real-time mobile shift metrics for field collectors: total litres collected, field sales revenue, spoilage, and net station handover.",
		Tags:        []string{"Executive & Mobile Dashboards"},
	}, PermDashboardCollectorRead), handler.GetCollectorDashboard)
}
