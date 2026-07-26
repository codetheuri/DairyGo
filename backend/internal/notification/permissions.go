package notification

import "github.com/codetheuri/tusk/pkg/authz"

// Notification domain permission constants.
const (
	PermNotificationsSMSSend = "notifications.sms.send"
	PermNotificationsSMSRead = "notifications.sms.read"
)

// Permissions exported by the notification module.
var Permissions = []authz.Permission{
	{
		Name:        PermNotificationsSMSSend,
		Description: "Allows sending custom or broadcast SMS notifications to farmers and staff",
	},
	{
		Name:        PermNotificationsSMSRead,
		Description: "Allows viewing SMS delivery audit logs",
	},
}

// init registers the module's permissions automatically into the default registry.
func init() {
	authz.Register(Permissions...)
}
