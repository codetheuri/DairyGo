package member

import (
	"context"
	"fmt"
	"time"
)

// markIdleSQL marks inactive every active farmer who has brought no milk in
// their Sacco's inactivity period (sacco_settings.inactive_after_days, 60
// when not set, 0 = never), and records each change in the farmer's history.
//
// The period is counted from the farmer's last milk (rejected collections do
// not count), and never from before they were registered or last changed
// status: a new or just-reactivated farmer gets the full period.
//
// Parameters: today (the date), now (the timestamp written), default days.
// Postgres only (UPDATE ... FROM with RETURNING in a CTE).
const markIdleSQL = `
WITH settings AS (
    SELECT s.id AS sacco_id, COALESCE(ss.inactive_after_days, @default_days) AS days
    FROM saccos s
    LEFT JOIN sacco_settings ss ON ss.sacco_id = s.id
    WHERE s.deleted_at IS NULL
), idle AS (
    UPDATE members m
    SET status = 'INACTIVE', status_changed_at = @now, updated_at = @now
    FROM settings st
    WHERE st.sacco_id = m.sacco_id
      AND st.days > 0
      AND m.status = 'ACTIVE'
      AND m.deleted_at IS NULL
      AND GREATEST(m.created_at, COALESCE(m.status_changed_at, m.created_at))::date <= CAST(@today AS date) - st.days
      AND NOT EXISTS (
          SELECT 1 FROM milk_collections c
          WHERE c.sacco_id = m.sacco_id AND c.member_id = m.id
            AND c.status <> 'REJECTED'
            AND c.collection_date > CAST(@today AS date) - st.days
      )
    RETURNING m.id, m.sacco_id, st.days
)
INSERT INTO audit_logs (id, sacco_id, entity_type, entity_id, action, actor_id, reason, old_values, new_values, created_at)
SELECT gen_random_uuid()::text, sacco_id, 'member', id, 'STATUS', NULL,
       'No milk for ' || days || ' days: marked inactive automatically',
       '{"status":"ACTIVE"}', '{"status":"INACTIVE"}', @now
FROM idle`

// MarkIdleInactive marks inactive the farmers who have brought no milk for
// their Sacco's inactivity period, as of today, and returns how many. It is
// safe to run any number of times. See markIdleSQL for the rule.
func (r *Repository) MarkIdleInactive(ctx context.Context, today time.Time) (int64, error) {
	res := r.db.WithContext(ctx).Exec(markIdleSQL, map[string]any{
		"today":        today.Format("2006-01-02"),
		"now":          time.Now(),
		"default_days": DefaultInactiveAfterDays,
	})
	if res.Error != nil {
		return 0, fmt.Errorf("mark idle farmers inactive: %w", res.Error)
	}
	return res.RowsAffected, nil
}
