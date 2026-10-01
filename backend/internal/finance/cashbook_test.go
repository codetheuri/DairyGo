package finance

import (
	"testing"
	"time"
)

func day(d int) time.Time { return time.Date(2026, 10, d, 0, 0, 0, 0, time.UTC) }

func TestBuildCashbook(t *testing.T) {
	at := func(h int) time.Time { return day(1).Add(time.Duration(h) * time.Hour) }
	moves := []Movement{
		{Source: SrcExpense, Date: day(5), CreatedAt: at(2), Out: 1500},
		{Source: SrcCustomerPayment, Date: day(5), CreatedAt: at(1), In: 10000},
		{Source: SrcTransferIn, Date: day(2), CreatedAt: at(1), In: 3000}, // before the period
		{Source: SrcFarmerPay, Date: day(9), CreatedAt: at(9), Out: 9000.555},
	}
	open, lines, in, out, closing := buildCashbook(500, day(3), moves)
	if open != 3500 {
		t.Errorf("opening = %v, want 500 + 3000 before the period", open)
	}
	if len(lines) != 3 || lines[0].Source != SrcCustomerPayment || lines[1].Source != SrcExpense {
		t.Fatalf("lines out of order: %+v", lines)
	}
	if lines[0].Balance != 13500 || lines[1].Balance != 12000 {
		t.Errorf("running balances = %v, %v", lines[0].Balance, lines[1].Balance)
	}
	if in != 10000 || out != 10500.56 || closing != 2999.44 {
		t.Errorf("in %v out %v closing %v", in, out, closing)
	}
	if round2(open+in-out) != closing {
		t.Errorf("opening + in − out = %v, closing %v", open+in-out, closing)
	}
}

func TestBuildCashbookEmptyPeriod(t *testing.T) {
	open, lines, _, _, closing := buildCashbook(100, day(10), []Movement{{Date: day(2), In: 50}})
	if open != 150 || closing != 150 || len(lines) != 0 {
		t.Errorf("open %v closing %v lines %d", open, closing, len(lines))
	}
}
