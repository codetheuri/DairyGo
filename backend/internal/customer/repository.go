package customer

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/query"
)

// Repository stores customers and payments and reads the ledger. It reads
// milk_sales directly for statements rather than depending on the collection
// module.
type Repository struct {
	db *gorm.DB
}

// NewRepository creates a customer repository.
func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// Create saves a customer and its audit entry atomically.
func (r *Repository) Create(ctx context.Context, c *Customer, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(c).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// Update saves an edited customer and its audit entry atomically.
func (r *Repository) Update(ctx context.Context, c *Customer, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Scopes(query.TenantScope(ctx)).Omit("Balance").Save(c).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// FindByID loads a customer from the caller's Sacco.
func (r *Repository) FindByID(ctx context.Context, id string) (*Customer, error) {
	var c Customer
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&c).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("%w: customer not found", ErrNotFound)
		}
		return nil, err
	}
	return &c, nil
}

// FindByPhone returns the customer in a Sacco with this phone, if any.
func (r *Repository) FindByPhone(ctx context.Context, saccoID, phone string) (*Customer, error) {
	var c Customer
	err := r.db.WithContext(ctx).Where("sacco_id = ? AND phone = ?", saccoID, phone).First(&c).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &c, nil
}

// List returns a page of customers, searchable by name and phone.
func (r *Repository) List(ctx context.Context, q query.Query) ([]Customer, query.Meta, error) {
	cfg := query.Config{
		DefaultSort:    "name",
		DefaultPerPage: 20,
		MaxPerPage:     100,
		AllowedSorts: map[string]string{
			"name":       "customers.name",
			"created_at": "customers.created_at",
		},
		AllowedSearches: []string{"customers.name", "customers.phone"},
		AllowedFilters: map[string]string{
			"status":        "customers.status",
			"customer_type": "customers.customer_type",
		},
	}
	session := r.db.Model(&Customer{}).Scopes(query.TenantScope(ctx))
	return query.Paginate[Customer](ctx, session, q, cfg)
}

// CreatePayment saves a payment and its audit entry atomically.
func (r *Repository) CreatePayment(ctx context.Context, p *Payment, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(p).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// FindPaymentByID loads a payment from the caller's Sacco.
func (r *Repository) FindPaymentByID(ctx context.Context, id string) (*Payment, error) {
	var p Payment
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&p).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("%w: payment not found", ErrNotFound)
		}
		return nil, err
	}
	return &p, nil
}

// VoidPayment marks a payment voided and saves the audit entry atomically.
func (r *Repository) VoidPayment(ctx context.Context, p *Payment, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		err := tx.Model(&Payment{}).Where("id = ? AND sacco_id = ?", p.ID, p.SaccoID).
			Updates(map[string]any{"voided_at": p.VoidedAt, "void_reason": p.VoidReason}).Error
		if err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// History returns the audit trail of a customer or payment record.
func (r *Repository) History(ctx context.Context, saccoID, entityType, entityID string) ([]audit.Log, error) {
	return audit.List(ctx, r.db, saccoID, entityType, entityID)
}

// Balances returns what each customer of a Sacco owes, largest first. When
// ids is non-empty only those customers are returned.
func (r *Repository) Balances(ctx context.Context, saccoID string, ids []string) ([]Balance, error) {
	session := r.db.WithContext(ctx).
		Table("customers c").
		Select(`c.id AS customer_id, c.name, c.phone, c.customer_type,
			COALESCE(s.total, 0) AS total_sales,
			COALESCE(s.paid, 0) + COALESCE(p.paid, 0) AS total_paid,
			COALESCE(s.total, 0) - COALESCE(s.paid, 0) - COALESCE(p.paid, 0) AS balance`).
		Joins(`LEFT JOIN (
			SELECT customer_id, SUM(total_amount) AS total, SUM(amount_paid) AS paid
			FROM milk_sales WHERE sacco_id = ? AND deleted_at IS NULL AND voided_at IS NULL
			GROUP BY customer_id) s ON s.customer_id = c.id`, saccoID).
		Joins(`LEFT JOIN (
			SELECT customer_id, SUM(amount) AS paid
			FROM customer_payments WHERE sacco_id = ? AND voided_at IS NULL
			GROUP BY customer_id) p ON p.customer_id = c.id`, saccoID).
		Where("c.sacco_id = ? AND c.deleted_at IS NULL", saccoID)
	if len(ids) > 0 {
		session = session.Where("c.id IN ?", ids)
	}

	var balances []Balance
	if err := session.Order("balance DESC, c.name ASC").Scan(&balances).Error; err != nil {
		return nil, err
	}
	for i := range balances {
		balances[i].TotalSales = round2(balances[i].TotalSales)
		balances[i].TotalPaid = round2(balances[i].TotalPaid)
		balances[i].Balance = round2(balances[i].Balance)
	}
	return balances, nil
}

// OpeningBalance is what a customer owed before the start of day from.
func (r *Repository) OpeningBalance(ctx context.Context, saccoID, customerID string, from time.Time) (float64, error) {
	fromStr := from.Format(dateLayout)

	var owedOnSales float64
	err := r.db.WithContext(ctx).Table("milk_sales").
		Select("COALESCE(SUM(total_amount - amount_paid), 0)").
		Where("sacco_id = ? AND customer_id = ? AND deleted_at IS NULL AND voided_at IS NULL AND sale_date < ?", saccoID, customerID, fromStr).
		Scan(&owedOnSales).Error
	if err != nil {
		return 0, err
	}

	var paid float64
	err = r.db.WithContext(ctx).Table("customer_payments").
		Select("COALESCE(SUM(amount), 0)").
		Where("sacco_id = ? AND customer_id = ? AND voided_at IS NULL AND payment_date < ?", saccoID, customerID, fromStr).
		Scan(&paid).Error
	if err != nil {
		return 0, err
	}
	return round2(owedOnSales - paid), nil
}

// LedgerEvents returns a customer's sales and payments dated within [from, to].
func (r *Repository) LedgerEvents(ctx context.Context, saccoID, customerID string, from, to time.Time) ([]LedgerEvent, error) {
	fromStr, toStr := from.Format(dateLayout), to.Format(dateLayout)

	var sales []struct {
		ID             string
		SaleDate       time.Time
		CreatedAt      time.Time
		QuantityLitres float64
		UnitPrice      float64
		TotalAmount    float64
		AmountPaid     float64
		PaymentMethod  string
	}
	err := r.db.WithContext(ctx).Table("milk_sales").
		Select("id, sale_date, created_at, quantity_litres, unit_price, total_amount, amount_paid, payment_method").
		Where("sacco_id = ? AND customer_id = ? AND deleted_at IS NULL AND voided_at IS NULL AND sale_date BETWEEN ? AND ?", saccoID, customerID, fromStr, toStr).
		Scan(&sales).Error
	if err != nil {
		return nil, err
	}

	var payments []Payment
	err = r.db.WithContext(ctx).
		Where("sacco_id = ? AND customer_id = ? AND voided_at IS NULL AND payment_date BETWEEN ? AND ?", saccoID, customerID, fromStr, toStr).
		Find(&payments).Error
	if err != nil {
		return nil, err
	}

	events := make([]LedgerEvent, 0, len(sales)+len(payments))
	for _, s := range sales {
		desc := fmt.Sprintf("Milk sale %.2f L @ %.2f", s.QuantityLitres, s.UnitPrice)
		if s.AmountPaid > 0 {
			desc += fmt.Sprintf(", %.2f paid at sale (%s)", s.AmountPaid, s.PaymentMethod)
		}
		events = append(events, LedgerEvent{
			Kind: EntrySale, ReferenceID: s.ID, Date: s.SaleDate, CreatedAt: s.CreatedAt,
			Description: desc, Litres: s.QuantityLitres, Debit: s.TotalAmount, Credit: s.AmountPaid,
		})
	}
	for _, p := range payments {
		desc := "Payment (" + string(p.Method) + ")"
		if p.Reference != nil && *p.Reference != "" {
			desc += " ref " + *p.Reference
		}
		events = append(events, LedgerEvent{
			Kind: EntryPayment, ReferenceID: p.ID, Date: p.PaymentDate, CreatedAt: p.CreatedAt,
			Description: desc, Credit: p.Amount,
		})
	}
	return events, nil
}
