package payout

import (
	"strings"
	"testing"

	"github.com/xuri/excelize/v2"
)

func TestParseShareRowsCSV(t *testing.T) {
	data := []byte("Maru Dairy shares\nMember No,Name,Shares\nM001,Jane,\"12,500\"\nM002,John,KES 3000.50\nM003,Ann,0\n,blank,\nM004,Bad,abc\nm001,Again,5\n")
	rows, problems := ParseShareRows(data)
	if len(rows) != 2 || rows[0].MembershipNumber != "M001" || rows[0].Amount != 12500 || rows[1].Amount != 3000.5 {
		t.Fatalf("rows = %+v", rows)
	}
	if len(problems) != 2 || !strings.Contains(problems[0], "M004") || !strings.Contains(problems[1], "also on line 3") {
		t.Fatalf("problems = %v", problems)
	}
}

func TestParseShareRowsExcel(t *testing.T) {
	f := excelize.NewFile()
	_ = f.SetSheetRow("Sheet1", "A1", &[]any{"Membership number", "Share balance"})
	_ = f.SetSheetRow("Sheet1", "A2", &[]any{"M010", 4200})
	buf, err := f.WriteToBuffer()
	if err != nil {
		t.Fatal(err)
	}
	rows, problems := ParseShareRows(buf.Bytes())
	if len(problems) != 0 || len(rows) != 1 || rows[0].MembershipNumber != "M010" || rows[0].Amount != 4200 {
		t.Fatalf("rows = %+v problems = %v", rows, problems)
	}
}

func TestParseShareRowsNeedsHeader(t *testing.T) {
	_, problems := ParseShareRows([]byte("a,b\n1,2\n"))
	if len(problems) != 1 || !strings.Contains(problems[0], "header") {
		t.Fatalf("problems = %v", problems)
	}
}
