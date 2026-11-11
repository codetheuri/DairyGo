package ledger

import (
	"context"
	"fmt"
	"sort"
	"time"
)

// What the downloads (internal/export) need from the books: every journal
// line in a period, plain enough to import into other accounting software,
// and every account's entries for the general ledger.

// ExportLine is one journal line with its journal and account.
type ExportLine struct {
	JournalID   string
	Number      int64
	Date        time.Time
	Kind        Kind
	SourceType  *string
	Memo        string
	Reference   *string
	AccountID   string
	AccountCode string
	AccountName string
	AccountType Type
	Debit       float64
	Credit      float64
	LineMemo    *string
}

// Source names where the line's journal came from, for people.
func (l ExportLine) Source() string {
	if l.Kind == KindManual {
		return "Manual"
	}
	if l.SourceType != nil {
		if s, ok := SourceLabels[*l.SourceType]; ok {
			return s
		}
	}
	return "Record"
}

// Period checks a download's period against the books: they must have
// started. Days before the start have nothing in them.
func (s *Service) Period(ctx context.Context) (start time.Time, err error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return time.Time{}, err
	}
	b, err := s.started(ctx, s.db.WithContext(ctx), saccoID)
	if err != nil {
		return time.Time{}, err
	}
	return b.StartDate, nil
}

// Lines lists every journal line dated from–to, by date, journal and line.
func (s *Service) Lines(ctx context.Context, from, to time.Time) ([]ExportLine, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	if _, err := s.started(ctx, db, saccoID); err != nil {
		return nil, err
	}
	var out []ExportLine
	err = db.Table("journal_lines l").
		Select(`j.id AS journal_id, j.number, j.journal_date AS date, j.kind, j.source_type, j.memo, j.reference,
			l.account_id, a.code AS account_code, a.name AS account_name, a.type AS account_type,
			l.debit, l.credit, l.memo AS line_memo`).
		Joins("JOIN journals j ON j.id = l.journal_id").
		Joins("JOIN ledger_accounts a ON a.id = l.account_id").
		Where("l.sacco_id = ? AND l.journal_date BETWEEN ? AND ?", saccoID, from.Format(dateLayout), to.Format(dateLayout)).
		Order("j.journal_date, j.number, l.line_no").Scan(&out).Error
	return out, err
}

// LedgerAccountEntries is one account in the general ledger.
type LedgerAccountEntries struct {
	Account *LedgerAccount
	Opening float64 // in the account's usual direction
	Lines   []ExportLine
	Debit   float64
	Credit  float64
	Closing float64
}

// GeneralLedger lists every account with an opening balance or entries in
// the period, by code, with balances in each account's usual direction.
func (s *Service) GeneralLedger(ctx context.Context, from, to time.Time) ([]LedgerAccountEntries, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	if to.Before(from) {
		return nil, fmt.Errorf("%w: the period ends before it starts", ErrInvalid)
	}
	lines, err := s.Lines(ctx, from, to)
	if err != nil {
		return nil, err
	}
	day := from.AddDate(0, 0, -1).Format(dateLayout)
	opening, err := balances(ctx, db, saccoID, &day)
	if err != nil {
		return nil, err
	}
	c, err := loadChart(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	byAccount := map[string]*LedgerAccountEntries{}
	get := func(id string) *LedgerAccountEntries {
		if e, ok := byAccount[id]; ok {
			return e
		}
		a := c.accounts[id]
		if a == nil {
			return nil
		}
		sign := 1.0
		if !a.Type.DebitNormal() {
			sign = -1
		}
		e := &LedgerAccountEntries{Account: a, Opening: round2(opening[id] * sign)}
		byAccount[id] = e
		return e
	}
	for id, v := range opening {
		if v != 0 {
			get(id)
		}
	}
	for _, l := range lines {
		if e := get(l.AccountID); e != nil {
			e.Lines = append(e.Lines, l)
			e.Debit += l.Debit
			e.Credit += l.Credit
		}
	}
	out := make([]LedgerAccountEntries, 0, len(byAccount))
	for _, e := range byAccount {
		sign := 1.0
		if !e.Account.Type.DebitNormal() {
			sign = -1
		}
		e.Debit, e.Credit = round2(e.Debit), round2(e.Credit)
		e.Closing = round2(e.Opening + (e.Debit-e.Credit)*sign)
		out = append(out, *e)
	}
	sort.Slice(out, func(i, k int) bool { return codeLess(out[i].Account.Code, out[k].Account.Code) })
	return out, nil
}
