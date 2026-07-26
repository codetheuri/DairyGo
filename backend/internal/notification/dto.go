package notification

import (
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/response"
	"github.com/codetheuri/tusk/pkg/sms"
)

type SendSMSRequest struct {
	RecipientPhone string `json:"recipient_phone" minLength:"10" doc:"Target recipient phone number (e.g. 0712345678 or +254712345678)"`
	Message        string `json:"message" minLength:"2" doc:"SMS body text"`
}

type SendSMSInput struct {
	Body SendSMSRequest
}

type SendSMSData struct {
	Result *sms.SMSResult `json:"result"`
}

type SendSMSOutput struct {
	Body response.Data[SendSMSData]
}

type ListSMSLogsInput struct {
	Page    int    `query:"page" doc:"Page number"`
	PerPage int    `query:"per_page" doc:"Items per page"`
	Phone   string `query:"phone" doc:"Filter by recipient phone number"`
}

type ListSMSLogsData struct {
	Logs []sms.SMSLog `json:"logs"`
	Meta query.Meta   `json:"meta"`
}

type ListSMSLogsOutput struct {
	Body response.Data[ListSMSLogsData]
}
