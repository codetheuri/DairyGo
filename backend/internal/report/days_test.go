package report

import (
	"testing"
	"time"

	"github.com/codetheuri/tusk/pkg/reconcile"
)

func TestMergeDays(t *testing.T) {
	d := func(day int) time.Time { return time.Date(2026, 10, day, 0, 0, 0, 0, time.Local) }
	intake := []dayFlows{{Day: d(2), Litres: 100, Collectors: 2}, {Day: d(1), Litres: 50, Collectors: 1}}
	sales := []dayFlows{{Day: d(1), Litres: 49.5, Amount: 2970}, {Day: d(2), Litres: 60, Amount: 3600}, {Day: d(3), Litres: 5, Amount: 300}}
	spoilage := []dayFlows{{Day: d(2), Litres: 2}}

	days := mergeDays(intake, sales, spoilage, 1)
	if len(days) != 3 {
		t.Fatalf("got %d days, want 3", len(days))
	}
	want := []struct {
		date   string
		status reconcile.Status
		left   float64
	}{
		{"2026-10-01", reconcile.StatusBalanced, 0.5}, // 0.5 L within 1 L for one collector
		{"2026-10-02", reconcile.StatusMissing, 38},   // 100 - 60 - 2
		{"2026-10-03", reconcile.StatusOversold, -5},  // sold milk no one collected that day
	}
	for i, w := range want {
		got := days[i]
		if got.Date != w.date || got.Status != w.status || got.UnaccountedLitres != w.left {
			t.Errorf("day %d = %s %s %.2f, want %s %s %.2f", i, got.Date, got.Status, got.UnaccountedLitres, w.date, w.status, w.left)
		}
	}
	if days[1].AllowanceLitres != 2 {
		t.Errorf("allowance on a two-collector day = %.2f, want 2", days[1].AllowanceLitres)
	}
	if days[1].SalesKES != 3600 || days[1].SpoiledLitres != 2 {
		t.Errorf("day 2 = %+v", days[1])
	}
}
