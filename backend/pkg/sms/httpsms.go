package sms

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

type HttpSmsProvider struct {
	apiKey     string
	fromPhone  string
	httpClient *http.Client
}

func NewHttpSmsProvider(apiKey, fromPhone string) *HttpSmsProvider {
	return &HttpSmsProvider{
		apiKey:    apiKey,
		fromPhone: fromPhone,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (p *HttpSmsProvider) Name() string {
	return "HTTPSMS"
}

type httpSmsRequest struct {
	Content string `json:"content"`
	From    string `json:"from"`
	To      string `json:"to"`
}

type httpSmsResponse struct {
	Status  string `json:"status"` // "success" or "error"
	Message string `json:"message"`
	Data    struct {
		ID string `json:"id"`
	} `json:"data"`
}

func (p *HttpSmsProvider) Send(ctx context.Context, recipientPhone string, message string) (*SMSResult, error) {
	if p.apiKey == "" {
		return nil, fmt.Errorf("httpSms API key is not configured")
	}

	payload := httpSmsRequest{
		Content: message,
		From:    p.fromPhone,
		To:      recipientPhone,
	}

	jsonBytes, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to encode httpSms request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://api.httpsms.com/v1/messages/send", bytes.NewBuffer(jsonBytes))
	if err != nil {
		return nil, fmt.Errorf("failed to create httpSms request: %w", err)
	}

	req.Header.Set("x-api-key", p.apiKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	resp, err := p.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("httpSms request failed: %w", err)
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("httpSms returned error status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	var resObj httpSmsResponse
	if err := json.Unmarshal(bodyBytes, &resObj); err == nil && resObj.Data.ID != "" {
		return &SMSResult{
			MessageID: resObj.Data.ID,
			Provider:  p.Name(),
			Status:    "SENT",
		}, nil
	}

	return &SMSResult{
		MessageID: fmt.Sprintf("httpsms-%d", time.Now().UnixNano()),
		Provider:  p.Name(),
		Status:    "SENT",
	}, nil
}
