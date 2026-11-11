package ledger

import (
	"context"
	"database/sql"
	"sort"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/finance"
)

// The check: each account kept from records must equal what the records
// say, worked out the way the rest of DairyGo works it out (the customer
// list, farmers' accounts, the pay run, each cashbook). A difference means
// a journal is missing or a record changed without one; "bring up to date"
// (or the nightly check) posts what is missing.

// Control compares one account in the books with its records.
type Control struct {
	Name       string  `json:"name"`
	AccountID  string  `json:"account_id"`
	Code       string  `json:"code"`
	Books      float64 `json:"books" doc:"The account's balance in the books, in its usual direction"`
	Records    float64 `json:"records" doc:"What the records say"`
	Difference float64 `json:"difference"`
	OK         bool    `json:"ok"`
}

type checkResult struct {
	Balanced     bool
	Agrees       bool
	Controls     []Control
	NotInAccount float64
}

// balances is each account's debits less credits, up to a day when given.
func balances(ctx context.Context, db *gorm.DB, saccoID string, upTo *string) (map[string]float64, error) {
	var rows []struct {
		AccountID string
		Net       float64
	}
	q := db.WithContext(ctx).Table("journal_lines").Select("account_id, SUM(debit) - SUM(credit) AS net").
		Where("sacco_id = ?", saccoID)
	if upTo != nil {
		q = q.Where("journal_date <= ?", *upTo)
	}
	if err := q.Group("account_id").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := map[string]float64{}
	for _, r := range rows {
		out[r.AccountID] = round2(r.Net)
	}
	return out, nil
}

func sum(ctx context.Context, db *gorm.DB, q string, args ...any) (float64, error) {
	var v sql.NullFloat64
	err := db.WithContext(ctx).Raw(q, args...).Scan(&v).Error
	return round2(v.Float64), err
}

func (s *Service) check(ctx context.Context, db *gorm.DB, saccoID string) (*checkResult, error) {
	c, err := loadChart(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	net, err := balances(ctx, db, saccoID, nil)
	if err != nil {
		return nil, err
	}
	var totals struct{ Debit, Credit float64 }
	if err := db.WithContext(ctx).Table("journal_lines").Select("COALESCE(SUM(debit), 0) AS debit, COALESCE(SUM(credit), 0) AS credit").
		Where("sacco_id = ?", saccoID).Scan(&totals).Error; err != nil {
		return nil, err
	}
	res := &checkResult{Balanced: same(totals.Debit, totals.Credit), Agrees: true, Controls: []Control{}}

	customers, err := sum(ctx, db, `SELECT
		(SELECT COALESCE(SUM(total_amount - amount_paid), 0) FROM milk_sales WHERE sacco_id = @s AND voided_at IS NULL AND deleted_at IS NULL)
	  - (SELECT COALESCE(SUM(amount), 0) FROM customer_payments WHERE sacco_id = @s AND voided_at IS NULL)`, sql.Named("s", saccoID))
	if err != nil {
		return nil, err
	}
	farmers, err := sum(ctx, db, `SELECT -COALESCE(SUM(amount), 0) FROM member_transactions WHERE sacco_id = ? AND voided_at IS NULL`, saccoID)
	if err != nil {
		return nil, err
	}
	payDue, err := sum(ctx, db, `SELECT COALESCE(SUM(l.net), 0) FROM pay_run_lines l JOIN pay_runs p ON p.id = l.pay_run_id
		WHERE l.sacco_id = ? AND p.status = 'APPROVED' AND l.paid_at IS NULL AND l.net > 0`, saccoID)
	if err != nil {
		return nil, err
	}

	add := func(name string, accountID string, records float64) {
		a := c.accounts[accountID]
		if a == nil {
			return
		}
		books := net[accountID]
		if !a.Type.DebitNormal() {
			books = -books
		}
		books = round2(books)
		d := round2(books - records)
		ok := same(d, 0)
		res.Agrees = res.Agrees && ok
		res.Controls = append(res.Controls, Control{Name: name, AccountID: a.ID, Code: a.Code, Books: books, Records: round2(records), Difference: d, OK: ok})
	}
	add("Customers", c.links[roleKey(RoleCustomers)], customers)
	add("Farmers' accounts", c.links[roleKey(RoleFarmers)], farmers)
	add("Farmers' pay due", c.links[roleKey(RolePayDue)], payDue)

	// Cash accounts: each cashbook's balance now, summed by the ledger
	// account they post to.
	var cash []struct {
		ID             string
		OpeningBalance float64
	}
	if err := db.WithContext(ctx).Table("cash_accounts").Select("id, opening_balance").Where("sacco_id = ?", saccoID).
		Order("created_at, name").Scan(&cash).Error; err != nil {
		return nil, err
	}
	moved, err := finance.NewRepository(db).Balances(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	byLedger := map[string]float64{}
	var order []string
	for _, a := range cash {
		id, ok := c.links[cashKey(a.ID)]
		if !ok {
			continue
		}
		if _, seen := byLedger[id]; !seen {
			order = append(order, id)
		}
		byLedger[id] += a.OpeningBalance + moved[a.ID]
	}
	sort.SliceStable(order, func(i, k int) bool { return c.accounts[order[i]].Code < c.accounts[order[k]].Code })
	for _, id := range order {
		add(c.accounts[id].Name, id, byLedger[id])
	}

	if id, ok := c.links[roleKey(RoleNoAccount)]; ok {
		res.NotInAccount = net[id]
	}
	return res, nil
}
