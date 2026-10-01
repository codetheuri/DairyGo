package document

import (
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/xuri/excelize/v2"
)

// XLSX renders the document as an Excel workbook: one sheet per table, each
// with the letterhead, title, period and key figures above the table.
//
// Amounts and litres are stored as numbers (so they add up in Excel) and
// membership numbers and phones as text (so "002" and "0712..." keep their
// leading zeros, which a CSV file would lose when opened in Excel).
func XLSX(d *Document) ([]byte, error) {
	f := excelize.NewFile()
	defer f.Close()
	_ = f.SetDocProps(&excelize.DocProperties{
		Title: d.Title + " - " + d.Period, Creator: "DairyGo", Description: d.Letterhead.Name,
	})

	s, err := newSheetStyles(f)
	if err != nil {
		return nil, err
	}

	tables := d.Tables
	if len(tables) == 0 {
		tables = []Table{{Title: d.Title}} // still write the letterhead and figures
	}
	used := map[string]bool{}
	for i := range tables {
		name := sheetName(tables[i].Title, d.Title, used)
		if i == 0 {
			if err := f.SetSheetName("Sheet1", name); err != nil {
				return nil, err
			}
		} else if _, err := f.NewSheet(name); err != nil {
			return nil, err
		}
		if err := writeSheet(f, s, name, d, &tables[i]); err != nil {
			return nil, fmt.Errorf("sheet %s: %w", name, err)
		}
	}
	f.SetActiveSheet(0)

	buf, err := f.WriteToBuffer()
	if err != nil {
		return nil, fmt.Errorf("write xlsx: %w", err)
	}
	return buf.Bytes(), nil
}

type sheetStyles struct {
	name, contact, title, period, figureLabel, figureValue, header, text int
	byKind                                                               map[Kind]int
	totalsByKind                                                         map[Kind]int
}

func newSheetStyles(f *excelize.File) (*sheetStyles, error) {
	var firstErr error
	style := func(st *excelize.Style) int {
		id, err := f.NewStyle(st)
		if err != nil && firstErr == nil {
			firstErr = err
		}
		return id
	}
	green := "0A5C36"
	numFmt := func(code string) *string { return &code }
	border := []excelize.Border{{Type: "bottom", Color: "CBD5E1", Style: 1}}
	top := []excelize.Border{{Type: "top", Color: "0F172A", Style: 2}}
	right := &excelize.Alignment{Horizontal: "right"}

	s := &sheetStyles{
		name:        style(&excelize.Style{Font: &excelize.Font{Bold: true, Size: 14, Color: "0F172A"}}),
		contact:     style(&excelize.Style{Font: &excelize.Font{Size: 9, Color: "64748B"}}),
		title:       style(&excelize.Style{Font: &excelize.Font{Bold: true, Size: 12, Color: green}}),
		period:      style(&excelize.Style{Font: &excelize.Font{Size: 10, Color: "0F172A"}}),
		figureLabel: style(&excelize.Style{Font: &excelize.Font{Size: 9, Color: "64748B"}}),
		figureValue: style(&excelize.Style{Font: &excelize.Font{Bold: true, Size: 11, Color: green}}),
		header: style(&excelize.Style{
			Font:      &excelize.Font{Bold: true, Color: "FFFFFF"},
			Fill:      excelize.Fill{Type: "pattern", Pattern: 1, Color: []string{green}},
			Alignment: &excelize.Alignment{Vertical: "center", WrapText: true},
		}),
		text: style(&excelize.Style{Border: border, NumFmt: 49}), // 49 = text
	}
	formats := map[Kind]string{Money: "#,##0.00", Litres: "#,##0.00", Number: "#,##0.00", Count: "#,##0", Date: "dd mmm yyyy"}
	s.byKind = map[Kind]int{Text: s.text}
	s.totalsByKind = map[Kind]int{Text: style(&excelize.Style{Border: top, Font: &excelize.Font{Bold: true}})}
	for k, code := range formats {
		al := right
		if k == Date {
			al = nil
		}
		s.byKind[k] = style(&excelize.Style{Border: border, CustomNumFmt: numFmt(code), Alignment: al})
		s.totalsByKind[k] = style(&excelize.Style{Border: top, Font: &excelize.Font{Bold: true}, CustomNumFmt: numFmt(code), Alignment: al})
	}
	return s, firstErr
}

func writeSheet(f *excelize.File, s *sheetStyles, sheet string, d *Document, t *Table) error {
	cell := func(col, row int) string {
		name, _ := excelize.CoordinatesToCellName(col, row)
		return name
	}
	set := func(col, row int, v any, style int) {
		_ = f.SetCellValue(sheet, cell(col, row), v)
		_ = f.SetCellStyle(sheet, cell(col, row), cell(col, row), style)
	}

	row := 1
	set(1, row, d.Letterhead.Name, s.name)
	row++
	for _, line := range contactLines(d.Letterhead) {
		set(1, row, strings.ReplaceAll(line, "   ·   ", "   "), s.contact)
		row++
	}
	set(1, row, d.Title, s.title)
	row++
	period := d.Period
	if d.Subject != "" {
		period = d.Subject + "   ·   " + period
	}
	set(1, row, period, s.period)
	row++
	generated := "Generated " + d.GeneratedAt.Format("02 Jan 2006 15:04")
	if d.GeneratedBy != "" {
		generated += " by " + d.GeneratedBy
	}
	set(1, row, generated+" · DairyGo", s.contact)
	row += 2

	for _, fig := range d.Figures {
		set(1, row, fig.Label, s.figureLabel)
		set(2, row, fig.Value, s.figureValue)
		row++
	}
	if len(d.Figures) > 0 {
		row++
	}

	if t.Title != "" && t.Title != sheet {
		set(1, row, t.Title, s.title)
		row++
	}
	if len(t.Columns) == 0 {
		return nil
	}
	if len(t.Rows) == 0 {
		empty := t.Empty
		if empty == "" {
			empty = "Nothing recorded in this period."
		}
		set(1, row, empty, s.contact)
		return nil
	}

	headerRow := row
	widths := make([]float64, len(t.Columns))
	for c, col := range t.Columns {
		title := col.Title
		if col.Kind == Money && !strings.Contains(strings.ToUpper(title), "KES") {
			title += " (KES)"
		}
		set(c+1, row, title, s.header)
		widths[c] = float64(len(title)) + 2
	}
	_ = f.SetRowHeight(sheet, row, 22)
	row++

	write := func(values []any, styles map[Kind]int) {
		for c, col := range t.Columns {
			var v any
			if c < len(values) {
				v = values[c]
			}
			set(c+1, row, excelValue(col.Kind, v), styles[col.Kind])
			if w := float64(len([]rune(Format(col.Kind, v)))) + 2; w > widths[c] {
				widths[c] = w
			}
		}
		row++
	}
	for _, r := range t.Rows {
		write(r, s.byKind)
	}
	lastData := row - 1
	if t.Totals != nil {
		write(t.Totals, s.totalsByKind)
	}

	for c, w := range widths {
		name, _ := excelize.ColumnNumberToName(c + 1)
		_ = f.SetColWidth(sheet, name, name, min(max(w, 9), 48))
	}
	// Keep the column titles in view while scrolling, and let people sort
	// and filter the rows.
	_ = f.SetPanes(sheet, &excelize.Panes{
		Freeze: true, YSplit: headerRow, TopLeftCell: cell(1, headerRow+1), ActivePane: "bottomLeft",
	})
	return f.AutoFilter(sheet, cell(1, headerRow)+":"+cell(len(t.Columns), lastData), nil)
}

// excelValue is the value to store: numbers as numbers, text as text.
func excelValue(k Kind, v any) any {
	switch {
	case v == nil:
		return nil
	case k == Text:
		return fmt.Sprint(v)
	case k == Date:
		if t, ok := v.(time.Time); ok {
			return t
		}
	}
	if f, ok := toFloat(v); ok {
		return f
	}
	return fmt.Sprint(v)
}

var badSheetChars = regexp.MustCompile(`[\[\]:*?/\\]`)

// sheetName is a valid, unique Excel sheet name (at most 31 characters).
func sheetName(title, fallback string, used map[string]bool) string {
	name := strings.TrimSpace(badSheetChars.ReplaceAllString(title, " "))
	if name == "" {
		name = strings.TrimSpace(badSheetChars.ReplaceAllString(fallback, " "))
	}
	if name == "" {
		name = "Report"
	}
	if r := []rune(name); len(r) > 31 {
		name = string(r[:31])
	}
	base := name
	for i := 2; used[strings.ToLower(name)]; i++ {
		suffix := fmt.Sprintf(" (%d)", i)
		r := []rune(base)
		if len(r)+len(suffix) > 31 {
			r = r[:31-len(suffix)]
		}
		name = string(r) + suffix
	}
	used[strings.ToLower(name)] = true
	return name
}
