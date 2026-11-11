package ledger

import (
	"math"
	"testing"
)

func TestRound2NoNegativeZero(t *testing.T) {
	if v := round2(-0.001); math.Signbit(v) {
		t.Fatalf("round2(-0.001) = %v, want 0", v)
	}
	if v := round2(-(0.0)); math.Signbit(v) {
		t.Fatal("negated zero must print as 0")
	}
}
