package notification

import (
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/logger"
	"github.com/codetheuri/tusk/pkg/sms"
)

func RegisterRoutes(api huma.API, db *gorm.DB, cfg *config.Config, log logger.Logger) {
	smsService := sms.NewService(cfg, db, log)
	handler := NewHandler(smsService, db, log)

	guard := authz.NewGuard(api, db)

	// -------------------------------------------------------------
	// PLUGGABLE SMS NOTIFICATION ENDPOINTS
	// -------------------------------------------------------------

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "send-sms-notification",
		Method:      http.MethodPost,
		Path:        "/api/v1/sacco/notifications/sms/send",
		Summary:     "Send SMS Notification",
		Description: "Dispatches an SMS notification to a recipient using the configured provider driver (httpSMS Android SIM Gateway, Africa's Talking, or Console).",
		Tags:        []string{"SMS Notifications"},
	}, PermNotificationsSMSSend), handler.SendSMS)

	huma.Register(api, guard.Protected(huma.Operation{
		OperationID: "list-sms-logs",
		Method:      http.MethodGet,
		Path:        "/api/v1/sacco/notifications/sms/logs",
		Summary:     "List SMS Delivery Logs",
		Description: "Returns a paginated log of dispatched SMS messages and delivery statuses for the Sacco.",
		Tags:        []string{"SMS Notifications"},
	}, PermNotificationsSMSRead), handler.ListSMSLogs)
}
