package collection

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/audit"
)

// priceCustomer is what a price change needs to know about a customer.
type priceCustomer struct {
	ID                   string
	SaccoID              string
	Name                 string
	DefaultPricePerLitre *float64
	CreatedAt            time.Time
	FirstSale            *time.Time
}

// FirstDay is the earliest day the customer existed: when they were added,
// or their first sale if that is earlier (customers made from older sales).
func (c *priceCustomer) FirstDay() time.Time {
	d := c.CreatedAt
	if c.FirstSale != nil && c.FirstSale.Before(d) {
		d = *c.FirstSale
	}
	return time.Date(d.Year(), d.Month(), d.Day(), 0, 0, 0, 0, time.Local)
}

// FindPriceCustomer loads a customer of the Sacco with their first sale day.
func (r *Repository) FindPriceCustomer(ctx context.Context, saccoID, customerID string) (*priceCustomer, error) {
	var c priceCustomer
	err := r.db.WithContext(ctx).Table("customers c").
		Select(`c.id, c.sacco_id, c.name, c.default_price_per_litre, c.created_at,
			(SELECT MIN(s.sale_date) FROM milk_sales s WHERE s.customer_id = c.id AND s.deleted_at IS NULL) AS first_sale`).
		Where("c.id = ? AND c.sacco_id = ? AND c.deleted_at IS NULL", customerID, saccoID).
		Take(&c).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("%w: customer not found in this Sacco", ErrNotFound)
	}
	return &c, err
}

// CustomerPriceRows is a customer's schedule: the active rows, or with
// activeOnly false every row, cancelled ones too.
func (r *Repository) CustomerPriceRows(ctx context.Context, saccoID, customerID string, activeOnly bool) ([]CustomerPrice, error) {
	var rows []CustomerPrice
	q := r.db.WithContext(ctx).Where("sacco_id = ? AND customer_id = ?", saccoID, customerID)
	if activeOnly {
		q = q.Where("is_active = ?", true)
	}
	err := q.Find(&rows).Error
	return rows, err
}

// nameCreators fills in who set each price.
func (r *Repository) nameCreators(ctx context.Context, rows []CustomerPrice) {
	ids := make([]uint, 0, len(rows))
	for _, p := range rows {
		if p.CreatedByID != nil {
			ids = append(ids, *p.CreatedByID)
		}
	}
	names := r.staffNames(ctx, ids)
	for i := range rows {
		if rows[i].CreatedByID != nil {
			rows[i].CreatedBy = names[*rows[i].CreatedByID]
		}
	}
}

// CustomerSalesFrom is a customer's sales dated from day on, not voided.
func (r *Repository) CustomerSalesFrom(ctx context.Context, saccoID, customerID string, day time.Time) ([]MilkSale, error) {
	var rows []MilkSale
	err := r.db.WithContext(ctx).
		Where("sacco_id = ? AND customer_id = ? AND voided_at IS NULL AND sale_date >= ?", saccoID, customerID, day.Format(dateLayout)).
		Order("sale_date, created_at").Find(&rows).Error
	return rows, err
}

// SaveCustomerPrice saves added or voided schedule rows, the repriced sales,
// the customer's agreed price (when agreed is set) and every history entry
// in one transaction.
func (r *Repository) SaveCustomerPrice(ctx context.Context, customerID string, added []CustomerPrice, voided *CustomerPrice,
	changes []saleReprice, agreed *float64, entries []audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		now := time.Now()
		for i := range added {
			if err := tx.Omit("CreatedBy").Create(&added[i]).Error; err != nil {
				return err
			}
		}
		if voided != nil {
			if err := tx.Model(&CustomerPrice{}).Where("id = ?", voided.ID).Updates(map[string]any{
				"is_active": false, "voided_at": voided.VoidedAt, "void_reason": voided.VoidReason, "updated_at": now,
			}).Error; err != nil {
				return err
			}
		}
		for _, c := range changes {
			if err := tx.Model(&MilkSale{}).Where("id = ?", c.Sale.ID).Updates(map[string]any{
				"unit_price": c.NewPrice, "total_amount": c.NewTotal, "payment_status": c.NewStatus, "updated_at": now,
			}).Error; err != nil {
				return err
			}
		}
		if agreed != nil {
			if err := tx.Table("customers").Where("id = ?", customerID).Updates(map[string]any{
				"default_price_per_litre": *agreed, "updated_at": now,
			}).Error; err != nil {
				return err
			}
		}
		for _, e := range entries {
			if err := audit.Record(tx, e); err != nil {
				return err
			}
		}
		return nil
	})
}
