package collection

import (
	"context"
	"strings"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/audit"
)

// repriceBatch bounds one UPDATE: a Sacco's unpaid milk can be many thousands
// of records.
const repriceBatch = 500

// MilkFrom is the Sacco's milk from a day on, with only what repricing reads.
func (r *Repository) MilkFrom(ctx context.Context, saccoID, from string) ([]MilkCollection, error) {
	var rows []MilkCollection
	err := r.db.WithContext(ctx).
		Select("id, member_id, collection_date, quantity_litres, price_per_litre, total_amount, status").
		Where("sacco_id = ? AND collection_date >= ?", saccoID, from).
		Find(&rows).Error
	return rows, err
}

// AllMemberPriceRows is every farmer's active own-price rows, sorted, by farmer.
func (r *Repository) AllMemberPriceRows(ctx context.Context, saccoID string) (map[string][]MemberPrice, error) {
	var rows []MemberPrice
	err := r.db.WithContext(ctx).Where("sacco_id = ? AND is_active = ?", saccoID, true).Find(&rows).Error
	if err != nil {
		return nil, err
	}
	sortSchedules(rows, nil)
	byFarmer := map[string][]MemberPrice{}
	for _, row := range rows {
		byFarmer[row.MemberID] = append(byFarmer[row.MemberID], row)
	}
	return byFarmer, nil
}

// SaveSaccoPrice saves the new price row, the repriced milk and every history
// entry in one transaction, in batches: one statement per batch, not per
// record, so a whole Sacco's milk saves in seconds.
func (r *Repository) SaveSaccoPrice(ctx context.Context, added *MilkPrice, changes []priceChange, entries []audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if added != nil {
			if err := tx.Create(added).Error; err != nil {
				return err
			}
		}
		now := time.Now()
		for start := 0; start < len(changes); start += repriceBatch {
			end := min(start+repriceBatch, len(changes))
			batch := changes[start:end]
			args := make([]any, 0, 1+3*len(batch))
			args = append(args, now)
			for _, c := range batch {
				args = append(args, c.Collection.ID, c.NewPrice, c.NewTotal)
			}
			values := strings.TrimSuffix(strings.Repeat("(?::varchar, ?::numeric, ?::numeric),", len(batch)), ",")
			if err := tx.Exec(`UPDATE milk_collections AS m
				SET price_per_litre = v.price, total_amount = v.total, updated_at = ?
				FROM (VALUES `+values+`) AS v(id, price, total) WHERE m.id = v.id`, args...).Error; err != nil {
				return err
			}
		}
		return audit.RecordAll(tx, entries)
	})
}
