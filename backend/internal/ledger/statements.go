package ledger

import (
	"context"
	"fmt"
	"sort"
	"time"

	"gorm.io/gorm"
)

// The statements (phase 3): the income statement for a period and the
// balance sheet on a day, each with the period before beside it, worked out
// from the journals alone, so they always agree with the trial balance.
//
// Until years are closed (phase 5), income and expenses stay in their
// accounts, so the balance sheet shows them as two equity lines: this
// financial year's surplus, and the surplus of earlier years since the books
// started (what was made before the start is already in Retained surplus,
// through the opening journal).

// BooksLine is one account on a statement, positive in the account's
// usual direction.
type BooksLine struct {
	AccountID string  `json:"account_id,omitempty"`
	Code      string  `json:"code,omitempty"`
	Name      string  `json:"name"`
	Amount    float64 `json:"amount"`
	Previous  float64 `json:"previous"`
}

// BooksSection is a group of lines with their totals.
type BooksSection struct {
	Title         string      `json:"title"`
	Lines         []BooksLine `json:"lines"`
	Total         float64     `json:"total"`
	PreviousTotal float64     `json:"previous_total"`
}

// IncomeStatement is income less expenses over a period.
type IncomeStatement struct {
	From            string       `json:"from_date"`
	To              string       `json:"to_date"`
	PreviousFrom    string       `json:"previous_from"`
	PreviousTo      string       `json:"previous_to"`
	StartDate       string       `json:"books_start_date"`
	Income          BooksSection `json:"income"`
	Expenses        BooksSection `json:"expenses"`
	Surplus         float64      `json:"surplus" doc:"Income less expenses; negative is a deficit"`
	PreviousSurplus float64      `json:"previous_surplus"`
}

// BalanceSheet is what the Sacco owns and owes on a day.
type BalanceSheet struct {
	Date                     string       `json:"date"`
	PreviousDate             string       `json:"previous_date"`
	StartDate                string       `json:"books_start_date"`
	Assets                   BooksSection `json:"assets"`
	Liabilities              BooksSection `json:"liabilities"`
	Equity                   BooksSection `json:"equity"`
	LiabilitiesAndEquity     float64      `json:"liabilities_and_equity"`
	PrevLiabilitiesAndEquity float64      `json:"previous_liabilities_and_equity"`
	Balanced                 bool         `json:"balanced" doc:"Assets equal liabilities plus equity"`
}

// previousPeriod is the period of the same length just before from–to:
// whole months when from is the 1st (a month, a quarter, a financial year),
// otherwise the same number of days.
func previousPeriod(from, to time.Time) (time.Time, time.Time) {
	if from.Day() == 1 {
		months := (to.Year()-from.Year())*12 + int(to.Month()-from.Month()) + 1
		pf := from.AddDate(0, -months, 0)
		endOfMonth := to.AddDate(0, 0, 1).Day() == 1
		if endOfMonth {
			first := time.Date(to.Year(), to.Month(), 1, 0, 0, 0, 0, time.UTC)
			return pf, first.AddDate(0, -months+1, -1)
		}
		pt := time.Date(to.Year(), to.Month()-time.Month(months), 1, 0, 0, 0, 0, time.UTC)
		last := pt.AddDate(0, 1, -1)
		if to.Day() > last.Day() {
			return pf, last
		}
		return pf, pt.AddDate(0, 0, to.Day()-1)
	}
	days := int(to.Sub(from).Hours()/24) + 1
	pt := from.AddDate(0, 0, -1)
	return pt.AddDate(0, 0, -days+1), pt
}

// yearStart is the first day of the financial year day falls in.
func yearStart(day time.Time, startMonth int) time.Time {
	if startMonth < 1 || startMonth > 12 {
		startMonth = 1
	}
	y := day.Year()
	if int(day.Month()) < startMonth {
		y--
	}
	return time.Date(y, time.Month(startMonth), 1, 0, 0, 0, 0, time.UTC)
}

// movements is each account's debits less credits between two days.
func movements(ctx context.Context, db *gorm.DB, saccoID string, from, to time.Time) (map[string]float64, error) {
	var rows []struct {
		AccountID string
		Net       float64
	}
	if err := db.WithContext(ctx).Table("journal_lines").Select("account_id, SUM(debit) - SUM(credit) AS net").
		Where("sacco_id = ? AND journal_date BETWEEN ? AND ?", saccoID, from.Format(dateLayout), to.Format(dateLayout)).
		Group("account_id").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := map[string]float64{}
	for _, r := range rows {
		out[r.AccountID] = round2(r.Net)
	}
	return out, nil
}

// section lists the accounts of one type with an amount in either column,
// by code, in the type's usual direction.
func section(title string, t Type, c *chart, now, before map[string]float64) BooksSection {
	sign := 1.0
	if !t.DebitNormal() {
		sign = -1
	}
	s := BooksSection{Title: title, Lines: []BooksLine{}}
	for id, a := range c.accounts {
		if a.Type != t {
			continue
		}
		cur, prev := round2(now[id]*sign), round2(before[id]*sign)
		if cur == 0 && prev == 0 {
			continue
		}
		s.Lines = append(s.Lines, BooksLine{AccountID: id, Code: a.Code, Name: a.Name, Amount: cur, Previous: prev})
		s.Total += cur
		s.PreviousTotal += prev
	}
	sort.Slice(s.Lines, func(i, k int) bool { return codeLess(s.Lines[i].Code, s.Lines[k].Code) })
	s.Total, s.PreviousTotal = round2(s.Total), round2(s.PreviousTotal)
	return s
}

// IncomeStatement is income and expenses between two days (default this
// month so far), with the period before beside it.
func (s *Service) IncomeStatement(ctx context.Context, from, to string) (*IncomeStatement, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	b, err := s.started(ctx, db, saccoID)
	if err != nil {
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
	pf, pt := previousPeriod(f, t)
	c, err := loadChart(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	now, err := movements(ctx, db, saccoID, f, t)
	if err != nil {
		return nil, err
	}
	before, err := movements(ctx, db, saccoID, pf, pt)
	if err != nil {
		return nil, err
	}
	out := &IncomeStatement{From: f.Format(dateLayout), To: t.Format(dateLayout), PreviousFrom: pf.Format(dateLayout),
		PreviousTo: pt.Format(dateLayout), StartDate: b.StartDate.Format(dateLayout),
		Income: section("Income", Income, c, now, before), Expenses: section("Expenses", Expense, c, now, before)}
	out.Surplus = round2(out.Income.Total - out.Expenses.Total)
	out.PreviousSurplus = round2(out.Income.PreviousTotal - out.Expenses.PreviousTotal)
	return out, nil
}

// BalanceSheet is the position at the end of a day (default today), beside
// the position at the end of another (default the end of the last
// financial year).
func (s *Service) BalanceSheet(ctx context.Context, date, previous string) (*BalanceSheet, error) {
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
	var month int
	if err := db.Table("sacco_settings").Select("COALESCE(MAX(financial_year_start_month), 1)").
		Where("sacco_id = ?", saccoID).Scan(&month).Error; err != nil {
		return nil, err
	}
	prev, err := parseDay(previous, yearStart(day, month).AddDate(0, 0, -1))
	if err != nil {
		return nil, err
	}
	c, err := loadChart(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	at := func(d time.Time) (map[string]float64, error) {
		v := d.Format(dateLayout)
		return balances(ctx, db, saccoID, &v)
	}
	now, err := at(day)
	if err != nil {
		return nil, err
	}
	before, err := at(prev)
	if err != nil {
		return nil, err
	}
	out := &BalanceSheet{Date: day.Format(dateLayout), PreviousDate: prev.Format(dateLayout), StartDate: b.StartDate.Format(dateLayout),
		Assets:      section("Assets", Asset, c, now, before),
		Liabilities: section("Liabilities", Liability, c, now, before),
		Equity:      section("Equity", Equity, c, now, before)}

	// Income and expenses not yet closed into retained surplus: this
	// financial year's, and earlier years' since the books started.
	surplus := func(upTo time.Time, nets map[string]float64) (thisYear, earlier float64, err error) {
		ys := yearStart(upTo, month)
		mv, err := movements(ctx, db, saccoID, ys, upTo)
		if err != nil {
			return 0, 0, err
		}
		for id, a := range c.accounts {
			if a.Type == Income || a.Type == Expense {
				earlier -= nets[id] - mv[id]
				thisYear -= mv[id]
			}
		}
		return round2(thisYear), round2(earlier), nil
	}
	ty, ey, err := surplus(day, now)
	if err != nil {
		return nil, err
	}
	pty, pey, err := surplus(prev, before)
	if err != nil {
		return nil, err
	}
	if ey != 0 || pey != 0 {
		out.Equity.Lines = append(out.Equity.Lines, BooksLine{Name: "Surplus of earlier years (not yet closed)", Amount: ey, Previous: pey})
	}
	out.Equity.Lines = append(out.Equity.Lines, BooksLine{Name: "Surplus this financial year", Amount: ty, Previous: pty})
	out.Equity.Total = round2(out.Equity.Total + ty + ey)
	out.Equity.PreviousTotal = round2(out.Equity.PreviousTotal + pty + pey)
	out.LiabilitiesAndEquity = round2(out.Liabilities.Total + out.Equity.Total)
	out.PrevLiabilitiesAndEquity = round2(out.Liabilities.PreviousTotal + out.Equity.PreviousTotal)
	out.Balanced = same(out.Assets.Total, out.LiabilitiesAndEquity) && same(out.Assets.PreviousTotal, out.PrevLiabilitiesAndEquity)
	return out, nil
}
