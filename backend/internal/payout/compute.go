package payout

import (
	"math"
	"sort"
)

// Rule is a deduction as it applies to one farmer in one pay run: the
// Sacco's deduction type with any per-farmer amount or target already
// applied (see Repository.RulesFor).
type Rule struct {
	TypeID    string
	Name      string
	Method    Method
	Base      Base
	Amount    float64 // FIXED: KES; PERCENT: percent; PER_LITRE: KES per litre
	Tiers     []Tier  // TIERED only
	Frequency Frequency
	Target    float64 // UNTIL_TARGET only
	Savings   bool
	Priority  int
}

// Taken is what a farmer has already paid towards one deduction type in
// earlier pay runs, which decides whether ONCE_PER_MEMBER, ONCE_PER_YEAR and
// UNTIL_TARGET deductions are due again.
type Taken struct {
	Ever     bool
	ThisYear bool
	Total    float64
}

// SlipInput is everything needed to work out one farmer's pay.
type SlipInput struct {
	// Opening is the farmer's balance from earlier pay runs: arrears are
	// negative.
	Opening float64
	Litres  float64
	Gross   float64
	// Entries are advances, charges and adjustments since the last pay run,
	// signed (an advance is negative).
	Entries float64
	Rules   []Rule
	Taken   map[string]Taken
}

// Item is one deduction on a payslip.
type Item struct {
	TypeID  string  `json:"deduction_type_id"`
	Name    string  `json:"name"`
	Amount  float64 `json:"amount"`
	Savings bool    `json:"savings"`
}

// Slip is one farmer's pay for a run.
type Slip struct {
	Opening    float64 `json:"opening_balance"`
	Litres     float64 `json:"litres"`
	Gross      float64 `json:"gross"`
	Entries    float64 `json:"advances_and_charges"`
	Items      []Item  `json:"deductions"`
	Deductions float64 `json:"total_deductions"`
	// Net is what is paid out; never negative.
	Net float64 `json:"net"`
	// Closing is what is carried to the next run: zero, or arrears
	// (negative) when the farmer owes more than they earned.
	Closing float64 `json:"closing_balance"`
}

// Compute works out a farmer's pay:
//
//	available = opening + gross + advances/charges (signed)
//	then each due deduction in priority order (deductions on GROSS first,
//	then those on the NET pay, such as the transaction cost)
//	net = max(0, what is left); closing = min(0, what is left)
//
// Fees and other charges are taken in full even when the farmer earned
// less, so the shortfall is carried forward as arrears. Savings (shares)
// take only what is available: a shortfall in savings is not a debt.
// Deductions on the NET pay are only taken from money actually being paid,
// and skipped when they would take all of it.
// Deductions apply only to farmers who delivered milk in the period.
func Compute(in SlipInput) Slip {
	slip := Slip{
		Opening: round2(in.Opening),
		Litres:  round2(in.Litres),
		Gross:   round2(in.Gross),
		Entries: round2(in.Entries),
		Items:   []Item{},
	}
	available := slip.Opening + slip.Gross + slip.Entries

	if slip.Gross > 0 {
		rules := make([]Rule, len(in.Rules))
		copy(rules, in.Rules)
		sort.SliceStable(rules, func(i, j int) bool {
			if (rules[i].Base == BaseNet) != (rules[j].Base == BaseNet) {
				return rules[j].Base == BaseNet
			}
			return rules[i].Priority < rules[j].Priority
		})

		for _, r := range rules {
			taken := in.Taken[r.TypeID]
			if !dueAgain(r, taken) {
				continue
			}
			base := slip.Gross
			if r.Base == BaseNet {
				base = math.Max(available, 0)
			}
			due := round2(amountFor(r, base, slip.Litres))
			if r.Frequency == FreqUntilTarget {
				due = math.Min(due, round2(r.Target-taken.Total))
			}
			if r.Base == BaseNet && due >= round2(available) {
				// It would eat the whole payment: nothing is sent, so
				// there is no cost to recover.
				continue
			}
			if r.Savings {
				due = math.Min(due, math.Max(round2(available), 0))
			}
			if due <= 0 {
				continue
			}
			slip.Items = append(slip.Items, Item{TypeID: r.TypeID, Name: r.Name, Amount: due, Savings: r.Savings})
			slip.Deductions = round2(slip.Deductions + due)
			available = round2(available - due)
		}
	}

	available = round2(available)
	slip.Net = math.Max(available, 0)
	slip.Closing = math.Min(available, 0)
	return slip
}

// dueAgain reports whether a deduction applies given what was taken before.
func dueAgain(r Rule, t Taken) bool {
	switch r.Frequency {
	case FreqOncePerMember:
		return !t.Ever
	case FreqOncePerYear:
		return !t.ThisYear
	case FreqUntilTarget:
		return r.Target > 0 && t.Total < r.Target
	default:
		return true
	}
}

// amountFor is a rule's amount before limits.
func amountFor(r Rule, base, litres float64) float64 {
	switch r.Method {
	case MethodPercent:
		return base * r.Amount / 100
	case MethodPerLitre:
		return litres * r.Amount
	case MethodTiered:
		return tierFee(r.Tiers, base)
	default:
		return r.Amount
	}
}

// tierFee is the fee of the first band the amount falls in. Bands are
// ordered by UpTo; a band with no UpTo covers everything above.
func tierFee(tiers []Tier, amount float64) float64 {
	if amount <= 0 {
		return 0
	}
	for _, t := range tiers {
		if t.UpTo == nil || amount <= *t.UpTo {
			return t.Fee
		}
	}
	return 0
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
