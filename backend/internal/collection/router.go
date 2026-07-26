package collection

import (
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/logger"
	"github.com/codetheuri/tusk/pkg/sms"
)

func RegisterRoutes(api huma.API, db *gorm.DB, cfg *config.Config, log logger.Logger) {
	repo := NewRepository(db)
	smsService := sms.NewService(cfg, db, log)
	service := NewService(repo, smsService)
	handler := NewHandler(service, log)

	guard := authz.NewGuard(api, db)

	// -------------------------------------------------------------
	// MILK BUYING PRICING ENDPOINTS
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "set-milk-price",
		Method:      http.MethodPost,
		Path:        "/api/v1/sacco/milk-prices",
		Summary:     "Configure active Milk buying price",
		Description: "Sets a new buying price per litre for the Sacco. Past collections retain their historical snapshot rates.",
		Tags:        []string{"Milk Pricing"},
	}, PermMilkPricesManage), handler.SetPrice)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-active-milk-price",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-prices/active",
		Summary:     "Get active Milk buying price",
		Description: "Retrieves the currently active Sacco buying price rate per litre.",
		Tags:        []string{"Milk Pricing"},
	}, PermMilkPricesRead), handler.GetActivePrice)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-milk-prices",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-prices",
		Summary:     "Milk price rate history",
		Description: "Returns historical rate changes for the Sacco.",
		Tags:        []string{"Milk Pricing"},
	}, PermMilkPricesRead), handler.ListPrices)

	// -------------------------------------------------------------
	// MILK COLLECTION ENDPOINTS
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "record-milk-collection",
		Method:      http.MethodPost,
		Path:        "/api/v1/sacco/milk-collections",
		Summary:     "Record Farmer Milk Collection",
		Description: "Logs milk received from a farmer in the field. Automatically applies effective buying price snapshot.",
		Tags:        []string{"Milk Collections"},
	}, PermMilkCollectionsCreate), handler.RecordCollection)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-milk-collections",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-collections",
		Summary:     "List Milk Collections",
		Description: "Returns a paginated and filterable list of farmer milk collections.",
		Tags:        []string{"Milk Collections"},
	}, PermMilkCollectionsRead), handler.ListCollections)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-collection-by-id",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-collections/{id}",
		Summary:     "Get Collection entry",
		Description: "Retrieves a single milk collection entry by ID.",
		Tags:        []string{"Milk Collections"},
	}, PermMilkCollectionsRead), handler.GetCollectionByID)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-collection",
		Method:      http.MethodPut,
		Path:        "/api/v1/sacco/milk-collections/{id}",
		Summary:     "Update Collection entry",
		Description: "Edits an existing milk collection record (quantity, shift, or notes). Recalculates total amount based on original snapshot price.",
		Tags:        []string{"Milk Collections"},
	}, PermMilkCollectionsCreate), handler.UpdateCollection)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-collection-status",
		Method:      http.MethodPatch,
		Path:        "/api/v1/sacco/milk-collections/{id}/status",
		Summary:     "Verify / Adjust Collection status",
		Description: "Updates collection status to VERIFIED, REJECTED, or ADJUSTED.",
		Tags:        []string{"Milk Collections"},
	}, PermMilkCollectionsManage), handler.UpdateCollectionStatus)

	// -------------------------------------------------------------
	// DIRECT FIELD MILK SALES ENDPOINTS
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "record-milk-sale",
		Method:      http.MethodPost,
		Path:        "/api/v1/sacco/milk-sales",
		Summary:     "Record Field Milk Sale",
		Description: "Logs direct milk sales made by collectors in the field to buyers, hotels, or processors.",
		Tags:        []string{"Milk Sales"},
	}, PermMilkSalesCreate), handler.RecordSale)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-milk-sales",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-sales",
		Summary:     "List Milk Sales",
		Description: "Returns a paginated list of direct field sales.",
		Tags:        []string{"Milk Sales"},
	}, PermMilkSalesRead), handler.ListSales)

	// -------------------------------------------------------------
	// MILK SPOILAGE / LOSS ENDPOINTS
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "record-milk-spoilage",
		Method:      http.MethodPost,
		Path:        "/api/v1/sacco/milk-spoilage",
		Summary:     "Log Milk Spoilage or Loss",
		Description: "Logs milk spillage, spoilage, or acidity test failure in transit.",
		Tags:        []string{"Milk Spoilage"},
	}, PermMilkSpoilageCreate), handler.RecordSpoilage)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-milk-spoilage",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-spoilage",
		Summary:     "List Spoilage Logs",
		Description: "Returns a paginated log of milk spoilage events.",
		Tags:        []string{"Milk Spoilage"},
	}, PermMilkSpoilageRead), handler.ListSpoilage)

	// -------------------------------------------------------------
	// COLLECTOR RECONCILIATION SUMMARY
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-collector-reconciliation",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/reconciliation",
		Summary:     "Collector Daily Reconciliation Overview",
		Description: "Calculates total collected litres, total field sales, total spoilage, and net litres delivered to the cooling station.",
		Tags:        []string{"Collector Reconciliation"},
	}, PermMilkReconciliationRead), handler.GetReconciliation)
}
