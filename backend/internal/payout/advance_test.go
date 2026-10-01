package payout

import "testing"

func TestRoomFor(t *testing.T) {
	f := func(v float64) *float64 { return &v }
	i := func(v int) *int { return &v }
	tests := []struct {
		name                 string
		rules                AdvanceRules
		day                  int
		milk, taken, balance float64
		want                 *float64
		closed               bool
	}{
		{name: "no rules", day: 20, milk: 0, want: nil},
		{name: "limit only", rules: AdvanceRules{Max: f(5000)}, day: 5, taken: 3000, balance: -3000, want: f(2000)},
		{name: "limit used up", rules: AdvanceRules{Max: f(5000)}, day: 5, taken: 6000, want: f(0)},
		{name: "no milk, no advance", rules: AdvanceRules{MilkPercent: i(100)}, day: 5, milk: 0, want: f(0)},
		{name: "half the milk", rules: AdvanceRules{MilkPercent: i(50)}, day: 5, milk: 8000, want: f(4000)},
		{name: "milk less what is owed", rules: AdvanceRules{MilkPercent: i(100)}, day: 5, milk: 8000, taken: 2000, balance: -3500, want: f(4500)},
		{name: "arrears bigger than milk", rules: AdvanceRules{MilkPercent: i(100)}, day: 5, milk: 1000, balance: -1300, want: f(0)},
		{name: "smaller of limit and milk", rules: AdvanceRules{Max: f(5000), MilkPercent: i(100)}, day: 5, milk: 3000, want: f(3000)},
		{name: "limit smaller than milk", rules: AdvanceRules{Max: f(2000), MilkPercent: i(100)}, day: 5, milk: 9000, want: f(2000)},
		{name: "before the day", rules: AdvanceRules{FromDay: i(15), Max: f(5000)}, day: 14, want: f(0), closed: true},
		{name: "on the 1st, before the day", rules: AdvanceRules{FromDay: i(15)}, day: 1, want: f(0), closed: true},
		{name: "on the day", rules: AdvanceRules{FromDay: i(15)}, day: 15, want: nil},
		{name: "after the day", rules: AdvanceRules{FromDay: i(15), Max: f(5000)}, day: 31, want: f(5000)},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := roomFor(tt.rules, tt.day, tt.milk, tt.taken, tt.balance)
			if (got.Closed != "") != tt.closed {
				t.Errorf("closed = %q, want closed %v", got.Closed, tt.closed)
			}
			switch {
			case tt.want == nil && got.Available != nil:
				t.Errorf("available = %v, want no limit", *got.Available)
			case tt.want != nil && (got.Available == nil || *got.Available != *tt.want):
				t.Errorf("available = %v, want %v", got.Available, *tt.want)
			}
		})
	}
}

func TestOrdinal(t *testing.T) {
	for n, want := range map[int]string{1: "1st", 2: "2nd", 3: "3rd", 4: "4th", 11: "11th", 12: "12th", 13: "13th", 15: "15th", 21: "21st", 22: "22nd", 31: "31st"} {
		if got := ordinal(n); got != want {
			t.Errorf("ordinal(%d) = %q, want %q", n, got, want)
		}
	}
}

func TestAdvanceRefusal(t *testing.T) {
	f := func(v float64) *float64 { return &v }
	pct := 100
	tests := []struct {
		name   string
		amount float64
		info   AdvanceInfo
		want   string
	}{
		{name: "no rules", amount: 9000, info: AdvanceInfo{}, want: ""},
		{name: "within", amount: 2000, info: AdvanceInfo{Limit: f(5000), Available: f(2000)}, want: ""},
		{name: "closed", amount: 100, info: AdvanceInfo{Closed: "advances are given from the 15th of the month", Available: f(0)},
			want: "no advance on this date: advances are given from the 15th of the month"},
		{name: "over the limit", amount: 3000, info: AdvanceInfo{Limit: f(5000), OpenAdvance: 3000, Available: f(2000)},
			want: "Jane Muthoni can take at most KES 2,000 more this period (limit KES 5,000, already taken KES 3,000)"},
		{name: "no milk", amount: 5000, info: AdvanceInfo{MilkPercent: &pct, MilkAllows: f(0), Available: f(0)},
			want: "Jane Muthoni can take at most KES 0 now: 100% of the milk delivered (KES 0) less what they owe (KES 0)"},
		{name: "milk binds before the limit", amount: 4000, info: AdvanceInfo{Limit: f(5000), MilkPercent: &pct, MilkSoFar: 3000,
			Balance: -1000, OpenAdvance: 1000, MilkAllows: f(2000), Available: f(2000)},
			want: "Jane Muthoni can take at most KES 2,000 now: 100% of the milk delivered (KES 3,000) less what they owe (KES 1,000)"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := advanceRefusal("Jane Muthoni", tt.amount, &tt.info); got != tt.want {
				t.Errorf("got  %q\nwant %q", got, tt.want)
			}
		})
	}
}
