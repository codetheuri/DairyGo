package sms

import (
	"context"
	"fmt"

	"github.com/codetheuri/tusk/pkg/logger"
	"github.com/google/uuid"
)

type ConsoleProvider struct {
	log logger.Logger
}

func NewConsoleProvider(log logger.Logger) *ConsoleProvider {
	return &ConsoleProvider{log: log}
}

func (p *ConsoleProvider) Name() string {
	return "CONSOLE"
}

func (p *ConsoleProvider) Send(ctx context.Context, recipientPhone string, message string) (*SMSResult, error) {
	msgID := uuid.New().String()
	p.log.Info(fmt.Sprintf("[DEV SMS LOG] To: %s | Message ID: %s | Message: %s", recipientPhone, msgID, message))
	return &SMSResult{
		MessageID: msgID,
		Provider:  p.Name(),
		Status:    "SENT",
	}, nil
}
