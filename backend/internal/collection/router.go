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
	service := NewService(repo, smsService, authz.NewEvaluator(db))
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
		Description: "Logs milk received from an ACTIVE farmer of the Sacco, priced at the buying rate in force on the collection date.",
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
		Description: "Edits quantity, shift or notes and recalculates the total at the original snapshot price. Collectors may edit only their own SUBMITTED records on the day they were recorded; admins may edit SUBMITTED or ADJUSTED records and must give a reason. VERIFIED and REJECTED records are locked (409).",
		Tags:        []string{"Milk Collections"},
	}, PermMilkCollectionsCreate), handler.UpdateCollection)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-collection-history",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-collections/{id}/history",
		Summary:     "Collection change history",
		Description: "Returns who created and changed a collection, with before/after values and reasons, oldest first.",
		Tags:        []string{"Milk Collections"},
	}, PermMilkCollectionsRead), handler.GetCollectionHistory)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-collection-status",
		Method:      http.MethodPatch,
		Path:        "/api/v1/sacco/milk-collections/{id}/status",
		Summary:     "Verify / Adjust Collection status",
		Description: "Moves a collection through SUBMITTED -> VERIFIED/REJECTED/ADJUSTED, ADJUSTED -> VERIFIED/REJECTED, and reopens VERIFIED/REJECTED as ADJUSTED. REJECTED and ADJUSTED require a reason.",
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
		Description: "Records milk sold to a customer (coolers included: every litre leaving a collector is a sale). The unit price defaults to the customer's agreed price. amount_paid is what was paid at the sale (defaults to the full total, or 0 for CREDIT); the rest goes on the customer's balance.",
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

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-milk-sale",
		Method:      http.MethodPut,
		Path:        "/api/v1/sacco/milk-sales/{id}",
		Summary:     "Correct a Milk Sale",
		Description: "Collectors may correct their own sales on the day they were recorded; admins (milk.sales.manage) may correct any non-voided sale and must give a reason. Voided sales are locked (409).",
		Tags:        []string{"Milk Sales"},
	}, PermMilkSalesCreate), handler.UpdateSale)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "void-milk-sale",
		Method:      http.MethodPost,
		Path:        "/api/v1/sacco/milk-sales/{id}/void",
		Summary:     "Void a Milk Sale",
		Description: "Cancels a sale recorded in error. It stays on record for audit but no longer counts in reconciliation or the customer's balance.",
		Tags:        []string{"Milk Sales"},
	}, PermMilkSalesManage), handler.VoidSale)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-milk-sale-history",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-sales/{id}/history",
		Summary:     "Milk Sale change history",
		Tags:        []string{"Milk Sales"},
	}, PermMilkSalesRead), handler.GetSaleHistory)

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
	// MILK TRANSFERS BETWEEN COLLECTORS
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-transfer-recipients",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-transfers/recipients",
		Summary:     "Collectors milk can be transferred to",
		Description: "Active staff of the Sacco who record milk, except the caller, by name.",
		Tags:        []string{"Milk Transfers"},
	}, PermMilkTransfersCreate), handler.TransferRecipients)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "record-milk-transfer",
		Method:      http.MethodPost,
		Path:        "/api/v1/sacco/milk-transfers",
		Summary:     "Transfer milk to another collector",
		Description: "Records milk handed to another collector. It counts at once for both: collected + received - sold - transferred out - spoiled = unaccounted. Collectors transfer their own milk; admins (milk.transfers.manage) may give from_collector_id.",
		Tags:        []string{"Milk Transfers"},
	}, PermMilkTransfersCreate), handler.RecordTransfer)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-milk-transfers",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-transfers",
		Summary:     "List milk transfers",
		Description: "Newest first. Collectors see transfers they sent or received; admins and board members see all. Cancelled transfers are left out unless include_cancelled=true.",
		Tags:        []string{"Milk Transfers"},
	}, PermMilkTransfersRead), handler.ListTransfers)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-milk-transfer",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-transfers/{id}",
		Summary:     "Get a milk transfer",
		Tags:        []string{"Milk Transfers"},
	}, PermMilkTransfersRead), handler.GetTransfer)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-milk-transfer",
		Method:      http.MethodPut,
		Path:        "/api/v1/sacco/milk-transfers/{id}",
		Summary:     "Correct a milk transfer",
		Description: "The sender may correct the receiver, litres or notes on the day it was recorded; admins may correct any transfer and must give a reason for another collector's. Cancelled transfers are locked (409).",
		Tags:        []string{"Milk Transfers"},
	}, PermMilkTransfersCreate), handler.UpdateTransfer)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "cancel-milk-transfer",
		Method:      http.MethodPost,
		Path:        "/api/v1/sacco/milk-transfers/{id}/cancel",
		Summary:     "Cancel a milk transfer",
		Description: "Same rules as correcting. The transfer stays on record for the history but no longer counts for either collector.",
		Tags:        []string{"Milk Transfers"},
	}, PermMilkTransfersCreate), handler.CancelTransfer)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-milk-transfer-history",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/milk-transfers/{id}/history",
		Summary:     "Milk transfer change history",
		Tags:        []string{"Milk Transfers"},
	}, PermMilkTransfersRead), handler.GetTransferHistory)

	// -------------------------------------------------------------
	// COLLECTOR RECONCILIATION SUMMARY
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-collector-reconciliation",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/reconciliation",
		Summary:     "Collector Daily Reconciliation Overview",
		Description: "Balances a collector's day: collected + received from other collectors - sold - transferred out - spoiled = unaccounted. Includes the day's transfers.",
		Tags:        []string{"Collector Reconciliation"},
	}, PermMilkReconciliationRead), handler.GetReconciliation)
}
