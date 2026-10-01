package payout

import (
	"context"
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/document"
)

// Letterheads gives the Sacco details printed on payslips and registers
// (export.Repository).
type Letterheads interface {
	Letterhead(ctx context.Context, saccoID string) (document.Letterhead, error)
	StaffName(ctx context.Context, userID uint) string
}

// File is a generated document.
type File struct {
	Name        string
	ContentType string
	Data        []byte
}

const (
	contentPDF  = "application/pdf"
	contentXLSX = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
)

var unsafeName = regexp.MustCompile(`[^a-z0-9-]+`)

func fileName(sacco, what string, run *PayRun, ext string) string {
	base := strings.ToLower(sacco + "-" + what + "-" + run.FromDate.Format(dateLayout) + "-to-" + run.ToDate.Format(dateLayout))
	return strings.Trim(unsafeName.ReplaceAllString(base, "-"), "-") + "." + ext
}

// newDoc starts a document with the Sacco's letterhead.
func (s *Service) newDoc(ctx context.Context, run *PayRun, title string) (*document.Document, error) {
	if s.letterheads == nil {
		return nil, fmt.Errorf("documents are not available")
	}
	lh, err := s.letterheads.Letterhead(ctx, run.SaccoID)
	if err != nil {
		return nil, err
	}
	return &document.Document{
		Letterhead: lh, Title: title, Period: document.FormatPeriod(run.FromDate, run.ToDate),
		GeneratedBy: s.letterheads.StaffName(ctx, middleware.GetUserID(ctx)), GeneratedAt: s.now(),
	}, nil
}

func render(d *document.Document, format string) ([]byte, string, string, error) {
	if format == "xlsx" {
		b, err := document.XLSX(d)
		return b, contentXLSX, "xlsx", err
	}
	b, err := document.PDF(d)
	return b, contentPDF, "pdf", err
}

func col(title string, kind document.Kind, width float64) document.Column {
	return document.Column{Title: title, Kind: kind, Width: width}
}

func deref(p *string) string {
	if p == nil {
		return ""
	}
	return strings.TrimSpace(*p)
}

// mpesaPhone writes a phone the way M-Pesa bulk files expect: 2547XXXXXXXX.
func mpesaPhone(p string) string {
	p = strings.NewReplacer(" ", "", "-", "", "+", "").Replace(strings.TrimSpace(p))
	switch {
	case strings.HasPrefix(p, "0") && len(p) == 10:
		return "254" + p[1:]
	case len(p) == 9 && (strings.HasPrefix(p, "7") || strings.HasPrefix(p, "1")):
		return "254" + p
	}
	return p
}

// PaymentFile is the list of farmers still to be paid in an approved run,
// as an Excel file for an M-Pesa bulk payment or a bank upload. Farmers
// without the details needed are listed on a second sheet.
func (s *Service) PaymentFile(ctx context.Context, runID, kind string) (*File, error) {
	run, err := s.repo.FindRun(ctx, runID)
	if err != nil {
		return nil, err
	}
	if run.Status != RunApproved {
		return nil, fmt.Errorf("%w: the payment list is made once the pay run is approved and until everyone is paid", ErrLocked)
	}
	lines, err := s.repo.Lines(ctx, runID, "", true)
	if err != nil {
		return nil, err
	}
	bank := kind == "bank"
	title := "M-Pesa Payment List"
	if bank {
		title = "Bank Payment List"
	}
	d, err := s.newDoc(ctx, run, title)
	if err != nil {
		return nil, err
	}
	pay := document.Table{Title: "To pay", Empty: "Nobody to pay this way."}
	missing := document.Table{Title: "Missing payment details", Empty: "Everyone has the details needed.",
		Columns: []document.Column{col("No.", document.Text, 0.7), col("Farmer", document.Text, 2), col("Phone", document.Text, 1.2), col("Net pay", document.Money, 1.2)}}
	if bank {
		pay.Columns = []document.Column{col("Bank", document.Text, 1.4), col("Account", document.Text, 1.5), col("Name", document.Text, 2), col("Amount", document.Money, 1.2), col("Reference", document.Text, 1)}
	} else {
		pay.Columns = []document.Column{col("Phone", document.Text, 1.3), col("Amount", document.Money, 1.2), col("Name", document.Text, 2), col("Reference", document.Text, 1)}
	}
	total := 0.0
	for _, l := range lines {
		switch {
		case bank && deref(l.BankAccountNumber) != "":
			pay.Rows = append(pay.Rows, []any{deref(l.BankName), deref(l.BankAccountNumber), l.FarmerName, l.Net, l.MembershipNumber})
			total += l.Net
		case !bank && (deref(l.MpesaNumber) != "" || l.Phone != ""):
			phone := deref(l.MpesaNumber)
			if phone == "" {
				phone = l.Phone
			}
			pay.Rows = append(pay.Rows, []any{mpesaPhone(phone), l.Net, l.FarmerName, l.MembershipNumber})
			total += l.Net
		default:
			missing.Rows = append(missing.Rows, []any{l.MembershipNumber, l.FarmerName, l.Phone, l.Net})
		}
	}
	if bank {
		pay.Totals = []any{"Total", nil, nil, round2(total), nil}
	} else {
		pay.Totals = []any{"Total", round2(total), nil, nil}
	}
	d.Figures = []document.Figure{
		{Label: "Farmers to pay", Value: fmt.Sprint(len(pay.Rows))},
		{Label: "Amount", Value: document.Format(document.Money, round2(total))},
	}
	d.Tables = []document.Table{pay}
	if bank {
		d.Notes = append(d.Notes, "Only farmers with a bank account are listed. Farmers paid by M-Pesa are in the M-Pesa list.")
	} else {
		d.Notes = append(d.Notes, "Farmers are paid on their M-Pesa number, or their phone when no M-Pesa number is set.")
	}
	if !bank || len(missing.Rows) > 0 {
		d.Tables = append(d.Tables, missing)
	}
	d.Notes = append(d.Notes, "After paying, mark the farmers paid in DairyGo with the payment reference.")
	data, err := document.XLSX(d)
	if err != nil {
		return nil, err
	}
	return &File{Name: fileName(d.Letterhead.Name, kind+"-payments", run, "xlsx"), ContentType: contentXLSX, Data: data}, nil
}

// Register is the whole pay run: every farmer's milk, each deduction,
// advances and charges, net pay and how they were paid.
func (s *Service) Register(ctx context.Context, runID, format string) (*File, error) {
	detail, err := s.GetRun(ctx, runID, "", false)
	if err != nil {
		return nil, err
	}
	run := detail.Run
	title := "Pay Run Register"
	if run.Status == RunDraft {
		title += " (draft, not approved)"
	}
	d, err := s.newDoc(ctx, run, title)
	if err != nil {
		return nil, err
	}
	d.Landscape = true

	// One column per deduction taken in this run, in the order taken.
	type colInfo struct {
		name  string
		order int
	}
	seen := map[string]colInfo{}
	for _, l := range detail.Lines {
		for i, it := range l.Items {
			if _, ok := seen[it.Name]; !ok {
				seen[it.Name] = colInfo{it.Name, i*1000 + len(seen)}
			}
		}
	}
	names := make([]string, 0, len(seen))
	for n := range seen {
		names = append(names, n)
	}
	sort.Slice(names, func(i, j int) bool { return seen[names[i]].order < seen[names[j]].order })

	// Plain numbers (amounts in KES, said once in the notes) so wide
	// registers fit the page.
	num := document.Number
	cols := []document.Column{col("No.", document.Text, 0.6), col("Farmer", document.Text, 1.7), col("Litres", document.Litres, 0.9),
		col("Gross", num, 1.1), col("B/f", num, 0.9), col("Adv. & charges", num, 1.1)}
	for _, n := range names {
		cols = append(cols, col(n, num, 1))
	}
	cols = append(cols, col("Net pay", num, 1.1), col("C/f", num, 0.9), col("Paid", document.Text, 1.3))

	t := document.Table{Columns: cols, Empty: "No farmers in this pay run."}
	sums := make([]float64, len(cols))
	for _, l := range detail.Lines {
		byName := map[string]float64{}
		for _, it := range l.Items {
			byName[it.Name] += it.Amount
		}
		row := []any{l.MembershipNumber, l.FarmerName, l.Litres, l.Gross, l.Opening, -l.Entries}
		for _, n := range names {
			row = append(row, round2(byName[n]))
		}
		paid := ""
		if l.PaidAt != nil {
			paid = strings.TrimSpace(methodLabel(l.PaidMethod) + " " + deref(l.PaidReference))
		} else if l.Net > 0 {
			paid = "Not yet"
		}
		row = append(row, l.Net, l.Closing, paid)
		for i, v := range row {
			if f, ok := v.(float64); ok {
				sums[i] += f
			}
		}
		t.Rows = append(t.Rows, row)
	}
	totals := []any{"Total", nil}
	for i := 2; i < len(cols)-1; i++ {
		totals = append(totals, round2(sums[i]))
	}
	totals = append(totals, nil)
	t.Totals = totals
	d.Tables = []document.Table{t}
	d.Figures = []document.Figure{
		{Label: "Farmers", Value: fmt.Sprint(run.Farmers)},
		{Label: "Milk", Value: document.Format(document.Litres, run.TotalLitres) + " L"},
		{Label: "Gross", Value: document.Format(document.Money, run.TotalGross)},
		{Label: "Deductions", Value: document.Format(document.Money, run.TotalDeductions)},
		{Label: "Net pay", Value: document.Format(document.Money, run.TotalNet)},
	}
	d.Notes = []string{
		"Amounts are in KES.",
		"B/f is the balance brought forward from earlier pay runs (negative = the farmer owed the Sacco). C/f is carried forward to the next run.",
		"Advances & charges are those recorded since the last pay run, recovered in this one.",
	}
	data, ctype, ext, err := render(d, format)
	if err != nil {
		return nil, err
	}
	return &File{Name: fileName(d.Letterhead.Name, "pay-run", run, ext), ContentType: ctype, Data: data}, nil
}

func methodLabel(m *PayMethod) string {
	if m == nil {
		return ""
	}
	switch *m {
	case PayMpesa:
		return "M-Pesa"
	case PayBank:
		return "Bank"
	case PayCheck:
		return "Cheque"
	}
	return "Cash"
}

// Payslip is one farmer's pay for a run as a PDF.
func (s *Service) Payslip(ctx context.Context, runID, memberID string) (*File, error) {
	run, err := s.repo.FindRun(ctx, runID)
	if err != nil {
		return nil, err
	}
	l, err := s.repo.LineForMember(ctx, runID, memberID)
	if err != nil {
		return nil, err
	}
	title := "Payslip"
	if run.Status == RunDraft {
		title += " (draft)"
	}
	d, err := s.newDoc(ctx, run, title)
	if err != nil {
		return nil, err
	}
	d.Subject = l.FarmerName + " · " + l.MembershipNumber
	d.Figures = []document.Figure{
		{Label: "Milk", Value: document.Format(document.Litres, l.Litres) + " L"},
		{Label: "Gross pay", Value: document.Format(document.Money, l.Gross)},
		{Label: "Taken off", Value: document.Format(document.Money, max(round2(l.Gross-l.Net), 0))},
		{Label: "Net pay", Value: document.Format(document.Money, l.Net)},
	}
	t := document.Table{Title: "Pay", Columns: []document.Column{col("Item", document.Text, 3), col("Amount", document.Money, 1.2)}}
	t.Rows = append(t.Rows, []any{"Milk delivered (" + trimZeros(l.Litres) + " L)", l.Gross})
	if l.Opening != 0 {
		label := "Brought forward from last pay run"
		if l.Opening < 0 {
			label = "Owed from last pay run"
		}
		t.Rows = append(t.Rows, []any{label, l.Opening})
	}
	// The advances, charges and adjustments themselves, once approved.
	if run.Status != RunDraft {
		entries, err := s.repo.RunEntries(ctx, runID, memberID)
		if err != nil {
			return nil, err
		}
		for _, e := range entries {
			t.Rows = append(t.Rows, []any{kindLabel(e.Kind) + ": " + e.Description + " (" + e.EntryDate.Format("2 Jan") + ")", e.Amount})
		}
	} else if l.Entries != 0 {
		t.Rows = append(t.Rows, []any{"Advances, charges and adjustments", l.Entries})
	}
	for _, it := range l.Items {
		t.Rows = append(t.Rows, []any{it.Name, -it.Amount})
	}
	t.Totals = []any{"Net pay", l.Net}
	d.Tables = []document.Table{t}
	if l.Closing < 0 {
		d.Notes = append(d.Notes, fmt.Sprintf("You owe the Sacco %s, carried to the next pay run.", document.Format(document.Money, -l.Closing)))
	}
	if l.PaidAt != nil {
		d.Notes = append(d.Notes, fmt.Sprintf("Paid on %s by %s %s.", l.PaidAt.Format("2 Jan 2006"), methodLabel(l.PaidMethod), deref(l.PaidReference)))
	}
	if _, shares, err := s.repo.Balance(ctx, run.SaccoID, memberID, nil); err == nil && shares > 0 {
		d.Notes = append(d.Notes, "Your shares to date: "+document.Format(document.Money, round2(shares))+".")
	}
	data, err := document.PDF(d)
	if err != nil {
		return nil, err
	}
	return &File{Name: fileName(d.Letterhead.Name, "payslip-"+l.MembershipNumber, run, "pdf"), ContentType: contentPDF, Data: data}, nil
}

func kindLabel(k Kind) string {
	switch k {
	case KindAdvance:
		return "Advance"
	case KindCharge:
		return "Charge"
	case KindAdjustment:
		return "Adjustment"
	}
	return string(k)
}
