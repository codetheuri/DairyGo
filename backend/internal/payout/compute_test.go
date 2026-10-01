package payout

import (
	"reflect"
	"testing"
)

func ptr(f float64) *float64 { return &f }

// The M-Pesa-like tariff used in the tests.
var tariff = []Tier{{UpTo: ptr(100), Fee: 0}, {UpTo: ptr(1500), Fee: 5}, {UpTo: ptr(20000), Fee: 13}, {Fee: 23}}

var (
	shares  = Rule{TypeID: "shares", Name: "Shares", Method: MethodFixed, Amount: 500, Frequency: FreqUntilTarget, Target: 5000, Savings: true, Priority: 30}
	regFee  = Rule{TypeID: "reg", Name: "Registration fee", Method: MethodFixed, Amount: 300, Frequency: FreqOncePerMember, Priority: 10}
	subs    = Rule{TypeID: "subs", Name: "Annual subscription", Method: MethodFixed, Amount: 1200, Frequency: FreqOncePerYear, Priority: 20}
	txCost  = Rule{TypeID: "tx", Name: "Transaction cost", Method: MethodTiered, Base: BaseNet, Tiers: tariff, Frequency: FreqEveryRun, Priority: 1}
	cess    = Rule{TypeID: "cess", Name: "Cess", Method: MethodPercent, Amount: 1, Frequency: FreqEveryRun, Priority: 40}
	haulage = Rule{TypeID: "haul", Name: "Transport", Method: MethodPerLitre, Amount: 1.5, Frequency: FreqEveryRun, Priority: 5}
)

func names(items []Item) map[string]float64 {
	out := map[string]float64{}
	for _, it := range items {
		out[it.TypeID] = it.Amount
	}
	return out
}

func TestCompute(t *testing.T) {
	tests := []struct {
		name      string
		in        SlipInput
		wantItems map[string]float64
		wantNet   float64
		wantClose float64
	}{
		{
			name: "the plan's farmer: 400 L at 50, an advance and feeds, every rule",
			in: SlipInput{
				Litres: 400, Gross: 20000, Entries: -3000 - 1500,
				Rules: []Rule{shares, regFee, subs, txCost},
			},
			// 20,000 − 4,500 − 300 − 1,200 − 500 = 13,500; fee on 13,500 is 13.
			wantItems: map[string]float64{"reg": 300, "subs": 1200, "shares": 500, "tx": 13},
			wantNet:   13487,
		},
		{
			name: "once-per-member and yearly deductions are not taken again",
			in: SlipInput{
				Litres: 100, Gross: 5000,
				Rules: []Rule{regFee, subs},
				Taken: map[string]Taken{"reg": {Ever: true}, "subs": {Ever: true, ThisYear: true}},
			},
			wantItems: map[string]float64{},
			wantNet:   5000,
		},
		{
			name: "a new year: the subscription is due again",
			in: SlipInput{
				Gross: 5000, Rules: []Rule{subs},
				Taken: map[string]Taken{"subs": {Ever: true}},
			},
			wantItems: map[string]float64{"subs": 1200},
			wantNet:   3800,
		},
		{
			name: "shares stop at the target, taking only what is left",
			in: SlipInput{
				Gross: 5000, Rules: []Rule{shares},
				Taken: map[string]Taken{"shares": {Total: 4800}},
			},
			wantItems: map[string]float64{"shares": 200},
			wantNet:   4800,
		},
		{
			name: "shares reached: nothing taken",
			in: SlipInput{
				Gross: 5000, Rules: []Rule{shares},
				Taken: map[string]Taken{"shares": {Total: 5000}},
			},
			wantItems: map[string]float64{},
			wantNet:   5000,
		},
		{
			name: "fees above pay become arrears; savings and the transaction cost are not",
			in: SlipInput{
				Gross: 1000, Entries: -800,
				Rules: []Rule{regFee, shares, txCost},
			},
			// 1,000 − 800 = 200; fee 300 → −100 owed; nothing for shares or M-Pesa.
			wantItems: map[string]float64{"reg": 300},
			wantNet:   0,
			wantClose: -100,
		},
		{
			name: "savings take part when the pay is short",
			in: SlipInput{
				Gross: 1200, Entries: -900,
				Rules: []Rule{shares},
			},
			wantItems: map[string]float64{"shares": 300},
			wantNet:   0,
		},
		{
			name: "arrears from last run are recovered first",
			in: SlipInput{
				Opening: -2500, Gross: 6000,
				Rules: []Rule{txCost},
			},
			wantItems: map[string]float64{"tx": 13},
			wantNet:   3487,
		},
		{
			name: "no milk: no deductions, advances carried as arrears",
			in: SlipInput{
				Entries: -2000,
				Rules:   []Rule{regFee, subs, shares, txCost},
			},
			wantItems: map[string]float64{},
			wantNet:   0,
			wantClose: -2000,
		},
		{
			name: "per litre and percent of gross",
			in: SlipInput{
				Litres: 200, Gross: 9000,
				Rules: []Rule{haulage, cess},
			},
			// 200 × 1.5 = 300; 1% of 9,000 = 90.
			wantItems: map[string]float64{"haul": 300, "cess": 90},
			wantNet:   8610,
		},
		{
			name: "the transaction cost is taken last whatever its priority, on the money sent",
			in: SlipInput{
				Gross: 1550, Rules: []Rule{txCost, regFee},
			},
			// 1,550 − 300 = 1,250 → band up to 1,500 → 5.
			wantItems: map[string]float64{"reg": 300, "tx": 5},
			wantNet:   1245,
		},
		{
			name: "a transaction cost that would eat the whole payment is skipped",
			in: SlipInput{
				Gross: 1000, Entries: -990,
				Rules: []Rule{{TypeID: "flat", Method: MethodTiered, Base: BaseNet, Tiers: []Tier{{Fee: 13}}, Frequency: FreqEveryRun}},
			},
			wantItems: map[string]float64{},
			wantNet:   10,
		},
		{
			name: "a credit adjustment adds to pay",
			in: SlipInput{
				Gross: 1000, Entries: 250.5,
			},
			wantItems: map[string]float64{},
			wantNet:   1250.5,
		},
		{
			name: "rounding to cents",
			in: SlipInput{
				Litres: 33.33, Gross: 1666.5, Rules: []Rule{{TypeID: "p", Method: MethodPercent, Amount: 2.5, Frequency: FreqEveryRun}},
			},
			// 2.5% of 1,666.50 = 41.6625 → 41.66
			wantItems: map[string]float64{"p": 41.66},
			wantNet:   1624.84,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := Compute(tt.in)
			if items := names(got.Items); !reflect.DeepEqual(items, tt.wantItems) {
				t.Errorf("deductions = %v, want %v", items, tt.wantItems)
			}
			if got.Net != tt.wantNet {
				t.Errorf("net = %v, want %v", got.Net, tt.wantNet)
			}
			if got.Closing != tt.wantClose {
				t.Errorf("closing = %v, want %v", got.Closing, tt.wantClose)
			}
			if got.Net < 0 {
				t.Errorf("net is negative: %v", got.Net)
			}
			// Everything adds up.
			sum := got.Opening + got.Gross + got.Entries - got.Deductions
			if round2(sum) != round2(got.Net+got.Closing) {
				t.Errorf("opening+gross+entries−deductions = %v, but net+closing = %v", sum, got.Net+got.Closing)
			}
		})
	}
}

func TestComputeTakesInPriorityOrder(t *testing.T) {
	a := Rule{TypeID: "a", Method: MethodFixed, Amount: 100, Frequency: FreqEveryRun, Priority: 2, Savings: true}
	b := Rule{TypeID: "b", Method: MethodFixed, Amount: 100, Frequency: FreqEveryRun, Priority: 1, Savings: true}
	got := Compute(SlipInput{Gross: 150, Rules: []Rule{a, b}})
	if len(got.Items) != 2 || got.Items[0].TypeID != "b" || got.Items[0].Amount != 100 || got.Items[1].Amount != 50 {
		t.Fatalf("items = %+v, want b 100 then a 50", got.Items)
	}
}

func TestTierFee(t *testing.T) {
	for amount, want := range map[float64]float64{0: 0, 50: 0, 100: 0, 100.01: 5, 1500: 5, 20000: 13, 20000.5: 23, 150000: 23} {
		if got := tierFee(tariff, amount); got != want {
			t.Errorf("tierFee(%v) = %v, want %v", amount, got, want)
		}
	}
	if got := tierFee([]Tier{{UpTo: ptr(100), Fee: 1}}, 500); got != 0 {
		t.Errorf("above the last band with a limit = %v, want 0", got)
	}
}
