package customer

import (
	"testing"
	"time"
)

func TestBuildStatement(t *testing.T) {
	day := func(d int) time.Time { return time.Date(2026, 9, d, 0, 0, 0, 0, time.UTC) }
	at := func(h int) time.Time { return time.Date(2026, 9, 1, h, 0, 0, 0, time.UTC) }

	events := []LedgerEvent{
		// Out of order on purpose: statement must sort by date, then entry time.
		{Kind: EntryPayment, ReferenceID: "p1", Date: day(12), CreatedAt: at(9), Credit: 3000},
		{Kind: EntrySale, ReferenceID: "s1", Date: day(10), CreatedAt: at(8), Litres: 100, Debit: 5000, Credit: 1000},
		{Kind: EntrySale, ReferenceID: "s2", Date: day(12), CreatedAt: at(7), Litres: 40, Debit: 2000},
	}

	lines, debit, credit, closing := buildStatement(500, events)

	wantOrder := []string{"s1", "s2", "p1"}
	wantBalances := []float64{4500, 6500, 3500}
	if len(lines) != 3 {
		t.Fatalf("expected 3 lines, got %d", len(lines))
	}
	for i, l := range lines {
		if l.ReferenceID != wantOrder[i] {
			t.Errorf("line %d: expected %s, got %s", i, wantOrder[i], l.ReferenceID)
		}
		if l.Balance != wantBalances[i] {
			t.Errorf("line %d: expected balance %.2f, got %.2f", i, wantBalances[i], l.Balance)
		}
	}
	if debit != 7000 || credit != 4000 || closing != 3500 {
		t.Errorf("totals: debit %.2f credit %.2f closing %.2f", debit, credit, closing)
	}
}

func TestBuildStatementEmptyKeepsOpening(t *testing.T) {
	lines, debit, credit, closing := buildStatement(1234.5, nil)
	if len(lines) != 0 || debit != 0 || credit != 0 || closing != 1234.5 {
		t.Fatalf("unexpected: %v %v %v %v", lines, debit, credit, closing)
	}
}
