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

	permission string
	landscape  bool
	build      builder
}

// catalog lists the reports in the order people look for them.
var catalog = []Report{
	{
		Key: "farmer-payouts", Title: "Farmer Payouts",
		Description: "What each farmer is owed for the period, with M-Pesa or bank details, for paying farmers.",
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
		Description:     "For each collector: collected, received, sold, transferred, spoiled and unaccounted litres.",
		CollectorFilter: true, permission: report.PermReportsCollectorRead, landscape: true, build: milkBalance,
	},
	{
		Key: "sacco-summary", Title: "Sacco Summary",
		Description: "Day by day: milk in and out, cost of milk, sales revenue and margin, with totals.",
		permission:  report.PermReportsReconciliationRead, landscape: true, build: saccoSummary,
	},
	{
		Key: "farmer-register", Title: "Farmer Register",
		Description: "All farmers with contacts, payout details, next of kin and status.",
		AsAt:        true, StatusFilter: true, permission: report.PermReportsPayoutRead, landscape: true, build: farmerRegister,
	},
}

func findReport(key string) (Report, bool) {
	for _, r := range catalog {
		if r.Key == key {
			return r, true
		}
	}
	return Report{}, false
}
