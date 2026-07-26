package sms

import (
	"context"
	"time"
)

// SMSResult contains execution output from an SMS provider driver.
type SMSResult struct {
	MessageID string `json:"message_id"`
	Provider  string `json:"provider"`
	Status    string `json:"status"` // SENT, QUEUED, FAILED
	Cost      string `json:"cost,omitempty"`
	Error     string `json:"error,omitempty"`
}

// SMSLog represents an audit log entry in the sms_logs table.
type SMSLog struct {
	ID             string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID        *string   `json:"sacco_id,omitempty" gorm:"index;type:varchar(36)"`
	RecipientPhone string    `json:"recipient_phone" gorm:"index;not null"`
	Message        string    `json:"message" gorm:"type:text;not null"`
	Provider       string    `json:"provider" gorm:"not null"`
	Status         string    `json:"status" gorm:"default:'SENT'"`
	ErrorMessage   *string   `json:"error_message,omitempty"`
	CreatedAt      time.Time `json:"created_at"`
}

func (SMSLog) TableName() string {
	return "sms_logs"
}

// Provider interface defines the driver contract for pluggable SMS services.
type Provider interface {
	Name() string
	Send(ctx context.Context, recipientPhone string, message string) (*SMSResult, error)
}
