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
	// The books (migration 00030): the financial year now; the ledger,
	// journals and statements in the next phases.
	PermBooksRead   = "books.read"
	PermBooksManage = "books.manage"
)

// Permissions exported by the finance module.
var Permissions = []authz.Permission{
	{Name: PermRead, Description: "Allows viewing expenses, cash accounts, cashbooks and the income and expenditure"},
	{Name: PermExpensesManage, Description: "Allows recording and voiding expenses, other income, bills and payments to suppliers"},
	{Name: PermAccountsManage, Description: "Allows setting up cash accounts, expense and income categories and moving money between accounts"},
	{Name: PermBooksRead, Description: "Allows viewing the books: financial year, ledger, journals and statements"},
	{Name: PermBooksManage, Description: "Allows keeping the books: setting the financial year, journals and closing periods"},
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

	huma.Register(api, guard.Protected(op("list-income-categories", http.MethodGet, "/income-categories", "Income categories",
		"What other income is grouped by (interest, rent, items sold…)."), PermRead), h.IncomeCategories)
	huma.Register(api, guard.Protected(op("create-income-category", http.MethodPost, "/income-categories", "Add an income category", ""), PermAccountsManage), h.CreateIncomeCategory)
	huma.Register(api, guard.Protected(op("update-income-category", http.MethodPut, "/income-categories/{id}", "Rename or switch off an income category", ""), PermAccountsManage), h.UpdateIncomeCategory)

	huma.Register(api, guard.Protected(op("list-other-income", http.MethodGet, "/other-income", "Other income",
		"Money received besides milk sales over a period (default this month), with the total and totals by category."), PermRead), h.OtherIncome)
	huma.Register(api, guard.Protected(op("record-other-income", http.MethodPost, "/other-income", "Record other income",
		"Interest, rent, items sold, a grant… received into one of the Sacco's accounts."), PermExpensesManage), h.RecordIncome)
	huma.Register(api, guard.Protected(op("void-other-income", http.MethodPost, "/other-income/{id}/void", "Void other income", "Recorded in error; it stays on record."), PermExpensesManage), h.VoidIncome)

	// The deduction screen picks who a deduction's money goes to, so those
	// who set up deductions can list (and add) suppliers too.
	listSuppliers := op("list-suppliers", http.MethodGet, "/suppliers", "Suppliers",
		"Who the Sacco pays, with each one's unpaid bills and the money held for them from farmers' deductions.")
	listSuppliers.Security = authz.BearerSecurity
	listSuppliers.Middlewares = huma.Middlewares{guard.RequireAny(PermRead, "payouts.deductions.manage")}
	huma.Register(api, listSuppliers, h.Suppliers)
	addSupplier := op("create-supplier", http.MethodPost, "/suppliers", "Add a supplier", "")
	addSupplier.Security = authz.BearerSecurity
	addSupplier.Middlewares = huma.Middlewares{guard.RequireAny(PermExpensesManage, "payouts.deductions.manage")}
	huma.Register(api, addSupplier, h.CreateSupplier)
	huma.Register(api, guard.Protected(op("update-supplier", http.MethodPut, "/suppliers/{id}", "Change a supplier", ""), PermExpensesManage), h.UpdateSupplier)
	huma.Register(api, guard.Protected(op("get-supplier", http.MethodGet, "/suppliers/{id}", "A supplier",
		"Their bills with what is paid, payments made, and what deductions took for them by pay run."), PermRead), h.SupplierDetail)
	huma.Register(api, guard.Protected(op("pay-over", http.MethodPost, "/suppliers/{id}/pay-over", "Pay over money held",
		"Pays a supplier money taken from farmers' pay for them; no more than is held."), PermExpensesManage), h.PayOver)

	huma.Register(api, guard.Protected(op("list-unpaid-bills", http.MethodGet, "/bills", "Bills to pay",
		"Every supplier's bills not yet fully paid, with what is left."), PermRead), h.UnpaidBills)
	huma.Register(api, guard.Protected(op("record-bill", http.MethodPost, "/bills", "Record a bill",
		"Something bought now and paid later; it counts as spending on its date."), PermExpensesManage), h.RecordBill)
	huma.Register(api, guard.Protected(op("void-bill", http.MethodPost, "/bills/{id}/void", "Void a bill", "Only once its payments are voided."), PermExpensesManage), h.VoidBill)
	huma.Register(api, guard.Protected(op("pay-bill", http.MethodPost, "/bills/{id}/pay", "Pay a bill",
		"In full or in part, from one of the Sacco's accounts."), PermExpensesManage), h.PayBill)
	huma.Register(api, guard.Protected(op("void-supplier-payment", http.MethodPost, "/supplier-payments/{id}/void", "Void a payment to a supplier",
		"The bill is unpaid again, or the money is held again."), PermExpensesManage), h.VoidSupplierPayment)

	// Anyone who records money chooses the account it went through, so the
	// list (names and kinds, no balances) is open to each of them.
	anyRecorder := op("cash-account-choices", http.MethodGet, "/cash-accounts/choices", "Accounts to choose from",
		"The accounts in use (no balances) and, for each kind (CASH, MPESA, BANK), the one money paid that way goes to when none is chosen.")
	anyRecorder.Security = authz.BearerSecurity
	anyRecorder.Middlewares = huma.Middlewares{guard.RequireAny(PermRead, "customers.payments.manage", "milk.sales.create",
		"payouts.advances.manage", "payouts.runs.pay")}
	huma.Register(api, anyRecorder, h.AccountChoices)

	yearRead := op("financial-year", http.MethodGet, "/financial-year", "Financial year",
		"The month the Sacco's financial year starts, and this and last financial year's dates.")
	yearRead.Security = authz.BearerSecurity
	yearRead.Middlewares = huma.Middlewares{guard.RequireAny(PermRead, PermBooksRead, "sacco.settings.read")}
	huma.Register(api, yearRead, h.FinancialYear)
	huma.Register(api, guard.Protected(op("set-financial-year", http.MethodPut, "/financial-year", "Change the financial year",
		"Only groups dates for reports; no record changes."), PermBooksManage), h.SetFinancialYear)

	huma.Register(api, guard.Protected(op("finance-summary", http.MethodGet, "/finance/summary", "Income and expenditure",
		"For a period: milk sales and purchases, fees and charges kept, expenses by category and the surplus; and now: cash, what customers owe, farmers' pay due, what farmers owe and share capital."), PermRead), h.Summary)
}
