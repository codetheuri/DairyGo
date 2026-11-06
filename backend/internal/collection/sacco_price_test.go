package collection

import (
	"testing"
	"time"
)

func TestSaccoReprice(t *testing.T) {
	d := func(month time.Month, day int) time.Time { return time.Date(2026, month, day, 0, 0, 0, 0, time.Local) }
	milk := func(id, farmer string, on time.Time, litres, price float64, status CollectionStatus) MilkCollection {
		return MilkCollection{ID: id, MemberID: farmer, CollectionDate: on, QuantityLitres: litres,
			PricePerLitre: price, TotalAmount: litres * price, Status: status}
	}
	row := func(on time.Time, price float64) MilkPrice { return MilkPrice{EffectiveDate: on, PricePerLitre: price} }
	own := 50.0
	sacco := []MilkPrice{row(d(9, 1), 42), row(d(10, 1), 45), row(d(11, 5), 47)}
	schedules := map[string][]MemberPrice{"own": {{EffectiveDate: d(10, 3), PricePerLitre: &own}}}

	res := &SaccoPriceResult{}
	changes := saccoReprice([]MilkCollection{
		milk("oct", "jane", d(10, 2), 10, 42, StatusSubmitted),       // 42 → 45
		milk("nov", "jane", d(11, 1), 12.35, 42, StatusVerified),     // verified milk too: 42 → 45
		milk("later", "jane", d(11, 5), 10, 47, StatusSubmitted),     // the later row already applies
		milk("rejected", "peter", d(10, 5), 10, 42, StatusRejected),  // repriced, but unpaid: not in the totals
		milk("before-own", "own", d(10, 2), 10, 42, StatusSubmitted), // the Sacco's price before their own starts
		milk("on-own", "own", d(10, 4), 10, 50, StatusSubmitted),     // stays on their own price
	}, schedules, sacco, res)

	got := map[string]priceChange{}
	for _, c := range changes {
		got[c.Collection.ID] = c
	}
	if len(changes) != 4 {
		t.Fatalf("changed %d records, want 4: %+v", len(changes), changes)
	}
	if c := got["oct"]; c.NewPrice != 45 || c.NewTotal != 450 {
		t.Errorf("oct = %+v", c)
	}
	if c := got["nov"]; c.NewPrice != 45 || c.NewTotal != 555.75 {
		t.Errorf("nov = %+v", c)
	}
	if _, ok := got["later"]; ok {
		t.Error("milk already at the later price changed")
	}
	if _, ok := got["on-own"]; ok {
		t.Error("a farmer's own price changed")
	}
	want := SaccoPriceResult{Repriced: 4, Farmers: 2, Litres: 32.35, ValueChange: 97.05, OwnPrice: 1}
	if *res != want {
		t.Errorf("result = %+v, want %+v", *res, want)
	}
}

func TestLastRowOn(t *testing.T) {
	on := time.Date(2026, 10, 1, 0, 0, 0, 0, time.Local)
	rows := []MilkPrice{{EffectiveDate: on, PricePerLitre: 54}, {EffectiveDate: on, PricePerLitre: 45}}
	if r := lastRowOn(rows, "2026-10-01"); r == nil || r.PricePerLitre != 45 {
		t.Errorf("the row entered last sets the day's price: %+v", r)
	}
	if r := lastRowOn(rows, "2026-10-02"); r != nil {
		t.Errorf("no row on that day: %+v", r)
	}
}
