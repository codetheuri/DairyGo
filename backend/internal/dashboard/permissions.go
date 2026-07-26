package dashboard

import "github.com/codetheuri/tusk/pkg/authz"

// Dashboard domain permission constants.
const (
	PermDashboardExecutiveRead = "dashboard.executive.read"
	PermDashboardCollectorRead = "dashboard.collector.read"
)

// Permissions exported by the dashboard module.
var Permissions = []authz.Permission{
	{
		Name:        PermDashboardExecutiveRead,
		Description: "Allows viewing Sacco-wide executive summary dashboard cards and trend graphs",
	},
	{
		Name:        PermDashboardCollectorRead,
		Description: "Allows field collectors to view real-time mobile shift metrics",
	},
}

// init registers the module's permissions automatically into the default registry.
func init() {
	authz.Register(Permissions...)
}
