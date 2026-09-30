package member

import (
	"fmt"
	"strconv"
)

// minNumberWidth is the fewest digits a membership number is written with,
// as Saccos number their farmers: 002, 045, 150.
const minNumberWidth = 3

// nextMembershipNumber returns the number for the next farmer registered
// without one: one more than the highest number used so far, written with
// as many digits as the Sacco's own numbers (at least three).
//
// Only the digits at the end of a number count, so older numbers such as
// MEM-0012 continue as 013. Numbers used by removed farmers are included
// (existing should contain them): a number is never given out twice.
func nextMembershipNumber(existing []string) string {
	highest, width := 0, minNumberWidth
	for _, n := range existing {
		digits := trailingDigits(n)
		if digits == "" {
			continue
		}
		v, err := strconv.Atoi(digits)
		if err != nil {
			continue // too long to be a membership number
		}
		if v > highest {
			highest = v
		}
		// Match the width of numbers that are only digits (0150 -> 0151).
		if len(digits) == len(n) && len(n) > width {
			width = len(n)
		}
	}
	return fmt.Sprintf("%0*d", width, highest+1)
}

// trailingDigits returns the run of digits that s ends with.
func trailingDigits(s string) string {
	i := len(s)
	for i > 0 && s[i-1] >= '0' && s[i-1] <= '9' {
		i--
	}
	return s[i:]
}
