package collection

import (
	"errors"
	"testing"
	"time"
)

func TestRecordDay(t *testing.T) {
	day := func(s string) time.Time { d, _ := time.Parse(dateLayout, s); return d }
	reason := func(s string) *string { return &s }
	const today = "2026-10-02"
	tests := []struct {
		name      string
		day       string
		platform  bool
		reason    *string
		wantLate  bool
		wantErr   bool
		forbidden bool
	}{
		{name: "today, staff", day: today},
		{name: "today, support", day: today, platform: true},
		{name: "future, staff", day: "2026-10-03", wantErr: true},
		{name: "future, support", day: "2026-10-03", platform: true, reason: reason("phone off"), wantErr: true},
		{name: "yesterday, staff", day: "2026-10-01", wantErr: true, forbidden: true},
		{name: "yesterday, staff with a reason", day: "2026-10-01", reason: reason("phone off"), wantErr: true, forbidden: true},
		{name: "yesterday, support with a reason", day: "2026-10-01", platform: true, reason: reason("Collector's phone was off"), wantLate: true},
		{name: "yesterday, support without a reason", day: "2026-10-01", platform: true, wantErr: true},
		{name: "yesterday, support, blank reason", day: "2026-10-01", platform: true, reason: reason("  "), wantErr: true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			why, err := recordDay(day(tt.day), today, tt.platform, tt.reason, "milk")
			if (err != nil) != tt.wantErr {
				t.Fatalf("err = %v, wantErr %v", err, tt.wantErr)
			}
			if tt.forbidden != errors.Is(err, ErrForbidden) {
				t.Errorf("forbidden = %v, want %v (%v)", errors.Is(err, ErrForbidden), tt.forbidden, err)
			}
			if (why != nil) != tt.wantLate {
				t.Errorf("late = %v, want %v", why, tt.wantLate)
			}
		})
	}
}
