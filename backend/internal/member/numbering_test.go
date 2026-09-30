package member

import "testing"

func TestNextMembershipNumber(t *testing.T) {
	tests := []struct {
		name     string
		existing []string
		want     string
	}{
		{"first farmer", nil, "001"},
		{"continues the Sacco's numbers", []string{"002", "150", "045"}, "151"},
		{"order does not matter", []string{"150", "002"}, "151"},
		{"keeps a wider style", []string{"0150", "0002"}, "0151"},
		{"grows past 999", []string{"999"}, "1000"},
		{"older prefixed numbers continue", []string{"MEM-0012", "MEM-0003"}, "013"},
		{"mixed", []string{"MEM-0200", "150"}, "201"},
		{"numbers without digits are ignored", []string{"ABC", "007"}, "008"},
		{"only letters", []string{"ABC"}, "001"},
		{"absurdly long number is ignored", []string{"99999999999999999999999", "010"}, "011"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := nextMembershipNumber(tt.existing); got != tt.want {
				t.Errorf("nextMembershipNumber(%q) = %q, want %q", tt.existing, got, tt.want)
			}
		})
	}
}
