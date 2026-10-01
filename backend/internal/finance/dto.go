package finance

import "github.com/codetheuri/tusk/pkg/response"

// CashAccountRequest creates or changes an account; on update only the fields
// sent change.
type CashAccountRequest struct {
	Name           *string  `json:"name,omitempty" doc:"e.g. Petty cash, Equity Bank, M-Pesa till"`
	Kind           *string  `json:"kind,omitempty" enum:"CASH,BANK,MPESA"`
	AccountNumber  *string  `json:"account_number,omitempty" doc:"Bank account, till or paybill number"`
	OpeningBalance *float64 `json:"opening_balance,omitempty" doc:"Money in it on the opening date"`
	OpeningDate    *string  `json:"opening_date,omitempty" doc:"YYYY-MM-DD (default today); earlier movements are not counted"`
	IsActive       *bool    `json:"is_active,omitempty"`
}

type CashCreateAccountInput struct {
	Body CashAccountRequest
}

type CashUpdateAccountInput struct {
	ID   string `path:"id" doc:"CashAccount UUID"`
	Body CashAccountRequest
}

type CashAccountData struct {
	CashAccount *CashAccount `json:"account"`
}

type CashAccountOutput struct {
	Body response.Data[CashAccountData]
}

type CashAccountsData struct {
	Accounts []CashAccount `json:"accounts"`
	Total    float64   `json:"total" doc:"Money in all accounts"`
}

type CashAccountsOutput struct {
	Body response.Data[CashAccountsData]
}

type FinCashbookInput struct {
	ID   string `path:"id" doc:"CashAccount UUID"`
	From string `query:"from" doc:"YYYY-MM-DD (default the 1st of this month)"`
	To   string `query:"to" doc:"YYYY-MM-DD (default today)"`
}

type FinCashbookData struct {
	Cashbook *Cashbook `json:"cashbook"`
}

type FinCashbookOutput struct {
	Body response.Data[FinCashbookData]
}

// FinCategoryRequest creates or changes an expense category.
type FinCategoryRequest struct {
	Name     *string `json:"name,omitempty"`
	IsActive *bool   `json:"is_active,omitempty"`
}

type FinCreateCategoryInput struct {
	Body FinCategoryRequest
}

type FinUpdateCategoryInput struct {
	ID   string `path:"id" doc:"ExpenseCategory UUID"`
	Body FinCategoryRequest
}

type FinCategoryData struct {
	ExpenseCategory *ExpenseCategory `json:"category"`
}

type FinCategoryOutput struct {
	Body response.Data[FinCategoryData]
}

type FinCategoriesData struct {
	Categories []ExpenseCategory `json:"categories"`
}

type FinCategoriesOutput struct {
	Body response.Data[FinCategoriesData]
}

// FinExpenseRequest records an expense.
type FinExpenseRequest struct {
	CategoryID  string  `json:"category_id" doc:"Expense category UUID"`
	AccountID   string  `json:"cash_account_id" doc:"CashAccount the money came from"`
	Amount      float64 `json:"amount" doc:"KES"`
	Payee       string  `json:"payee" maxLength:"150" doc:"Who was paid"`
	Date        string  `json:"date,omitempty" doc:"YYYY-MM-DD (default today)"`
	Reference   string  `json:"reference,omitempty" maxLength:"100" doc:"Receipt, M-Pesa or cheque number"`
	Description string  `json:"description,omitempty" maxLength:"1000"`
}

type FinRecordExpenseInput struct {
	Body FinExpenseRequest
}

type FinListExpensesInput struct {
	From       string `query:"from" doc:"YYYY-MM-DD (default the 1st of this month)"`
	To         string `query:"to" doc:"YYYY-MM-DD (default today)"`
	CategoryID string `query:"category_id"`
	AccountID  string `query:"cash_account_id"`
	Search     string `query:"search" doc:"Payee, description or reference"`
	WithVoided bool   `query:"with_voided"`
}

type FinExpenseData struct {
	Expense *Expense `json:"expense"`
}

type FinExpenseOutput struct {
	Body response.Data[FinExpenseData]
}

type FinExpensesOutput struct {
	Body response.Data[ExpenseList]
}

// FinVoidInput cancels an expense or transfer.
type FinVoidInput struct {
	ID   string `path:"id"`
	Body struct {
		Reason string `json:"reason" minLength:"3" doc:"Why it is cancelled"`
	}
}

// FinTransferRequest moves money between accounts.
type FinTransferRequest struct {
	FromAccountID string  `json:"from_account_id"`
	ToAccountID   string  `json:"to_account_id"`
	Amount        float64 `json:"amount" doc:"KES"`
	Date          string  `json:"date,omitempty" doc:"YYYY-MM-DD (default today)"`
	Reference     string  `json:"reference,omitempty" maxLength:"100"`
	Notes         string  `json:"notes,omitempty" maxLength:"500"`
}

type FinRecordTransferInput struct {
	Body FinTransferRequest
}

type FinListTransfersInput struct {
	From string `query:"from" doc:"YYYY-MM-DD (default the 1st of this month)"`
	To   string `query:"to" doc:"YYYY-MM-DD (default today)"`
}

type FinTransferData struct {
	AccountTransfer *AccountTransfer `json:"transfer"`
}

type FinTransferOutput struct {
	Body response.Data[FinTransferData]
}

type FinTransfersData struct {
	Transfers []AccountTransfer `json:"transfers"`
}

type FinTransfersOutput struct {
	Body response.Data[FinTransfersData]
}

type FinSummaryInput struct {
	From string `query:"from" doc:"YYYY-MM-DD (default the 1st of this month)"`
	To   string `query:"to" doc:"YYYY-MM-DD (default today)"`
}

type FinSummaryData struct {
	FinanceSummary *FinanceSummary `json:"summary"`
}

type FinSummaryOutput struct {
	Body response.Data[FinSummaryData]
}
