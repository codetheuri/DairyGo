package payout

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"strconv"
	"strings"

	"github.com/xuri/excelize/v2"
)

// ParseShareRows reads a spreadsheet (Excel .xlsx, or CSV) of opening
// shares: a header row with a membership number column ("Member No",
// "Membership number", "No.") and an amount column ("Shares", "Amount",
// "Balance"), then one farmer per row. Rows without a number or with no
// shares are skipped; anything unreadable is a problem, and nothing should
// be imported until the file is fixed.
func ParseShareRows(data []byte) (rows []ShareRow, problems []string) {
	table, err := readTable(data)
	if err != nil {
		return nil, []string{err.Error()}
	}
	header, numCol, amtCol := -1, -1, -1
	for i := 0; i < len(table) && i < 10 && header < 0; i++ {
		n, a := -1, -1
		for j, cell := range table[i] {
			c := strings.ToLower(strings.TrimSpace(cell))
			switch {
			case n < 0 && (strings.Contains(c, "member") || c == "no" || c == "no." || c == "number"):
				n = j
			case a < 0 && (strings.Contains(c, "share") || strings.Contains(c, "amount") || strings.Contains(c, "balance")):
				a = j
			}
		}
		if n >= 0 && a >= 0 {
			header, numCol, amtCol = i, n, a
		}
	}
	if header < 0 {
		return nil, []string{"no header row found: the file needs a membership number column (e.g. \"Member No\") and a shares column (e.g. \"Shares\")"}
	}
	seen := map[string]int{}
	for i := header + 1; i < len(table); i++ {
		line := i + 1
		cell := func(j int) string {
			if j < len(table[i]) {
				return strings.TrimSpace(table[i][j])
			}
			return ""
		}
		number, raw := cell(numCol), cell(amtCol)
		if number == "" {
			continue
		}
		amount, ok := parseAmount(raw)
		switch {
		case !ok:
			problems = append(problems, fmt.Sprintf("line %d (%s): %q is not an amount", line, number, raw))
			continue
		case amount < 0:
			problems = append(problems, fmt.Sprintf("line %d (%s): shares cannot be negative", line, number))
			continue
		case amount == 0:
			continue
		}
		key := strings.ToUpper(number)
		if first, dup := seen[key]; dup {
			problems = append(problems, fmt.Sprintf("line %d: %s is also on line %d", line, number, first))
			continue
		}
		seen[key] = line
		rows = append(rows, ShareRow{Line: line, MembershipNumber: number, Amount: round2(amount)})
	}
	if len(rows) == 0 && len(problems) == 0 {
		problems = append(problems, "the file has no shares to import")
	}
	return rows, problems
}

// readTable reads the first sheet of an Excel file, or a CSV file.
func readTable(data []byte) ([][]string, error) {
	if bytes.HasPrefix(data, []byte("PK")) {
		f, err := excelize.OpenReader(bytes.NewReader(data))
		if err != nil {
			return nil, fmt.Errorf("cannot read the Excel file: %v", err)
		}
		defer f.Close()
		sheets := f.GetSheetList()
		if len(sheets) == 0 {
			return nil, fmt.Errorf("the Excel file has no sheets")
		}
		return f.GetRows(sheets[0])
	}
	r := csv.NewReader(bytes.NewReader(bytes.TrimPrefix(data, []byte("\xef\xbb\xbf"))))
	r.FieldsPerRecord = -1
	table, err := r.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("cannot read the file as Excel or CSV: %v", err)
	}
	return table, nil
}

// parseAmount reads "12,500", "KES 12,500.50" or "12500"; blank is 0.
func parseAmount(s string) (float64, bool) {
	s = strings.TrimSpace(strings.TrimPrefix(strings.ToUpper(strings.TrimSpace(s)), "KES"))
	s = strings.NewReplacer(",", "", " ", "").Replace(s)
	if s == "" || s == "-" {
		return 0, true
	}
	v, err := strconv.ParseFloat(s, 64)
	return v, err == nil
}
