package memberimport

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/member"
	"github.com/codetheuri/tusk/pkg/audit"
)

// Options says what to import where.
type Options struct {
	SaccoID string
	Rows    []Row

	// Replace clears the Sacco's farmers and milk records first (see
	// clearSteps). Without it, the farmers are added to those already there.
	Replace bool

	// DryRun does all the work and reports it, then undoes it.
	DryRun bool

	// Source names the file, for the audit trail.
	Source string
}

// Report is what an import did (or would do, in a dry run).
type Report struct {
	// Cleared counts the rows deleted per table, in the order deleted.
	Cleared  []Count
	Added    int
	Active   int
	Inactive int
	NoPhone  int
}

// Count is the rows deleted from one table.
type Count struct {
	Table string
	Rows  int64
}

// clearSteps delete a Sacco's test data, children before parents so no
// foreign key refuses. Everything is limited to the one Sacco (?). Staff,
// roles, the Sacco's settings and milk prices are kept, and so is the audit
// trail of staff, role and Sacco changes.
var clearSteps = []struct{ table, sql string }{
	{"customer_payments", `DELETE FROM customer_payments WHERE sacco_id = ?`},
	{"milk_sales", `DELETE FROM milk_sales WHERE sacco_id = ?`},
	{"customers", `DELETE FROM customers WHERE sacco_id = ?`},
	{"milk_spoilage", `DELETE FROM milk_spoilage WHERE sacco_id = ?`},
	{"milk_transfers", `DELETE FROM milk_transfers WHERE sacco_id = ?`},
	{"milk_collections", `DELETE FROM milk_collections WHERE sacco_id = ?`},
	{"members", `DELETE FROM members WHERE sacco_id = ?`},
	{"audit_logs", `DELETE FROM audit_logs WHERE sacco_id = ? AND entity_type NOT IN ('user', 'role', 'sacco')`},
	{"sms_logs", `DELETE FROM sms_logs WHERE sacco_id = ?`},
	// Saved answers to staff requests, which may describe deleted records.
	{"idempotency_keys", `DELETE FROM idempotency_keys WHERE user_id IN (SELECT id FROM users WHERE sacco_id = ?)`},
}

var errDryRun = errors.New("dry run")

// Import runs the import in one transaction: all of it happens, or none.
func Import(ctx context.Context, db *gorm.DB, opt Options) (Report, error) {
	var report Report
	err := db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var saccos int64
		if err := tx.Table("saccos").Where("id = ?", opt.SaccoID).Count(&saccos).Error; err != nil {
			return err
		}
		if saccos == 0 {
			return fmt.Errorf("no Sacco with id %s", opt.SaccoID)
		}

		if opt.Replace {
			for _, step := range clearSteps {
				res := tx.Exec(step.sql, opt.SaccoID)
				if res.Error != nil {
					return fmt.Errorf("clear %s: %w", step.table, res.Error)
				}
				report.Cleared = append(report.Cleared, Count{step.table, res.RowsAffected})
			}
		}

		members := make([]member.Member, 0, len(opt.Rows))
		for _, r := range opt.Rows {
			gender := r.Gender
			members = append(members, member.Member{
				ID:               uuid.New().String(),
				SaccoID:          opt.SaccoID,
				MembershipNumber: r.Number,
				FirstName:        r.FirstName,
				LastName:         r.LastName,
				Phone:            r.Phone,
				Gender:           &gender,
				Status:           r.Status,
			})
			switch r.Status {
			case member.StatusActive:
				report.Active++
			default:
				report.Inactive++
			}
			if r.Phone == "" {
				report.NoPhone++
			}
		}
		if err := tx.CreateInBatches(&members, 100).Error; err != nil {
			if strings.Contains(err.Error(), "uq_sacco_membership") {
				return fmt.Errorf("a membership number in the file is already used in this Sacco (use --replace to start afresh): %w", err)
			}
			return fmt.Errorf("add farmers: %w", err)
		}
		report.Added = len(members)

		reason := fmt.Sprintf("Farmer register imported from %s: %d added", opt.Source, report.Added)
		if opt.Replace {
			reason += "; earlier farmers and milk records cleared"
		}
		if err := audit.Record(tx, audit.Entry{
			SaccoID:    opt.SaccoID,
			EntityType: "sacco",
			EntityID:   opt.SaccoID,
			Action:     audit.ActionUpdate,
			Reason:     &reason,
			NewValues:  report,
		}); err != nil {
			return err
		}

		if opt.DryRun {
			return errDryRun
		}
		return nil
	})
	if errors.Is(err, errDryRun) {
		err = nil
	}
	return report, err
}
