package document

import (
	"bytes"
	"fmt"
	"net/http"

	"github.com/go-pdf/fpdf"
)

// Page layout, in millimetres, and colours.
const (
	margin     = 12.0
	rowHeight  = 6.4
	headHeight = 7.2
	footerRoom = 16.0
)

type rgb struct{ r, g, b int }

var (
	brand    = rgb{10, 92, 54}    // DairyGo green
	ink      = rgb{15, 23, 42}    // body text
	muted    = rgb{100, 116, 139} // secondary text
	rule     = rgb{203, 213, 225} // lines
	zebra    = rgb{243, 247, 245} // every other row
	figureBg = rgb{232, 245, 233} // key figure boxes
)

// PDF renders the document as an A4 PDF.
func PDF(d *Document) ([]byte, error) {
	orientation := "P"
	if d.Landscape {
		orientation = "L"
	}
	pdf := fpdf.New(orientation, "mm", "A4", "")
	pdf.SetMargins(margin, margin, margin)
	pdf.SetCellMargin(1.8)
	pdf.SetAutoPageBreak(true, footerRoom)
	pdf.AliasNbPages("{nb}")
	pdf.SetTitle(d.Title+" - "+d.Period, true)
	pdf.SetAuthor(d.Letterhead.Name, true)
	pdf.SetCreator("DairyGo", true)

	r := &pdfRenderer{pdf: pdf, doc: d, tr: pdf.UnicodeTranslatorFromDescriptor("")}
	r.logo = r.registerLogo()
	// Not "home mode": the body starts where the header ends.
	pdf.SetHeaderFuncMode(r.header, false)
	pdf.SetFooterFunc(r.footer)
	pdf.AddPage()

	r.subject()
	r.figures()
	for i := range d.Tables {
		r.table(&d.Tables[i])
	}
	r.notes()

	if err := pdf.Error(); err != nil {
		return nil, fmt.Errorf("render pdf: %w", err)
	}
	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return nil, fmt.Errorf("write pdf: %w", err)
	}
	return buf.Bytes(), nil
}

type pdfRenderer struct {
	pdf  *fpdf.Fpdf
	doc  *Document
	tr   func(string) string // UTF-8 to the core fonts' encoding
	logo string              // registered image name, "" without a logo
	// table being drawn, so its header repeats on a new page
	current *Table
	widths  []float64
}

func (r *pdfRenderer) color(c rgb) { r.pdf.SetTextColor(c.r, c.g, c.b) }
func (r *pdfRenderer) fill(c rgb)  { r.pdf.SetFillColor(c.r, c.g, c.b) }
func (r *pdfRenderer) draw(c rgb)  { r.pdf.SetDrawColor(c.r, c.g, c.b) }
func (r *pdfRenderer) contentWidth() float64 {
	w, _ := r.pdf.GetPageSize()
	return w - 2*margin
}

func (r *pdfRenderer) registerLogo() string {
	logo := r.doc.Letterhead.Logo
	if len(logo) == 0 {
		return ""
	}
	kind := ""
	switch http.DetectContentType(logo) {
	case "image/png":
		kind = "PNG"
	case "image/jpeg":
		kind = "JPG"
	default:
		return "" // not an image we can print: the name alone
	}
	info := r.pdf.RegisterImageOptionsReader("logo", fpdf.ImageOptions{ImageType: kind}, bytes.NewReader(logo))
	if info == nil || r.pdf.Err() {
		r.pdf.ClearError()
		return ""
	}
	return "logo"
}

// header draws the letterhead in full on the first page and a slim one on
// the others.
func (r *pdfRenderer) header() {
	pdf, d := r.pdf, r.doc
	width := r.contentWidth()
	top := margin

	if pdf.PageNo() > 1 {
		pdf.SetY(top)
		pdf.SetFont("Helvetica", "B", 9)
		r.color(brand)
		pdf.CellFormat(width/2, 5, r.tr(d.Letterhead.Name), "", 0, "L", false, 0, "")
		pdf.SetFont("Helvetica", "", 8.5)
		r.color(muted)
		pdf.CellFormat(width/2, 5, r.tr(d.Title+" · "+d.Period), "", 1, "R", false, 0, "")
		r.draw(brand)
		pdf.SetLineWidth(0.4)
		pdf.Line(margin, pdf.GetY()+1, margin+width, pdf.GetY()+1)
		pdf.SetY(pdf.GetY() + 4)
		r.tableHeader() // continue the table on this page
		return
	}

	const logoSize = 24.0
	if r.logo != "" {
		pdf.ImageOptions(r.logo, margin, top, logoSize, logoSize, false, fpdf.ImageOptions{}, 0, "")
	}
	// The text block is centred on the page, clear of the logo.
	pdf.SetY(top + 1)
	pdf.SetFont("Helvetica", "B", 16)
	r.color(ink)
	pdf.CellFormat(width, 7, r.tr(upper(d.Letterhead.Name)), "", 1, "C", false, 0, "")
	pdf.SetFont("Helvetica", "", 9)
	r.color(muted)
	for _, line := range contactLines(d.Letterhead) {
		pdf.CellFormat(width, 4.6, r.tr(line), "", 1, "C", false, 0, "")
	}
	pdf.Ln(1.5)
	pdf.SetFont("Helvetica", "B", 12.5)
	r.color(brand)
	pdf.CellFormat(width, 6.5, r.tr(d.Title), "", 1, "C", false, 0, "")
	pdf.SetFont("Helvetica", "", 9.5)
	r.color(ink)
	pdf.CellFormat(width, 5, r.tr(d.Period), "", 1, "C", false, 0, "")

	y := pdf.GetY() + 2
	if r.logo != "" && y < top+logoSize+2 {
		y = top + logoSize + 2
	}
	r.draw(brand)
	pdf.SetLineWidth(0.6)
	pdf.Line(margin, y, margin+width, y)
	pdf.SetY(y + 5)
}

func (r *pdfRenderer) footer() {
	pdf, d := r.pdf, r.doc
	width := r.contentWidth()
	_, h := pdf.GetPageSize()
	pdf.SetY(h - footerRoom + 3)
	r.draw(rule)
	pdf.SetLineWidth(0.2)
	pdf.Line(margin, pdf.GetY(), margin+width, pdf.GetY())
	pdf.Ln(1.5)
	pdf.SetFont("Helvetica", "", 7.5)
	r.color(muted)
	generated := "Generated " + d.GeneratedAt.Format("02 Jan 2006 15:04")
	if d.GeneratedBy != "" {
		generated += " by " + d.GeneratedBy
	}
	generated += " · DairyGo"
	pdf.CellFormat(width*0.7, 4, r.tr(generated), "", 0, "L", false, 0, "")
	pdf.CellFormat(width*0.3, 4, fmt.Sprintf("Page %d of {nb}", pdf.PageNo()), "", 1, "R", false, 0, "")
	pdf.SetFont("Helvetica", "I", 7)
	pdf.CellFormat(width, 4, r.tr(d.Footer()), "", 1, "C", false, 0, "")
}

func (r *pdfRenderer) subject() {
	if r.doc.Subject == "" {
		return
	}
	pdf := r.pdf
	pdf.SetFont("Helvetica", "B", 11)
	r.color(ink)
	pdf.MultiCell(r.contentWidth(), 6, r.tr(r.doc.Subject), "", "L", false)
	pdf.Ln(2)
}

// figures draws the key numbers as a row of boxes, up to four per row.
func (r *pdfRenderer) figures() {
	figs := r.doc.Figures
	if len(figs) == 0 {
		return
	}
	pdf := r.pdf
	const perRow, gap, boxH = 4, 3.0, 15.0
	width := r.contentWidth()
	for start := 0; start < len(figs); start += perRow {
		row := figs[start:min(start+perRow, len(figs))]
		boxW := (width - gap*float64(perRow-1)) / perRow
		if len(row) < perRow && start == 0 {
			boxW = (width - gap*float64(len(row)-1)) / float64(len(row))
		}
		y := pdf.GetY()
		for i, f := range row {
			x := margin + float64(i)*(boxW+gap)
			r.fill(figureBg)
			pdf.RoundedRect(x, y, boxW, boxH, 2, "1234", "F")
			pdf.SetXY(x+3, y+2.2)
			pdf.SetFont("Helvetica", "", 7.5)
			r.color(muted)
			pdf.CellFormat(boxW-6, 4, r.tr(upper(f.Label)), "", 2, "L", false, 0, "")
			pdf.SetX(x + 3)
			pdf.SetFont("Helvetica", "B", 11.5)
			r.color(brand)
			pdf.CellFormat(boxW-6, 7, r.fit(f.Value, boxW-6), "", 0, "L", false, 0, "")
		}
		pdf.SetY(y + boxH + gap)
	}
	pdf.Ln(3)
}

func (r *pdfRenderer) table(t *Table) {
	pdf := r.pdf
	width := r.contentWidth()

	if t.Title != "" {
		r.keepTogether(14)
		pdf.SetFont("Helvetica", "B", 10.5)
		r.color(ink)
		pdf.CellFormat(width, 7, r.tr(t.Title), "", 1, "L", false, 0, "")
	}
	if len(t.Rows) == 0 {
		pdf.SetFont("Helvetica", "I", 9)
		r.color(muted)
		empty := t.Empty
		if empty == "" {
			empty = "Nothing recorded in this period."
		}
		pdf.CellFormat(width, 7, r.tr(empty), "", 1, "L", false, 0, "")
		pdf.Ln(4)
		return
	}

	r.widths = columnWidths(t.Columns, width)
	r.current = t
	r.keepTogether(headHeight + 3*rowHeight)
	r.tableHeader()

	pdf.SetFont("Helvetica", "", 8.5)
	for i, row := range t.Rows {
		r.ensureRoom(rowHeight) // a new page repeats the header
		r.color(ink)
		fill := i%2 == 1
		if fill {
			r.fill(zebra)
		}
		pdf.SetFont("Helvetica", "", 8.5)
		r.draw(rule)
		pdf.SetLineWidth(0.1)
		for c, col := range t.Columns {
			var v any
			if c < len(row) {
				v = row[c]
			}
			pdf.CellFormat(r.widths[c], rowHeight, r.fit(Format(col.Kind, v), r.widths[c]-2), "B", 0, align(col.Kind), fill, 0, "")
		}
		pdf.Ln(-1)
	}
	if t.Totals != nil {
		r.ensureRoom(rowHeight + 1)
		pdf.SetFont("Helvetica", "B", 8.8)
		r.color(ink)
		r.draw(ink)
		pdf.SetLineWidth(0.35)
		y := pdf.GetY()
		pdf.Line(margin, y, margin+width, y)
		for c, col := range t.Columns {
			var v any
			if c < len(t.Totals) {
				v = t.Totals[c]
			}
			pdf.CellFormat(r.widths[c], rowHeight+0.6, r.fit(Format(col.Kind, v), r.widths[c]-2), "", 0, align(col.Kind), false, 0, "")
		}
		pdf.Ln(-1)
	}
	r.current = nil
	pdf.Ln(5)
}

// tableHeader draws the current table's column titles.
func (r *pdfRenderer) tableHeader() {
	t := r.current
	if t == nil {
		return
	}
	pdf := r.pdf
	pdf.SetFont("Helvetica", "B", 8.3)
	r.fill(brand)
	pdf.SetTextColor(255, 255, 255)
	for c, col := range t.Columns {
		pdf.CellFormat(r.widths[c], headHeight, r.fit(col.Title, r.widths[c]-2), "", 0, align(col.Kind), true, 0, "")
	}
	pdf.Ln(-1)
}

// ensureRoom starts a new page when h more millimetres would not fit.
func (r *pdfRenderer) ensureRoom(h float64) {
	_, pageH := r.pdf.GetPageSize()
	if r.pdf.GetY()+h > pageH-footerRoom {
		r.pdf.AddPage()
	}
}

// keepTogether moves a heading and the start of its table to a new page
// rather than leaving the heading alone at the bottom.
func (r *pdfRenderer) keepTogether(h float64) {
	saved := r.current
	r.current = nil // no table header to repeat for a heading
	r.ensureRoom(h)
	r.current = saved
}

func (r *pdfRenderer) notes() {
	if len(r.doc.Notes) == 0 {
		return
	}
	pdf := r.pdf
	pdf.SetFont("Helvetica", "", 8)
	r.color(muted)
	for _, n := range r.doc.Notes {
		pdf.MultiCell(r.contentWidth(), 4.2, r.tr(n), "", "L", false)
	}
}

// fit shortens s with an ellipsis to fit width w, in the current font.
func (r *pdfRenderer) fit(s string, w float64) string {
	s = r.tr(s)
	if r.pdf.GetStringWidth(s) <= w {
		return s
	}
	ellipsis := r.tr("…")
	runes := []rune(s)
	for len(runes) > 1 && r.pdf.GetStringWidth(string(runes)+ellipsis) > w {
		runes = runes[:len(runes)-1]
	}
	return string(runes) + ellipsis
}

func align(k Kind) string {
	if k.numeric() {
		return "R"
	}
	return "L"
}

// columnWidths shares width between the columns by their Width weights.
func columnWidths(cols []Column, width float64) []float64 {
	total := 0.0
	for _, c := range cols {
		total += weight(c)
	}
	out := make([]float64, len(cols))
	for i, c := range cols {
		out[i] = width * weight(c) / total
	}
	return out
}

func weight(c Column) float64 {
	if c.Width <= 0 {
		return 1
	}
	return c.Width
}

func contactLines(l Letterhead) []string {
	var lines []string
	if l.Address != "" {
		lines = append(lines, l.Address)
	}
	contact := ""
	if l.Phone != "" {
		contact = "Tel: " + l.Phone
	}
	if l.Email != "" {
		if contact != "" {
			contact += "   ·   "
		}
		contact += "Email: " + l.Email
	}
	if contact != "" {
		lines = append(lines, contact)
	}
	return lines
}

func upper(s string) string {
	b := []rune(s)
	for i, c := range b {
		if c >= 'a' && c <= 'z' {
			b[i] = c - 32
		}
	}
	return string(b)
}
