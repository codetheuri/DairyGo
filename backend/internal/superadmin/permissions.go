package superadmin

import "github.com/codetheuri/tusk/pkg/authz"

// PermPlatformManage guards every platform console endpoint. No Sacco role is
// granted it (migration 00013), so only platform super users, who bypass
// permission checks, can call these endpoints.
const PermPlatformManage = "platform.manage"

// Permissions exported by the platform console module.
var Permissions = []authz.Permission{
	{Name: PermPlatformManage, Description: "Platform console: manage all Saccos, their staff and farmers, and review logs"},
}

func init() {
	authz.Register(Permissions...)
}
