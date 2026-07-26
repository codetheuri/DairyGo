package sms

import (
	"context"
	"strings"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/pkg/logger"
)

type Service struct {
	cfg            *config.Config
	db             *gorm.DB
	log            logger.Logger
	defaultDriver Provider
}

func NewService(cfg *config.Config, db *gorm.DB, log logger.Logger) *Service {
	s := &Service{
		cfg: cfg,
		db:  db,
		log: log,
	}

	// Initialize default provider driver based on environment config
	providerType := strings.ToUpper(cfg.SMSProvider)
	switch providerType {
	case "HTTPSMS":
		s.defaultDriver = NewHttpSmsProvider(cfg.HttpSMSAPIKey, cfg.HttpSMSFromPhone)
	case "AFRICAS_TALKING":
		s.defaultDriver = NewAfricasTalkingProvider(cfg.ATUsername, cfg.ATAPIKey, cfg.ATSenderID, cfg.ATIsSandbox)
	default:
		s.defaultDriver = NewConsoleProvider(log)
	}

	return s
}

// SendSync sends an SMS message synchronously and returns execution result.
func (s *Service) SendSync(ctx context.Context, saccoID *string, recipientPhone, message string) (*SMSResult, error) {
	phone := sanitizePhone(recipientPhone)

	res, err := s.defaultDriver.Send(ctx, phone, message)
	status := "SENT"
	var errorMsg *string

	if err != nil {
		status = "FAILED"
		msg := err.Error()
		errorMsg = &msg
		s.log.Error("[SMS FAILURE] Failed to deliver SMS to "+phone, err)
	}

	// Write audit log entry into sms_logs table
	logEntry := SMSLog{
		ID:             uuid.New().String(),
		SaccoID:        saccoID,
		RecipientPhone: phone,
		Message:        message,
		Provider:       s.defaultDriver.Name(),
		Status:         status,
		ErrorMessage:   errorMsg,
	}

	if s.db != nil {
		_ = s.db.Create(&logEntry)
	}

	return res, err
}

// SendAsync dispatches SMS in a background goroutine so application HTTP requests are never blocked.
func (s *Service) SendAsync(saccoID *string, recipientPhone, message string) {
	go func() {
		ctx := context.Background()
		_, _ = s.SendSync(ctx, saccoID, recipientPhone, message)
	}()
}

// Helper to sanitize phone numbers into E.164 international format (e.g. 0712345678 -> +254712345678)
func sanitizePhone(phone string) string {
	phone = strings.TrimSpace(phone)
	phone = strings.ReplaceAll(phone, " ", "")
	phone = strings.ReplaceAll(phone, "-", "")

	if strings.HasPrefix(phone, "0") {
		return "+254" + phone[1:]
	}
	if strings.HasPrefix(phone, "254") {
		return "+" + phone
	}
	return phone
}
