package sms

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type AfricasTalkingProvider struct {
	username   string
	apiKey     string
	senderID   string
	isSandbox  bool
	httpClient *http.Client
}

func NewAfricasTalkingProvider(username, apiKey, senderID string, isSandbox bool) *AfricasTalkingProvider {
	return &AfricasTalkingProvider{
		username:  username,
		apiKey:    apiKey,
		senderID:  senderID,
		isSandbox: isSandbox,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (p *AfricasTalkingProvider) Name() string {
	return "AFRICAS_TALKING"
}

func (p *AfricasTalkingProvider) Send(ctx context.Context, recipientPhone string, message string) (*SMSResult, error) {
	apiKey := strings.TrimSpace(p.apiKey)
	username := strings.TrimSpace(p.username)

	if apiKey == "" || username == "" {
		return nil, fmt.Errorf("Africa's Talking credentials are not configured")
	}

	apiURL := "https://api.africastalking.com/version1/messaging"
	if p.isSandbox {
		apiURL = "https://api.sandbox.africastalking.com/version1/messaging"
	}

	form := url.Values{}
	form.Set("username", username)
	form.Set("to", recipientPhone)
	form.Set("message", message)
	
	// Only set 'from' if a custom Sender ID is explicitly configured
	if senderID := strings.TrimSpace(p.senderID); senderID != "" {
		form.Set("from", senderID)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, apiURL, strings.NewReader(form.Encode()))
	if err != nil {
		return nil, fmt.Errorf("failed to create Africa's Talking request: %w", err)
	}

	// Set header for Africa's Talking authentication
	req.Header.Set("apiKey", apiKey)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Accept", "application/json")

	resp, err := p.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("Africa's Talking request failed: %w", err)
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		keyHint := ""
		if len(apiKey) > 8 {
			keyHint = apiKey[:4] + "..." + apiKey[len(apiKey)-4:]
		}
		return nil, fmt.Errorf("Africa's Talking error status %d: %s (Username: '%s', KeyHint: '%s', Sandbox: %t, URL: %s)", resp.StatusCode, string(bodyBytes), username, keyHint, p.isSandbox, apiURL)
	}

	var atResp struct {
		SMSMessageData struct {
			Message    string `json:"Message"`
			Recipients []struct {
				StatusCode int    `json:"statusCode"`
				Number     string `json:"number"`
				MessageId  string `json:"messageId"`
				Status     string `json:"status"`
				Cost       string `json:"cost"`
			} `json:"Recipients"`
		} `json:"SMSMessageData"`
	}

	if err := json.Unmarshal(bodyBytes, &atResp); err != nil {
		return nil, fmt.Errorf("failed to parse Africa's Talking response: %s", string(bodyBytes))
	}

	if len(atResp.SMSMessageData.Recipients) == 0 {
		return nil, fmt.Errorf("Africa's Talking dispatch failed: %s", atResp.SMSMessageData.Message)
	}

	rec := atResp.SMSMessageData.Recipients[0]
	if rec.Status != "Success" && rec.Status != "Processed" && rec.Status != "Sent" {
		return nil, fmt.Errorf("Africa's Talking recipient error [%s]: %s (Status Code: %d)", rec.Status, atResp.SMSMessageData.Message, rec.StatusCode)
	}

	return &SMSResult{
		MessageID: rec.MessageId,
		Provider:  p.Name(),
		Status:    rec.Status,
		Cost:      rec.Cost,
	}, nil
}
