package member

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
	// MEMBER / FARMER MANAGEMENT ENDPOINTS
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "create-member",
		Method:      http.MethodPost,
		Path:        "/api/v1/sacco/members",
		Summary:     "Register new Member / Farmer",
		Description: "Registers a new dairy producer/farmer under the authenticated Sacco.",
		Tags:        []string{"Member Management"},
	}, PermMembersCreate), handler.Create)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-members",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/members",
		Summary:     "List Sacco Members",
		Description: "Returns a paginated and filterable list of farmers registered in the authenticated Sacco.",
		Tags:        []string{"Member Management"},
	}, PermMembersRead), handler.List)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-member-by-id",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/members/{id}",
		Summary:     "Get Member details",
		Description: "Retrieves a single farmer's details and payout information by ID.",
		Tags:        []string{"Member Management"},
	}, PermMembersRead), handler.GetByID)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-member",
		Method:      http.MethodPut,
		Path:        "/api/v1/sacco/members/{id}",
		Summary:     "Update Member profile",
		Description: "Modifies farmer contact, identity, and payment details.",
		Tags:        []string{"Member Management"},
	}, PermMembersUpdate), handler.Update)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-member-status",
		Method:      http.MethodPatch,
		Path:        "/api/v1/sacco/members/{id}/status",
		Summary:     "Update Member status",
		Description: "Changes a member's status to ACTIVE, INACTIVE, or SUSPENDED.",
		Tags:        []string{"Member Management"},
	}, PermMembersUpdateStatus), handler.UpdateStatus)
}
