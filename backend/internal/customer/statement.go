package customer

import (
	"math"
	"sort"
	"time"
)

// EntryKind identifies what a statement line records.
type EntryKind string

const (
	EntrySale    EntryKind = "SALE"
	EntryPayment EntryKind = "PAYMENT"
)

// LedgerEvent is a sale or payment as read from storage, before balances are applied.
// For a sale, Debit is the sale total and Credit is what was paid at the sale.
// For a payment, Debit is zero and Credit is the amount paid.
type LedgerEvent struct {
	Kind        EntryKind
	ReferenceID string
	Date        time.Time
	CreatedAt   time.Time
	Description string
	Litres      float64
	Debit       float64
	Credit      float64
	// Who and how, shown when a line is opened: Rate is the sale's price
	// per litre; RecordedByID the collector (sale) or staff (payment).
	Rate         float64
	RecordedByID *uint
	RecordedBy   string
	Method       string
	Reference    string
	LateReason   *string
}

// StatementLine is one row of a customer statement with its running balance.
type StatementLine struct {
	Kind        EntryKind `json:"kind"`
	ReferenceID string    `json:"reference_id"`
	Date        string    `json:"date"`
	Description string    `json:"description"`
	Litres      float64   `json:"litres,omitempty"`
	Debit       float64   `json:"debit"`
	Credit      float64   `json:"credit"`
	Balance     float64   `json:"balance"`
	Rate        float64   `json:"rate,omitempty" doc:"Sales: price per litre"`
	RecordedBy  string    `json:"recorded_by,omitempty" doc:"The collector who made the sale, or the staff member who recorded the payment"`
	RecordedAt  time.Time `json:"recorded_at" doc:"When it was entered"`
	Method      string    `json:"method,omitempty" doc:"How it was paid (CASH, MPESA, BANK_TRANSFER, CHEQUE, CREDIT)"`
	Reference   string    `json:"reference,omitempty" doc:"Payments: M-Pesa code or other reference"`
	LateReason  *string   `json:"late_reason,omitempty" doc:"Sales entered after their day by DairyGo support: why"`
}

// Statement is a customer's ledger over a period. A positive balance is money
// the customer owes the Sacco; a negative balance is an overpayment (credit).
type Statement struct {
	Customer       *Customer       `json:"customer"`
	FromDate       string          `json:"from_date"`
	ToDate         string          `json:"to_date"`
	OpeningBalance float64         `json:"opening_balance"`
	TotalDebit     float64         `json:"total_debit"`
	TotalCredit    float64         `json:"total_credit"`
	TotalLitres    float64         `json:"total_litres" doc:"Litres sold to the customer in the period"`
	ClosingBalance float64         `json:"closing_balance"`
	Lines          []StatementLine `json:"lines"`
}

// buildStatement orders events by date (then by entry time) and applies each
// one to the running balance, starting from the opening balance.
func buildStatement(opening float64, events []LedgerEvent) (lines []StatementLine, totalDebit, totalCredit, closing float64) {
	sorted := make([]LedgerEvent, len(events))
	copy(sorted, events)
	sort.SliceStable(sorted, func(i, j int) bool {
		if !sorted[i].Date.Equal(sorted[j].Date) {
			return sorted[i].Date.Before(sorted[j].Date)
		}
		return sorted[i].CreatedAt.Before(sorted[j].CreatedAt)
	})

	balance := opening
	lines = make([]StatementLine, 0, len(sorted))
	for _, e := range sorted {
		balance = round2(balance + e.Debit - e.Credit)
		totalDebit += e.Debit
		totalCredit += e.Credit
		lines = append(lines, StatementLine{
			Kind:        e.Kind,
			ReferenceID: e.ReferenceID,
			Date:        e.Date.Format("2006-01-02"),
			Description: e.Description,
			Litres:      e.Litres,
			Debit:       round2(e.Debit),
			Credit:      round2(e.Credit),
			Balance:     balance,
			Rate:        round2(e.Rate),
			RecordedBy:  e.RecordedBy,
			RecordedAt:  e.CreatedAt,
			Method:      e.Method,
			Reference:   e.Reference,
			LateReason:  e.LateReason,
		})
	}
	return lines, round2(totalDebit), round2(totalCredit), balance
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
