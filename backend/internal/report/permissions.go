package report

import "github.com/codetheuri/tusk/pkg/authz"

// Report domain permission constants.
const (
	PermReportsPayoutRead         = "reports.payout.read"
	PermReportsReconciliationRead = "reports.reconciliation.read"
	PermReportsCollectorRead      = "reports.collector.read"
)

// Permissions exported by the report module.
var Permissions = []authz.Permission{
	{
		Name:        PermReportsPayoutRead,
		Description: "Allows viewing farmer payroll and payout statement reports",
	},
	{
		Name:        PermReportsReconciliationRead,
		Description: "Allows viewing Sacco-wide intake vs field sales vs spoilage balancing ledgers",
	},
	{
		Name:        PermReportsCollectorRead,
		Description: "Allows viewing collector audit and transit performance reports",
	},
}

// init registers the module's permissions automatically into the default registry.
func init() {
	authz.Register(Permissions...)
}
