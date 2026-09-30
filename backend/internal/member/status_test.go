package member

import (
	"strings"
	"testing"
)

func TestCheckStatusChange(t *testing.T) {
	tests := []struct {
		name       string
		from, to   Status
		reason     string
		wantReason string
		wantErr    string
	}{
		{"deactivate without a reason", StatusActive, StatusInactive, "", "", ""},
		{"reactivate", StatusSuspended, StatusActive, " Dispute settled ", "Dispute settled", ""},
		{"suspend with a reason", StatusActive, StatusSuspended, "Water in milk", "Water in milk", ""},
		{"suspend an inactive farmer", StatusInactive, StatusSuspended, "Left the Sacco", "Left the Sacco", ""},
		{"suspend needs a reason", StatusActive, StatusSuspended, "  ", "", "give a reason"},
		{"no change", StatusActive, StatusActive, "", "", "already active"},
		{"unknown status", StatusActive, Status("GONE"), "", "", "invalid member status"},
		{"reason too long", StatusActive, StatusInactive, strings.Repeat("x", 501), "", "too long"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			reason, err := checkStatusChange(tt.from, tt.to, tt.reason)
			if tt.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), tt.wantErr) {
					t.Fatalf("err = %v, want it to contain %q", err, tt.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if reason != tt.wantReason {
				t.Errorf("reason = %q, want %q", reason, tt.wantReason)
			}
		})
	}
}
