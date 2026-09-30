package memberimport

import (
	"strings"
	"testing"

	"github.com/codetheuri/tusk/internal/member"
)

func TestParseAGoodFile(t *testing.T) {
	file := "\uFEFFMembership_Number,Name,Gender,Phone,Status\n" +
		"002,RUDIAH MUNGAYO,F,0726750512,ACTIVE\n" +
		"049,MUTAHI  MACHARIA ,M,,active\n" +
		",,,,\n" + // a blank row from the spreadsheet
		"008,virginia wa-njeri mwangi,F,+254 711 856 758,INACTIVE\n" +
		"010,JOHN KAMAU,,711856758,\n"
	rows, problems, warnings := Parse(strings.NewReader(file))
	if len(problems) > 0 {
		t.Fatalf("problems: %v", problems)
	}
	want := []Row{
		{Line: 2, Number: "002", FirstName: "Rudiah", LastName: "Mungayo", Gender: "FEMALE", Phone: "0726750512", Status: member.StatusActive},
		{Line: 3, Number: "049", FirstName: "Mutahi", LastName: "Macharia", Gender: "MALE", Phone: "", Status: member.StatusActive},
		{Line: 5, Number: "008", FirstName: "Virginia", LastName: "Wa-Njeri Mwangi", Gender: "FEMALE", Phone: "0711856758", Status: member.StatusInactive},
		{Line: 6, Number: "010", FirstName: "John", LastName: "Kamau", Gender: "OTHER", Phone: "0711856758", Status: member.StatusActive},
	}
	if len(rows) != len(want) {
		t.Fatalf("got %d rows, want %d: %+v", len(rows), len(want), rows)
	}
	for i := range want {
		if rows[i] != want[i] {
			t.Errorf("row %d = %+v, want %+v", i, rows[i], want[i])
		}
	}
	if len(warnings) != 1 || !strings.Contains(warnings[0], "line 6: phone 0711856758 is also on line 5") {
		t.Errorf("warnings = %v", warnings)
	}
}

func TestParseReportsEveryProblem(t *testing.T) {
	file := "membership_number,name,gender,phone,status\n" +
		",JANE WAMBUI,F,0722232053,ACTIVE\n" +
		"003,JANE,F,0722232054,ACTIVE\n" +
		"004,JANE MUTHONI,X,12345,GONE\n" +
		"005,MARY WANJIRU,F,,ACTIVE\n" +
		"005,MARY NJERI,F,,ACTIVE\n"
	_, problems, _ := Parse(strings.NewReader(file))
	wantParts := []string{
		"line 2: membership number is missing",
		`line 3: name "JANE" needs a first and a last name`,
		`line 4: gender "X"`,
		`line 4: phone "12345"`,
		`line 4: status "GONE"`,
		"line 6: membership number 005 is also on line 5",
	}
	if len(problems) != len(wantParts) {
		t.Fatalf("problems = %q", problems)
	}
	for i, part := range wantParts {
		if !strings.Contains(problems[i], part) {
			t.Errorf("problem %d = %q, want it to contain %q", i, problems[i], part)
		}
	}
}

func TestParseNeedsTheColumns(t *testing.T) {
	// The spreadsheet's own headings: only Name matches.
	_, problems, _ := Parse(strings.NewReader("No.,Name,Sex,Phone No.\n002,A B,F,\n"))
	if len(problems) != 4 {
		t.Fatalf("problems = %q", problems)
	}
	for _, p := range problems {
		if !strings.HasPrefix(p, "missing column") {
			t.Errorf("problem %q", p)
		}
	}
	if _, problems, _ := Parse(strings.NewReader("")); len(problems) != 1 {
		t.Errorf("empty file: %q", problems)
	}
	if _, problems, _ := Parse(strings.NewReader("membership_number,name,gender,phone,status\n")); len(problems) != 1 {
		t.Errorf("header only: %q", problems)
	}
}

func TestNormalisePhone(t *testing.T) {
	for in, want := range map[string]string{
		"0726750512":    "0726750512",
		"0110 123 456":  "0110123456",
		"+254726750512": "0726750512",
		"254726750512":  "0726750512",
		"726750512":     "0726750512",
		"0826750512":    "",
		"12345":         "",
		"07267505120":   "",
		"not a number":  "",
	} {
		if got := normalisePhone(in); got != want {
			t.Errorf("normalisePhone(%q) = %q, want %q", in, got, want)
		}
	}
}
