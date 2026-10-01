package export

import "testing"

// Collected 142.5 L, sold 312 L: 169.5 L oversold, never "-169.5 L not sold yet".
func TestSplitBalance(t *testing.T) {
	for _, tt := range []struct{ in, notSold, over float64 }{
		{-169.5, 0, 169.5}, {12.5, 12.5, 0}, {0, 0, 0},
	} {
		if ns, ov := splitBalance(tt.in); ns != tt.notSold || ov != tt.over {
			t.Errorf("splitBalance(%v) = %v, %v; want %v, %v", tt.in, ns, ov, tt.notSold, tt.over)
		}
	}
	if f := balanceFigure(-196.5); f.Label != "Sold over collected" || f.Value != "196.50 L" {
		t.Errorf("oversold figure = %+v", f)
	}
	if f := balanceFigure(12); f.Label != "Not sold yet" || f.Value != "12.00 L" {
		t.Errorf("not sold figure = %+v", f)
	}
}
