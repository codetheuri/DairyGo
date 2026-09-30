package reconcile

import "testing"

func TestCompute(t *testing.T) {
	tests := []struct {
		name                         string
		collected, sold, spoiled, ok float64
		wantUnaccounted              float64
		wantStatus                   Status
	}{
		{"all milk sold or spoiled", 500, 480, 20, 0, 0, StatusBalanced},
		{"missing milk", 500, 450, 20, 0, 30, StatusMissing},
		{"oversold milk", 500, 510, 0, 0, -10, StatusOversold},
		{"small difference within tolerance", 500, 499.2, 0, 1, 0.8, StatusBalanced},
		{"oversold within tolerance", 500, 500.5, 0, 1, -0.5, StatusBalanced},
		{"beyond tolerance", 500, 497, 0, 1, 3, StatusMissing},
		{"float noise is balanced", 100.1, 60.05, 40.05, 0, 0, StatusBalanced},
		{"nothing happened", 0, 0, 0, 0, 0, StatusBalanced},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := Compute(tt.collected, tt.sold, tt.spoiled, tt.ok)
			if r.UnaccountedLitres != tt.wantUnaccounted || r.Status != tt.wantStatus {
				t.Fatalf("got %+v, want unaccounted %.2f status %s", r, tt.wantUnaccounted, tt.wantStatus)
			}
			if r.IsBalanced != (tt.wantStatus == StatusBalanced) {
				t.Fatalf("IsBalanced mismatch: %+v", r)
			}
		})
	}
}

// The owner's example: A collects 80, sells 55, gives B 20, spoils 5.
func TestBalanceWithTransfers(t *testing.T) {
	a := Balance(Flows{Collected: 80, Sold: 55, TransferredOut: 20, Spoiled: 5}, 0)
	if a.UnaccountedLitres != 0 || a.Status != StatusBalanced {
		t.Fatalf("sender: got %+v", a)
	}
	// B collected 100, received A's 20 and sold 110: 10 L are missing.
	b := Balance(Flows{Collected: 100, Received: 20, Sold: 110}, 0)
	if b.UnaccountedLitres != 10 || b.Status != StatusMissing {
		t.Fatalf("receiver: got %+v", b)
	}
	// Forgetting the transfer would blame the wrong collector.
	if Compute(80, 55, 5, 0).Status != StatusMissing || Compute(100, 110, 0, 0).Status != StatusOversold {
		t.Fatal("without transfers the balances should be off")
	}
	// Across the Sacco the transfer cancels out.
	sacco := Balance(Flows{Collected: 180, Received: 20, Sold: 165, TransferredOut: 20, Spoiled: 5}, 0)
	if sacco != Compute(180, 165, 5, 0) {
		t.Fatalf("sacco: %+v vs %+v", sacco, Compute(180, 165, 5, 0))
	}
}
