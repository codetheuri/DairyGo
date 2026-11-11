package finance

import (
	"testing"
	"time"
)

func TestKindFor(t *testing.T) {
	for method, want := range map[string]Kind{
		"CASH": KindCash, "": KindCash, "CREDIT": KindCash, // the paid part of a credit sale is cash
		"MPESA": KindMpesa, "mpesa": KindMpesa,
		"BANK_TRANSFER": KindBank, "CHEQUE": KindBank, "BANK": KindBank,
	} {
		if got := KindFor(method); got != want {
			t.Errorf("KindFor(%q) = %s, want %s", method, got, want)
		}
	}
}

func TestDefaultsByKind(t *testing.T) {
	got := defaultsByKind([]AccountChoice{ // oldest first, as activeChoices lists them
		{ID: "petty", Kind: "CASH"}, {ID: "equity", Kind: "BANK"}, {ID: "float", Kind: "CASH"},
	})
	if got["CASH"] != "petty" || got["BANK"] != "equity" {
		t.Errorf("the account opened first is the default: %v", got)
	}
	if _, ok := got["MPESA"]; ok {
		t.Errorf("no M-Pesa account, no default: %v", got)
	}
}

func TestFinancialYear(t *testing.T) {
	day := func(s string) time.Time { d, _ := time.Parse(dateLayout, s); return d }
	cases := []struct {
		today string
		start int
		want  FinancialYear
	}{
		{"2026-11-11", 1, FinancialYear{1, "2026-01-01", "2026-12-31", "2025-01-01", "2025-12-31"}},
		{"2026-11-11", 7, FinancialYear{7, "2026-07-01", "2027-06-30", "2025-07-01", "2026-06-30"}},
		{"2026-03-15", 7, FinancialYear{7, "2025-07-01", "2026-06-30", "2024-07-01", "2025-06-30"}},
		{"2026-07-01", 7, FinancialYear{7, "2026-07-01", "2027-06-30", "2025-07-01", "2026-06-30"}},
		{"2028-02-29", 3, FinancialYear{3, "2027-03-01", "2028-02-29", "2026-03-01", "2027-02-28"}},
	}
	for _, c := range cases {
		if got := financialYear(day(c.today), c.start); *got != c.want {
			t.Errorf("%s from month %d = %+v, want %+v", c.today, c.start, *got, c.want)
		}
	}
}
