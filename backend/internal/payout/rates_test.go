package payout

import "testing"

func TestApplyRates(t *testing.T) {
	lines := []PayRunLine{
		{MemberID: "one", Litres: 400, Gross: 20000},
		{MemberID: "mixed", Litres: 400, Gross: 17100},
		{MemberID: "none", Litres: 0, Gross: 0},
	}
	applyRates(lines, map[string][]RateLine{
		"one":   {{Rate: 50, Litres: 400, Amount: 20000}},
		"mixed": {{Rate: 42, Litres: 300, Amount: 12600}, {Rate: 45, Litres: 100, Amount: 4500}},
	})
	if l := lines[0]; l.Rate != 50 || l.MixedRates || rateText(l) != "50.00" {
		t.Errorf("one rate: %+v %q", l, rateText(l))
	}
	if l := lines[1]; l.Rate != 42.75 || !l.MixedRates || rateText(l) != "42.75*" || len(l.Rates) != 2 {
		t.Errorf("mixed rates: %+v %q", l, rateText(l))
	}
	if l := lines[2]; l.Rate != 0 || rateText(l) != "" || l.Rates == nil {
		t.Errorf("no milk: %+v", l)
	}
}
