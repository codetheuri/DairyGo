package finance

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// Domain errors, mapped to HTTP status codes by the handler.
var (
	ErrNotFound = errors.New("not found")
	ErrConflict = errors.New("conflict")
	ErrLocked   = errors.New("locked")
	ErrInvalid  = errors.New("invalid")
)

const dateLayout = "2006-01-02"

// Service holds the finance rules.
type Service struct {
	repo *Repository
	now  func() time.Time
}

// NewService creates a finance service.
func NewService(repo *Repository) *Service {
	return &Service{repo: repo, now: time.Now}
}

func (s *Service) saccoID(ctx context.Context) (string, error) {
	id, ok := middleware.GetSaccoID(ctx)
	if !ok || id == "" {
		return "", fmt.Errorf("%w: sacco context is required", ErrInvalid)
	}
	return id, nil
}

func (s *Service) today() time.Time {
	n := s.now().In(time.Local)
	return time.Date(n.Year(), n.Month(), n.Day(), 0, 0, 0, 0, time.UTC)
}

func actor(ctx context.Context) *uint {
	if id := middleware.GetUserID(ctx); id > 0 {
		return &id
	}
	return nil
}

func entry(saccoID, kind, id string, action audit.Action, ctx context.Context, before, after any) audit.Entry {
	return audit.Entry{SaccoID: saccoID, EntityType: kind, EntityID: id, Action: action,
		ActorID: middleware.GetUserID(ctx), OldValues: before, NewValues: after}
}

func parseDay(v string, def time.Time) (time.Time, error) {
	v = strings.TrimSpace(v)
	if v == "" {
		return def, nil
	}
	d, err := time.Parse(dateLayout, v)
	if err != nil {
		return time.Time{}, fmt.Errorf("%w: dates must look like 2026-10-31", ErrInvalid)
	}
	return d, nil
}

// period reads a from/to pair, by default this month so far.
func (s *Service) period(from, to string) (time.Time, time.Time, error) {
	today := s.today()
	end, err := parseDay(to, today)
	if err != nil {
		return end, end, err
	}
	start, err := parseDay(from, time.Date(end.Year(), end.Month(), 1, 0, 0, 0, 0, time.UTC))
	if err != nil {
		return start, end, err
	}
	if start.After(end) {
		return start, end, fmt.Errorf("%w: the start date is after the end date", ErrInvalid)
	}
	return start, end, nil
}

func trimOrNil(v *string) *string {
	if v == nil {
		return nil
	}
	t := strings.TrimSpace(*v)
	if t == "" {
		return nil
	}
	return &t
}

// --- accounts ---

// Accounts lists the Sacco's accounts with their balances now.
func (s *Service) Accounts(ctx context.Context) ([]CashAccount, float64, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, 0, err
	}
	accounts, err := s.repo.Accounts(ctx)
	if err != nil {
		return nil, 0, err
	}
	moved, err := s.repo.Balances(ctx, saccoID)
	if err != nil {
		return nil, 0, err
	}
	total := 0.0
	for i := range accounts {
		accounts[i].Balance = round2(accounts[i].OpeningBalance + moved[accounts[i].ID])
		total += accounts[i].Balance
	}
	if accounts == nil {
		accounts = []CashAccount{}
	}
	return accounts, round2(total), nil
}

// SaveAccount creates (id empty) or updates an account.
func (s *Service) SaveAccount(ctx context.Context, id string, req *CashAccountRequest) (*CashAccount, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	a := &CashAccount{ID: uuid.New().String(), SaccoID: saccoID, Kind: KindCash, IsActive: true, OpeningDate: s.today(), CreatedByID: actor(ctx)}
	action := audit.ActionCreate
	var before *CashAccount
	if id != "" {
		if a, err = s.repo.FindAccount(ctx, id); err != nil {
			return nil, err
		}
		copied := *a
		before, action = &copied, audit.ActionUpdate
	}
	if req.Name != nil {
		a.Name = strings.TrimSpace(*req.Name)
	}
	if req.Kind != nil {
		a.Kind = Kind(strings.ToUpper(*req.Kind))
	}
	if req.AccountNumber != nil {
		a.AccountNumber = trimOrNil(req.AccountNumber)
	}
	if req.OpeningBalance != nil {
		a.OpeningBalance = round2(*req.OpeningBalance)
	}
	if req.OpeningDate != nil {
		if a.OpeningDate, err = parseDay(*req.OpeningDate, a.OpeningDate); err != nil {
			return nil, err
		}
	}
	if req.IsActive != nil {
		a.IsActive = *req.IsActive
	}
	if len(a.Name) < 2 {
		return nil, fmt.Errorf("%w: give the account a name, e.g. Petty cash", ErrInvalid)
	}
	if a.Kind != KindCash && a.Kind != KindBank && a.Kind != KindMpesa {
		return nil, fmt.Errorf("%w: the account is CASH, BANK or MPESA", ErrInvalid)
	}
	if a.OpeningDate.After(s.today()) {
		return nil, fmt.Errorf("%w: the opening date cannot be in the future", ErrInvalid)
	}
	if taken, err := s.repo.NameTaken(ctx, "cash_accounts", saccoID, a.Name, a.ID); err != nil {
		return nil, err
	} else if taken {
		return nil, fmt.Errorf("%w: there is already an account called %s", ErrConflict, a.Name)
	}
	if err := s.repo.SaveAccount(ctx, a, entry(saccoID, "cash_account", a.ID, action, ctx, before, a)); err != nil {
		return nil, err
	}
	return a, nil
}

// Cashbook is an account's money in and out over a period with the running
// balance.
func (s *Service) Cashbook(ctx context.Context, id, from, to string) (*Cashbook, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	a, err := s.repo.FindAccount(ctx, id)
	if err != nil {
		return nil, err
	}
	start, end, err := s.period(from, to)
	if err != nil {
		return nil, err
	}
	moves, err := s.repo.Movements(ctx, saccoID, a, end)
	if err != nil {
		return nil, err
	}
	cb := &Cashbook{CashAccount: a, FromDate: start.Format(dateLayout), ToDate: end.Format(dateLayout)}
	cb.OpeningBalance, cb.Lines, cb.TotalIn, cb.TotalOut, cb.ClosingBalance = buildCashbook(a.OpeningBalance, start, moves)
	all, err := s.repo.Balances(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	a.Balance = round2(a.OpeningBalance + all[a.ID])
	return cb, nil
}

// --- categories ---

// Categories lists the expense categories.
func (s *Service) Categories(ctx context.Context) ([]ExpenseCategory, error) {
	out, err := s.repo.Categories(ctx)
	if out == nil {
		out = []ExpenseCategory{}
	}
	return out, err
}

// SaveCategory creates (id empty) or renames / switches off a category.
func (s *Service) SaveCategory(ctx context.Context, id string, req *FinCategoryRequest) (*ExpenseCategory, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	c := &ExpenseCategory{ID: uuid.New().String(), SaccoID: saccoID, IsActive: true}
	action := audit.ActionCreate
	var before *ExpenseCategory
	if id != "" {
		if c, err = s.repo.FindCategory(ctx, id); err != nil {
			return nil, err
		}
		copied := *c
		before, action = &copied, audit.ActionUpdate
	}
	if req.Name != nil {
		c.Name = strings.TrimSpace(*req.Name)
	}
	if req.IsActive != nil {
		c.IsActive = *req.IsActive
	}
	if len(c.Name) < 2 {
		return nil, fmt.Errorf("%w: give the category a name", ErrInvalid)
	}
	if taken, err := s.repo.NameTaken(ctx, "expense_categories", saccoID, c.Name, c.ID); err != nil {
		return nil, err
	} else if taken {
		return nil, fmt.Errorf("%w: there is already a category called %s", ErrConflict, c.Name)
	}
	if err := s.repo.SaveCategory(ctx, c, entry(saccoID, "expense_category", c.ID, action, ctx, before, c)); err != nil {
		return nil, err
	}
	return c, nil
}

// --- expenses ---

// ExpenseList is expenses over a period with totals.
type ExpenseList struct {
	Expenses   []Expense     `json:"expenses"`
	Total      float64       `json:"total"`
	ByCategory []NamedAmount `json:"by_category"`
	FromDate   string        `json:"from_date"`
	ToDate     string        `json:"to_date"`
}

// Expenses lists expenses over a period (default this month).
func (s *Service) Expenses(ctx context.Context, in *FinListExpensesInput) (*ExpenseList, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	start, end, err := s.period(in.From, in.To)
	if err != nil {
		return nil, err
	}
	rows, err := s.repo.Expenses(ctx, saccoID, ExpenseFilter{From: start, To: end, CategoryID: in.CategoryID,
		AccountID: in.AccountID, WithVoided: in.WithVoided, Search: strings.TrimSpace(in.Search)})
	if err != nil {
		return nil, err
	}
	out := &ExpenseList{Expenses: rows, ByCategory: []NamedAmount{}, FromDate: start.Format(dateLayout), ToDate: end.Format(dateLayout)}
	if out.Expenses == nil {
		out.Expenses = []Expense{}
	}
	idx := map[string]int{}
	for _, e := range rows {
		if e.VoidedAt != nil {
			continue
		}
		out.Total += e.Amount
		if i, ok := idx[e.CategoryName]; ok {
			out.ByCategory[i].Amount += e.Amount
		} else {
			idx[e.CategoryName] = len(out.ByCategory)
			out.ByCategory = append(out.ByCategory, NamedAmount{e.CategoryName, e.Amount})
		}
	}
	out.Total = round2(out.Total)
	for i := range out.ByCategory {
		out.ByCategory[i].Amount = round2(out.ByCategory[i].Amount)
	}
	return out, nil
}

// ExpensesFor lists the expenses of a period (not voided), for reports.
func (s *Service) ExpensesFor(ctx context.Context, from, to time.Time) (*ExpenseList, error) {
	return s.Expenses(ctx, &FinListExpensesInput{From: from.Format(dateLayout), To: to.Format(dateLayout)})
}

// RecordExpense records money the Sacco spent from one of its accounts.
func (s *Service) RecordExpense(ctx context.Context, req *FinExpenseRequest) (*Expense, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	day, err := parseDay(req.Date, s.today())
	if err != nil {
		return nil, err
	}
	if day.After(s.today()) {
		return nil, fmt.Errorf("%w: the date cannot be in the future", ErrInvalid)
	}
	if req.Amount <= 0 {
		return nil, fmt.Errorf("%w: the amount must be more than 0", ErrInvalid)
	}
	payee := strings.TrimSpace(req.Payee)
	if len(payee) < 2 {
		return nil, fmt.Errorf("%w: who was paid? (a person, shop or company)", ErrInvalid)
	}
	cat, err := s.repo.FindCategory(ctx, req.CategoryID)
	if err != nil {
		return nil, fmt.Errorf("%w: choose a category", ErrInvalid)
	}
	if !cat.IsActive {
		return nil, fmt.Errorf("%w: the category %s is switched off", ErrInvalid, cat.Name)
	}
	acc, err := s.repo.FindAccount(ctx, req.AccountID)
	if err != nil || !acc.IsActive {
		return nil, fmt.Errorf("%w: choose the account the money came from", ErrInvalid)
	}
	if day.Before(acc.OpeningDate) {
		return nil, fmt.Errorf("%w: %s was opened on %s; the expense cannot be earlier", ErrInvalid, acc.Name, acc.OpeningDate.Format("2 Jan 2006"))
	}
	e := &Expense{ID: uuid.New().String(), SaccoID: saccoID, CategoryID: cat.ID, CashAccountID: acc.ID, ExpenseDate: day,
		Amount: round2(req.Amount), Payee: payee, Reference: trimOrNil(&req.Reference), Description: trimOrNil(&req.Description),
		RecordedByID: actor(ctx)}
	if err := s.repo.SaveExpense(ctx, e, entry(saccoID, "expense", e.ID, audit.ActionCreate, ctx, nil, e)); err != nil {
		return nil, err
	}
	e.CategoryName, e.AccountName = cat.Name, acc.Name
	return e, nil
}

// VoidExpense cancels an expense recorded in error; it stays on record.
func (s *Service) VoidExpense(ctx context.Context, id, reason string) (*Expense, error) {
	e, err := s.repo.FindExpense(ctx, id)
	if err != nil {
		return nil, err
	}
	if e.VoidedAt != nil {
		return nil, fmt.Errorf("%w: already voided", ErrConflict)
	}
	reason = strings.TrimSpace(reason)
	if len(reason) < 3 {
		return nil, fmt.Errorf("%w: give the reason for voiding", ErrInvalid)
	}
	before := *e
	now := s.now()
	e.VoidedAt, e.VoidReason = &now, &reason
	en := entry(e.SaccoID, "expense", e.ID, audit.ActionVoid, ctx, before, e)
	en.Reason = &reason
	return e, s.repo.SaveExpense(ctx, e, en)
}

// --- transfers ---

// Transfers lists transfers over a period.
func (s *Service) Transfers(ctx context.Context, from, to string) ([]AccountTransfer, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	start, end, err := s.period(from, to)
	if err != nil {
		return nil, err
	}
	out, err := s.repo.Transfers(ctx, saccoID, start, end)
	if out == nil {
		out = []AccountTransfer{}
	}
	return out, err
}

// RecordTransfer moves money between two of the Sacco's accounts.
func (s *Service) RecordTransfer(ctx context.Context, req *FinTransferRequest) (*AccountTransfer, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	day, err := parseDay(req.Date, s.today())
	if err != nil {
		return nil, err
	}
	if day.After(s.today()) {
		return nil, fmt.Errorf("%w: the date cannot be in the future", ErrInvalid)
	}
	if req.Amount <= 0 {
		return nil, fmt.Errorf("%w: the amount must be more than 0", ErrInvalid)
	}
	if req.FromAccountID == req.ToAccountID {
		return nil, fmt.Errorf("%w: choose two different accounts", ErrInvalid)
	}
	from, err := s.repo.FindAccount(ctx, req.FromAccountID)
	if err != nil || !from.IsActive {
		return nil, fmt.Errorf("%w: choose the account the money leaves", ErrInvalid)
	}
	to, err := s.repo.FindAccount(ctx, req.ToAccountID)
	if err != nil || !to.IsActive {
		return nil, fmt.Errorf("%w: choose the account the money goes to", ErrInvalid)
	}
	t := &AccountTransfer{ID: uuid.New().String(), SaccoID: saccoID, FromAccountID: from.ID, ToAccountID: to.ID, TransferDate: day,
		Amount: round2(req.Amount), Reference: trimOrNil(&req.Reference), Notes: trimOrNil(&req.Notes), RecordedByID: actor(ctx)}
	if err := s.repo.SaveTransfer(ctx, t, entry(saccoID, "account_transfer", t.ID, audit.ActionCreate, ctx, nil, t)); err != nil {
		return nil, err
	}
	t.FromName, t.ToName = from.Name, to.Name
	return t, nil
}

// VoidTransfer cancels a transfer recorded in error.
func (s *Service) VoidTransfer(ctx context.Context, id, reason string) (*AccountTransfer, error) {
	t, err := s.repo.FindTransfer(ctx, id)
	if err != nil {
		return nil, err
	}
	if t.VoidedAt != nil {
		return nil, fmt.Errorf("%w: already voided", ErrConflict)
	}
	reason = strings.TrimSpace(reason)
	if len(reason) < 3 {
		return nil, fmt.Errorf("%w: give the reason for voiding", ErrInvalid)
	}
	before := *t
	now := s.now()
	t.VoidedAt, t.VoidReason = &now, &reason
	en := entry(t.SaccoID, "account_transfer", t.ID, audit.ActionVoid, ctx, before, t)
	en.Reason = &reason
	return t, s.repo.SaveTransfer(ctx, t, en)
}

// --- income and expenditure ---

// FinanceSummary is the Sacco's income and expenditure over a period, and where it
// stands now.
type FinanceSummary struct {
	FromDate string `json:"from_date"`
	ToDate   string `json:"to_date"`

	MilkSales     float64       `json:"milk_sales" doc:"Milk sold to customers"`
	MilkPurchases float64       `json:"milk_purchases" doc:"Milk bought from farmers"`
	GrossMargin   float64       `json:"gross_margin" doc:"Milk sales minus milk bought"`
	Fees          []NamedAmount `json:"fees" doc:"Deductions kept as income (registration, subscriptions, transaction costs…)"`
	FeesTotal     float64       `json:"fees_total"`
	FarmerCharges float64       `json:"farmer_charges" doc:"Charged to farmers (feeds, services)"`
	Expenses      []NamedAmount `json:"expenses" doc:"By category"`
	ExpensesTotal float64       `json:"expenses_total"`
	Surplus       float64       `json:"surplus" doc:"Gross margin + fees + charges − expenses; negative is a deficit"`
	SharesRaised  []NamedAmount `json:"shares_raised" doc:"Savings taken from farmers in the period (not income)"`

	Cash         float64 `json:"cash" doc:"Money in all accounts now"`
	Receivables  float64 `json:"receivables" doc:"What customers owe now"`
	FarmerPayDue float64 `json:"farmer_pay_due" doc:"Approved farmers' pay not yet sent"`
	FarmersOwe   float64 `json:"farmers_owe" doc:"Advances, charges and arrears farmers owe now"`
	ShareCapital float64 `json:"share_capital" doc:"All shares taken from farmers to date"`
}

// Summary works out the income and expenditure for a period (default this
// month) and the position now.
func (s *Service) Summary(ctx context.Context, from, to string) (*FinanceSummary, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	start, end, err := s.period(from, to)
	if err != nil {
		return nil, err
	}
	out := &FinanceSummary{FromDate: start.Format(dateLayout), ToDate: end.Format(dateLayout)}
	steps := []func() error{
		func() (e error) { out.MilkSales, e = s.repo.MilkSales(ctx, saccoID, start, end); return },
		func() (e error) { out.MilkPurchases, e = s.repo.MilkPurchases(ctx, saccoID, start, end); return },
		func() (e error) { out.Fees, out.SharesRaised, e = s.repo.Deductions(ctx, saccoID, start, end); return },
		func() (e error) { out.FarmerCharges, e = s.repo.FarmerCharges(ctx, saccoID, start, end); return },
		func() (e error) { out.Expenses, e = s.repo.ExpensesByCategory(ctx, saccoID, start, end); return },
		func() (e error) { _, out.Cash, e = s.Accounts(ctx); return },
		func() (e error) { out.Receivables, e = s.repo.Receivables(ctx, saccoID); return },
		func() (e error) { out.FarmerPayDue, e = s.repo.FarmerPayDue(ctx, saccoID); return },
		func() (e error) { out.FarmersOwe, e = s.repo.FarmersOwe(ctx, saccoID); return },
		func() (e error) { out.ShareCapital, e = s.repo.ShareCapital(ctx, saccoID); return },
	}
	for _, step := range steps {
		if err := step(); err != nil {
			return nil, err
		}
	}
	for _, f := range out.Fees {
		out.FeesTotal += f.Amount
	}
	for _, e := range out.Expenses {
		out.ExpensesTotal += e.Amount
	}
	out.MilkSales, out.MilkPurchases = round2(out.MilkSales), round2(out.MilkPurchases)
	out.GrossMargin = round2(out.MilkSales - out.MilkPurchases)
	out.FeesTotal, out.ExpensesTotal, out.FarmerCharges = round2(out.FeesTotal), round2(out.ExpensesTotal), round2(out.FarmerCharges)
	out.Surplus = round2(out.GrossMargin + out.FeesTotal + out.FarmerCharges - out.ExpensesTotal)
	out.Receivables, out.FarmerPayDue = round2(out.Receivables), round2(out.FarmerPayDue)
	out.FarmersOwe, out.ShareCapital = round2(out.FarmersOwe), round2(out.ShareCapital)
	return out, nil
}
