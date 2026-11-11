package finance

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/query"
)

// Other income is money the Sacco receives besides milk sales: interest,
// rent, items sold, grants. It is recorded like an expense, the other way
// round: into one of the Sacco's accounts, under an income category.

// IncomeCategory groups other income.
type IncomeCategory struct {
	ID        string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID   string    `json:"sacco_id" gorm:"type:varchar(36);not null"`
	Name      string    `json:"name"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// TableName sets the database table name.
func (IncomeCategory) TableName() string { return "income_categories" }

// DefaultIncomeCategories are the income categories every Sacco starts with
// (migration 00032 gave existing Saccos the same list).
var DefaultIncomeCategories = []string{"Interest received", "Rent received", "Sale of items", "Grants and donations", "Other income"}

// IncomeCategories are a new Sacco's income categories.
func IncomeCategories(saccoID string) []IncomeCategory {
	out := make([]IncomeCategory, len(DefaultIncomeCategories))
	for i, name := range DefaultIncomeCategories {
		out[i] = IncomeCategory{ID: uuid.New().String(), SaccoID: saccoID, Name: name, IsActive: true}
	}
	return out
}

// OtherIncome is money the Sacco received besides milk sales.
type OtherIncome struct {
	ID            string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID       string     `json:"sacco_id" gorm:"type:varchar(36);not null"`
	CategoryID    string     `json:"category_id" gorm:"type:varchar(36);not null"`
	CashAccountID string     `json:"cash_account_id" gorm:"type:varchar(36);not null"`
	IncomeDate    time.Time  `json:"income_date" gorm:"type:date"`
	Amount        float64    `json:"amount"`
	Payer         string     `json:"payer"`
	Reference     *string    `json:"reference,omitempty"`
	Description   *string    `json:"description,omitempty"`
	RecordedByID  *uint      `json:"recorded_by_id,omitempty"`
	VoidedAt      *time.Time `json:"voided_at,omitempty"`
	VoidReason    *string    `json:"void_reason,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`

	CategoryName string `json:"category_name,omitempty" gorm:"->;-:migration"`
	AccountName  string `json:"account_name,omitempty" gorm:"->;-:migration"`
}

// TableName sets the database table name.
func (OtherIncome) TableName() string { return "other_income" }

// --- repository ---

// IncomeCategoryList lists the Sacco's income categories by name.
func (r *Repository) IncomeCategoryList(ctx context.Context) ([]IncomeCategory, error) {
	var out []IncomeCategory
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Order("is_active DESC, name").Find(&out).Error
	return out, err
}

// FindIncomeCategory loads an income category of the caller's Sacco.
func (r *Repository) FindIncomeCategory(ctx context.Context, id string) (*IncomeCategory, error) {
	var c IncomeCategory
	if err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&c).Error; err != nil {
		return nil, notFound(err, "income category")
	}
	return &c, nil
}

// IncomeFilter narrows the other income list.
type IncomeFilter struct {
	From, To   time.Time
	CategoryID string
	WithVoided bool
}

// OtherIncomeList lists other income with category and account names,
// newest first.
func (r *Repository) OtherIncomeList(ctx context.Context, saccoID string, f IncomeFilter) ([]OtherIncome, error) {
	var out []OtherIncome
	q := r.db.WithContext(ctx).Table("other_income i").
		Select("i.*, c.name AS category_name, a.name AS account_name").
		Joins("JOIN income_categories c ON c.id = i.category_id").
		Joins("JOIN cash_accounts a ON a.id = i.cash_account_id").
		Where("i.sacco_id = ? AND i.income_date BETWEEN ? AND ?", saccoID, f.From.Format(dateLayout), f.To.Format(dateLayout))
	if f.CategoryID != "" {
		q = q.Where("i.category_id = ?", f.CategoryID)
	}
	if !f.WithVoided {
		q = q.Where("i.voided_at IS NULL")
	}
	err := q.Order("i.income_date DESC, i.created_at DESC").Limit(1000).Scan(&out).Error
	return out, err
}

// FindOtherIncome loads other income of the caller's Sacco.
func (r *Repository) FindOtherIncome(ctx context.Context, id string) (*OtherIncome, error) {
	var i OtherIncome
	if err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&i).Error; err != nil {
		return nil, notFound(err, "income")
	}
	return &i, nil
}

// OtherIncomeByCategory totals other income in a period, largest first.
func (r *Repository) OtherIncomeByCategory(ctx context.Context, saccoID string, from, to time.Time) ([]NamedAmount, error) {
	var out []NamedAmount
	err := r.db.WithContext(ctx).Raw(`SELECT c.name, SUM(i.amount) AS amount FROM other_income i
		JOIN income_categories c ON c.id = i.category_id
		WHERE i.sacco_id = ? AND i.voided_at IS NULL AND i.income_date BETWEEN ? AND ?
		GROUP BY c.name ORDER BY 2 DESC`, saccoID, from.Format(dateLayout), to.Format(dateLayout)).Scan(&out).Error
	if out == nil {
		out = []NamedAmount{}
	}
	return out, err
}

// --- service ---

// IncomeCategoryList lists the income categories.
func (s *Service) IncomeCategoryList(ctx context.Context) ([]IncomeCategory, error) {
	out, err := s.repo.IncomeCategoryList(ctx)
	if out == nil {
		out = []IncomeCategory{}
	}
	return out, err
}

// SaveIncomeCategory creates (id empty) or renames / switches off an income
// category.
func (s *Service) SaveIncomeCategory(ctx context.Context, id string, req *FinCategoryRequest) (*IncomeCategory, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	c := &IncomeCategory{ID: uuid.New().String(), SaccoID: saccoID, IsActive: true}
	action := audit.ActionCreate
	var before *IncomeCategory
	if id != "" {
		if c, err = s.repo.FindIncomeCategory(ctx, id); err != nil {
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
	if taken, err := s.repo.NameTaken(ctx, "income_categories", saccoID, c.Name, c.ID); err != nil {
		return nil, err
	} else if taken {
		return nil, fmt.Errorf("%w: there is already a category called %s", ErrConflict, c.Name)
	}
	if err := s.repo.save(ctx, c, entry(saccoID, "income_category", c.ID, action, ctx, before, c)); err != nil {
		return nil, err
	}
	return c, nil
}

// IncomeList is other income over a period with totals.
type IncomeList struct {
	Items      []OtherIncome `json:"items"`
	Total      float64       `json:"total"`
	ByCategory []NamedAmount `json:"by_category"`
	FromDate   string        `json:"from_date"`
	ToDate     string        `json:"to_date"`
}

// OtherIncomeList lists other income over a period (default this month).
func (s *Service) OtherIncomeList(ctx context.Context, in *FinListIncomeInput) (*IncomeList, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	start, end, err := s.period(in.From, in.To)
	if err != nil {
		return nil, err
	}
	rows, err := s.repo.OtherIncomeList(ctx, saccoID, IncomeFilter{From: start, To: end, CategoryID: in.CategoryID, WithVoided: in.WithVoided})
	if err != nil {
		return nil, err
	}
	out := &IncomeList{Items: rows, ByCategory: []NamedAmount{}, FromDate: start.Format(dateLayout), ToDate: end.Format(dateLayout)}
	if out.Items == nil {
		out.Items = []OtherIncome{}
	}
	idx := map[string]int{}
	for _, i := range rows {
		if i.VoidedAt != nil {
			continue
		}
		out.Total += i.Amount
		if k, ok := idx[i.CategoryName]; ok {
			out.ByCategory[k].Amount += i.Amount
		} else {
			idx[i.CategoryName] = len(out.ByCategory)
			out.ByCategory = append(out.ByCategory, NamedAmount{i.CategoryName, i.Amount})
		}
	}
	out.Total = round2(out.Total)
	for k := range out.ByCategory {
		out.ByCategory[k].Amount = round2(out.ByCategory[k].Amount)
	}
	return out, nil
}

// RecordIncome records money the Sacco received into one of its accounts.
func (s *Service) RecordIncome(ctx context.Context, req *FinIncomeRequest) (*OtherIncome, error) {
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
	payer := strings.TrimSpace(req.Payer)
	if len(payer) < 2 {
		return nil, fmt.Errorf("%w: who paid the Sacco? (a person, bank or company)", ErrInvalid)
	}
	cat, err := s.repo.FindIncomeCategory(ctx, req.CategoryID)
	if err != nil {
		return nil, fmt.Errorf("%w: choose a category", ErrInvalid)
	}
	if !cat.IsActive {
		return nil, fmt.Errorf("%w: the category %s is switched off", ErrInvalid, cat.Name)
	}
	acc, err := s.accountOn(ctx, req.AccountID, day, "the account the money went into", "income")
	if err != nil {
		return nil, err
	}
	i := &OtherIncome{ID: uuid.New().String(), SaccoID: saccoID, CategoryID: cat.ID, CashAccountID: acc.ID, IncomeDate: day,
		Amount: round2(req.Amount), Payer: payer, Reference: trimOrNil(&req.Reference), Description: trimOrNil(&req.Description),
		RecordedByID: actor(ctx)}
	if err := s.repo.save(ctx, i, entry(saccoID, "other_income", i.ID, audit.ActionCreate, ctx, nil, i)); err != nil {
		return nil, err
	}
	i.CategoryName, i.AccountName = cat.Name, acc.Name
	return i, nil
}

// VoidIncome cancels income recorded in error; it stays on record.
func (s *Service) VoidIncome(ctx context.Context, id, reason string) (*OtherIncome, error) {
	i, err := s.repo.FindOtherIncome(ctx, id)
	if err != nil {
		return nil, err
	}
	if i.VoidedAt != nil {
		return nil, fmt.Errorf("%w: already voided", ErrConflict)
	}
	reason, err = voidReason(reason)
	if err != nil {
		return nil, err
	}
	before := *i
	now := s.now()
	i.VoidedAt, i.VoidReason = &now, &reason
	en := entry(i.SaccoID, "other_income", i.ID, audit.ActionVoid, ctx, before, i)
	en.Reason = &reason
	return i, s.repo.save(ctx, i, en)
}

// accountOn loads an active account that was open on day; what names the
// account in the message, kind names the record.
func (s *Service) accountOn(ctx context.Context, id string, day time.Time, what, kind string) (*CashAccount, error) {
	acc, err := s.repo.FindAccount(ctx, id)
	if err != nil || !acc.IsActive {
		return nil, fmt.Errorf("%w: choose %s", ErrInvalid, what)
	}
	if day.Before(acc.OpeningDate) {
		return nil, fmt.Errorf("%w: %s was opened on %s; the %s cannot be earlier", ErrInvalid, acc.Name,
			acc.OpeningDate.Format("2 Jan 2006"), kind)
	}
	return acc, nil
}

func voidReason(reason string) (string, error) {
	reason = strings.TrimSpace(reason)
	if len(reason) < 3 {
		return "", fmt.Errorf("%w: give the reason for voiding", ErrInvalid)
	}
	return reason, nil
}
