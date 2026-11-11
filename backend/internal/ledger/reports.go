package ledger

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"time"

	"gorm.io/gorm"
)

// TrialRow is one account's balance on the trial balance.
type TrialRow struct {
	AccountID string  `json:"account_id"`
	Code      string  `json:"code"`
	Name      string  `json:"name"`
	Type      Type    `json:"type"`
	Debit     float64 `json:"debit"`
	Credit    float64 `json:"credit"`
}

// TrialBalance is every account's balance on a day.
type TrialBalance struct {
	Date        string     `json:"date"`
	StartDate   string     `json:"start_date"`
	Rows        []TrialRow `json:"rows"`
	TotalDebit  float64    `json:"total_debit"`
	TotalCredit float64    `json:"total_credit"`
	Balanced    bool       `json:"balanced"`
}

// TrialBalance lists each account with a balance at the end of a day
// (default today), debits and credits in their columns.
func (s *Service) TrialBalance(ctx context.Context, date string) (*TrialBalance, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	b, err := s.started(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	day, err := parseDay(date, s.today())
	if err != nil {
		return nil, err
	}
	upTo := day.Format(dateLayout)
	net, err := balances(ctx, db, saccoID, &upTo)
	if err != nil {
		return nil, err
	}
	c, err := loadChart(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	out := &TrialBalance{Date: upTo, StartDate: b.StartDate.Format(dateLayout), Rows: []TrialRow{}}
	for id, n := range net {
		a := c.accounts[id]
		if a == nil || n == 0 {
			continue
		}
		r := TrialRow{AccountID: id, Code: a.Code, Name: a.Name, Type: a.Type}
		if n > 0 {
			r.Debit = n
		} else {
			r.Credit = -n
		}
		out.TotalDebit += r.Debit
		out.TotalCredit += r.Credit
		out.Rows = append(out.Rows, r)
	}
	sort.Slice(out.Rows, func(i, k int) bool { return codeLess(out.Rows[i].Code, out.Rows[k].Code) })
	out.TotalDebit, out.TotalCredit = round2(out.TotalDebit), round2(out.TotalCredit)
	out.Balanced = same(out.TotalDebit, out.TotalCredit)
	return out, nil
}

// LedgerLine is one entry on an account with the balance after it.
type LedgerLine struct {
	JournalID string    `json:"journal_id"`
	Number    int64     `json:"number"`
	Date      time.Time `json:"date"`
	Memo      string    `json:"memo"`
	LineMemo  *string   `json:"line_memo,omitempty"`
	Kind      Kind      `json:"kind"`
	Debit     float64   `json:"debit"`
	Credit    float64   `json:"credit"`
	Balance   float64   `json:"balance" doc:"After this entry, in the account's usual direction"`
}

// AccountLedger is an account's entries over a period.
type AccountLedger struct {
	Account     *LedgerAccount `json:"account"`
	From        string         `json:"from_date"`
	To          string         `json:"to_date"`
	Opening     float64        `json:"opening_balance"`
	TotalDebit  float64        `json:"total_debit"`
	TotalCredit float64        `json:"total_credit"`
	Closing     float64        `json:"closing_balance"`
	Lines       []LedgerLine   `json:"lines"`
}

// AccountLedger lists an account's entries over a period (default this
// month) with the running balance, positive in the account's usual
// direction.
func (s *Service) AccountLedger(ctx context.Context, id, from, to string) (*AccountLedger, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	if _, err := s.started(ctx, db, saccoID); err != nil {
		return nil, err
	}
	var a LedgerAccount
	if err := db.Where("sacco_id = ? AND id = ?", saccoID, id).Take(&a).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("%w: account not found", ErrNotFound)
		}
		return nil, err
	}
	today := s.today()
	f, err := parseDay(from, time.Date(today.Year(), today.Month(), 1, 0, 0, 0, 0, time.UTC))
	if err != nil {
		return nil, err
	}
	t, err := parseDay(to, today)
	if err != nil {
		return nil, err
	}
	if t.Before(f) {
		return nil, fmt.Errorf("%w: the period ends before it starts", ErrInvalid)
	}
	sign := 1.0
	if !a.Type.DebitNormal() {
		sign = -1
	}
	var opening float64
	if err := db.Table("journal_lines").Select("COALESCE(SUM(debit) - SUM(credit), 0)").
		Where("sacco_id = ? AND account_id = ? AND journal_date < ?", saccoID, a.ID, f.Format(dateLayout)).
		Scan(&opening).Error; err != nil {
		return nil, err
	}
	var lines []LedgerLine
	if err := db.Table("journal_lines l").
		Select("l.journal_id, j.number, j.journal_date AS date, j.memo, l.memo AS line_memo, j.kind, l.debit, l.credit").
		Joins("JOIN journals j ON j.id = l.journal_id").
		Where("l.sacco_id = ? AND l.account_id = ? AND l.journal_date BETWEEN ? AND ?", saccoID, a.ID, f.Format(dateLayout), t.Format(dateLayout)).
		Order("j.journal_date, j.number, l.line_no").Scan(&lines).Error; err != nil {
		return nil, err
	}
	out := &AccountLedger{Account: &a, From: f.Format(dateLayout), To: t.Format(dateLayout), Lines: []LedgerLine{}}
	balance := round2(opening * sign)
	out.Opening = balance
	for _, l := range lines {
		balance = round2(balance + (l.Debit-l.Credit)*sign)
		l.Balance = balance
		out.TotalDebit += l.Debit
		out.TotalCredit += l.Credit
		out.Lines = append(out.Lines, l)
	}
	out.TotalDebit, out.TotalCredit, out.Closing = round2(out.TotalDebit), round2(out.TotalCredit), balance
	return out, nil
}
