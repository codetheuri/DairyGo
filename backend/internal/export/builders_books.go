package export

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/codetheuri/tusk/internal/ledger"
	"github.com/codetheuri/tusk/pkg/document"
)

// The books' reports (docs/books.md): the income statement and balance
// sheet, and the trial balance, general ledger, journals and chart of
// accounts as files the Sacco's own accounting software can import (Excel
// or CSV: plain columns, account codes, debits and credits).

// booksErr turns "the books have not started" into a refusal people read.
func booksErr(err error) error {
	if errors.Is(err, ledger.ErrNotStarted) {
		return fmt.Errorf("%w: the books have not been started yet (Books → Start the books)", ErrInvalid)
	}
	return err
}

// periodName is a short name for a period: "Oct 2026" for a whole month,
// otherwise "1 Oct 2026 – 15 Nov 2026".
func periodName(from, to time.Time) string {
	if from.Day() == 1 && to.AddDate(0, 0, 1).Day() == 1 && from.Year() == to.Year() && from.Month() == to.Month() {
		return from.Format("Jan 2006")
	}
	return from.Format("2 Jan 2006") + " – " + to.Format("2 Jan 2006")
}

func parse(v string) time.Time {
	d, _ := time.Parse(dateLayout, v)
	return d
}

func accountName(code, name string) string {
	if code == "" {
		return name
	}
	return code + "  " + name
}

// statementTable is one section of a statement with this and the earlier
// column.
func statementTable(sec ledger.BooksSection, nowTitle, prevTitle, totalLabel string) document.Table {
	t := document.Table{Title: sec.Title, Columns: []document.Column{col("Account", txt, 3), col(nowTitle, money, 1.4), col(prevTitle, money, 1.4)},
		Empty: "Nothing."}
	for _, l := range sec.Lines {
		t.Rows = append(t.Rows, []any{accountName(l.Code, l.Name), l.Amount, l.Previous})
	}
	t.Totals = []any{totalLabel, sec.Total, sec.PreviousTotal}
	return t
}

func surplusWord(v float64) string {
	if v < 0 {
		return "Deficit"
	}
	return "Surplus"
}

func incomeStatement(ctx context.Context, s *Service, in *input) error {
	st, err := s.books.IncomeStatement(ctx, in.from.Format(dateLayout), in.to.Format(dateLayout))
	if err != nil {
		return booksErr(err)
	}
	now := periodName(in.from, in.to)
	prev := periodName(parse(st.PreviousFrom), parse(st.PreviousTo))
	inc := statementTable(st.Income, now, prev, "Total income")
	exp := statementTable(st.Expenses, now, prev, "Total expenses")
	result := document.Table{Title: surplusWord(st.Surplus), Columns: inc.Columns, Rows: [][]any{
		{"Income less expenses", st.Surplus, st.PreviousSurplus},
	}}
	in.doc.Figures = []document.Figure{
		{Label: "Income", Value: kes(st.Income.Total)},
		{Label: "Expenses", Value: kes(st.Expenses.Total)},
		{Label: surplusWord(st.Surplus), Value: kes(st.Surplus)},
	}
	in.doc.Tables = []document.Table{inc, exp, result}
	in.doc.Notes = append(in.doc.Notes,
		fmt.Sprintf("Beside it: %s.", document.FormatPeriod(parse(st.PreviousFrom), parse(st.PreviousTo))),
		"Milk bought from farmers is counted when its pay run is approved, on the pay run's last day.",
		"Shares and other savings taken from farmers' pay are the farmers' own: they are equity, not income.")
	if start := parse(st.StartDate); in.from.Before(start) {
		in.doc.Notes = append(in.doc.Notes, fmt.Sprintf("The books start on %s; what happened before is in the opening balances, not here.",
			start.Format("2 Jan 2006")))
	}
	return nil
}

func balanceSheet(ctx context.Context, s *Service, in *input) error {
	prevDay := in.from.AddDate(0, 0, -1)
	bs, err := s.books.BalanceSheet(ctx, in.to.Format(dateLayout), prevDay.Format(dateLayout))
	if err != nil {
		return booksErr(err)
	}
	now := "At " + in.to.Format("2 Jan 2006")
	prev := "At " + prevDay.Format("2 Jan 2006")
	assets := statementTable(bs.Assets, now, prev, "Total assets")
	liab := statementTable(bs.Liabilities, now, prev, "Total liabilities")
	equity := statementTable(bs.Equity, now, prev, "Total equity")
	both := document.Table{Title: "Liabilities and equity", Columns: assets.Columns, Rows: [][]any{
		{"Liabilities plus equity", bs.LiabilitiesAndEquity, bs.PrevLiabilitiesAndEquity},
	}}
	in.doc.Figures = []document.Figure{
		{Label: "Assets", Value: kes(bs.Assets.Total)},
		{Label: "Liabilities", Value: kes(bs.Liabilities.Total)},
		{Label: "Equity", Value: kes(bs.Equity.Total)},
	}
	in.doc.Tables = []document.Table{assets, liab, equity, both}
	if bs.Balanced {
		in.doc.Notes = append(in.doc.Notes, "Assets equal liabilities plus equity.")
	} else {
		in.doc.Notes = append(in.doc.Notes, "Assets do not equal liabilities plus equity: open Books in the app and bring them up to date.")
	}
	in.doc.Notes = append(in.doc.Notes,
		"Until a year is closed, its income and expenses show as the surplus lines under equity.",
		fmt.Sprintf("The books start on %s.", parse(bs.StartDate).Format("2 Jan 2006")))
	return nil
}

func trialBalance(ctx context.Context, s *Service, in *input) error {
	tb, err := s.books.TrialBalance(ctx, in.to.Format(dateLayout))
	if err != nil {
		return booksErr(err)
	}
	kinds := map[ledger.Type]string{ledger.Asset: "Asset", ledger.Liability: "Liability", ledger.Equity: "Equity", ledger.Income: "Income", ledger.Expense: "Expense"}
	t := document.Table{
		Columns: []document.Column{col("Code", txt, 0.8), col("Account", txt, 3), col("Kind", txt, 1), col("Debit", money, 1.4), col("Credit", money, 1.4)},
		Empty:   "Nothing posted by this day.",
	}
	for _, r := range tb.Rows {
		var dr, cr any
		if r.Debit != 0 {
			dr = r.Debit
		}
		if r.Credit != 0 {
			cr = r.Credit
		}
		t.Rows = append(t.Rows, []any{r.Code, r.Name, kinds[r.Type], dr, cr})
	}
	t.Totals = []any{nil, "Total", nil, tb.TotalDebit, tb.TotalCredit}
	in.doc.Figures = []document.Figure{{Label: "Debits", Value: kes(tb.TotalDebit)}, {Label: "Credits", Value: kes(tb.TotalCredit)},
		{Label: "Accounts", Value: count(len(tb.Rows))}}
	in.doc.Tables = []document.Table{t}
	if tb.Balanced {
		in.doc.Notes = []string{"Debits equal credits."}
	} else {
		in.doc.Notes = []string{"Debits and credits differ: open Books in the app and bring them up to date."}
	}
	return nil
}

func generalLedger(ctx context.Context, s *Service, in *input) error {
	accounts, err := s.books.GeneralLedger(ctx, in.from, in.to)
	if err != nil {
		return booksErr(err)
	}
	cols := []document.Column{col("Date", day, 1), col("Journal", txt, 0.8), col("Memo", txt, 4), col("Debit", money, 1.3), col("Credit", money, 1.3), col("Balance", money, 1.4)}
	flat := document.Table{Columns: append([]document.Column{col("Code", txt, 0.8), col("Account", txt, 2)}, cols...)}
	for _, a := range accounts {
		t := document.Table{Title: accountName(a.Account.Code, a.Account.Name), Columns: cols}
		t.Rows = append(t.Rows, []any{in.from, nil, "Opening balance", nil, nil, a.Opening})
		flat.Rows = append(flat.Rows, []any{a.Account.Code, a.Account.Name, in.from, nil, "Opening balance", nil, nil, a.Opening})
		balance := a.Opening
		sign := 1.0
		if !a.Account.Type.DebitNormal() {
			sign = -1
		}
		for _, l := range a.Lines {
			balance += (l.Debit - l.Credit) * sign
			memo := l.Memo
			if l.LineMemo != nil && *l.LineMemo != "" {
				memo += " (" + *l.LineMemo + ")"
			}
			var dr, cr any
			if l.Debit != 0 {
				dr = l.Debit
			}
			if l.Credit != 0 {
				cr = l.Credit
			}
			j := fmt.Sprintf("J-%d", l.Number)
			t.Rows = append(t.Rows, []any{l.Date, j, memo, dr, cr, balance})
			flat.Rows = append(flat.Rows, []any{a.Account.Code, a.Account.Name, l.Date, j, memo, dr, cr, balance})
		}
		t.Totals = []any{nil, nil, "Closing balance", a.Debit, a.Credit, a.Closing}
		in.doc.Tables = append(in.doc.Tables, t)
	}
	in.doc.Flat = &flat
	in.doc.Figures = []document.Figure{{Label: "Accounts", Value: count(len(accounts))}}
	in.doc.Notes = []string{"Balances are in each account's usual direction: debits less credits for assets and expenses, credits less debits otherwise."}
	if len(accounts) == 0 {
		in.doc.Tables = []document.Table{{Columns: cols, Empty: "Nothing posted in this period."}}
	}
	return nil
}

func journals(ctx context.Context, s *Service, in *input) error {
	lines, err := s.books.Lines(ctx, in.from, in.to)
	if err != nil {
		return booksErr(err)
	}
	t := document.Table{
		Columns: []document.Column{col("Date", day, 1), col("Journal", txt, 0.8), col("Source", txt, 1.3), col("Memo", txt, 3),
			col("Reference", txt, 1), col("Account code", txt, 0.9), col("Account", txt, 2), col("Debit", money, 1.2),
			col("Credit", money, 1.2), col("Line note", txt, 1.4)},
		Empty: "No journals in this period.",
	}
	var dr, cr float64
	journalsSeen := map[string]bool{}
	for _, l := range lines {
		var d, c any
		if l.Debit != 0 {
			d = l.Debit
		}
		if l.Credit != 0 {
			c = l.Credit
		}
		ref, note := "", ""
		if l.Reference != nil {
			ref = *l.Reference
		}
		if l.LineMemo != nil {
			note = *l.LineMemo
		}
		t.Rows = append(t.Rows, []any{l.Date, fmt.Sprintf("J-%d", l.Number), l.Source(), l.Memo, ref, l.AccountCode, l.AccountName, d, c, note})
		dr += l.Debit
		cr += l.Credit
		journalsSeen[l.JournalID] = true
	}
	if len(lines) > 0 {
		t.Totals = []any{nil, nil, nil, "Total", nil, nil, nil, dr, cr, nil}
	}
	in.doc.Figures = []document.Figure{{Label: "Journals", Value: count(len(journalsSeen))}, {Label: "Lines", Value: count(len(lines))},
		{Label: "Debits = credits", Value: kes(dr)}}
	in.doc.Tables = []document.Table{t}
	in.doc.Notes = []string{"One row per debit or credit; the lines of a journal share its number and add up to equal debits and credits."}
	return nil
}

func chartOfAccounts(ctx context.Context, s *Service, in *input) error {
	accounts, err := s.books.Accounts(ctx)
	if err != nil {
		return booksErr(err)
	}
	kinds := map[ledger.Type]string{ledger.Asset: "Asset", ledger.Liability: "Liability", ledger.Equity: "Equity", ledger.Income: "Income", ledger.Expense: "Expense"}
	t := document.Table{Columns: []document.Column{col("Code", txt, 0.8), col("Account", txt, 2.4), col("Kind", txt, 1), col("Usual side", txt, 0.9),
		col("In use", txt, 0.7), col("Kept from", txt, 1.8), col("Balance today", money, 1.4)}}
	for _, a := range accounts {
		side, use := "Credit", "Yes"
		if a.Type.DebitNormal() {
			side = "Debit"
		}
		if !a.IsActive {
			use = "No"
		}
		t.Rows = append(t.Rows, []any{a.Code, a.Name, kinds[a.Type], side, use, a.KeptBy, a.Balance})
	}
	in.doc.Figures = []document.Figure{{Label: "Accounts", Value: count(len(accounts))}}
	in.doc.Tables = []document.Table{t}
	in.doc.Notes = []string{"Accounts kept from records change only through those records (sales, payments, pay runs, cashbooks)."}
	return nil
}
