package finance

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/query"
)

// Repository stores accounts, categories, expenses and transfers, and reads
// money movements from the tables where they were recorded.
type Repository struct {
	db *gorm.DB
}

// NewRepository creates a finance repository.
func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func notFound(err error, what string) error {
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return fmt.Errorf("%w: %s not found", ErrNotFound, what)
	}
	return err
}

// save creates or updates a row with its audit entry.
func (r *Repository) save(ctx context.Context, row any, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(row).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// --- accounts ---

// Accounts lists the Sacco's accounts by name.
func (r *Repository) Accounts(ctx context.Context) ([]CashAccount, error) {
	var out []CashAccount
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Order("is_active DESC, name").Find(&out).Error
	return out, err
}

// FindAccount loads an account of the caller's Sacco.
func (r *Repository) FindAccount(ctx context.Context, id string) (*CashAccount, error) {
	var a CashAccount
	if err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&a).Error; err != nil {
		return nil, notFound(err, "account")
	}
	return &a, nil
}

// NameTaken reports whether another row of a Sacco's table has this name.
func (r *Repository) NameTaken(ctx context.Context, table, saccoID, name, exceptID string) (bool, error) {
	var n int64
	err := r.db.WithContext(ctx).Table(table).
		Where("sacco_id = ? AND LOWER(name) = LOWER(?) AND id <> ?", saccoID, name, exceptID).Count(&n).Error
	return n > 0, err
}

// SaveAccount creates or updates an account.
func (r *Repository) SaveAccount(ctx context.Context, a *CashAccount, entry audit.Entry) error {
	return r.save(ctx, a, entry)
}

// --- categories ---

// Categories lists the Sacco's expense categories by name.
func (r *Repository) Categories(ctx context.Context) ([]ExpenseCategory, error) {
	var out []ExpenseCategory
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Order("is_active DESC, name").Find(&out).Error
	return out, err
}

// FindCategory loads a category of the caller's Sacco.
func (r *Repository) FindCategory(ctx context.Context, id string) (*ExpenseCategory, error) {
	var c ExpenseCategory
	if err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&c).Error; err != nil {
		return nil, notFound(err, "category")
	}
	return &c, nil
}

// SaveCategory creates or updates a category.
func (r *Repository) SaveCategory(ctx context.Context, c *ExpenseCategory, entry audit.Entry) error {
	return r.save(ctx, c, entry)
}

// --- expenses ---

// ExpenseFilter narrows the expense list.
type ExpenseFilter struct {
	From, To   time.Time
	CategoryID string
	AccountID  string
	WithVoided bool
	Search     string
}

// Expenses lists expenses with their category and account names, newest first.
func (r *Repository) Expenses(ctx context.Context, saccoID string, f ExpenseFilter) ([]Expense, error) {
	var out []Expense
	q := r.db.WithContext(ctx).Table("expenses e").
		Select("e.*, c.name AS category_name, a.name AS account_name").
		Joins("JOIN expense_categories c ON c.id = e.category_id").
		Joins("JOIN cash_accounts a ON a.id = e.cash_account_id").
		Where("e.sacco_id = ? AND e.expense_date BETWEEN ? AND ?", saccoID, f.From.Format(dateLayout), f.To.Format(dateLayout))
	if f.CategoryID != "" {
		q = q.Where("e.category_id = ?", f.CategoryID)
	}
	if f.AccountID != "" {
		q = q.Where("e.cash_account_id = ?", f.AccountID)
	}
	if !f.WithVoided {
		q = q.Where("e.voided_at IS NULL")
	}
	if f.Search != "" {
		like := "%" + f.Search + "%"
		q = q.Where("LOWER(e.payee) LIKE LOWER(?) OR LOWER(COALESCE(e.description, '')) LIKE LOWER(?) OR e.reference LIKE ?", like, like, like)
	}
	err := q.Order("e.expense_date DESC, e.created_at DESC").Limit(1000).Scan(&out).Error
	return out, err
}

// FindExpense loads an expense of the caller's Sacco.
func (r *Repository) FindExpense(ctx context.Context, id string) (*Expense, error) {
	var e Expense
	if err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&e).Error; err != nil {
		return nil, notFound(err, "expense")
	}
	return &e, nil
}

// SaveExpense creates or updates an expense.
func (r *Repository) SaveExpense(ctx context.Context, e *Expense, entry audit.Entry) error {
	return r.save(ctx, e, entry)
}

// --- transfers ---

// Transfers lists transfers with account names, newest first.
func (r *Repository) Transfers(ctx context.Context, saccoID string, from, to time.Time) ([]AccountTransfer, error) {
	var out []AccountTransfer
	err := r.db.WithContext(ctx).Table("account_transfers t").
		Select("t.*, fa.name AS from_name, ta.name AS to_name").
		Joins("JOIN cash_accounts fa ON fa.id = t.from_account_id").
		Joins("JOIN cash_accounts ta ON ta.id = t.to_account_id").
		Where("t.sacco_id = ? AND t.transfer_date BETWEEN ? AND ?", saccoID, from.Format(dateLayout), to.Format(dateLayout)).
		Order("t.transfer_date DESC, t.created_at DESC").Limit(500).Scan(&out).Error
	return out, err
}

// FindTransfer loads a transfer of the caller's Sacco.
func (r *Repository) FindTransfer(ctx context.Context, id string) (*AccountTransfer, error) {
	var t AccountTransfer
	if err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&t).Error; err != nil {
		return nil, notFound(err, "transfer")
	}
	return &t, nil
}

// SaveTransfer creates or updates a transfer.
func (r *Repository) SaveTransfer(ctx context.Context, t *AccountTransfer, entry audit.Entry) error {
	return r.save(ctx, t, entry)
}

// --- movements: every shilling in or out of an account, wherever recorded ---

// movementsSQL lists every movement of a Sacco's accounts. Farmers' pay is
// one line per pay run and day, not one per farmer.
const movementsSQL = `
SELECT p.cash_account_id AS account_id, 'CUSTOMER_PAYMENT' AS source, p.payment_date AS date, p.created_at,
       'Payment from ' || c.name AS description, p.reference, p.id AS ref_id, p.amount AS amount_in, 0 AS amount_out
  FROM customer_payments p JOIN customers c ON c.id = p.customer_id
 WHERE p.sacco_id = @sacco AND p.cash_account_id IS NOT NULL AND p.voided_at IS NULL
UNION ALL
SELECT s.cash_account_id, 'CASH_SALE', s.sale_date, s.created_at,
       'Paid at sale: ' || s.buyer_name, NULL, s.id, s.amount_paid, 0
  FROM milk_sales s
 WHERE s.sacco_id = @sacco AND s.cash_account_id IS NOT NULL AND s.voided_at IS NULL AND s.deleted_at IS NULL AND s.amount_paid > 0
UNION ALL
SELECT t.to_account_id, 'TRANSFER_IN', t.transfer_date, t.created_at,
       'From ' || a.name, t.reference, t.id, t.amount, 0
  FROM account_transfers t JOIN cash_accounts a ON a.id = t.from_account_id
 WHERE t.sacco_id = @sacco AND t.voided_at IS NULL
UNION ALL
SELECT t.from_account_id, 'TRANSFER_OUT', t.transfer_date, t.created_at,
       'To ' || a.name, t.reference, t.id, 0, t.amount
  FROM account_transfers t JOIN cash_accounts a ON a.id = t.to_account_id
 WHERE t.sacco_id = @sacco AND t.voided_at IS NULL
UNION ALL
SELECT e.cash_account_id, 'EXPENSE', e.expense_date, e.created_at,
       c.name || ': ' || e.payee, e.reference, e.id, 0, e.amount
  FROM expenses e JOIN expense_categories c ON c.id = e.category_id
 WHERE e.sacco_id = @sacco AND e.voided_at IS NULL
UNION ALL
SELECT i.cash_account_id, 'OTHER_INCOME', i.income_date, i.created_at,
       c.name || ': ' || i.payer, i.reference, i.id, i.amount, 0
  FROM other_income i JOIN income_categories c ON c.id = i.category_id
 WHERE i.sacco_id = @sacco AND i.voided_at IS NULL
UNION ALL
SELECT p.cash_account_id, CASE p.kind WHEN 'BILL' THEN 'BILL_PAYMENT' ELSE 'PAY_OVER' END, p.payment_date, p.created_at,
       CASE p.kind WHEN 'BILL' THEN 'Bill paid: ' ELSE 'Paid over to ' END || s.name, p.reference, p.id, 0, p.amount
  FROM supplier_payments p JOIN suppliers s ON s.id = p.supplier_id
 WHERE p.sacco_id = @sacco AND p.voided_at IS NULL
UNION ALL
SELECT e.cash_account_id, 'SHARE_REFUND', e.entry_date, e.created_at,
       'Shares refunded to ' || mb.first_name || ' ' || mb.last_name, e.reference, e.id, 0, -e.amount
  FROM share_entries e JOIN members mb ON mb.id = e.member_id
 WHERE e.sacco_id = @sacco AND e.kind = 'REFUND' AND e.cash_account_id IS NOT NULL AND e.voided_at IS NULL
UNION ALL
SELECT m.cash_account_id, 'ADVANCE', m.entry_date, m.created_at,
       'Advance to ' || mb.first_name || ' ' || mb.last_name, m.reference, m.id, 0, -m.amount
  FROM member_transactions m JOIN members mb ON mb.id = m.member_id
 WHERE m.sacco_id = @sacco AND m.cash_account_id IS NOT NULL AND m.kind = 'ADVANCE' AND m.voided_at IS NULL
UNION ALL
SELECT l.cash_account_id, 'FARMER_PAY', CAST(l.paid_at AS DATE), MIN(l.paid_at),
       'Farmers'' pay (' || COUNT(*) || CASE WHEN COUNT(*) = 1 THEN ' farmer)' ELSE ' farmers)' END, MIN(l.paid_reference), l.pay_run_id, 0, SUM(l.net)
  FROM pay_run_lines l
 WHERE l.sacco_id = @sacco AND l.cash_account_id IS NOT NULL AND l.paid_at IS NOT NULL
 GROUP BY l.cash_account_id, l.pay_run_id, CAST(l.paid_at AS DATE)`

type movementRow struct {
	AccountID   string
	Source      string
	Date        time.Time
	CreatedAt   time.Time
	Description string
	Reference   *string
	RefID       string
	AmountIn    float64
	AmountOut   float64
}

// Movements lists one account's movements up to a day (from its opening
// date), for its cashbook.
func (r *Repository) Movements(ctx context.Context, saccoID string, a *CashAccount, to time.Time) ([]Movement, error) {
	var rows []movementRow
	err := r.db.WithContext(ctx).Raw(`SELECT * FROM (`+movementsSQL+`) m
		WHERE m.account_id = @account AND m.date >= @opening AND m.date <= @to`,
		sql.Named("sacco", saccoID), sql.Named("account", a.ID),
		sql.Named("opening", a.OpeningDate.Format(dateLayout)), sql.Named("to", to.Format(dateLayout))).
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}
	out := make([]Movement, len(rows))
	for i, m := range rows {
		out[i] = Movement{AccountID: m.AccountID, Source: Source(m.Source), Date: m.Date, CreatedAt: m.CreatedAt,
			Description: m.Description, Reference: m.Reference, RefID: m.RefID, In: m.AmountIn, Out: m.AmountOut}
	}
	return out, nil
}

// Balances is each account's money in and out since its opening date.
func (r *Repository) Balances(ctx context.Context, saccoID string) (map[string]float64, error) {
	var rows []struct {
		AccountID string
		Net       float64
	}
	err := r.db.WithContext(ctx).Raw(`SELECT m.account_id, SUM(m.amount_in - m.amount_out) AS net
		FROM (`+movementsSQL+`) m JOIN cash_accounts a ON a.id = m.account_id
		WHERE m.date >= a.opening_date GROUP BY m.account_id`, sql.Named("sacco", saccoID)).Scan(&rows).Error
	out := map[string]float64{}
	for _, row := range rows {
		out[row.AccountID] = row.Net
	}
	return out, err
}

// ActiveAccount checks an account belongs to the Sacco and is in use.
func ActiveAccount(ctx context.Context, db *gorm.DB, saccoID, id string) error {
	var n int64
	if err := db.WithContext(ctx).Table("cash_accounts").Where("id = ? AND sacco_id = ? AND is_active = ?", id, saccoID, true).
		Count(&n).Error; err != nil {
		return err
	}
	if n == 0 {
		return fmt.Errorf("choose one of the Sacco's accounts (petty cash, bank or M-Pesa)")
	}
	return nil
}

// --- income and expenditure ---

// NamedAmount is an amount with a label (a category, a deduction).
type NamedAmount struct {
	Name   string  `json:"name"`
	Amount float64 `json:"amount"`
}

func (r *Repository) sum(ctx context.Context, q string, args ...any) (float64, error) {
	var v sql.NullFloat64
	err := r.db.WithContext(ctx).Raw(q, args...).Scan(&v).Error
	return v.Float64, err
}

// MilkSales is the value of milk sold in a period.
func (r *Repository) MilkSales(ctx context.Context, saccoID string, from, to time.Time) (float64, error) {
	return r.sum(ctx, `SELECT SUM(total_amount) FROM milk_sales WHERE sacco_id = ? AND voided_at IS NULL AND deleted_at IS NULL
		AND sale_date BETWEEN ? AND ?`, saccoID, from.Format(dateLayout), to.Format(dateLayout))
}

// MilkPurchases is the value of milk bought from farmers in a period.
func (r *Repository) MilkPurchases(ctx context.Context, saccoID string, from, to time.Time) (float64, error) {
	return r.sum(ctx, `SELECT SUM(total_amount) FROM milk_collections WHERE sacco_id = ? AND deleted_at IS NULL AND status <> 'REJECTED'
		AND collection_date BETWEEN ? AND ?`, saccoID, from.Format(dateLayout), to.Format(dateLayout))
}

// Deductions totals what pay runs took from farmers in a period, by
// deduction, split by where the money went: the Sacco's income (fees), the
// farmers' savings (shares), or held for a supplier to pay over (named
// "<deduction> for <supplier>").
func (r *Repository) Deductions(ctx context.Context, saccoID string, from, to time.Time) (income, savings, held []NamedAmount, err error) {
	var rows []struct {
		Name      string
		IsSavings bool
		Payee     *string
		Amount    float64
	}
	err = r.db.WithContext(ctx).Raw(`SELECT COALESCE(t.name, m.description) AS name, m.is_savings, s.name AS payee, SUM(-m.amount) AS amount
		FROM member_transactions m LEFT JOIN deduction_types t ON t.id = m.deduction_type_id
		LEFT JOIN suppliers s ON s.id = m.payee_id
		WHERE m.sacco_id = ? AND m.kind = 'DEDUCTION' AND m.voided_at IS NULL AND m.entry_date BETWEEN ? AND ?
		GROUP BY COALESCE(t.name, m.description), m.is_savings, s.name ORDER BY 4 DESC`,
		saccoID, from.Format(dateLayout), to.Format(dateLayout)).Scan(&rows).Error
	income, savings, held = []NamedAmount{}, []NamedAmount{}, []NamedAmount{}
	for _, row := range rows {
		switch {
		case row.Payee != nil:
			held = append(held, NamedAmount{row.Name + " for " + *row.Payee, round2(row.Amount)})
		case row.IsSavings:
			savings = append(savings, NamedAmount{row.Name, round2(row.Amount)})
		default:
			income = append(income, NamedAmount{row.Name, round2(row.Amount)})
		}
	}
	return income, savings, held, err
}

// FarmerCharges is what farmers were charged (feeds, services) in a period.
func (r *Repository) FarmerCharges(ctx context.Context, saccoID string, from, to time.Time) (float64, error) {
	return r.sum(ctx, `SELECT SUM(-amount) FROM member_transactions WHERE sacco_id = ? AND kind = 'CHARGE' AND voided_at IS NULL
		AND entry_date BETWEEN ? AND ?`, saccoID, from.Format(dateLayout), to.Format(dateLayout))
}

// ExpensesByCategory totals expenses in a period, largest first.
func (r *Repository) ExpensesByCategory(ctx context.Context, saccoID string, from, to time.Time) ([]NamedAmount, error) {
	var out []NamedAmount
	err := r.db.WithContext(ctx).Raw(`SELECT c.name, SUM(e.amount) AS amount FROM expenses e
		JOIN expense_categories c ON c.id = e.category_id
		WHERE e.sacco_id = ? AND e.voided_at IS NULL AND e.expense_date BETWEEN ? AND ?
		GROUP BY c.name ORDER BY 2 DESC`, saccoID, from.Format(dateLayout), to.Format(dateLayout)).Scan(&out).Error
	if out == nil {
		out = []NamedAmount{}
	}
	return out, err
}

// Receivables is what customers owe now: the sum of each customer's balance
// where it is owed. A customer in credit (paid ahead) does not reduce what
// others owe.
func (r *Repository) Receivables(ctx context.Context, saccoID string) (float64, error) {
	return r.sum(ctx, `SELECT SUM(b) FROM (
		SELECT COALESCE(s.owed, 0) - COALESCE(p.paid, 0) AS b
		  FROM customers c
		  LEFT JOIN (SELECT customer_id, SUM(total_amount - amount_paid) AS owed FROM milk_sales
		              WHERE sacco_id = @sacco AND voided_at IS NULL AND deleted_at IS NULL GROUP BY customer_id) s ON s.customer_id = c.id
		  LEFT JOIN (SELECT customer_id, SUM(amount) AS paid FROM customer_payments
		              WHERE sacco_id = @sacco AND voided_at IS NULL GROUP BY customer_id) p ON p.customer_id = c.id
		 WHERE c.sacco_id = @sacco) x WHERE b > 0`, sql.Named("sacco", saccoID))
}

// FarmerPayDue is net pay approved but not yet paid.
func (r *Repository) FarmerPayDue(ctx context.Context, saccoID string) (float64, error) {
	return r.sum(ctx, `SELECT SUM(l.net) FROM pay_run_lines l JOIN pay_runs p ON p.id = l.pay_run_id
		WHERE l.sacco_id = ? AND p.status = 'APPROVED' AND l.paid_at IS NULL AND l.net > 0`, saccoID)
}

// FarmersOwe is what farmers owe the Sacco now: advances and charges not yet
// recovered, and arrears.
func (r *Repository) FarmersOwe(ctx context.Context, saccoID string) (float64, error) {
	return r.sum(ctx, `SELECT -SUM(b) FROM (SELECT SUM(amount) AS b FROM member_transactions
		WHERE sacco_id = ? AND voided_at IS NULL GROUP BY member_id) x WHERE b < 0`, saccoID)
}

// ShareCapital is members' shares now: savings taken in pay runs, and
// shares moved outside them (opening shares, refunds).
func (r *Repository) ShareCapital(ctx context.Context, saccoID string) (float64, error) {
	return r.sum(ctx, `SELECT
		(SELECT COALESCE(SUM(-amount), 0) FROM member_transactions WHERE sacco_id = @s AND kind = 'DEDUCTION' AND is_savings AND voided_at IS NULL)
	  + (SELECT COALESCE(SUM(amount), 0) FROM share_entries WHERE sacco_id = @s AND voided_at IS NULL)`, sql.Named("s", saccoID))
}

// --- financial year ---

// FinancialYearStart is the month the Sacco's financial year starts (1 when
// the Sacco has no settings row yet).
func (r *Repository) FinancialYearStart(ctx context.Context, saccoID string) (int, error) {
	var month sql.NullInt64
	err := r.db.WithContext(ctx).Raw(`SELECT financial_year_start_month FROM sacco_settings WHERE sacco_id = ?`, saccoID).
		Scan(&month).Error
	if !month.Valid || month.Int64 < 1 {
		return 1, err
	}
	return int(month.Int64), err
}

// SetFinancialYearStart saves the start month with its history line.
func (r *Repository) SetFinancialYearStart(ctx context.Context, saccoID string, month int, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		res := tx.Table("sacco_settings").Where("sacco_id = ?", saccoID).
			Updates(map[string]any{"financial_year_start_month": month, "updated_at": time.Now()})
		if res.Error != nil {
			return res.Error
		}
		if res.RowsAffected == 0 {
			return fmt.Errorf("%w: the Sacco's settings were not found", ErrNotFound)
		}
		return audit.Record(tx, entry)
	})
}

// NotInAccount counts money received or paid in a period that names no
// account (recorded before accounts were chosen everywhere), and its total,
// so the accountant can see what the cashbooks are missing.
func (r *Repository) NotInAccount(ctx context.Context, saccoID string, from, to time.Time) (int, float64, error) {
	var row struct {
		N     int
		Total sql.NullFloat64
	}
	err := r.db.WithContext(ctx).Raw(`SELECT COUNT(*) AS n, SUM(amount) AS total FROM (
		SELECT amount FROM customer_payments
		 WHERE sacco_id = @sacco AND cash_account_id IS NULL AND voided_at IS NULL AND payment_date BETWEEN @from AND @to
		UNION ALL
		SELECT amount_paid FROM milk_sales
		 WHERE sacco_id = @sacco AND cash_account_id IS NULL AND voided_at IS NULL AND deleted_at IS NULL
		   AND amount_paid > 0 AND sale_date BETWEEN @from AND @to
		UNION ALL
		SELECT -amount FROM member_transactions
		 WHERE sacco_id = @sacco AND cash_account_id IS NULL AND kind = 'ADVANCE' AND voided_at IS NULL AND entry_date BETWEEN @from AND @to
		UNION ALL
		SELECT net FROM pay_run_lines
		 WHERE sacco_id = @sacco AND cash_account_id IS NULL AND paid_at IS NOT NULL AND net > 0
		   AND CAST(paid_at AS DATE) BETWEEN @from AND @to) x`,
		sql.Named("sacco", saccoID), sql.Named("from", from.Format(dateLayout)), sql.Named("to", to.Format(dateLayout))).
		Scan(&row).Error
	return row.N, round2(row.Total.Float64), err
}
