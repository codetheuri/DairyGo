package sacco

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
	// PLATFORM SUPER USER SACCO MANAGEMENT
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "create-sacco",
		Method:      http.MethodPost,
		Path:        "/api/v1/admin/saccos",
		Summary:     "Provision new Dairy Sacco",
		Description: "Creates a new Sacco tenant, default operational settings, and initial Sacco Administrator user account.",
		Tags:        []string{"Sacco Management (Admin)"},
	}, PermSaccosCreate), handler.Create)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-saccos",
		Method:      http.MethodGet,
		Path:        "/api/v1/admin/saccos",
		Summary:     "List all Dairy Saccos",
		Description: "Returns a paginated and filterable list of all Saccos registered on the platform.",
		Tags:        []string{"Sacco Management (Admin)"},
	}, PermSaccosRead), handler.List)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-sacco-by-id",
		Method:      http.MethodGet,
		Path:        "/api/v1/admin/saccos/{id}",
		Summary:     "Get Sacco by ID",
		Description: "Retrieves details for a specific Sacco.",
		Tags:        []string{"Sacco Management (Admin)"},
	}, PermSaccosRead), handler.GetByID)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-sacco",
		Method:      http.MethodPut,
		Path:        "/api/v1/admin/saccos/{id}",
		Summary:     "Update Sacco details",
		Description: "Modifies Sacco profile details (name, email, phone, address).",
		Tags:        []string{"Sacco Management (Admin)"},
	}, PermSaccosUpdate), handler.Update)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-sacco-status",
		Method:      http.MethodPatch,
		Path:        "/api/v1/admin/saccos/{id}/status",
		Summary:     "Update Sacco operational status",
		Description: "Changes Sacco status to ACTIVE, INACTIVE, or SUSPENDED.",
		Tags:        []string{"Sacco Management (Admin)"},
	}, PermSaccosUpdateStatus), handler.UpdateStatus)

	// -------------------------------------------------------------
	// TENANT SACCO PROFILE & SETTINGS ENDPOINTS
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-current-sacco-profile",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/profile",
		Summary:     "Current Sacco profile",
		Description: "Returns details and operational configuration of the authenticated user's Sacco.",
		Tags:        []string{"Sacco Tenant Profile"},
	}, ""), handler.GetCurrentSacco)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-sacco-settings",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/settings",
		Summary:     "Get Sacco settings",
		Description: "Retrieves operational settings (currency, milk unit, cutoff times) for the authenticated Sacco.",
		Tags:        []string{"Sacco Tenant Profile"},
	}, PermSaccoSettingsRead), handler.GetSettings)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-sacco-settings",
		Method:      http.MethodPut,
		Path:        "/api/v1/sacco/settings",
		Summary:     "Update Sacco settings",
		Description: "Modifies operational settings for the authenticated Sacco.",
		Tags:        []string{"Sacco Tenant Profile"},
	}, PermSaccoSettingsManage), handler.UpdateSettings)
}
