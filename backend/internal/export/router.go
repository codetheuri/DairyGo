package export

import (
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/internal/customer"
	"github.com/codetheuri/tusk/internal/finance"
	"github.com/codetheuri/tusk/internal/report"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/logger"
)

// RegisterRoutes registers the report downloads. Both routes need only a
// signed-in user: each report checks its own permission (see catalog.go).
func RegisterRoutes(api huma.API, db *gorm.DB, cfg *config.Config, log logger.Logger) {
	evaluator := authz.NewEvaluator(db)
	service := NewService(
		NewRepository(db),
		report.NewService(report.NewRepository(db)),
		customer.NewService(customer.NewRepository(db), evaluator),
		finance.NewService(finance.NewRepository(db)),
		evaluator,
	)
	h := NewHandler(service, log)
	guard := authz.NewGuard(api, db)
	tags := []string{"Report Downloads"}

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-report-downloads",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/exports",
		Summary:     "Reports you can download",
		Description: "The reports the caller's permissions allow, with what each needs (a farmer, a customer, a period).",
		Tags:        tags,
	}, ""), h.Catalog)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "download-report",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/exports/{report}",
		Summary:     "Download a report",
		Description: "Builds the report on the server and returns it as a PDF or Excel file. Periods are at most a year.",
		Tags:        tags,
		Responses: map[string]*huma.Response{"200": {
			Description: "The report file",
			Content: map[string]*huma.MediaType{
				"application/pdf": {},
				"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": {},
			},
		}},
	}, ""), h.Export)
}
