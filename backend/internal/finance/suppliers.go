package finance

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/query"
)

// Suppliers are the people and businesses the Sacco pays, for two reasons:
//
//   - bills: goods or services bought now and paid later, in parts if need
//     be. A bill counts as spending on its date (like an expense); what is
//     still unpaid is owed to the supplier.
//   - money held for them: a deduction can send farmers' money to a supplier
//     (an insurer, a union, an agrovet) instead of the Sacco's income. It is
//     held, owed to them, until the Sacco pays it over.

// Payment kinds.
const (
	PayBill    = "BILL"     // pays a bill
	PayOverAll = "PAY_OVER" // pays over money held from deductions
)

// Supplier is someone the Sacco pays.
type Supplier struct {
	ID          string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID     string    `json:"sacco_id" gorm:"type:varchar(36);not null"`
	Name        string    `json:"name"`
	Phone       *string   `json:"phone,omitempty"`
	Notes       *string   `json:"notes,omitempty"`
	IsActive    bool      `json:"is_active"`
	CreatedByID *uint     `json:"created_by_id,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Worked out from the records; never stored.
	BillsOwed float64 `json:"bills_owed" gorm:"-" doc:"Bills not yet paid"`
	Held      float64 `json:"held" gorm:"-" doc:"Deductions taken for them, not yet paid over"`
	IsPayee   bool    `json:"is_payee" gorm:"-" doc:"A deduction sends money to them"`
}

// TableName sets the database table name.
func (Supplier) TableName() string { return "suppliers" }

// Bill is something bought from a supplier, to be paid later.
type Bill struct {
	ID           string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID      string     `json:"sacco_id" gorm:"type:varchar(36);not null"`
	SupplierID   string     `json:"supplier_id" gorm:"type:varchar(36);not null"`
	CategoryID   string     `json:"category_id" gorm:"type:varchar(36);not null"`
	BillDate     time.Time  `json:"bill_date" gorm:"type:date"`
	DueDate      *time.Time `json:"due_date,omitempty" gorm:"type:date"`
	Amount       float64    `json:"amount"`
	Reference    *string    `json:"reference,omitempty"`
	Description  *string    `json:"description,omitempty"`
	RecordedByID *uint      `json:"recorded_by_id,omitempty"`
	VoidedAt     *time.Time `json:"voided_at,omitempty"`
	VoidReason   *string    `json:"void_reason,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`

	SupplierName string  `json:"supplier_name,omitempty" gorm:"->;-:migration"`
	CategoryName string  `json:"category_name,omitempty" gorm:"->;-:migration"`
	Paid         float64 `json:"paid" gorm:"->;-:migration"`
	Unpaid       float64 `json:"unpaid" gorm:"-"`
}

// TableName sets the database table name.
func (Bill) TableName() string { return "bills" }

// SupplierPayment pays a bill or pays over money held for a supplier.
type SupplierPayment struct {
	ID            string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID       string     `json:"sacco_id" gorm:"type:varchar(36);not null"`
	SupplierID    string     `json:"supplier_id" gorm:"type:varchar(36);not null"`
	Kind          string     `json:"kind" doc:"BILL or PAY_OVER"`
	BillID        *string    `json:"bill_id,omitempty" gorm:"type:varchar(36)"`
	CashAccountID string     `json:"cash_account_id" gorm:"type:varchar(36);not null"`
	PaymentDate   time.Time  `json:"payment_date" gorm:"type:date"`
	Amount        float64    `json:"amount"`
	Reference     *string    `json:"reference,omitempty"`
	Notes         *string    `json:"notes,omitempty"`
	RecordedByID  *uint      `json:"recorded_by_id,omitempty"`
	VoidedAt      *time.Time `json:"voided_at,omitempty"`
	VoidReason    *string    `json:"void_reason,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`

	AccountName string `json:"account_name,omitempty" gorm:"->;-:migration"`
}

// TableName sets the database table name.
func (SupplierPayment) TableName() string { return "supplier_payments" }

// HeldLine is what one pay run took from farmers for a supplier.
type HeldLine struct {
	PayRunID *string   `json:"pay_run_id,omitempty"`
	Date     time.Time `json:"date"`
	Name     string    `json:"name" doc:"The deduction"`
	Farmers  int       `json:"farmers"`
	Amount   float64   `json:"amount"`
}

// SupplierDetail is a supplier with their bills, payments and what was held
// for them.
type SupplierDetail struct {
	Supplier *Supplier         `json:"supplier"`
	Bills    []Bill            `json:"bills"`
	Payments []SupplierPayment `json:"payments"`
	Taken    []HeldLine        `json:"taken" doc:"Deductions taken for them, by pay run"`
	Payees   []string          `json:"deductions" doc:"Deductions that send money to them now"`
}

// SupplierList is the suppliers with what is owed to them.
type SupplierList struct {
	Suppliers []Supplier `json:"suppliers"`
	BillsOwed float64    `json:"bills_owed" doc:"All bills not yet paid"`
	Held      float64    `json:"held" doc:"All money held to pay over"`
}

// --- repository ---

// supplierBalancesSQL is each supplier's unpaid bills and money held.
const supplierBalancesSQL = `
SELECT s.id,
       COALESCE((SELECT SUM(b.amount) FROM bills b WHERE b.supplier_id = s.id AND b.voided_at IS NULL), 0)
     - COALESCE((SELECT SUM(p.amount) FROM supplier_payments p WHERE p.supplier_id = s.id AND p.kind = 'BILL' AND p.voided_at IS NULL), 0) AS bills_owed,
       COALESCE((SELECT SUM(-m.amount) FROM member_transactions m WHERE m.payee_id = s.id AND m.kind = 'DEDUCTION' AND m.voided_at IS NULL), 0)
     - COALESCE((SELECT SUM(p.amount) FROM supplier_payments p WHERE p.supplier_id = s.id AND p.kind = 'PAY_OVER' AND p.voided_at IS NULL), 0) AS held,
       EXISTS (SELECT 1 FROM deduction_types t WHERE t.payee_id = s.id AND t.deleted_at IS NULL) AS is_payee
  FROM suppliers s
 WHERE s.sacco_id = ?`

type supplierBalance struct {
	ID        string
	BillsOwed float64
	Held      float64
	IsPayee   bool
}

// SupplierBalances is each supplier's unpaid bills and money held, by id.
func (r *Repository) SupplierBalances(ctx context.Context, saccoID string) (map[string]supplierBalance, error) {
	var rows []supplierBalance
	if err := r.db.WithContext(ctx).Raw(supplierBalancesSQL, saccoID).Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make(map[string]supplierBalance, len(rows))
	for _, row := range rows {
		row.BillsOwed, row.Held = round2(row.BillsOwed), round2(row.Held)
		out[row.ID] = row
	}
	return out, nil
}

// SuppliersOwed is what the Sacco owes all suppliers for bills, and holds
// for them from deductions.
func (r *Repository) SuppliersOwed(ctx context.Context, saccoID string) (bills, held float64, err error) {
	var row struct{ Bills, Held sql.NullFloat64 }
	err = r.db.WithContext(ctx).Raw(`SELECT SUM(bills_owed) AS bills, SUM(held) AS held FROM (`+supplierBalancesSQL+`) x`, saccoID).
		Scan(&row).Error
	return round2(row.Bills.Float64), round2(row.Held.Float64), err
}

// FindSupplier loads a supplier of the caller's Sacco.
func (r *Repository) FindSupplier(ctx context.Context, id string) (*Supplier, error) {
	var s Supplier
	if err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&s).Error; err != nil {
		return nil, notFound(err, "supplier")
	}
	return &s, nil
}

const billsSelect = `b.*, s.name AS supplier_name, c.name AS category_name,
	COALESCE((SELECT SUM(p.amount) FROM supplier_payments p WHERE p.bill_id = b.id AND p.voided_at IS NULL), 0) AS paid`

// Bills lists bills, newest first: a supplier's (voided ones too), or every
// supplier's unpaid ones.
func (r *Repository) Bills(ctx context.Context, saccoID, supplierID string, unpaidOnly bool) ([]Bill, error) {
	var out []Bill
	q := r.db.WithContext(ctx).Table("bills b").Select(billsSelect).
		Joins("JOIN suppliers s ON s.id = b.supplier_id").
		Joins("JOIN expense_categories c ON c.id = b.category_id").
		Where("b.sacco_id = ?", saccoID)
	if supplierID != "" {
		q = q.Where("b.supplier_id = ?", supplierID)
	}
	if unpaidOnly {
		q = q.Where(`b.voided_at IS NULL AND b.amount > COALESCE((SELECT SUM(p.amount) FROM supplier_payments p
			WHERE p.bill_id = b.id AND p.voided_at IS NULL), 0)`)
	}
	if err := q.Order("b.bill_date DESC, b.created_at DESC").Limit(1000).Scan(&out).Error; err != nil {
		return nil, err
	}
	for i := range out {
		out[i].Paid = round2(out[i].Paid)
		if out[i].VoidedAt == nil {
			out[i].Unpaid = round2(out[i].Amount - out[i].Paid)
		}
	}
	return out, nil
}

// findBill loads a bill with what is paid, locking it until the
// transaction ends so two payments never pay the same shilling.
func findBill(ctx context.Context, tx *gorm.DB, saccoID, id string) (*Bill, error) {
	var b Bill
	if err := tx.WithContext(ctx).Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("sacco_id = ? AND id = ?", saccoID, id).First(&b).Error; err != nil {
		return nil, notFound(err, "bill")
	}
	var paid sql.NullFloat64
	if err := tx.WithContext(ctx).Raw(`SELECT SUM(amount) FROM supplier_payments WHERE bill_id = ? AND voided_at IS NULL`, id).
		Scan(&paid).Error; err != nil {
		return nil, err
	}
	b.Paid = round2(paid.Float64)
	b.Unpaid = round2(b.Amount - b.Paid)
	return &b, nil
}

// SupplierPayments lists a supplier's payments, newest first.
func (r *Repository) SupplierPayments(ctx context.Context, saccoID, supplierID string) ([]SupplierPayment, error) {
	var out []SupplierPayment
	err := r.db.WithContext(ctx).Table("supplier_payments p").Select("p.*, a.name AS account_name").
		Joins("JOIN cash_accounts a ON a.id = p.cash_account_id").
		Where("p.sacco_id = ? AND p.supplier_id = ?", saccoID, supplierID).
		Order("p.payment_date DESC, p.created_at DESC").Limit(1000).Scan(&out).Error
	return out, err
}

// Taken is what pay runs took from farmers for a supplier, by run and
// deduction, newest first.
func (r *Repository) Taken(ctx context.Context, saccoID, supplierID string) ([]HeldLine, error) {
	var out []HeldLine
	err := r.db.WithContext(ctx).Raw(`SELECT m.pay_run_id, m.entry_date AS date, COALESCE(t.name, m.description) AS name,
			COUNT(DISTINCT m.member_id) AS farmers, SUM(-m.amount) AS amount
		FROM member_transactions m LEFT JOIN deduction_types t ON t.id = m.deduction_type_id
		WHERE m.sacco_id = ? AND m.payee_id = ? AND m.kind = 'DEDUCTION' AND m.voided_at IS NULL
		GROUP BY m.pay_run_id, m.entry_date, COALESCE(t.name, m.description)
		ORDER BY m.entry_date DESC`, saccoID, supplierID).Scan(&out).Error
	for i := range out {
		out[i].Amount = round2(out[i].Amount)
	}
	return out, err
}

// held is what is held for a supplier now, read in tx.
func held(ctx context.Context, tx *gorm.DB, supplierID string) (float64, error) {
	var v sql.NullFloat64
	err := tx.WithContext(ctx).Raw(`SELECT
		COALESCE((SELECT SUM(-m.amount) FROM member_transactions m WHERE m.payee_id = @s AND m.kind = 'DEDUCTION' AND m.voided_at IS NULL), 0)
	  - COALESCE((SELECT SUM(p.amount) FROM supplier_payments p WHERE p.supplier_id = @s AND p.kind = 'PAY_OVER' AND p.voided_at IS NULL), 0)`,
		sql.Named("s", supplierID)).Scan(&v).Error
	return round2(v.Float64), err
}

// BillsByCategory totals bills dated in a period by expense category.
func (r *Repository) BillsByCategory(ctx context.Context, saccoID string, from, to time.Time) ([]NamedAmount, error) {
	var out []NamedAmount
	err := r.db.WithContext(ctx).Raw(`SELECT c.name, SUM(b.amount) AS amount FROM bills b
		JOIN expense_categories c ON c.id = b.category_id
		WHERE b.sacco_id = ? AND b.voided_at IS NULL AND b.bill_date BETWEEN ? AND ?
		GROUP BY c.name`, saccoID, from.Format(dateLayout), to.Format(dateLayout)).Scan(&out).Error
	return out, err
}

// --- service ---

// Suppliers lists the suppliers with what is owed to each.
func (s *Service) Suppliers(ctx context.Context) (*SupplierList, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	var list []Supplier
	if err := s.repo.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Order("is_active DESC, name").Find(&list).Error; err != nil {
		return nil, err
	}
	bal, err := s.repo.SupplierBalances(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	out := &SupplierList{Suppliers: make([]Supplier, 0, len(list))}
	for _, sp := range list {
		b := bal[sp.ID]
		sp.BillsOwed, sp.Held, sp.IsPayee = b.BillsOwed, b.Held, b.IsPayee
		out.BillsOwed += b.BillsOwed
		out.Held += b.Held
		out.Suppliers = append(out.Suppliers, sp)
	}
	out.BillsOwed, out.Held = round2(out.BillsOwed), round2(out.Held)
	return out, nil
}

// SupplierDetail is one supplier with their bills, payments and money held.
func (s *Service) SupplierDetail(ctx context.Context, id string) (*SupplierDetail, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	sp, err := s.repo.FindSupplier(ctx, id)
	if err != nil {
		return nil, err
	}
	bal, err := s.repo.SupplierBalances(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	b := bal[sp.ID]
	sp.BillsOwed, sp.Held, sp.IsPayee = b.BillsOwed, b.Held, b.IsPayee
	out := &SupplierDetail{Supplier: sp, Payees: []string{}}
	if out.Bills, err = s.repo.Bills(ctx, saccoID, sp.ID, false); err != nil {
		return nil, err
	}
	if out.Payments, err = s.repo.SupplierPayments(ctx, saccoID, sp.ID); err != nil {
		return nil, err
	}
	if out.Taken, err = s.repo.Taken(ctx, saccoID, sp.ID); err != nil {
		return nil, err
	}
	if err := s.repo.db.WithContext(ctx).Raw(`SELECT name FROM deduction_types WHERE payee_id = ? AND deleted_at IS NULL ORDER BY priority, name`,
		sp.ID).Scan(&out.Payees).Error; err != nil {
		return nil, err
	}
	if out.Bills == nil {
		out.Bills = []Bill{}
	}
	if out.Payments == nil {
		out.Payments = []SupplierPayment{}
	}
	if out.Taken == nil {
		out.Taken = []HeldLine{}
	}
	return out, nil
}

// SaveSupplier creates (id empty) or changes a supplier.
func (s *Service) SaveSupplier(ctx context.Context, id string, req *SupplierRequest) (*Supplier, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	sp := &Supplier{ID: uuid.New().String(), SaccoID: saccoID, IsActive: true, CreatedByID: actor(ctx)}
	action := audit.ActionCreate
	var before *Supplier
	if id != "" {
		if sp, err = s.repo.FindSupplier(ctx, id); err != nil {
			return nil, err
		}
		copied := *sp
		before, action = &copied, audit.ActionUpdate
	}
	if req.Name != nil {
		sp.Name = strings.TrimSpace(*req.Name)
	}
	if req.Phone != nil {
		sp.Phone = trimOrNil(req.Phone)
	}
	if req.Notes != nil {
		sp.Notes = trimOrNil(req.Notes)
	}
	if req.IsActive != nil {
		sp.IsActive = *req.IsActive
	}
	if len(sp.Name) < 2 {
		return nil, fmt.Errorf("%w: give the supplier a name", ErrInvalid)
	}
	if taken, err := s.repo.NameTaken(ctx, "suppliers", saccoID, sp.Name, sp.ID); err != nil {
		return nil, err
	} else if taken {
		return nil, fmt.Errorf("%w: there is already a supplier called %s", ErrConflict, sp.Name)
	}
	if err := s.repo.save(ctx, sp, entry(saccoID, "supplier", sp.ID, action, ctx, before, sp)); err != nil {
		return nil, err
	}
	return sp, nil
}

// UnpaidBills lists every supplier's bills still to pay, newest first.
func (s *Service) UnpaidBills(ctx context.Context) ([]Bill, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	out, err := s.repo.Bills(ctx, saccoID, "", true)
	if out == nil {
		out = []Bill{}
	}
	return out, err
}

// RecordBill records something bought from a supplier, to be paid later.
func (s *Service) RecordBill(ctx context.Context, req *BillRequest) (*Bill, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	day, err := parseDay(req.Date, s.today())
	if err != nil {
		return nil, err
	}
	if day.After(s.today()) {
		return nil, fmt.Errorf("%w: the bill's date cannot be in the future", ErrInvalid)
	}
	var due *time.Time
	if strings.TrimSpace(req.DueDate) != "" {
		d, err := parseDay(req.DueDate, day)
		if err != nil {
			return nil, err
		}
		if d.Before(day) {
			return nil, fmt.Errorf("%w: the bill cannot be due before its date", ErrInvalid)
		}
		due = &d
	}
	if req.Amount <= 0 {
		return nil, fmt.Errorf("%w: the amount must be more than 0", ErrInvalid)
	}
	sp, err := s.repo.FindSupplier(ctx, req.SupplierID)
	if err != nil {
		return nil, fmt.Errorf("%w: choose the supplier", ErrInvalid)
	}
	if !sp.IsActive {
		return nil, fmt.Errorf("%w: %s is switched off", ErrInvalid, sp.Name)
	}
	cat, err := s.repo.FindCategory(ctx, req.CategoryID)
	if err != nil {
		return nil, fmt.Errorf("%w: choose what the bill is for (an expense category)", ErrInvalid)
	}
	if !cat.IsActive {
		return nil, fmt.Errorf("%w: the category %s is switched off", ErrInvalid, cat.Name)
	}
	b := &Bill{ID: uuid.New().String(), SaccoID: saccoID, SupplierID: sp.ID, CategoryID: cat.ID, BillDate: day, DueDate: due,
		Amount: round2(req.Amount), Reference: trimOrNil(&req.Reference), Description: trimOrNil(&req.Description), RecordedByID: actor(ctx)}
	if err := s.repo.save(ctx, b, entry(saccoID, "bill", b.ID, audit.ActionCreate, ctx, nil, b)); err != nil {
		return nil, err
	}
	b.SupplierName, b.CategoryName, b.Unpaid = sp.Name, cat.Name, b.Amount
	return b, nil
}

// VoidBill cancels a bill recorded in error. Its payments are voided first,
// so nothing paid is left without its bill.
func (s *Service) VoidBill(ctx context.Context, id, reason string) (*Bill, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	reason, err = voidReason(reason)
	if err != nil {
		return nil, err
	}
	var out *Bill
	err = s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		b, err := findBill(ctx, tx, saccoID, id)
		if err != nil {
			return err
		}
		if b.VoidedAt != nil {
			return fmt.Errorf("%w: already voided", ErrConflict)
		}
		if b.Paid > 0 {
			return fmt.Errorf("%w: KES %s of this bill is paid; void its payments first", ErrConflict, money(b.Paid))
		}
		before := *b
		now := s.now()
		b.VoidedAt, b.VoidReason = &now, &reason
		if err := tx.Save(b).Error; err != nil {
			return err
		}
		en := entry(saccoID, "bill", b.ID, audit.ActionVoid, ctx, before, b)
		en.Reason = &reason
		out = b
		return audit.Record(tx, en)
	})
	return out, err
}

// PayBill pays a bill, in full or in part, from one of the Sacco's accounts.
func (s *Service) PayBill(ctx context.Context, billID string, req *SupplierPaymentRequest) (*SupplierPayment, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	day, err := s.paymentDay(req)
	if err != nil {
		return nil, err
	}
	acc, err := s.accountOn(ctx, req.AccountID, day, "the account the money came from", "payment")
	if err != nil {
		return nil, err
	}
	var p *SupplierPayment
	err = s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		b, err := findBill(ctx, tx, saccoID, billID)
		if err != nil {
			return err
		}
		if b.VoidedAt != nil {
			return fmt.Errorf("%w: this bill was voided", ErrConflict)
		}
		if b.Unpaid <= 0 {
			return fmt.Errorf("%w: this bill is paid", ErrConflict)
		}
		if req.Amount > b.Unpaid+0.005 {
			return fmt.Errorf("%w: only KES %s of this bill is unpaid", ErrInvalid, money(b.Unpaid))
		}
		if day.Before(b.BillDate) {
			return fmt.Errorf("%w: the payment cannot be before the bill's date (%s)", ErrInvalid, b.BillDate.Format("2 Jan 2006"))
		}
		p = &SupplierPayment{ID: uuid.New().String(), SaccoID: saccoID, SupplierID: b.SupplierID, Kind: PayBill, BillID: &b.ID,
			CashAccountID: acc.ID, PaymentDate: day, Amount: round2(req.Amount), Reference: trimOrNil(&req.Reference),
			Notes: trimOrNil(&req.Notes), RecordedByID: actor(ctx)}
		if err := tx.Create(p).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry(saccoID, "supplier_payment", p.ID, audit.ActionCreate, ctx, nil, p))
	})
	if err != nil {
		return nil, err
	}
	p.AccountName = acc.Name
	return p, nil
}

// PayOver pays a supplier money held for them from farmers' deductions.
func (s *Service) PayOver(ctx context.Context, supplierID string, req *SupplierPaymentRequest) (*SupplierPayment, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	day, err := s.paymentDay(req)
	if err != nil {
		return nil, err
	}
	acc, err := s.accountOn(ctx, req.AccountID, day, "the account the money came from", "payment")
	if err != nil {
		return nil, err
	}
	var p *SupplierPayment
	err = s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var sp Supplier
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).Where("sacco_id = ? AND id = ?", saccoID, supplierID).
			First(&sp).Error; err != nil {
			return notFound(err, "supplier")
		}
		h, err := held(ctx, tx, sp.ID)
		if err != nil {
			return err
		}
		if h <= 0 {
			return fmt.Errorf("%w: nothing is held for %s to pay over", ErrConflict, sp.Name)
		}
		if req.Amount > h+0.005 {
			return fmt.Errorf("%w: KES %s is held for %s; pay over no more than that", ErrInvalid, money(h), sp.Name)
		}
		p = &SupplierPayment{ID: uuid.New().String(), SaccoID: saccoID, SupplierID: sp.ID, Kind: PayOverAll,
			CashAccountID: acc.ID, PaymentDate: day, Amount: round2(req.Amount), Reference: trimOrNil(&req.Reference),
			Notes: trimOrNil(&req.Notes), RecordedByID: actor(ctx)}
		if err := tx.Create(p).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry(saccoID, "supplier_payment", p.ID, audit.ActionCreate, ctx, nil, p))
	})
	if err != nil {
		return nil, err
	}
	p.AccountName = acc.Name
	return p, nil
}

func (s *Service) paymentDay(req *SupplierPaymentRequest) (time.Time, error) {
	day, err := parseDay(req.Date, s.today())
	if err != nil {
		return day, err
	}
	if day.After(s.today()) {
		return day, fmt.Errorf("%w: the date cannot be in the future", ErrInvalid)
	}
	if req.Amount <= 0 {
		return day, fmt.Errorf("%w: the amount must be more than 0", ErrInvalid)
	}
	return day, nil
}

// VoidSupplierPayment cancels a payment recorded in error: the bill is
// unpaid again, or the money is held again.
func (s *Service) VoidSupplierPayment(ctx context.Context, id, reason string) (*SupplierPayment, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	reason, err = voidReason(reason)
	if err != nil {
		return nil, err
	}
	var p SupplierPayment
	if err := s.repo.db.WithContext(ctx).Where("sacco_id = ? AND id = ?", saccoID, id).First(&p).Error; err != nil {
		return nil, notFound(err, "payment")
	}
	if p.VoidedAt != nil {
		return nil, fmt.Errorf("%w: already voided", ErrConflict)
	}
	before := p
	now := s.now()
	p.VoidedAt, p.VoidReason = &now, &reason
	en := entry(saccoID, "supplier_payment", p.ID, audit.ActionVoid, ctx, before, &p)
	en.Reason = &reason
	return &p, s.repo.save(ctx, &p, en)
}

// money writes an amount the way messages show it: 12,500 or 12,500.50.
func money(v float64) string {
	v = round2(v)
	whole := int64(v)
	cents := int64((v-float64(whole))*100 + 0.5)
	s := fmt.Sprintf("%d", whole)
	for i := len(s) - 3; i > 0; i -= 3 {
		s = s[:i] + "," + s[i:]
	}
	if cents != 0 {
		s += fmt.Sprintf(".%02d", cents)
	}
	return s
}
