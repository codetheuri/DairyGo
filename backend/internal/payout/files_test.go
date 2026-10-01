package payout

import "testing"

func TestMpesaPhone(t *testing.T) {
	for in, want := range map[string]string{
		"0712345678": "254712345678", "+254712345678": "254712345678", "254712345678": "254712345678",
		"0112 345 678": "254112345678", "712345678": "254712345678", "": "",
	} {
		if got := mpesaPhone(in); got != want {
			t.Errorf("mpesaPhone(%q) = %q, want %q", in, got, want)
		}
	}
}
