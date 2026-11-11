package ledger

import (
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/logger"
)

// Every money record is saved with an audit entry in the same transaction,
// so the books follow the records from there: whatever screen, console tool
// or batch recorded the money, the journal is posted with it. The audit
// entity types below are the records that post.
var entitySources = map[string]string{
	"milk_sale":          SrcSale,
	"customer_payment":   SrcPayment,
	"expense":            SrcExpense,
	"account_transfer":   SrcTransfer,
	"member_transaction": SrcFarmerEntry,
	"pay_run":            SrcPayRun,
	"cash_account":       SrcCashAccount,
	"other_income":       SrcIncome,
	"bill":               SrcBill,
	"supplier_payment":   SrcSupplierPay,
	"share_entry":        SrcShareEntry,
	"ledger_opening":     SrcBooks,
}

// Install makes the books follow every money record from now on. Called
// once at start-up.
//
// Recording money never fails because of the books: the journals are
// written under a savepoint, and if posting fails the record is still saved,
// the failure is logged, and the nightly check (or the accountant's "bring
// up to date") posts it later.
func Install(log logger.Logger) {
	audit.OnRecord(func(tx *gorm.DB, entries []audit.Entry) error {
		bySacco := map[string][]Source{}
		for _, e := range entries {
			if src, ok := entitySources[e.EntityType]; ok && e.SaccoID != "" {
				bySacco[e.SaccoID] = append(bySacco[e.SaccoID], Source{Type: src, ID: e.EntityID})
			}
		}
		if len(bySacco) == 0 {
			return nil
		}
		ctx := tx.Statement.Context
		db := tx.Session(&gorm.Session{NewDB: true, Context: ctx})
		for saccoID, sources := range bySacco {
			if err := db.SavePoint("ledger_sync").Error; err != nil {
				// Not in a transaction: nothing to roll back to.
				if err := Sync(ctx, db, saccoID, sources); err != nil {
					log.Error("Books: posting failed; the nightly check will post it", err, "sacco_id", saccoID)
				}
				continue
			}
			if err := Sync(ctx, db, saccoID, sources); err != nil {
				log.Error("Books: posting failed; the nightly check will post it", err, "sacco_id", saccoID)
				if rb := db.RollbackTo("ledger_sync").Error; rb != nil {
					return rb
				}
			}
		}
		return nil
	})
}
