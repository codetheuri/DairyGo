// Package memberimport loads a Sacco's farmer register from a CSV file, and
// can first clear the Sacco's test data (farmers, milk records, customers),
// keeping its staff, settings and milk prices.
//
// It is run by the CLI (dairy-cli members import), not the API: it is a
// one-off job for onboarding a Sacco, done by the platform owner.
package memberimport

import (
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"strings"
	"unicode"

	"github.com/codetheuri/tusk/internal/member"
)

// Columns a file must have, in any order. Column names ignore case.
var requiredColumns = []string{"membership_number", "name", "gender", "phone", "status"}

// Row is one farmer read from the file, checked and tidied.
type Row struct {
	Line      int
	Number    string
	FirstName string
	LastName  string
	Gender    string // MALE, FEMALE or OTHER
	Phone     string // digits only; empty when not known
	Status    member.Status
}

// Parse reads farmers from CSV. It returns every problem found, with its
// line number, so the file can be fixed in one go; rows are only usable when
// there are no problems. Blank lines are skipped. Warnings are for things
// allowed but worth a look (two farmers with one phone).
func Parse(r io.Reader) (rows []Row, problems, warnings []string) {
	cr := csv.NewReader(r)
	cr.FieldsPerRecord = -1
	cr.TrimLeadingSpace = true

	header, err := cr.Read()
	if err != nil {
		return nil, []string{"the file is empty or not CSV"}, nil
	}
	col := map[string]int{}
	for i, h := range header {
		col[strings.ToLower(strings.TrimSpace(strings.TrimPrefix(h, "\uFEFF")))] = i
	}
	for _, c := range requiredColumns {
		if _, ok := col[c]; !ok {
			problems = append(problems, fmt.Sprintf("missing column %q (needs: %s)", c, strings.Join(requiredColumns, ", ")))
		}
	}
	if len(problems) > 0 {
		return nil, problems, nil
	}

	numbers := map[string]int{}
	phones := map[string]int{}
	line := 1
	for {
		rec, err := cr.Read()
		line++
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			problems = append(problems, fmt.Sprintf("line %d: %v", line, err))
			continue
		}
		field := func(name string) string {
			if i := col[name]; i < len(rec) {
				return strings.TrimSpace(rec[i])
			}
			return ""
		}
		if strings.TrimSpace(strings.Join(rec, "")) == "" {
			continue
		}

		row, rowProblems := parseRow(line, field("membership_number"), field("name"), field("gender"), field("phone"), field("status"))
		for _, p := range rowProblems {
			problems = append(problems, fmt.Sprintf("line %d: %s", line, p))
		}
		if row.Number != "" {
			if first, seen := numbers[row.Number]; seen {
				problems = append(problems, fmt.Sprintf("line %d: membership number %s is also on line %d", line, row.Number, first))
			} else {
				numbers[row.Number] = line
			}
		}
		if row.Phone != "" {
			if first, seen := phones[row.Phone]; seen {
				warnings = append(warnings, fmt.Sprintf("line %d: phone %s is also on line %d", line, row.Phone, first))
			} else {
				phones[row.Phone] = line
			}
		}
		rows = append(rows, row)
	}
	if len(rows) == 0 && len(problems) == 0 {
		problems = append(problems, "the file has no farmers")
	}
	return rows, problems, warnings
}

func parseRow(line int, number, name, gender, phone, status string) (Row, []string) {
	var problems []string
	row := Row{Line: line, Number: strings.ToUpper(number)}
	if row.Number == "" {
		problems = append(problems, "membership number is missing")
	}

	words := strings.Fields(name)
	if len(words) < 2 {
		problems = append(problems, fmt.Sprintf("name %q needs a first and a last name", name))
	} else {
		row.FirstName = titleCase(words[0])
		row.LastName = titleCase(strings.Join(words[1:], " "))
	}

	switch strings.ToUpper(gender) {
	case "M", "MALE":
		row.Gender = "MALE"
	case "F", "FEMALE":
		row.Gender = "FEMALE"
	case "", "OTHER":
		row.Gender = "OTHER"
	default:
		problems = append(problems, fmt.Sprintf("gender %q is not M or F", gender))
	}

	if phone != "" {
		row.Phone = normalisePhone(phone)
		if row.Phone == "" {
			problems = append(problems, fmt.Sprintf("phone %q is not a Kenyan mobile number", phone))
		}
	}

	switch strings.ToUpper(status) {
	case "", "ACTIVE":
		row.Status = member.StatusActive
	case "INACTIVE":
		row.Status = member.StatusInactive
	default:
		problems = append(problems, fmt.Sprintf("status %q is not ACTIVE or INACTIVE", status))
	}
	return row, problems
}

// normalisePhone returns a phone as 07XXXXXXXX or 01XXXXXXXX, from that form,
// +254 or 254 forms, or a 9-digit number that lost its leading 0 in a
// spreadsheet. It returns "" when the number is not a Kenyan mobile number.
func normalisePhone(s string) string {
	var b strings.Builder
	for _, r := range s {
		if r >= '0' && r <= '9' {
			b.WriteRune(r)
		}
	}
	d := b.String()
	switch {
	case len(d) == 12 && strings.HasPrefix(d, "254"):
		d = "0" + d[3:]
	case len(d) == 9:
		d = "0" + d
	}
	if len(d) != 10 || !(strings.HasPrefix(d, "07") || strings.HasPrefix(d, "01")) {
		return ""
	}
	return d
}

// titleCase writes a name as people write it: "WANJIRU" -> "Wanjiru",
// "wa-njeri" -> "Wa-Njeri".
func titleCase(s string) string {
	out := []rune(strings.ToLower(s))
	start := true
	for i, r := range out {
		if start && unicode.IsLetter(r) {
			out[i] = unicode.ToUpper(r)
		}
		start = r == ' ' || r == '-' || r == '\''
	}
	return string(out)
}
