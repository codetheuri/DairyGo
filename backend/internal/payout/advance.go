package payout

import (
	"fmt"
	"math"
)

// AdvanceRules are a Sacco's rules for advances; each is optional.
type AdvanceRules struct {
	Max         *float64 // most a farmer may take between pay runs, KES
	LastDay     *int     // advances only from the 1st up to this day of the month
	MilkPercent *int     // advance + what is owed ≤ this % of milk delivered since the last pay run
}

// advanceRoom is how much more a farmer may take as an advance, and why.
type advanceRoom struct {
	Closed    string   // why no advance can be given on this day; "" when open
	ByLimit   *float64 // what the KES limit leaves
	ByMilk    *float64 // what the milk rule leaves
	Available *float64 // the smaller of the two; nil when no rule limits it
}

// roomFor works out the room for an advance on day of the month, from the
// milk value delivered since the last pay run, the advances already taken
// and the farmer's account balance (negative = owes: open advances,
// charges and arrears). It is pure so the rules are table-tested.
func roomFor(r AdvanceRules, day int, milk, taken, balance float64) advanceRoom {
	var room advanceRoom
	if r.Max != nil {
		v := round2(math.Max(*r.Max-taken, 0))
		room.ByLimit = &v
	}
	if r.MilkPercent != nil {
		v := round2(math.Max(float64(*r.MilkPercent)/100*milk+balance, 0))
		room.ByMilk = &v
	}
	switch {
	case room.ByLimit != nil && room.ByMilk != nil:
		v := math.Min(*room.ByLimit, *room.ByMilk)
		room.Available = &v
	case room.ByLimit != nil:
		room.Available = room.ByLimit
	case room.ByMilk != nil:
		room.Available = room.ByMilk
	}
	if r.LastDay != nil && day > *r.LastDay {
		room.Closed = fmt.Sprintf("advances are given only up to the %s of the month", ordinal(*r.LastDay))
		zero := 0.0
		room.Available = &zero
	}
	return room
}

// ordinal writes 1 as 1st, 2 as 2nd, 15 as 15th, 22 as 22nd.
func ordinal(n int) string {
	suffix := "th"
	if n%100 < 11 || n%100 > 13 {
		switch n % 10 {
		case 1:
			suffix = "st"
		case 2:
			suffix = "nd"
		case 3:
			suffix = "rd"
		}
	}
	return fmt.Sprintf("%d%s", n, suffix)
}
