package sacco

import "github.com/codetheuri/tusk/pkg/authz"

// Sacco module permission constants to prevent raw string typos across handlers.
const (
	PermSaccosCreate       = "saccos.create"
	PermSaccosRead         = "saccos.read"
	PermSaccosUpdate       = "saccos.update"
	PermSaccosUpdateStatus = "saccos.update_status"
	PermSaccoSettingsRead   = "sacco.settings.read"
	PermSaccoSettingsManage = "sacco.settings.manage"
)

// Permissions exported by the sacco module.
var Permissions = []authz.Permission{
	{
		Name:        PermSaccosCreate,
		Description: "Provision new Dairy Saccos (Platform Super User)",
	},
	{
		Name:        PermSaccosRead,
		Description: "View Sacco details and list all Saccos",
	},
	{
		Name:        PermSaccosUpdate,
		Description: "Modify Sacco details",
	},
	{
		Name:        PermSaccosUpdateStatus,
		Description: "Change Sacco status (Active, Inactive, Suspended)",
	},
	{
		Name:        PermSaccoSettingsRead,
		Description: "View Sacco settings",
	},
	{
		Name:        PermSaccoSettingsManage,
		Description: "Configure Sacco operational parameters (currency, cutoff times)",
	},
}

// init registers the module's permissions automatically into the default registry.
func init() {
	authz.Register(Permissions...)
}
