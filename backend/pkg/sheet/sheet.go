// Package sheet reads the first sheet of a spreadsheet someone uploaded:
// Excel (.xlsx) or CSV, as rows of text.
package sheet

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"strconv"
	"strings"

	"github.com/xuri/excelize/v2"
)

// Read reads an Excel file's first sheet, or a CSV file (a UTF-8 byte order
// mark is ignored; rows may differ in length).
func Read(data []byte) ([][]string, error) {
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
	r.LazyQuotes = true
	table, err := r.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("cannot read the file as Excel or CSV: %v", err)
	}
	return table, nil
}

// Amount reads "12,500", "KES 12,500.50", "-500", "(500.00)" or "12500";
// blank (or "-") is 0.
func Amount(s string) (float64, bool) {
	s = strings.ToUpper(strings.TrimSpace(s))
	for _, p := range []string{"KES", "KSH", "KSHS"} {
		s = strings.TrimSpace(strings.TrimPrefix(s, p))
	}
	s = strings.NewReplacer(",", "", " ", "", " ", "").Replace(s)
	neg := false
	if strings.HasPrefix(s, "(") && strings.HasSuffix(s, ")") {
		neg, s = true, s[1:len(s)-1]
	}
	if s == "" || s == "-" {
		return 0, true
	}
	v, err := strconv.ParseFloat(s, 64)
	if neg {
		v = -v
	}
	return v, err == nil
}
