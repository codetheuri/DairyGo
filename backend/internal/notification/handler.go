package notification

import (
	"context"

	"github.com/danielgtaylor/huma/v2"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/logger"
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/sms"
)

type Handler struct {
	smsService *sms.Service
	db         *gorm.DB
	log        logger.Logger
}

func NewHandler(smsService *sms.Service, db *gorm.DB, log logger.Logger) *Handler {
	return &Handler{smsService: smsService, db: db, log: log}
}

func (h *Handler) SendSMS(ctx context.Context, input *SendSMSInput) (*SendSMSOutput, error) {
	var saccoIDPtr *string
	if saccoID, ok := middleware.GetSaccoID(ctx); ok && saccoID != "" {
		saccoIDPtr = &saccoID
	}

	result, err := h.smsService.SendSync(ctx, saccoIDPtr, input.Body.RecipientPhone, input.Body.Message)
	if err != nil {
		h.log.Error("SMS dispatch failed", err)
		return nil, huma.Error400BadRequest(err.Error(), err)
	}

	resp := &SendSMSOutput{}
	resp.Body.Success = true
	resp.Body.Message = "SMS sent successfully"
	resp.Body.Data.Result = result
	return resp, nil
}

func (h *Handler) ListSMSLogs(ctx context.Context, input *ListSMSLogsInput) (*ListSMSLogsOutput, error) {
	q := query.Query{
		Page:    input.Page,
		PerPage: input.PerPage,
		Filters: make(map[string]string),
	}
	if input.Phone != "" {
		q.Filters["recipient_phone"] = input.Phone
	}

	cfg := query.Config{
		DefaultSort:    "-created_at",
		DefaultPerPage: 20,
		MaxPerPage:     100,
		AllowedSorts: map[string]string{
			"created_at": "sms_logs.created_at",
		},
		AllowedSearches: []string{"sms_logs.recipient_phone", "sms_logs.message"},
		AllowedFilters: map[string]string{
			"recipient_phone": "sms_logs.recipient_phone",
			"provider":        "sms_logs.provider",
			"status":          "sms_logs.status",
		},
	}

	session := h.db.Model(&sms.SMSLog{}).Scopes(query.TenantScope(ctx))
	logs, meta, err := query.Paginate[sms.SMSLog](ctx, session, q, cfg)
	if err != nil {
		return nil, huma.Error500InternalServerError("Failed to retrieve SMS logs", err)
	}

	resp := &ListSMSLogsOutput{}
	resp.Body.Success = true
	resp.Body.Message = "SMS logs retrieved successfully"
	resp.Body.Data.Logs = logs
	resp.Body.Data.Meta = meta
	return resp, nil
}
