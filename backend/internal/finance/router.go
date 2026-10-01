package finance

import (
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/logger"
)

const tag = "Finance"

// Finance permissions. Grants for the Sacco roles are in migration 00023.
const (
	PermRead           = "finance.read"
	PermExpensesManage = "finance.expenses.manage"
	PermAccountsManage = "finance.accounts.manage"
)

// Permissions exported by the finance module.
var Permissions = []authz.Permission{
	{Name: PermRead, Description: "Allows viewing expenses, cash accounts, cashbooks and the income and expenditure"},
	{Name: PermExpensesManage, Description: "Allows recording and voiding expenses"},
	{Name: PermAccountsManage, Description: "Allows setting up cash accounts and expense categories and moving money between accounts"},
}

func init() {
	authz.Register(Permissions...)
}

// RegisterRoutes wires the finance module's endpoints.
func RegisterRoutes(api huma.API, db *gorm.DB, _ *config.Config, log logger.Logger) {
	h := NewHandler(NewService(NewRepository(db)), log)
	guard := authz.NewGuard(api, db)
	op := func(id, method, path, summary, desc string) huma.Operation {
		return huma.Operation{OperationID: id, Method: method, Path: "/api/v1/sacco" + path, Summary: summary, Description: desc, Tags: []string{tag}}
	}

	huma.Register(api, guard.Protected(op("list-cash-accounts", http.MethodGet, "/cash-accounts", "Accounts",
		"Where the Sacco keeps money (petty cash, bank, M-Pesa) with each balance now."), PermRead), h.Accounts)
	huma.Register(api, guard.Protected(op("create-cash-account", http.MethodPost, "/cash-accounts", "Add an account",
		"With its opening balance and date; movements before that date are not counted."), PermAccountsManage), h.CreateAccount)
	huma.Register(api, guard.Protected(op("update-cash-account", http.MethodPut, "/cash-accounts/{id}", "Change an account", ""), PermAccountsManage), h.UpdateAccount)
	huma.Register(api, guard.Protected(op("cash-account-cashbook", http.MethodGet, "/cash-accounts/{id}/cashbook", "Cashbook",
		"Every shilling in and out of the account over a period with the running balance: customer payments, cash at sales, transfers, expenses, advances and farmers' pay."), PermRead), h.Cashbook)

	huma.Register(api, guard.Protected(op("list-expense-categories", http.MethodGet, "/expense-categories", "Expense categories", ""), PermRead), h.Categories)
	huma.Register(api, guard.Protected(op("create-expense-category", http.MethodPost, "/expense-categories", "Add a category", ""), PermAccountsManage), h.CreateCategory)
	huma.Register(api, guard.Protected(op("update-expense-category", http.MethodPut, "/expense-categories/{id}", "Rename or switch off a category", ""), PermAccountsManage), h.UpdateCategory)

	huma.Register(api, guard.Protected(op("list-expenses", http.MethodGet, "/expenses", "Expenses",
		"Over a period (default this month) with the total and totals by category."), PermRead), h.Expenses)
	huma.Register(api, guard.Protected(op("record-expense", http.MethodPost, "/expenses", "Record an expense",
		"Salaries, petty cash spending, rent, fuel… paid from one of the Sacco's accounts."), PermExpensesManage), h.RecordExpense)
	huma.Register(api, guard.Protected(op("void-expense", http.MethodPost, "/expenses/{id}/void", "Void an expense", "Recorded in error; it stays on record."), PermExpensesManage), h.VoidExpense)

	huma.Register(api, guard.Protected(op("list-account-transfers", http.MethodGet, "/account-transfers", "Money moved between accounts", ""), PermRead), h.Transfers)
	huma.Register(api, guard.Protected(op("record-account-transfer", http.MethodPost, "/account-transfers", "Move money between accounts",
		"E.g. top up petty cash from the bank, or bank the day's cash."), PermAccountsManage), h.RecordTransfer)
	huma.Register(api, guard.Protected(op("void-account-transfer", http.MethodPost, "/account-transfers/{id}/void", "Void a transfer", ""), PermAccountsManage), h.VoidTransfer)

	huma.Register(api, guard.Protected(op("finance-summary", http.MethodGet, "/finance/summary", "Income and expenditure",
		"For a period: milk sales and purchases, fees and charges kept, expenses by category and the surplus; and now: cash, what customers owe, farmers' pay due, what farmers owe and share capital."), PermRead), h.Summary)
}
