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

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "admin-update-sacco-settings",
		Method:      http.MethodPut,
		Path:        "/api/v1/admin/saccos/{id}/settings",
		Summary:     "Update a Sacco's settings",
		Description: "Changes a Sacco's operational settings on its behalf (for example the days without milk after which farmers become inactive).",
		Tags:        []string{"Sacco Management (Admin)"},
	}, PermSaccosUpdate), handler.AdminUpdateSettings)

	// The logo printed on the Sacco's reports.
	logoImage := map[string]*huma.Response{"200": {
		Description: "The logo image",
		Content:     map[string]*huma.MediaType{"image/png": {}, "image/jpeg": {}},
	}}
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "admin-set-sacco-logo", Method: http.MethodPut, Path: "/api/v1/admin/saccos/{id}/logo",
		Summary: "Set a Sacco's logo", Description: "The logo printed on the Sacco's reports: PNG or JPEG, at most 512 KB, sent as base64.",
		Tags: []string{"Sacco Management (Admin)"},
	}, PermSaccosUpdate), handler.AdminSetLogo)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "admin-remove-sacco-logo", Method: http.MethodDelete, Path: "/api/v1/admin/saccos/{id}/logo",
		Summary: "Remove a Sacco's logo", Tags: []string{"Sacco Management (Admin)"},
	}, PermSaccosUpdate), handler.AdminRemoveLogo)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "admin-get-sacco-logo", Method: http.MethodGet, Path: "/api/v1/admin/saccos/{id}/logo",
		Summary: "A Sacco's logo", Tags: []string{"Sacco Management (Admin)"}, Responses: logoImage,
	}, PermSaccosRead), handler.AdminLogo)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "set-own-sacco-logo", Method: http.MethodPut, Path: "/api/v1/sacco/logo",
		Summary: "Set your Sacco's logo", Description: "The logo printed on your Sacco's reports: PNG or JPEG, at most 512 KB, sent as base64.",
		Tags: []string{"Sacco Tenant Profile"},
	}, PermSaccoSettingsManage), handler.SetOwnLogo)
	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-own-sacco-logo", Method: http.MethodGet, Path: "/api/v1/sacco/logo",
		Summary: "Your Sacco's logo", Tags: []string{"Sacco Tenant Profile"}, Responses: logoImage,
	}, ""), handler.OwnLogo)

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
