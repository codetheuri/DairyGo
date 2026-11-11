package finance

import (
	"strings"
	"testing"
)

func TestParseMpesaStatement(t *testing.T) {
	data := []byte("MPESA STATEMENT\nReceipt No.,Completion Time,Details,Transaction Status,Paid In,Withdrawn,Balance\n" +
		"QK12AB,2026-10-03 14:22:01,Customer Payment from 0711000001,Completed,\"1,500.00\",,\"11,500.00\"\n" +
		"QK13CD,2026-10-04 09:00:00,Pay Bill to 600100 CIC,Completed,,-300.00,\"11,200.00\"\n" +
		",,,,,,\n")
	lines, problems := ParseStatement(data)
	if len(problems) != 0 || len(lines) != 2 {
		t.Fatalf("lines %+v problems %v", lines, problems)
	}
	if lines[0].Amount != 1500 || lines[0].Reference != "QK12AB" || lines[0].Date.Format("2006-01-02") != "2026-10-03" ||
		*lines[0].Balance != 11500 {
		t.Fatalf("line 1 %+v", lines[0])
	}
	if lines[1].Amount != -300 || !strings.Contains(lines[1].Description, "CIC") {
		t.Fatalf("line 2 %+v", lines[1])
	}
}

func TestParseBankStatement(t *testing.T) {
	data := []byte("Transaction Date,Value Date,Narration,Cheque No,Debit,Credit,Balance\n" +
		"05/10/2026,05/10/2026,Opening balance,,,,50000.00\n" +
		"06/10/2026,06/10/2026,CHQ 1001 Kiambu Agrovet,1001,2500.00,,47500.00\n" +
		"15/10/2026,15/10/2026,Interest,,,1500.00,49000.00\n" +
		"16/13/2026,16/10/2026,Bad date,,10.00,,48990.00\n")
	lines, problems := ParseStatement(data)
	if len(lines) != 2 || lines[0].Amount != -2500 || lines[0].Date.Format("2006-01-02") != "2026-10-06" || lines[1].Amount != 1500 {
		t.Fatalf("lines %+v", lines)
	}
	if len(problems) != 1 || !strings.Contains(problems[0], "16/13/2026") {
		t.Fatalf("problems %v", problems)
	}
}

func TestParseSignedAmount(t *testing.T) {
	data := []byte("Date,Description,Amount\n2 Oct 2026,Deposit,\"2,000\"\n3 Oct 2026,Charges,(35.00)\n")
	lines, problems := ParseStatement(data)
	if len(problems) != 0 || len(lines) != 2 || lines[0].Amount != 2000 || lines[1].Amount != -35 {
		t.Fatalf("lines %+v problems %v", lines, problems)
	}
}

func TestParseStatementNeedsHeadings(t *testing.T) {
	_, problems := ParseStatement([]byte("a,b\n1,2\n"))
	if len(problems) != 1 || !strings.Contains(problems[0], "heading") {
		t.Fatalf("problems %v", problems)
	}
}
