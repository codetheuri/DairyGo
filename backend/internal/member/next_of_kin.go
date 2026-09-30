package member

import (
	"fmt"
	"strings"
)

// nextOfKin is a farmer's next of kin with all three details present.
type nextOfKin struct {
	Name         string
	Relationship string
	Phone        string
}

// cleanNextOfKin trims the details and requires all of them: a name, how
// the person is related, and a phone number with at least 10 digits.
func cleanNextOfKin(name, relationship, phone *string) (nextOfKin, error) {
	kin := nextOfKin{Name: trimmed(name), Relationship: trimmed(relationship), Phone: trimmed(phone)}
	switch {
	case len(kin.Name) < 2:
		return nextOfKin{}, fmt.Errorf("next of kin name is required (update the app if it does not ask for it)")
	case len(kin.Relationship) < 2:
		return nextOfKin{}, fmt.Errorf("next of kin relationship is required, e.g. Spouse, Son, Daughter")
	case countDigits(kin.Phone) < 10:
		return nextOfKin{}, fmt.Errorf("next of kin phone number is required (at least 10 digits)")
	}
	return kin, nil
}

// firstSet returns value when the request sets it, otherwise the stored one.
func firstSet(value, stored *string) *string {
	if value != nil {
		return value
	}
	return stored
}

func trimmed(s *string) string {
	if s == nil {
		return ""
	}
	return strings.TrimSpace(*s)
}

func countDigits(s string) int {
	n := 0
	for _, r := range s {
		if r >= '0' && r <= '9' {
			n++
		}
	}
	return n
}
