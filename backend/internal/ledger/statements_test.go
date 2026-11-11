package ledger

import "testing"

func TestPreviousPeriod(t *testing.T) {
	cases := []struct{ from, to, pf, pt string }{
		{"2026-10-01", "2026-10-31", "2026-09-01", "2026-09-30"}, // a month
		{"2026-11-01", "2026-11-11", "2026-10-01", "2026-10-11"}, // this month so far
		{"2026-01-01", "2026-01-31", "2025-12-01", "2025-12-31"}, // across the year
		{"2026-03-01", "2026-03-31", "2026-02-01", "2026-02-28"}, // a shorter month
		{"2026-03-01", "2026-03-30", "2026-02-01", "2026-02-28"}, // so far, past its end
		{"2026-07-01", "2027-06-30", "2025-07-01", "2026-06-30"}, // a financial year
		{"2026-01-01", "2026-03-31", "2025-10-01", "2025-12-31"}, // a quarter
		{"2026-10-05", "2026-10-14", "2026-09-25", "2026-10-04"}, // ten days
	}
	for _, c := range cases {
		pf, pt := previousPeriod(day(c.from), day(c.to))
		if pf.Format(dateLayout) != c.pf || pt.Format(dateLayout) != c.pt {
			t.Errorf("%s–%s: got %s–%s, want %s–%s", c.from, c.to, pf.Format(dateLayout), pt.Format(dateLayout), c.pf, c.pt)
		}
	}
}

func TestYearStart(t *testing.T) {
	cases := []struct {
		day   string
		month int
		want  string
	}{
		{"2026-11-11", 1, "2026-01-01"}, {"2026-11-11", 7, "2026-07-01"}, {"2026-03-31", 7, "2025-07-01"}, {"2026-07-01", 7, "2026-07-01"}, {"2026-05-05", 0, "2026-01-01"},
	}
	for _, c := range cases {
		if got := yearStart(day(c.day), c.month).Format(dateLayout); got != c.want {
			t.Errorf("yearStart(%s, %d) = %s, want %s", c.day, c.month, got, c.want)
		}
	}
}
