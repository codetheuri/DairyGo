package collection

import (
	"context"
	"time"
)

// LateRecord is one record entered after its day, for the console's list.
type LateRecord struct {
	Kind          string    `json:"kind" doc:"INTAKE, SALE, SPOILAGE or TRANSFER"`
	ID            string    `json:"id"`
	Day           time.Time `json:"day" doc:"The day the record is for"`
	Litres        float64   `json:"litres"`
	CollectorID   uint      `json:"collector_id"`
	CollectorName string    `json:"collector_name"`
	Party         string    `json:"party" doc:"The farmer, the customer, what spoiled, or the receiving collector"`
	Reason        string    `json:"late_reason"`
	EnteredByID   *uint     `json:"entered_by_id,omitempty"`
	EnteredBy     string    `json:"entered_by"`
	EnteredAt     time.Time `json:"entered_at"`
	OtherID       uint      `json:"-"`
}

// lateRecordsSQL lists a Sacco's late entries across the four kinds of milk
// record, newest first.
const lateRecordsSQL = `
SELECT 'INTAKE' AS kind, c.id, c.collection_date AS day, c.quantity_litres AS litres, c.collector_id,
       COALESCE(m.membership_number || ' ' || m.first_name || ' ' || m.last_name, '') AS party,
       c.late_reason AS reason, c.entered_by_id, c.created_at AS entered_at, 0 AS other_id
  FROM milk_collections c LEFT JOIN members m ON m.id = c.member_id
 WHERE c.sacco_id = @sacco AND c.late_reason IS NOT NULL AND c.deleted_at IS NULL
UNION ALL
SELECT 'SALE', s.id, s.sale_date, s.quantity_litres, s.collector_id, s.buyer_name,
       s.late_reason, s.entered_by_id, s.created_at, 0
  FROM milk_sales s
 WHERE s.sacco_id = @sacco AND s.late_reason IS NOT NULL AND s.deleted_at IS NULL
UNION ALL
SELECT 'SPOILAGE', sp.id, sp.spoilage_date, sp.quantity_litres, sp.collector_id, sp.reason,
       sp.late_reason, sp.entered_by_id, sp.created_at, 0
  FROM milk_spoilage sp
 WHERE sp.sacco_id = @sacco AND sp.late_reason IS NOT NULL AND sp.deleted_at IS NULL
UNION ALL
SELECT 'TRANSFER', t.id, t.transfer_date, t.quantity_litres, t.from_collector_id, '',
       t.late_reason, t.entered_by_id, t.created_at, t.to_collector_id
  FROM milk_transfers t
 WHERE t.sacco_id = @sacco AND t.late_reason IS NOT NULL AND t.deleted_at IS NULL
ORDER BY entered_at DESC
LIMIT 200`

// LateRecords lists the Sacco's late entries with staff names filled in.
func (r *Repository) LateRecords(ctx context.Context, saccoID string) ([]LateRecord, error) {
	var rows []LateRecord
	if err := r.db.WithContext(ctx).Raw(lateRecordsSQL, map[string]any{"sacco": saccoID}).Scan(&rows).Error; err != nil {
		return nil, err
	}
	ids := make([]uint, 0, 3*len(rows))
	for _, x := range rows {
		ids = append(ids, x.CollectorID, x.OtherID)
		if x.EnteredByID != nil {
			ids = append(ids, *x.EnteredByID)
		}
	}
	names := r.staffNames(ctx, ids)
	for i := range rows {
		rows[i].CollectorName = names[rows[i].CollectorID]
		if rows[i].Kind == "TRANSFER" {
			rows[i].Party = "To " + names[rows[i].OtherID]
		}
		if rows[i].EnteredByID != nil {
			rows[i].EnteredBy = names[*rows[i].EnteredByID]
		}
	}
	return rows, nil
}
