package member

import "github.com/codetheuri/tusk/pkg/authz"

// Member module permission constants.
const (
	PermMembersRead         = "members.read"
	PermMembersCreate       = "members.create"
	PermMembersUpdate       = "members.update"
	PermMembersUpdateStatus = "members.update_status"
)

// Permissions exported by the member module.
var Permissions = []authz.Permission{
	{
		Name:        PermMembersRead,
		Description: "Allows viewing member/farmer profiles and list",
	},
	{
		Name:        PermMembersCreate,
		Description: "Allows registering new members/farmers",
	},
	{
		Name:        PermMembersUpdate,
		Description: "Allows updating member/farmer details and payment info",
	},
	{
		Name:        PermMembersUpdateStatus,
		Description: "Allows changing member status (Active, Inactive, Suspended)",
	},
}

// init registers the module's permissions automatically into the default registry.
func init() {
	authz.Register(Permissions...)
}
