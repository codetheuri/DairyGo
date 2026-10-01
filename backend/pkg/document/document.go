// Package document describes a printable report (letterhead, title, period,
// key figures and tables) and renders it as PDF (document/pdf.go) or Excel
// (document/xlsx.go).
//
// Reports only fill in a Document; how it looks is decided here, once, so
// every report shares the same letterhead, table style and footer.
package document

import (
	"fmt"
	"math"
	"strings"
	"time"
)

// Kind says what a column holds, which decides its alignment and format.
type Kind int

const (
	Text   Kind = iota // left-aligned as given (names, numbers like "002")
	Money              // KES 1,460.00
	Litres             // 1,234.50
	Number             // 1,234.50 (prices, rates)
	Count              // 12
	Date               // 01 Oct 2026 (a time.Time)
)

// Column is one table column. Width is its share of the page width relative
// to the other columns (2 is twice as wide as 1); 0 means 1.
type Column struct {
	Title string
	Kind  Kind
	Width float64
}

// Table is a titled table. Rows hold one value per column: string, float64,
// int, int64, time.Time or nil. Totals, when set, is a last bold row.
type Table struct {
	Title   string
	Columns []Column
	Rows    [][]any
	Totals  []any
	// Empty is shown instead of the table when it has no rows.
	Empty string
}

// Figure is a key number shown in a box above the tables ("Total paid").
type Figure struct {
	Label string
	Value string
}

// Letterhead is who issues the report: the Sacco.
type Letterhead struct {
	Name    string
	Phone   string
	Email   string
	Address string
	// Logo is a PNG or JPEG image; nil prints the name alone.
	Logo []byte
}

// Document is a complete report.
type Document struct {
	Letterhead Letterhead
	Title      string
	// Period is the dates covered, e.g. "1 Oct 2026 to 31 Oct 2026".
	Period string
	// Subject names who the report is about, e.g. "Jane Muthoni · 003".
	Subject string
	Figures []Figure
	Tables  []Table
	// Notes are short explanations printed after the tables.
	Notes []string
	// Landscape for wide tables.
	Landscape   bool
	GeneratedBy string
	GeneratedAt time.Time
}

// Footer is the line at the foot of every page.
func (d *Document) Footer() string {
	who := d.Letterhead.Name
	if who == "" {
		return "This is a computer generated document."
	}
	msg := "This is a computer generated document. If found please return to " + who
	if d.Letterhead.Phone != "" {
		msg += " or contact " + d.Letterhead.Phone
	}
	return msg + "."
}

// FormatPeriod writes a date range as people read it.
func FormatPeriod(from, to time.Time) string {
	if from.Equal(to) {
		return from.Format("Mon 2 Jan 2006")
	}
	return from.Format("Mon 2 Jan 2006") + " to " + to.Format("Mon 2 Jan 2006")
}

// Format writes a cell value for its column kind, as both renderers show it
// in text (the Excel renderer stores numbers as numbers instead).
func Format(kind Kind, v any) string {
	if v == nil {
		return ""
	}
	switch kind {
	case Money:
		if f, ok := toFloat(v); ok {
			if out := Thousands(f, 2); strings.HasPrefix(out, "-") {
				return "-KES " + out[1:]
			}
			return "KES " + Thousands(f, 2)
		}
	case Litres, Number:
		if f, ok := toFloat(v); ok {
			return Thousands(f, 2)
		}
	case Count:
		if f, ok := toFloat(v); ok {
			return Thousands(f, 0)
		}
	case Date:
		if t, ok := v.(time.Time); ok {
			return t.Format("02 Jan 2006")
		}
	}
	return fmt.Sprint(v)
}

// Thousands writes f with comma thousand separators and decimals places.
func Thousands(f float64, decimals int) string {
	neg := f < 0
	f = math.Abs(f)
	s := fmt.Sprintf("%.*f", decimals, f)
	whole, frac, _ := strings.Cut(s, ".")
	var b strings.Builder
	for i, c := range whole {
		if i > 0 && (len(whole)-i)%3 == 0 {
			b.WriteByte(',')
		}
		b.WriteRune(c)
	}
	out := b.String()
	if frac != "" {
		out += "." + frac
	}
	if neg && strings.Trim(out, "0.,") != "" {
		out = "-" + out
	}
	return out
}

func toFloat(v any) (float64, bool) {
	switch n := v.(type) {
	case float64:
		return n, true
	case float32:
		return float64(n), true
	case int:
		return float64(n), true
	case int64:
		return float64(n), true
	case uint:
		return float64(n), true
	}
	return 0, false
}

// numeric reports whether a column's values are numbers (right-aligned).
func (k Kind) numeric() bool { return k == Money || k == Litres || k == Number || k == Count }
