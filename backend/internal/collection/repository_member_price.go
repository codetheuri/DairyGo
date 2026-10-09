package collection

import (
	"context"
	"errors"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/audit"
)

// MemberPriceRows is a farmer's active own-price rows.
func (r *Repository) MemberPriceRows(ctx context.Context, saccoID, memberID string) ([]MemberPrice, error) {
	var rows []MemberPrice
	err := r.db.WithContext(ctx).
		Where("sacco_id = ? AND member_id = ? AND is_active = ?", saccoID, memberID, true).
		Find(&rows).Error
	return rows, err
}

// SaccoPriceRows is the Sacco's active buying prices.
func (r *Repository) SaccoPriceRows(ctx context.Context, saccoID string) ([]MilkPrice, error) {
	var rows []MilkPrice
	err := r.db.WithContext(ctx).Where("sacco_id = ? AND is_active = ?", saccoID, true).Find(&rows).Error
	return rows, err
}

// FindMemberPrice loads one active row of a farmer's schedule.
func (r *Repository) FindMemberPrice(ctx context.Context, saccoID, memberID, id string) (*MemberPrice, error) {
	var p MemberPrice
	err := r.db.WithContext(ctx).
		Where("sacco_id = ? AND member_id = ? AND id = ? AND is_active = ?", saccoID, memberID, id, true).
		First(&p).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrNotFound
	}
	return &p, err
}

// UnpaidCollections is a farmer's milk not yet in an approved pay run: dated
// after closedThrough (all of it when nothing is paid yet).
func (r *Repository) UnpaidCollections(ctx context.Context, saccoID, memberID string, closedThrough *time.Time) ([]MilkCollection, error) {
	var rows []MilkCollection
	q := r.db.WithContext(ctx).Where("sacco_id = ? AND member_id = ?", saccoID, memberID)
	if closedThrough != nil {
		q = q.Where("collection_date > ?", closedThrough.Format(dateLayout))
	}
	err := q.Order("collection_date").Find(&rows).Error
	return rows, err
}

// SaveMemberPrice saves an added or voided price row, the repriced milk and
// every history entry in one transaction.
func (r *Repository) SaveMemberPrice(ctx context.Context, added, voided *MemberPrice, changes []priceChange, entries []audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if added != nil {
			if err := tx.Create(added).Error; err != nil {
				return err
			}
		}
		if voided != nil {
			if err := tx.Model(&MemberPrice{}).Where("id = ?", voided.ID).Updates(map[string]any{
				"is_active": false, "voided_at": voided.VoidedAt, "void_reason": voided.VoidReason, "updated_at": time.Now(),
			}).Error; err != nil {
				return err
			}
		}
		for _, c := range changes {
			if err := tx.Model(&MilkCollection{}).Where("id = ?", c.Collection.ID).Updates(map[string]any{
				"price_per_litre": c.NewPrice, "total_amount": c.NewTotal, "updated_at": time.Now(),
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
