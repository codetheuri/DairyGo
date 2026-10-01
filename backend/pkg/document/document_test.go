package document

import (
	"bytes"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/xuri/excelize/v2"
)

func TestThousands(t *testing.T) {
	for in, want := range map[float64]string{0: "0.00", 7120: "7,120.00", 1234567.891: "1,234,567.89", -1500: "-1,500.00", -0.001: "0.00"} {
		if got := Thousands(in, 2); got != want {
			t.Errorf("Thousands(%v) = %q, want %q", in, got, want)
		}
	}
	if got := Format(Money, 1460.0); got != "KES 1,460.00" {
		t.Errorf("money = %q", got)
	}
	if got := Format(Money, -46165.0); got != "-KES 46,165.00" {
		t.Errorf("negative money = %q", got)
	}
	if got := Format(Date, time.Date(2024, 12, 19, 0, 0, 0, 0, time.UTC)); got != "19 Dec 2024" {
		t.Errorf("date = %q", got)
	}
}

func sample(rows int) *Document {
	logo, _ := os.ReadFile(os.Getenv("DOC_LOGO")) // optional, for a visual check
	d := &Document{
		Letterhead:  Letterhead{Name: "Maru Dairy Farmers Society Ltd", Phone: "0114 692 339", Email: "marudairy2022@gmail.com", Logo: logo},
		Title:       "Farmer Statement",
		Period:      "Thu 21 Nov 2024 to Sat 21 Dec 2024",
		Subject:     "Jane Muthoni · Member 003 · 0707154545",
		Figures:     []Figure{{"Total payment", "KES 7,120.00"}, {"Litres collected", "178.00 L"}, {"Deliveries", "5"}},
		GeneratedBy: "admin1", GeneratedAt: time.Date(2026, 10, 1, 9, 30, 0, 0, time.UTC),
	}
	tbl := Table{Title: "Deliveries", Columns: []Column{
		{"#", Count, 0.5}, {"Date", Date, 1.3}, {"Shift", Text, 1}, {"Member no.", Text, 1}, {"Litres", Litres, 1}, {"Price/L", Number, 1}, {"Amount", Money, 1.4},
	}}
	day := time.Date(2024, 11, 21, 0, 0, 0, 0, time.UTC)
	var litres, amount float64
	for i := 0; i < rows; i++ {
		l := 30 + float64(i%10)
		tbl.Rows = append(tbl.Rows, []any{i + 1, day.AddDate(0, 0, i), "Morning", "003", l, 40.0, l * 40})
		litres += l
		amount += l * 40
	}
	tbl.Totals = []any{"Total", nil, nil, nil, litres, nil, amount}
	d.Tables = []Table{tbl, {Title: "Payments", Columns: []Column{{"Date", Date, 1}, {"Amount", Money, 1}}}}
	d.Notes = []string{"Amounts are at the price in force on each delivery date."}
	return d
}

func TestPDF(t *testing.T) {
	out, err := PDF(sample(120)) // several pages
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.HasPrefix(out, []byte("%PDF-")) || len(out) < 2000 {
		t.Fatalf("not a PDF (%d bytes)", len(out))
	}
	if p := os.Getenv("DOC_OUT"); p != "" {
		_ = os.WriteFile(p+".pdf", out, 0o644)
	}
}

func TestXLSX(t *testing.T) {
	out, err := XLSX(sample(30))
	if err != nil {
		t.Fatal(err)
	}
	if p := os.Getenv("DOC_OUT"); p != "" {
		_ = os.WriteFile(p+".xlsx", out, 0o644)
	}
	f, err := excelize.OpenReader(bytes.NewReader(out))
	if err != nil {
		t.Fatal(err)
	}
	if got := f.GetSheetList(); strings.Join(got, ",") != "Deliveries,Payments" {
		t.Fatalf("sheets = %v", got)
	}
	rows, _ := f.GetRows("Deliveries")
	var header []string
	for _, r := range rows {
		if len(r) > 0 && r[0] == "#" {
			header = r
		}
	}
	if strings.Join(header, "|") != "#|Date|Shift|Member no.|Litres|Price/L|Amount (KES)" {
		t.Errorf("header = %q", header)
	}
	// Membership numbers stay text with their leading zeros; litres are numbers.
	for _, r := range rows {
		if len(r) > 3 && r[0] == "1" {
			if r[3] != "003" {
				t.Errorf("member no = %q", r[3])
			}
		}
	}
	typ, _ := f.GetCellType("Deliveries", "E12")
	if typ == excelize.CellTypeSharedString || typ == excelize.CellTypeInlineString {
		t.Errorf("litres stored as text")
	}
}

func TestSheetName(t *testing.T) {
	used := map[string]bool{}
	if got := sheetName("Sales: Coolers/Hotels", "x", used); got != "Sales  Coolers Hotels" {
		t.Errorf("got %q", got)
	}
	if got := sheetName("Sales: Coolers/Hotels", "x", used); got != "Sales  Coolers Hotels (2)" {
		t.Errorf("duplicate got %q", got)
	}
	if got := sheetName(strings.Repeat("a", 40), "x", used); len(got) != 31 {
		t.Errorf("long = %q", got)
	}
}
