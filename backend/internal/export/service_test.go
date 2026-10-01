package export

import (
	"errors"
	"testing"
	"time"

	"github.com/codetheuri/tusk/internal/customer"
	"github.com/codetheuri/tusk/pkg/document"
)

func TestPeriod(t *testing.T) {
	// 15 Oct 2026, 08:00 in Nairobi.
	s := &Service{now: func() time.Time { return time.Date(2026, 10, 15, 5, 0, 0, 0, time.UTC) }}
	d := func(v string) time.Time { t, _ := time.Parse(dateLayout, v); return t }

	tests := []struct {
		name     string
		from, to string
		asAt     bool
		want     [2]string
		err      bool
	}{
		{name: "default: this month so far", want: [2]string{"2026-10-01", "2026-10-15"}},
		{name: "a chosen month", from: "2026-09-01", to: "2026-09-30", want: [2]string{"2026-09-01", "2026-09-30"}},
		{name: "never after today", from: "2026-10-01", to: "2026-12-31", want: [2]string{"2026-10-01", "2026-10-15"}},
		{name: "one day", from: "2026-10-03", to: "2026-10-03", want: [2]string{"2026-10-03", "2026-10-03"}},
		{name: "a full year", from: "2025-10-15", to: "2026-10-14", want: [2]string{"2025-10-15", "2026-10-14"}},
		{name: "more than a year", from: "2025-01-01", to: "2026-10-15", err: true},
		{name: "backwards", from: "2026-10-10", to: "2026-10-01", err: true},
		{name: "bad date", from: "1/10/2026", err: true},
		{name: "as at ignores dates", from: "2020-01-01", asAt: true, want: [2]string{"2026-10-15", "2026-10-15"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			from, to, err := s.period(Request{From: tt.from, To: tt.to}, tt.asAt)
			if tt.err {
				if !errors.Is(err, ErrInvalid) {
					t.Fatalf("err = %v, want ErrInvalid", err)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if !from.Equal(d(tt.want[0])) || !to.Equal(d(tt.want[1])) {
				t.Errorf("got %s to %s, want %s to %s", from.Format(dateLayout), to.Format(dateLayout), tt.want[0], tt.want[1])
			}
		})
	}
}

func TestFileName(t *testing.T) {
	from := time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC)
	to := time.Date(2026, 10, 31, 0, 0, 0, 0, time.UTC)
	in := &input{from: from, to: to, doc: &document.Document{
		Letterhead: document.Letterhead{Name: "Maru Dairy Farmers Society Ltd"},
		Subject:    "Jane Muthoni · Member 003",
	}}
	rep, _ := findReport("farmer-statement")
	if got := fileName(rep, in, PDF); got != "maru-dairy-farmers-society-ltd-farmer-statement-jane-muthoni-2026-10-01-to-2026-10-31.pdf" {
		t.Errorf("got %q", got)
	}
	owing, _ := findReport("customers-owing")
	in.doc.Subject = ""
	if got := fileName(owing, in, XLSX); got != "maru-dairy-farmers-society-ltd-customers-owing-2026-10-31.xlsx" {
		t.Errorf("got %q", got)
	}
}

func TestCatalogIsComplete(t *testing.T) {
	seen := map[string]bool{}
	for _, r := range catalog {
		if r.Key == "" || r.Title == "" || r.Description == "" || r.permission == "" || r.build == nil {
			t.Errorf("report %q is missing something", r.Key)
		}
		if seen[r.Key] {
			t.Errorf("report %q listed twice", r.Key)
		}
		seen[r.Key] = true
	}
}

func TestStatementDetails(t *testing.T) {
	for _, tt := range []struct {
		kind          customer.EntryKind
		desc          string
		debit, credit float64
		want          string
	}{
		{customer.EntrySale, "x", 54000, 0, "Milk sale"},
		{customer.EntrySale, "x", 54000, 20000, "Milk sale, part paid at sale"},
		{customer.EntrySale, "x", 54000, 54000, "Milk sale, paid at sale"},
		{customer.EntryPayment, "Payment (MPESA) ref QX12", 0, 5000, "Payment (M-Pesa) ref QX12"},
		{customer.EntryPayment, "Payment (BANK_TRANSFER)", 0, 5000, "Payment (bank transfer)"},
	} {
		if got := statementDetails(tt.kind, tt.desc, tt.debit, tt.credit); got != tt.want {
			t.Errorf("%v %v/%v = %q, want %q", tt.kind, tt.debit, tt.credit, got, tt.want)
		}
	}
}
