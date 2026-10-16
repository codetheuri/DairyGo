package collection

import (
	"strings"
	"testing"
)

func TestCheckReassign(t *testing.T) {
	ok := func() *ReassignRequest {
		return &ReassignRequest{FromCollectorID: 7, ToCollectorID: 8, Reason: " Phone was dead ",
			Records: []RecordRef{{RecordIntake, "c1"}, {RecordIntake, "c2"}, {RecordSale, "s1"}, {RecordPayment, "p1"}}}
	}
	tests := []struct {
		name   string
		change func(*ReassignRequest)
		want   string
	}{
		{"fine", func(*ReassignRequest) {}, ""},
		{"no reason", func(r *ReassignRequest) { r.Reason = "  ok " }, "say why"},
		{"no collector", func(r *ReassignRequest) { r.ToCollectorID = 0 }, "choose the account"},
		{"same collector", func(r *ReassignRequest) { r.ToCollectorID = 7 }, "already that collector's"},
		{"nothing chosen", func(r *ReassignRequest) { r.Records = nil }, "at least one"},
		{"transfers stay", func(r *ReassignRequest) { r.Records = []RecordRef{{"TRANSFER", "t1"}} }, "cannot be moved"},
		{"twice", func(r *ReassignRequest) { r.Records = append(r.Records, RecordRef{RecordSale, "s1"}) }, "once"},
		{"same id, other kind", func(r *ReassignRequest) { r.Records = append(r.Records, RecordRef{RecordSpoilage, "s1"}) }, ""},
		{"too many", func(r *ReassignRequest) { r.Records = make([]RecordRef, maxReassign+1) }, "at most"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := ok()
			tt.change(req)
			byKind, why, err := checkReassign(req)
			if tt.want != "" {
				if err == nil || !strings.Contains(err.Error(), tt.want) {
					t.Fatalf("error = %v, want it to mention %q", err, tt.want)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if why != "Phone was dead" {
				t.Errorf("reason = %q, want it trimmed", why)
			}
			if len(byKind[RecordIntake]) != 2 || len(byKind[RecordSale]) != 1 || len(byKind[RecordPayment]) != 1 {
				t.Errorf("grouped = %v", byKind)
			}
		})
	}
}
