package member

import (
	"fmt"
	"strings"
)

// nextOfKin is a farmer's next of kin. It is optional: an empty detail is
// stored as NULL.
type nextOfKin struct {
	Name         string
	Relationship string
	Phone        string
}

// cleanNextOfKin trims the details. All may be left empty; once any is
// given, the name is needed, and a phone number must have at least 10 digits.
func cleanNextOfKin(name, relationship, phone *string) (nextOfKin, error) {
	kin := nextOfKin{Name: trimmed(name), Relationship: trimmed(relationship), Phone: trimmed(phone)}
	switch {
	case kin == nextOfKin{}:
		return kin, nil
	case len(kin.Name) < 2:
		return nextOfKin{}, fmt.Errorf("give the next of kin's name, or leave all next of kin details empty")
	case kin.Phone != "" && countDigits(kin.Phone) < 10:
		return nextOfKin{}, fmt.Errorf("next of kin phone number must have at least 10 digits")
	}
	return kin, nil
}

// orNil is s, or nil when it is empty, so blank details are stored as NULL.
func orNil(s string) *string {
	if s == "" {
		return nil
	}
	return &s
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
