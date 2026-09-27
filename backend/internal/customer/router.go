package customer

import (
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/logger"
)

const tag = "Customers & Ledger"

// RegisterRoutes wires the customer module's endpoints.
func RegisterRoutes(api huma.API, db *gorm.DB, cfg *config.Config, log logger.Logger) {
	evaluator := authz.NewEvaluator(db)
	handler := NewHandler(NewService(NewRepository(db), evaluator), log)
	guard := authz.NewGuard(api, db)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "create-customer", Method: http.MethodPost, Path: "/api/v1/sacco/customers",
		Summary: "Add customer", Tags: []string{tag},
		Description: "Adds a buyer (cooler, processor, hotel, shop, individual). Collectors use this to add a customer on the spot while recording a sale. Phone numbers are unique per Sacco (409 if taken).",
	}, PermCustomersCreate), handler.Create)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-customers", Method: http.MethodGet, Path: "/api/v1/sacco/customers",
		Summary: "List / search customers", Tags: []string{tag},
		Description: "Paginated customer list, searchable by name or phone. Balances are included for users allowed to read statements.",
	}, PermCustomersRead), handler.List)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "customer-balances", Method: http.MethodGet, Path: "/api/v1/sacco/customers/balances",
		Summary: "Customer balances (who owes what)", Tags: []string{tag},
		Description: "Outstanding balance per customer, largest first, plus the total owed to the Sacco.",
	}, PermCustomerStatementRead), handler.Balances)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "get-customer", Method: http.MethodGet, Path: "/api/v1/sacco/customers/{id}",
		Summary: "Get customer", Tags: []string{tag},
	}, PermCustomersRead), handler.Get)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-customer", Method: http.MethodPut, Path: "/api/v1/sacco/customers/{id}",
		Summary: "Update customer", Tags: []string{tag},
	}, PermCustomersUpdate), handler.Update)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "update-customer-status", Method: http.MethodPatch, Path: "/api/v1/sacco/customers/{id}/status",
		Summary: "Activate / deactivate customer", Tags: []string{tag},
		Description: "Inactive customers keep their ledger and can still pay, but no new sales can be recorded for them.",
	}, PermCustomersUpdate), handler.UpdateStatus)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "customer-history", Method: http.MethodGet, Path: "/api/v1/sacco/customers/{id}/history",
		Summary: "Customer change history", Tags: []string{tag},
	}, PermCustomersRead), handler.History)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "customer-statement", Method: http.MethodGet, Path: "/api/v1/sacco/customers/{id}/statement",
		Summary: "Customer statement", Tags: []string{tag},
		Description: "Running-balance ledger for a period: opening balance, sales (debit, with any amount paid at sale as credit), payments (credit) and closing balance. Voided entries are excluded.",
	}, PermCustomerStatementRead), handler.Statement)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "record-customer-payment", Method: http.MethodPost, Path: "/api/v1/sacco/customers/{id}/payments",
		Summary: "Record customer payment", Tags: []string{tag},
		Description: "Records money received from a customer (e.g. a cooler settling credit). Reduces the running balance.",
	}, PermCustomerPaymentsManage), handler.RecordPayment)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "void-customer-payment", Method: http.MethodPost, Path: "/api/v1/sacco/customer-payments/{id}/void",
		Summary: "Void customer payment", Tags: []string{tag},
		Description: "Cancels a payment recorded in error. It stays on record for audit but no longer reduces the balance. A reason is required.",
	}, PermCustomerPaymentsManage), handler.VoidPayment)
}
