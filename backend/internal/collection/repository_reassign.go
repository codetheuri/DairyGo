package collection

import (
	"context"
	"fmt"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/audit"
)

// collectorDaySQL lists what one account saved for a day across the kinds of
// record that can be moved, in the order they were saved.
const collectorDaySQL = `
SELECT 'INTAKE' AS kind, c.id, c.created_at AS at, CAST(c.shift AS TEXT) AS shift, c.quantity_litres AS litres,
       c.total_amount AS amount,
       COALESCE(m.membership_number || ' ' || m.first_name || ' ' || m.last_name, '') AS party,
       FALSE AS voided, c.late_reason
  FROM milk_collections c LEFT JOIN members m ON m.id = c.member_id
 WHERE c.sacco_id = @sacco AND c.collector_id = @who AND c.collection_date = @day AND c.deleted_at IS NULL
UNION ALL
SELECT 'SALE', s.id, s.created_at, '', s.quantity_litres, s.total_amount, s.buyer_name,
       s.voided_at IS NOT NULL, s.late_reason
  FROM milk_sales s
 WHERE s.sacco_id = @sacco AND s.collector_id = @who AND s.sale_date = @day AND s.deleted_at IS NULL
UNION ALL
SELECT 'SPOILAGE', sp.id, sp.created_at, '', sp.quantity_litres, 0, sp.reason, FALSE, sp.late_reason
  FROM milk_spoilage sp
 WHERE sp.sacco_id = @sacco AND sp.collector_id = @who AND sp.spoilage_date = @day AND sp.deleted_at IS NULL
UNION ALL
SELECT 'PAYMENT', p.id, p.created_at, '', 0, p.amount, COALESCE(cu.name, ''), p.voided_at IS NOT NULL, NULL
  FROM customer_payments p LEFT JOIN customers cu ON cu.id = p.customer_id
 WHERE p.sacco_id = @sacco AND p.recorded_by_id = @who AND p.payment_date = @day
ORDER BY at`

// CollectorDay lists what an account saved for a day.
func (r *Repository) CollectorDay(ctx context.Context, saccoID string, who uint, day string) ([]DayRecord, error) {
	rows := []DayRecord{}
	err := r.db.WithContext(ctx).Raw(collectorDaySQL,
		map[string]any{"sacco": saccoID, "who": who, "day": day}).Scan(&rows).Error
	return rows, err
}

// Reassign moves the records to the collector to, with their history, in one
// transaction. A record no longer on from's account (moved, removed, or in
// another Sacco) stops the whole move.
func (r *Repository) Reassign(ctx context.Context, saccoID string, from, to uint,
	byKind map[string][]string, entries []audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		for kind, ids := range byKind {
			m := movable[kind]
			q := tx.Table(m.table).
				Where("sacco_id = ? AND "+m.column+" = ? AND id IN ?", saccoID, from, ids)
			if m.softDeleted {
				q = q.Where("deleted_at IS NULL")
			}
			res := q.Updates(map[string]any{m.column: to, "updated_at": time.Now()})
			if res.Error != nil {
				return res.Error
			}
			if missing := len(ids) - int(res.RowsAffected); missing > 0 {
				return fmt.Errorf("%w: %d of the chosen records are no longer on that account; "+
					"reload the list and try again (nothing was moved)", ErrNotFound, missing)
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
