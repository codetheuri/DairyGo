package document

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"strconv"
	"time"
)

// CSV writes the document's flat table (or its first table) as comma
// separated values for importing into accounting software or a spreadsheet:
// a header row of column titles, then one row per row. Values are plain:
// dates as 2026-10-31, amounts as 1460.00 with no "KES" or thousand
// separators. Totals, figures and notes are left out.
func CSV(d *Document) ([]byte, error) {
	t := d.Flat
	if t == nil {
		if len(d.Tables) == 0 {
			return nil, fmt.Errorf("csv: %s has no table", d.Title)
		}
		t = &d.Tables[0]
	}
	var buf bytes.Buffer
	w := csv.NewWriter(&buf)
	head := make([]string, len(t.Columns))
	for i, c := range t.Columns {
		head[i] = c.Title
	}
	if err := w.Write(head); err != nil {
		return nil, err
	}
	for _, row := range t.Rows {
		rec := make([]string, len(t.Columns))
		for i, c := range t.Columns {
			if i < len(row) {
				rec[i] = csvValue(c.Kind, row[i])
			}
		}
		if err := w.Write(rec); err != nil {
			return nil, err
		}
	}
	w.Flush()
	return buf.Bytes(), w.Error()
}

func csvValue(k Kind, v any) string {
	if v == nil {
		return ""
	}
	switch k {
	case Money, Litres, Number:
		if f, ok := toFloat(v); ok {
			return strconv.FormatFloat(f, 'f', 2, 64)
		}
	case Count:
		if f, ok := toFloat(v); ok {
			return strconv.FormatFloat(f, 'f', 0, 64)
		}
	case Date:
		if t, ok := v.(time.Time); ok {
			return t.Format("2006-01-02")
		}
	}
	return fmt.Sprint(v)
}
