package ledger

import (
	"testing"
	"time"
)

func day(s string) time.Time {
	d, _ := time.Parse(dateLayout, s)
	return d
}

func ptr(s string) *string { return &s }

// one is the single posting a record makes, failing when it makes another
// number or the posting does not balance.
func one(t *testing.T, rec record) posting {
	t.Helper()
	if len(rec.postings) != 1 {
		t.Fatalf("want 1 posting, got %d", len(rec.postings))
	}
	p := rec.postings[0]
	if !balanced(p.lines) {
		t.Fatalf("posting does not balance: %+v", p.lines)
	}
	return p
}

func wantNets(t *testing.T, got map[string]float64, want map[string]float64) {
	t.Helper()
	if len(got) != len(want) {
		t.Fatalf("lines = %v, want %v", got, want)
	}
	for k, v := range want {
		if !same(got[k], v) {
			t.Fatalf("%s = %.2f, want %.2f (all: %v)", k, got[k], v, got)
		}
	}
}

var ci = cashInfo{"petty": day("2026-10-01"), "bank": day("2026-01-01")}

func TestSaleRule(t *testing.T) {
	// Part paid in cash: the rest is owed.
	p := one(t, saleRule(saleRow{ID: "s1", SaleDate: day("2026-10-05"), BuyerName: "Hotel", Litres: 10, Total: 600, Paid: 200, AccountID: ptr("petty")}, ci))
	wantNets(t, nets(p.lines), map[string]float64{"role:CUSTOMERS": 400, "cash_account:petty": 200, "role:MILK_SALES": -600})
	if p.memo != "Milk sale: Hotel, 10 L" {
		t.Fatalf("memo %q", p.memo)
	}

	// On credit: all owed, no cash line.
	p = one(t, saleRule(saleRow{ID: "s2", SaleDate: day("2026-10-05"), BuyerName: "Shop", Litres: 2.5, Total: 150}, ci))
	wantNets(t, nets(p.lines), map[string]float64{"role:CUSTOMERS": 150, "role:MILK_SALES": -150})

	// Paid with no account named.
	p = one(t, saleRule(saleRow{ID: "s3", SaleDate: day("2026-10-05"), Total: 100, Paid: 100}, ci))
	wantNets(t, nets(p.lines), map[string]float64{"role:NO_ACCOUNT": 100, "role:MILK_SALES": -100})

	// Voided: nothing, but the date is known.
	rec := saleRule(saleRow{ID: "s4", SaleDate: day("2026-09-01"), Total: 100, Voided: true}, ci)
	if len(rec.postings) != 0 || !rec.date.Equal(day("2026-09-01")) {
		t.Fatalf("voided sale: %+v", rec)
	}
}

func TestCashBeforeOpeningDate(t *testing.T) {
	// Money into petty cash before it was opened is in its opening balance.
	p := one(t, paymentRule(paymentRow{ID: "p1", PaymentDate: day("2026-09-30"), Customer: "Hotel", Amount: 500, AccountID: ptr("petty")}, ci))
	wantNets(t, nets(p.lines), map[string]float64{"role:OPENING": 500, "role:CUSTOMERS": -500})
	p = one(t, paymentRule(paymentRow{ID: "p2", PaymentDate: day("2026-10-01"), Customer: "Hotel", Amount: 500, AccountID: ptr("petty")}, ci))
	wantNets(t, nets(p.lines), map[string]float64{"cash_account:petty": 500, "role:CUSTOMERS": -500})
}

func TestExpenseAndTransferRules(t *testing.T) {
	p := one(t, expenseRule(expenseRow{ID: "e1", ExpenseDate: day("2026-10-03"), CategoryID: "fuel", Category: "Fuel", Payee: "Shell", Amount: 1200, AccountID: ptr("bank")}, ci))
	wantNets(t, nets(p.lines), map[string]float64{"expense_category:fuel": 1200, "cash_account:bank": -1200})
	if p.memo != "Fuel: Shell" {
		t.Fatalf("memo %q", p.memo)
	}
	p = one(t, transferRule(transferRow{ID: "t1", TransferDate: day("2026-10-03"), FromID: "bank", ToID: "petty", FromName: "Bank", ToName: "Petty cash", Amount: 3000}, ci))
	wantNets(t, nets(p.lines), map[string]float64{"cash_account:petty": 3000, "cash_account:bank": -3000})
}

func TestFarmerEntryRules(t *testing.T) {
	p := one(t, entryRule(entryRow{ID: "a", EntryDate: day("2026-10-10"), Kind: "ADVANCE", Amount: -500, Farmer: "Jane", AccountID: ptr("bank")}, ci))
	wantNets(t, nets(p.lines), map[string]float64{"role:FARMERS": 500, "cash_account:bank": -500})
	p = one(t, entryRule(entryRow{ID: "c", EntryDate: day("2026-10-10"), Kind: "CHARGE", Amount: -300, Farmer: "Jane", Description: "Feeds"}, ci))
	wantNets(t, nets(p.lines), map[string]float64{"role:FARMERS": 300, "role:CHARGES": -300})
	if p.memo != "Charge to Jane: Feeds" {
		t.Fatalf("memo %q", p.memo)
	}
	// An adjustment in the farmer's favour: the Sacco owes more.
	p = one(t, entryRule(entryRow{ID: "j", EntryDate: day("2026-10-10"), Kind: "ADJUSTMENT", Amount: 80, Farmer: "Jane"}, ci))
	wantNets(t, nets(p.lines), map[string]float64{"role:ADJUSTMENTS": 80, "role:FARMERS": -80})
	// Milk, deductions and net pay post with the pay run.
	if rec := entryRule(entryRow{ID: "m", EntryDate: day("2026-10-31"), Kind: "MILK", Amount: 9000}, ci); len(rec.postings) != 0 {
		t.Fatal("milk entries post with their pay run")
	}
}

func TestRunRule(t *testing.T) {
	r := runRow{ID: "r", FromDate: day("2026-10-01"), ToDate: day("2026-10-31"), Milk: 10000,
		Deductions: []runDeduction{{TypeID: ptr("shares"), Name: "Shares", Amount: 500}, {TypeID: ptr("fee"), Name: "Transaction cost", Amount: 66}},
		Net:        9434,
		Paid: []runPaid{
			{Batch: "20261103T091500.000000", PaidDate: day("2026-11-03"), AccountID: ptr("bank"), Amount: 9000, Farmers: 20},
			{Batch: "20261104T101500.000000", PaidDate: day("2026-11-04"), Amount: 434, Farmers: 1},
		}}
	rec := runRule(r, ci)
	if len(rec.postings) != 3 {
		t.Fatalf("want approval and two payments, got %d", len(rec.postings))
	}
	for _, p := range rec.postings {
		if !balanced(p.lines) {
			t.Fatalf("%s does not balance", p.key)
		}
	}
	approved := rec.postings[0]
	if approved.key != "approved" || !approved.date.Equal(day("2026-10-31")) || approved.memo != "Farmers' pay Oct 2026: milk, deductions and net pay" {
		t.Fatalf("approval: %+v", approved)
	}
	// Milk in, deductions and net pay out: the farmers' account nets to zero.
	wantNets(t, nets(approved.lines), map[string]float64{"role:MILK_PURCHASES": 10000,
		"deduction_type:shares": -500, "deduction_type:fee": -66, "role:PAY_DUE": -9434})
	wantNets(t, nets(rec.postings[1].lines), map[string]float64{"role:PAY_DUE": 9000, "cash_account:bank": -9000})
	if rec.postings[1].key != "paid:20261103T091500.000000:bank" || rec.postings[1].memo != "Farmers' pay Oct 2026 sent (20 farmers)" {
		t.Fatalf("payment: %+v", rec.postings[1])
	}
	wantNets(t, nets(rec.postings[2].lines), map[string]float64{"role:PAY_DUE": 434, "role:NO_ACCOUNT": -434})
	if rec.postings[2].key != "paid:20261104T101500.000000:none" {
		t.Fatalf("key %q", rec.postings[2].key)
	}

	// A farmer who owes more than their milk: arrears stay on their account.
	rec = runRule(runRow{ID: "r2", FromDate: day("2026-10-01"), ToDate: day("2026-10-15"), Milk: 300, Net: 0}, ci)
	wantNets(t, nets(one(t, rec).lines), map[string]float64{"role:MILK_PURCHASES": 300, "role:FARMERS": -300})
	if one(t, rec).memo != "Farmers' pay 1 Oct – 15 Oct 2026: milk, deductions and net pay" {
		t.Fatalf("memo %q", one(t, rec).memo)
	}

	// A cancelled run: its entries are gone, so it posts nothing.
	if rec := runRule(runRow{ID: "r3", FromDate: day("2026-09-01"), ToDate: day("2026-09-30")}, ci); len(rec.postings) != 0 {
		t.Fatal("cancelled run posts nothing")
	}
}

func TestOpeningRule(t *testing.T) {
	types := map[string]Type{"role:CUSTOMERS": Asset, "role:MILK_SALES": Income, "cash_account:bank": Asset,
		"expense_category:fuel": Expense, "role:OPENING": Equity}
	before := []posting{
		one(t, saleRule(saleRow{ID: "s", SaleDate: day("2026-09-05"), Total: 1000, Paid: 400, AccountID: ptr("bank")}, ci)),
		one(t, expenseRule(expenseRow{ID: "e", ExpenseDate: day("2026-09-06"), CategoryID: "fuel", Amount: 150, AccountID: ptr("bank")}, ci)),
		one(t, cashAccountRule(cashAccountRow{ID: "bank", Name: "Bank", OpeningBalance: 2000, OpeningDate: day("2026-01-01")})),
	}
	p, err := openingRule(day("2026-10-01"), before, nil, func(link string) (Type, error) { return types[link], nil })
	if err != nil {
		t.Fatal(err)
	}
	if !balanced(p.lines) {
		t.Fatalf("opening does not balance: %+v", p.lines)
	}
	// Sales less expenses before the start (1000 - 150) are retained surplus.
	wantNets(t, nets(p.lines), map[string]float64{"role:CUSTOMERS": 600, "cash_account:bank": 2250,
		"role:RETAINED": -850, "role:OPENING": -2000})
	if !p.date.Equal(day("2026-10-01")) {
		t.Fatalf("opening dated %v", p.date)
	}
}

func TestMatches(t *testing.T) {
	p := one(t, paymentRule(paymentRow{ID: "p", PaymentDate: day("2026-10-02"), Customer: "Hotel", Amount: 500, AccountID: ptr("bank")}, ci))
	j := &Journal{JournalDate: day("2026-10-02"), Lines: []Line{
		{LinkKey: ptr("role:CUSTOMERS"), Credit: 500},
		{LinkKey: ptr("cash_account:bank"), Debit: 500},
	}}
	if !matches(j, p) {
		t.Fatal("same amounts and day should match, whatever the line order")
	}
	p2 := one(t, paymentRule(paymentRow{ID: "p", PaymentDate: day("2026-10-02"), Customer: "Hotel", Amount: 450, AccountID: ptr("bank")}, ci))
	if matches(j, p2) {
		t.Fatal("a changed amount must not match")
	}
	p3 := one(t, paymentRule(paymentRow{ID: "p", PaymentDate: day("2026-10-03"), Customer: "Hotel", Amount: 500, AccountID: ptr("bank")}, ci))
	if matches(j, p3) {
		t.Fatal("a changed day must not match")
	}
	p4 := one(t, paymentRule(paymentRow{ID: "p", PaymentDate: day("2026-10-02"), Customer: "Hotel", Amount: 500, AccountID: ptr("petty")}, ci))
	if matches(j, p4) {
		t.Fatal("a changed account must not match")
	}
}
