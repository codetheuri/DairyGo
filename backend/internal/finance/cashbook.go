package finance

import (
	"math"
	"sort"
	"time"
)

// Source is where a cashbook movement was recorded.
type Source string

const (
	SrcCustomerPayment Source = "CUSTOMER_PAYMENT"
	SrcCashSale        Source = "CASH_SALE"
	SrcTransferIn      Source = "TRANSFER_IN"
	SrcTransferOut     Source = "TRANSFER_OUT"
	SrcExpense         Source = "EXPENSE"
	SrcAdvance         Source = "ADVANCE"
	SrcFarmerPay       Source = "FARMER_PAY"
)

// Movement is money in or out of an account, as read from wherever it was
// recorded.
type Movement struct {
	AccountID   string    `json:"-"`
	Source      Source    `json:"source"`
	Date        time.Time `json:"date"`
	CreatedAt   time.Time `json:"-"`
	Description string    `json:"description"`
	Reference   *string   `json:"reference,omitempty"`
	RefID       string    `json:"ref_id"`
	In          float64   `json:"in"`
	Out         float64   `json:"out"`
}

// CashbookLine is a movement with the account balance after it.
type CashbookLine struct {
	Movement
	Balance float64 `json:"balance"`
}

// Cashbook is an account's money over a period.
type Cashbook struct {
	CashAccount    *CashAccount   `json:"account"`
	FromDate       string         `json:"from_date"`
	ToDate         string         `json:"to_date"`
	OpeningBalance float64        `json:"opening_balance"`
	TotalIn        float64        `json:"total_in"`
	TotalOut       float64        `json:"total_out"`
	ClosingBalance float64        `json:"closing_balance"`
	Lines          []CashbookLine `json:"lines"`
}

// buildCashbook applies movements in date order (then the order they were
// recorded) to a running balance. Movements before from only move the
// opening balance.
func buildCashbook(opening float64, from time.Time, moves []Movement) (open float64, lines []CashbookLine, in, out, closing float64) {
	sorted := make([]Movement, len(moves))
	copy(sorted, moves)
	sort.SliceStable(sorted, func(i, j int) bool {
		if !sorted[i].Date.Equal(sorted[j].Date) {
			return sorted[i].Date.Before(sorted[j].Date)
		}
		return sorted[i].CreatedAt.Before(sorted[j].CreatedAt)
	})
	balance := opening
	lines = []CashbookLine{}
	for _, m := range sorted {
		// Whole cents once, so totals and the running balance agree.
		m.In, m.Out = round2(m.In), round2(m.Out)
		if m.Date.Before(from) {
			balance += m.In - m.Out
			continue
		}
		if len(lines) == 0 {
			open = round2(balance)
		}
		balance = round2(balance + m.In - m.Out)
		in += m.In
		out += m.Out
		lines = append(lines, CashbookLine{Movement: m, Balance: balance})
	}
	if len(lines) == 0 {
		open = round2(balance)
	}
	return open, lines, round2(in), round2(out), round2(balance)
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
