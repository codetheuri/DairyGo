package collection

import (
	"testing"
	"time"
)

func day(s string) time.Time { d, _ := time.Parse(dateLayout, s); return d }

func own(date string, price float64) MemberPrice {
	if price == 0 {
		return MemberPrice{EffectiveDate: day(date)} // back to the Sacco's price
	}
	return MemberPrice{EffectiveDate: day(date), PricePerLitre: &price}
}

func TestPricedOn(t *testing.T) {
	sacco := []MilkPrice{{EffectiveDate: day("2026-09-01"), PricePerLitre: 42}, {EffectiveDate: day("2026-10-15"), PricePerLitre: 44}}
	jane := []MemberPrice{own("2026-10-03", 45), own("2026-10-20", 0)}
	tests := []struct {
		name    string
		day     string
		own     []MemberPrice
		want    float64
		wantOwn bool
		ok      bool
	}{
		{name: "no own price", day: "2026-10-05", want: 42, ok: true},
		{name: "before own price", day: "2026-10-02", own: jane, want: 42, ok: true},
		{name: "own price starts", day: "2026-10-03", own: jane, want: 45, wantOwn: true, ok: true},
		{name: "own price beats a Sacco change", day: "2026-10-16", own: jane, want: 45, wantOwn: true, ok: true},
		{name: "back to the Sacco price", day: "2026-10-20", own: jane, want: 44, ok: true},
		{name: "before any price", day: "2026-08-01", want: 0, ok: false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, isOwn, ok := pricedOn(tt.day, tt.own, sacco)
			if got != tt.want || isOwn != tt.wantOwn || ok != tt.ok {
				t.Errorf("pricedOn(%s) = %v, %v, %v; want %v, %v, %v", tt.day, got, isOwn, ok, tt.want, tt.wantOwn, tt.ok)
			}
		})
	}
}

func TestRepriceChanges(t *testing.T) {
	sacco := []MilkPrice{{EffectiveDate: day("2026-09-01"), PricePerLitre: 42}}
	milk := func(id, date string, litres, price float64) MilkCollection {
		return MilkCollection{ID: id, CollectionDate: day(date), QuantityLitres: litres, PricePerLitre: price, TotalAmount: litres * price}
	}
	collections := []MilkCollection{
		milk("1st", "2026-10-01", 10, 42),
		milk("3rd", "2026-10-03", 10, 42),
		milk("4th", "2026-10-04", 12.5, 42),
		milk("5th", "2026-10-05", 10, 45), // already at the new price
	}
	changes := repriceChanges(collections, []MemberPrice{own("2026-10-03", 45)}, sacco)
	if len(changes) != 2 || changes[0].Collection.ID != "3rd" || changes[1].Collection.ID != "4th" {
		t.Fatalf("changes = %+v", changes)
	}
	if changes[1].NewPrice != 45 || changes[1].NewTotal != 562.5 {
		t.Errorf("4th = %+v", changes[1])
	}
	// Cancelling the own price puts them back.
	back := repriceChanges(collections, nil, sacco)
	if len(back) != 1 || back[0].Collection.ID != "5th" || back[0].NewPrice != 42 {
		t.Errorf("back = %+v", back)
	}
}
