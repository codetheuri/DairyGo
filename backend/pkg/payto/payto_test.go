package payto

import "testing"

func TestDetails(t *testing.T) {
	s := func(v string) *string { return &v }
	tests := []struct {
		name  string
		d     Details
		ready bool
		says  string
	}{
		{"M-Pesa on the phone", Details{Method: MPesa, Phone: "0712345678"}, true, "M-Pesa 0712345678"},
		{"own M-Pesa number first", Details{Method: MPesa, Phone: "0712345678", MpesaNumber: s("0722000111")}, true, "M-Pesa 0722000111"},
		{"no phone", Details{Method: MPesa}, false, "M-Pesa: number missing"},
		{"bank", Details{Method: Bank, Phone: "0712345678", BankName: s("Equity"), Account: s("0160123"), Branch: s("Rumuruti")}, true, "Equity 0160123 Rumuruti"},
		{"bank without account never falls back to M-Pesa", Details{Method: Bank, Phone: "0712345678"}, false, "Bank: account missing"},
		{"unknown method is M-Pesa", Details{Method: "", Phone: "0712345678"}, true, "M-Pesa 0712345678"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.d.Ready(); got != tt.ready {
				t.Errorf("Ready = %v, want %v", got, tt.ready)
			}
			if got := tt.d.Describe(); got != tt.says {
				t.Errorf("Describe = %q, want %q", got, tt.says)
			}
		})
	}
}
