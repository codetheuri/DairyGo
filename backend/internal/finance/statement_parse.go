package finance

import (
	"fmt"
	"strings"
	"time"

	"github.com/codetheuri/tusk/pkg/sheet"
)

// ParsedLine is one line of a bank or M-Pesa statement.
type ParsedLine struct {
	Line        int
	Date        time.Time
	Description string
	Reference   string
	Amount      float64 // positive: money into the account
	Balance     *float64
}

// statement columns, found by their headings. The first heading matching a
// kind takes it; the kinds are tried in this order for each heading.
var columnWords = []struct {
	kind  string
	words []string
}{
	{"in", []string{"paid in", "money in", "credit", "deposit", "receipt amount"}},
	{"out", []string{"withdrawn", "withdrawal", "paid out", "money out", "debit"}},
	{"balance", []string{"balance"}},
	{"reference", []string{"receipt", "reference", "ref", "cheque", "transaction id", "trans id"}},
	{"date", []string{"date", "time"}},
	{"description", []string{"detail", "description", "narration", "particular", "narrative", "remarks"}},
	{"amount", []string{"amount"}},
}

// ParseStatement reads a bank or M-Pesa statement (CSV or Excel): a heading
// row with a date column and either money in and out columns ("Paid In" /
// "Withdrawn", "Credit" / "Debit") or one signed amount column, and
// optionally the details, a reference ("Receipt No.") and the balance. Lines
// without a date or an amount (opening balance, totals) are skipped; lines
// that cannot be read are problems, and nothing should be imported until
// the file is fixed.
func ParseStatement(data []byte) (lines []ParsedLine, problems []string) {
	table, err := sheet.Read(data)
	if err != nil {
		return nil, []string{err.Error()}
	}
	header, cols := -1, map[string]int{}
	for i := 0; i < len(table) && i < 20 && header < 0; i++ {
		found := map[string]int{}
		for j, cell := range table[i] {
			c := strings.ToLower(strings.TrimSpace(cell))
			if c == "" {
				continue
			}
		kinds:
			for _, k := range columnWords {
				if _, taken := found[k.kind]; taken {
					continue
				}
				for _, w := range k.words {
					if strings.Contains(c, w) {
						found[k.kind] = j
						break kinds
					}
				}
			}
		}
		_, date := found["date"]
		_, in := found["in"]
		_, out := found["out"]
		_, amount := found["amount"]
		if date && ((in && out) || amount) {
			header, cols = i, found
		}
	}
	if header < 0 {
		return nil, []string{"no heading row found: the statement needs a date column and either money in and out columns " +
			"(e.g. \"Paid In\" and \"Withdrawn\") or an amount column"}
	}
	for i := header + 1; i < len(table); i++ {
		row := table[i]
		cell := func(kind string) string {
			if j, ok := cols[kind]; ok && j < len(row) {
				return strings.TrimSpace(row[j])
			}
			return ""
		}
		rawDate := cell("date")
		var amount float64
		ok := true
		_, hasIn := cols["in"]
		_, hasOut := cols["out"]
		if hasIn && hasOut {
			in, ok1 := sheet.Amount(cell("in"))
			out, ok2 := sheet.Amount(cell("out"))
			ok = ok1 && ok2
			amount = abs(in) - abs(out)
		} else {
			amount, ok = sheet.Amount(cell("amount"))
		}
		if rawDate == "" {
			continue
		}
		if !ok {
			problems = append(problems, fmt.Sprintf("line %d: the amount cannot be read", i+1))
			continue
		}
		if amount == 0 {
			continue
		}
		day, err := parseStatementDate(rawDate)
		if err != nil {
			problems = append(problems, fmt.Sprintf("line %d: %q is not a date", i+1, rawDate))
			continue
		}
		l := ParsedLine{Line: i + 1, Date: day, Description: cell("description"), Reference: cell("reference"), Amount: round2(amount)}
		if b, ok := sheet.Amount(cell("balance")); ok && cell("balance") != "" {
			b = round2(b)
			l.Balance = &b
		}
		if l.Description == "" {
			l.Description = l.Reference
		}
		lines = append(lines, l)
	}
	if len(lines) == 0 && len(problems) == 0 {
		problems = append(problems, "the statement has no money in or out")
	}
	return lines, problems
}

func abs(v float64) float64 {
	if v < 0 {
		return -v
	}
	return v
}

// Statement dates come day first (Kenyan banks and M-Pesa), with or without
// a time.
var statementLayouts = []string{
	"2006-01-02 15:04:05", "2006-01-02T15:04:05", "2006-01-02 15:04", "2006-01-02",
	"02/01/2006 15:04:05", "02/01/2006 15:04", "02/01/2006", "2/1/2006", "02/01/06", "2/1/06",
	"02-01-2006 15:04:05", "02-01-2006", "2-1-2006", "02.01.2006",
	"02 Jan 2006", "2 Jan 2006", "02-Jan-2006", "2-Jan-2006", "02-Jan-06", "02 January 2006", "2 January 2006",
	"Jan 2, 2006",
}

func parseStatementDate(s string) (time.Time, error) {
	s = strings.TrimSpace(s)
	for _, l := range statementLayouts {
		if t, err := time.Parse(l, s); err == nil {
			return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC), nil
		}
	}
	return time.Time{}, fmt.Errorf("not a date")
}
