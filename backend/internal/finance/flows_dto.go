package finance

import "github.com/codetheuri/tusk/pkg/response"

// Out is a response with data; the handlers for other income and suppliers
// share it rather than declaring an output type per endpoint.
type Out[T any] struct {
	Body response.Data[T]
}

func ok[T any](msg string, v T) *Out[T] {
	out := &Out[T]{}
	out.Body.Success, out.Body.Message, out.Body.Data = true, msg, v
	return out
}

// --- other income ---

type FinIncomeCategoriesData struct {
	Categories []IncomeCategory `json:"categories"`
}

type FinIncomeCategoryData struct {
	Category *IncomeCategory `json:"category"`
}

type FinCreateIncomeCategoryInput struct {
	Body FinCategoryRequest
}

type FinUpdateIncomeCategoryInput struct {
	ID   string `path:"id" doc:"IncomeCategory UUID"`
	Body FinCategoryRequest
}

// FinIncomeRequest records money received besides milk sales.
type FinIncomeRequest struct {
	CategoryID  string  `json:"category_id" doc:"Income category UUID"`
	AccountID   string  `json:"cash_account_id" doc:"CashAccount the money went into"`
	Amount      float64 `json:"amount" doc:"KES"`
	Payer       string  `json:"payer" maxLength:"150" doc:"Who paid the Sacco"`
	Date        string  `json:"date,omitempty" doc:"YYYY-MM-DD (default today)"`
	Reference   string  `json:"reference,omitempty" maxLength:"100" doc:"Receipt, M-Pesa or bank reference"`
	Description string  `json:"description,omitempty" maxLength:"1000"`
}

type FinRecordIncomeInput struct {
	Body FinIncomeRequest
}

type FinListIncomeInput struct {
	From       string `query:"from" doc:"YYYY-MM-DD (default the 1st of this month)"`
	To         string `query:"to" doc:"YYYY-MM-DD (default today)"`
	CategoryID string `query:"category_id"`
	WithVoided bool   `query:"with_voided"`
}

type FinIncomeData struct {
	Income *OtherIncome `json:"income"`
}

// --- suppliers ---

// SupplierRequest creates or changes a supplier; on update only the fields
// sent change.
type SupplierRequest struct {
	Name     *string `json:"name,omitempty" maxLength:"150" doc:"e.g. Kiambu Agrovet, CIC Insurance"`
	Phone    *string `json:"phone,omitempty" maxLength:"30"`
	Notes    *string `json:"notes,omitempty" maxLength:"1000" doc:"Paybill, bank details, contact person"`
	IsActive *bool   `json:"is_active,omitempty"`
}

type FinCreateSupplierInput struct {
	Body SupplierRequest
}

type FinUpdateSupplierInput struct {
	ID   string `path:"id" doc:"Supplier UUID"`
	Body SupplierRequest
}

type FinSupplierIDInput struct {
	ID string `path:"id" doc:"Supplier UUID"`
}

type FinSupplierData struct {
	Supplier *Supplier `json:"supplier"`
}

// BillRequest records a bill.
type BillRequest struct {
	SupplierID  string  `json:"supplier_id"`
	CategoryID  string  `json:"category_id" doc:"Expense category: what the bill is for"`
	Amount      float64 `json:"amount" doc:"KES"`
	Date        string  `json:"date,omitempty" doc:"The bill's date, YYYY-MM-DD (default today)"`
	DueDate     string  `json:"due_date,omitempty" doc:"YYYY-MM-DD"`
	Reference   string  `json:"reference,omitempty" maxLength:"100" doc:"Invoice number"`
	Description string  `json:"description,omitempty" maxLength:"1000"`
}

type FinRecordBillInput struct {
	Body BillRequest
}

type FinBillData struct {
	Bill *Bill `json:"bill"`
}

type FinBillsData struct {
	Bills []Bill  `json:"bills"`
	Total float64 `json:"total" doc:"Still to pay"`
}

// SupplierPaymentRequest pays a bill or pays over money held.
type SupplierPaymentRequest struct {
	AccountID string  `json:"cash_account_id" doc:"CashAccount the money came from"`
	Amount    float64 `json:"amount" doc:"KES"`
	Date      string  `json:"date,omitempty" doc:"YYYY-MM-DD (default today)"`
	Reference string  `json:"reference,omitempty" maxLength:"100" doc:"M-Pesa, cheque or bank reference"`
	Notes     string  `json:"notes,omitempty" maxLength:"500"`
}

type FinPayBillInput struct {
	ID   string `path:"id" doc:"Bill UUID"`
	Body SupplierPaymentRequest
}

type FinPayOverInput struct {
	ID   string `path:"id" doc:"Supplier UUID"`
	Body SupplierPaymentRequest
}

type FinSupplierPaymentData struct {
	Payment *SupplierPayment `json:"payment"`
}

// --- bank reconciliation ---

type FinAccountIDInput struct {
	ID string `path:"id" doc:"CashAccount UUID"`
}

type FinImportStatementInput struct {
	ID   string `path:"id" doc:"CashAccount UUID"`
	Body StatementRequest
}

type FinStatementIDInput struct {
	ID string `path:"id" doc:"BankStatement UUID"`
}

type FinLineIDInput struct {
	ID string `path:"id" doc:"Statement line UUID"`
}

type FinMatchInput struct {
	ID   string `path:"id" doc:"Statement line UUID"`
	Body struct {
		MatchKey string `json:"match_key" doc:"The cashbook movement's match_key"`
	}
}

type FinStatementsData struct {
	Statements []BankStatement `json:"statements"`
}

type FinReconciliationData struct {
	Reconciliation *Reconciliation `json:"reconciliation"`
}

type FinCandidatesData struct {
	Movements []Movement `json:"movements"`
}

type FinLineData struct {
	Line *BankLine `json:"line"`
}

type FinAutoMatchData struct {
	Matched int `json:"matched"`
}
