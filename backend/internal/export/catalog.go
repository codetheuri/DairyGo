// Package export turns a Sacco's records into downloadable reports (PDF or
// Excel). The work is done on the server: the app asks for a report and a
// period and receives a finished file, so phones stay fast.
//
// Each report reuses the permission that already guards its data, and
// collectors who see only their own records get only their own rows.
package export

import (
	"github.com/codetheuri/tusk/internal/collection"
	"github.com/codetheuri/tusk/internal/customer"
	"github.com/codetheuri/tusk/internal/finance"
	"github.com/codetheuri/tusk/internal/ledger"
	"github.com/codetheuri/tusk/internal/payout"
	"github.com/codetheuri/tusk/internal/report"
)

// Needs says what a report asks for besides the period.
type Needs string

const (
	NeedsNothing  Needs = ""
	NeedsFarmer   Needs = "farmer"   // one farmer (member_id)
	NeedsCustomer Needs = "customer" // one customer (customer_id)
)

// Report is one report that can be downloaded.
type Report struct {
	Key         string `json:"key"`
	Title       string `json:"title"`
	Description string `json:"description"`
	// Needs a farmer or customer to be chosen.
	Needs Needs `json:"needs,omitempty"`
	// AsAt reports show the position today and take no period.
	AsAt bool `json:"as_at,omitempty"`
	// CollectorFilter: can be limited to one collector.
	CollectorFilter bool `json:"collector_filter,omitempty"`
	// StatusFilter: can be limited to farmers of one status.
	StatusFilter bool `json:"status_filter,omitempty"`
	// AtEnd reports show balances on one day: the last day of the period
	// chosen (the balance sheet, the trial balance).
	AtEnd bool `json:"at_end,omitempty"`
	// Formats the report comes in; empty means pdf and xlsx.
	Formats []Format `json:"formats,omitempty"`

	permission string
	landscape  bool
	build      builder
}

// catalog lists the reports in the order people look for them.
var catalog = []Report{
	{
		Key: "farmer-payouts", Title: "Farmers' Milk Value",
		Description: "Each farmer's milk and its value for any dates, before deductions. Not for paying: pay from the pay run's Bank or M-Pesa list.",
		permission:  report.PermReportsPayoutRead, landscape: true, build: farmerPayouts,
	},
	{
		Key: "farmer-statement", Title: "Farmer Statement",
		Description: "Every delivery by one farmer, with price and amount. To give to the farmer.",
		Needs:       NeedsFarmer, permission: report.PermReportsPayoutRead, build: farmerStatement,
	},
	{
		Key: "collections", Title: "Milk Collections",
		Description:     "Every intake in the period: farmer, litres, price, amount and collector.",
		CollectorFilter: true, permission: collection.PermMilkCollectionsRead, landscape: true, build: collections,
	},
	{
		Key: "sales", Title: "Milk Sales",
		Description:     "Every sale in the period: customer, litres, price, amount paid and owed.",
		CollectorFilter: true, permission: collection.PermMilkSalesRead, landscape: true, build: sales,
	},
	{
		Key: "customer-statement", Title: "Customer Statement",
		Description: "One customer's sales and payments with the running balance. To send to the customer.",
		Needs:       NeedsCustomer, permission: customer.PermCustomerStatementRead, build: customerStatement,
	},
	{
		Key: "customers-owing", Title: "Customers Owing",
		Description: "Every customer who owes the Sacco money, largest first.",
		AsAt:        true, permission: customer.PermCustomerStatementRead, build: customersOwing,
	},
	{
		Key: "milk-balance", Title: "Milk Balance by Collector",
		Description:     "For each collector: collected, received, sold, transferred, spoiled and not-yet-sold litres.",
		CollectorFilter: true, permission: report.PermReportsCollectorRead, landscape: true, build: milkBalance,
	},
	{
		Key: "sacco-summary", Title: "Sacco Summary",
		Description: "Day by day: milk in and out, cost of milk, sales revenue and margin, with totals.",
		permission:  report.PermReportsReconciliationRead, landscape: true, build: saccoSummary,
	},
	{
		Key: "deductions", Title: "Deductions",
		Description: "What pay runs took from farmers in the period: totals for each deduction (shares, fees, transaction cost…) and each farmer's.",
		permission:  payout.PermRead, landscape: true, build: deductions,
	},
	{
		Key: "farmer-balances", Title: "Farmer Balances",
		Description: "Farmers who owe the Sacco (advances, charges, arrears) or are owed, with their shares.",
		AsAt:        true, permission: payout.PermRead, build: farmerBalances,
	},
	{
		Key: "income-expenditure", Title: "Income and Expenditure",
		Description: "Milk sales and purchases, fees and charges, expenses by category and the surplus; with cash, debts and shares now.",
		permission:  finance.PermRead, build: incomeExpenditure,
	},
	{
		Key: "suppliers-owed", Title: "Owed to Suppliers",
		Description: "Each supplier's bills not yet paid, and the money taken from farmers' pay for them still to pay over.",
		AsAt:        true, permission: finance.PermRead, build: suppliersOwed,
	},
	{
		Key: "expenses", Title: "Expenses",
		Description: "Every expense in the period with category, payee, account and reference, and totals by category.",
		permission:  finance.PermRead, landscape: true, build: expenses,
	},
	{
		Key: "cashbooks", Title: "Cashbooks",
		Description: "Money in and out of each account (petty cash, bank, M-Pesa) with running balances.",
		permission:  finance.PermRead, landscape: true, build: cashbooks,
	},
	// The books (phase 3, see docs/books.md): statements, and files for the
	// Sacco's own accounting software.
	{
		Key: "income-statement", Title: "Income Statement",
		Description: "Income less expenses from the books for the period, beside the period before it.",
		permission:  ledger.PermRead, build: incomeStatement,
	},
	{
		Key: "balance-sheet", Title: "Balance Sheet",
		Description: "What the Sacco owns and owes at the end of the period, beside its start.",
		AtEnd:       true, permission: ledger.PermRead, build: balanceSheet,
	},
	{
		Key: "trial-balance", Title: "Trial Balance",
		Description: "Every account's balance at the end of the period, debits and credits in their columns.",
		AtEnd:       true, Formats: []Format{PDF, XLSX, CSV}, permission: ledger.PermRead, build: trialBalance,
	},
	{
		Key: "general-ledger", Title: "General Ledger",
		Description: "Every account's entries in the period with opening and closing balances.",
		Formats:     []Format{PDF, XLSX, CSV}, permission: ledger.PermRead, landscape: true, build: generalLedger,
	},
	{
		Key: "journals", Title: "Journals",
		Description: "Every journal line in the period (date, journal, account code, debit, credit, memo): to import into other accounting software.",
		Formats:     []Format{XLSX, CSV, PDF}, permission: ledger.PermRead, landscape: true, build: journals,
	},
	{
		Key: "chart-of-accounts", Title: "Chart of Accounts",
		Description: "Every account with its code, kind and balance today.",
		AsAt:        true, Formats: []Format{PDF, XLSX, CSV}, permission: ledger.PermRead, build: chartOfAccounts,
	},
	{
		Key: "farmer-register", Title: "Farmer Register",
		Description: "All farmers with contacts, payout details, next of kin and status.",
		AsAt:        true, StatusFilter: true, permission: report.PermReportsPayoutRead, landscape: true, build: farmerRegister,
	},
}

var defaultFormats = []Format{PDF, XLSX}

// FormatsOffered is what the report comes in.
func (r Report) FormatsOffered() []Format {
	if len(r.Formats) == 0 {
		return defaultFormats
	}
	return r.Formats
}

func (r Report) offers(f Format) bool {
	for _, x := range r.FormatsOffered() {
		if x == f {
			return true
		}
	}
	return false
}

func (r Report) formatList() string {
	names := map[Format]string{PDF: "PDF", XLSX: "Excel", CSV: "CSV"}
	out := ""
	list := r.FormatsOffered()
	for i, f := range list {
		switch {
		case i == 0:
		case i == len(list)-1:
			out += " or "
		default:
			out += ", "
		}
		out += names[f]
	}
	return out
}

func findReport(key string) (Report, bool) {
	for _, r := range catalog {
		if r.Key == key {
			return r, true
		}
	}
	return Report{}, false
}
