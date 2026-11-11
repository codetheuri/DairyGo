package ledger

import (
	"context"
	"time"

	"gorm.io/gorm"
)

// loader reads source records and applies their rules. With ids it reads
// those records, voided or not (a voided record must take back its journal);
// without, every record still standing, only those dated before `before`
// when it is set (for the opening journal).
type loader struct {
	ctx     context.Context
	db      *gorm.DB
	saccoID string
	cash    cashInfo
	before  *time.Time
}

type loadFn func(l *loader, ids []string) ([]record, error)

// loaders by source type, in the order a full sync posts them.
var loaders = []struct {
	src  string
	load loadFn
}{
	{SrcCashAccount, loadCashAccounts},
	{SrcSale, loadSales},
	{SrcPayment, loadPayments},
	{SrcExpense, loadExpenses},
	{SrcTransfer, loadTransfers},
	{SrcFarmerEntry, loadEntries},
	{SrcPayRun, loadRuns},
	{SrcIncome, loadIncome},
	{SrcBill, loadBills},
	{SrcSupplierPay, loadSupplierPayments},
	{SrcShareEntry, loadShareEntries},
}

func loaderFor(src string) loadFn {
	for _, l := range loaders {
		if l.src == src {
			return l.load
		}
	}
	return nil
}

func newLoader(ctx context.Context, db *gorm.DB, saccoID string) (*loader, error) {
	var rows []struct {
		ID          string
		OpeningDate time.Time
	}
	if err := db.WithContext(ctx).Table("cash_accounts").Select("id, opening_date").
		Where("sacco_id = ?", saccoID).Scan(&rows).Error; err != nil {
		return nil, err
	}
	ci := cashInfo{}
	for _, r := range rows {
		ci[r.ID] = r.OpeningDate
	}
	return &loader{ctx: ctx, db: db, saccoID: saccoID, cash: ci}, nil
}

// scope limits a query to the ids asked for, or to standing records (and
// those before l.before) when there are none.
func (l *loader) scope(q *gorm.DB, idCol, standing, dateCol string, ids []string) *gorm.DB {
	if ids != nil {
		return q.Where(idCol+" IN ?", ids)
	}
	if standing != "" {
		q = q.Where(standing)
	}
	if l.before != nil && dateCol != "" {
		q = q.Where(dateCol+" < ?", l.before.Format(dateLayout))
	}
	return q
}

func loadSales(l *loader, ids []string) ([]record, error) {
	var rows []saleRow
	q := l.db.WithContext(l.ctx).Table("milk_sales").
		Select(`id, sale_date, buyer_name, quantity_litres AS litres, total_amount AS total, amount_paid AS paid,
			cash_account_id AS account_id, (voided_at IS NOT NULL OR deleted_at IS NOT NULL) AS voided`).
		Where("sacco_id = ?", l.saccoID)
	q = l.scope(q, "id", "voided_at IS NULL AND deleted_at IS NULL", "sale_date", ids)
	if err := q.Order("sale_date, created_at").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]record, len(rows))
	for i, r := range rows {
		out[i] = saleRule(r, l.cash)
	}
	return out, nil
}

func loadPayments(l *loader, ids []string) ([]record, error) {
	var rows []paymentRow
	q := l.db.WithContext(l.ctx).Table("customer_payments p").
		Select(`p.id, p.payment_date, COALESCE(c.name, 'a customer') AS customer, p.amount,
			p.cash_account_id AS account_id, p.reference, (p.voided_at IS NOT NULL) AS voided`).
		Joins("LEFT JOIN customers c ON c.id = p.customer_id").
		Where("p.sacco_id = ?", l.saccoID)
	q = l.scope(q, "p.id", "p.voided_at IS NULL", "p.payment_date", ids)
	if err := q.Order("p.payment_date, p.created_at").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]record, len(rows))
	for i, r := range rows {
		out[i] = paymentRule(r, l.cash)
	}
	return out, nil
}

func loadExpenses(l *loader, ids []string) ([]record, error) {
	var rows []expenseRow
	q := l.db.WithContext(l.ctx).Table("expenses e").
		Select(`e.id, e.expense_date, e.category_id, COALESCE(c.name, 'Expense') AS category, e.payee, e.amount,
			e.cash_account_id AS account_id, e.reference, (e.voided_at IS NOT NULL) AS voided`).
		Joins("LEFT JOIN expense_categories c ON c.id = e.category_id").
		Where("e.sacco_id = ?", l.saccoID)
	q = l.scope(q, "e.id", "e.voided_at IS NULL", "e.expense_date", ids)
	if err := q.Order("e.expense_date, e.created_at").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]record, len(rows))
	for i, r := range rows {
		out[i] = expenseRule(r, l.cash)
	}
	return out, nil
}

func loadTransfers(l *loader, ids []string) ([]record, error) {
	var rows []transferRow
	q := l.db.WithContext(l.ctx).Table("account_transfers t").
		Select(`t.id, t.transfer_date, t.from_account_id AS from_id, t.to_account_id AS to_id,
			COALESCE(f.name, '') AS from_name, COALESCE(o.name, '') AS to_name, t.amount, t.reference,
			(t.voided_at IS NOT NULL) AS voided`).
		Joins("LEFT JOIN cash_accounts f ON f.id = t.from_account_id").
		Joins("LEFT JOIN cash_accounts o ON o.id = t.to_account_id").
		Where("t.sacco_id = ?", l.saccoID)
	q = l.scope(q, "t.id", "t.voided_at IS NULL", "t.transfer_date", ids)
	if err := q.Order("t.transfer_date, t.created_at").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]record, len(rows))
	for i, r := range rows {
		out[i] = transferRule(r, l.cash)
	}
	return out, nil
}

func loadEntries(l *loader, ids []string) ([]record, error) {
	var rows []entryRow
	q := l.db.WithContext(l.ctx).Table("member_transactions m").
		Select(`m.id, m.entry_date, m.kind, m.amount,
			COALESCE(mb.first_name || ' ' || mb.last_name, 'a farmer') AS farmer, m.description,
			m.cash_account_id AS account_id, m.reference, (m.voided_at IS NOT NULL) AS voided`).
		Joins("LEFT JOIN members mb ON mb.id = m.member_id").
		Where("m.sacco_id = ? AND m.kind IN ('ADVANCE', 'CHARGE', 'ADJUSTMENT')", l.saccoID)
	q = l.scope(q, "m.id", "m.voided_at IS NULL", "m.entry_date", ids)
	if err := q.Order("m.entry_date, m.created_at").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]record, len(rows))
	for i, r := range rows {
		out[i] = entryRule(r, l.cash)
	}
	return out, nil
}

// loadRuns reads pay runs with what approving them wrote to farmers'
// accounts (gone again if the run was cancelled) and what has been sent,
// by day and account as the cashbook shows it.
func loadRuns(l *loader, ids []string) ([]record, error) {
	db := l.db.WithContext(l.ctx)
	var heads []struct {
		ID       string
		FromDate time.Time
		ToDate   time.Time
	}
	q := db.Table("pay_runs").Select("id, from_date, to_date").Where("sacco_id = ?", l.saccoID)
	q = l.scope(q, "id", "status <> 'DRAFT'", "from_date", ids)
	if err := q.Order("to_date, created_at").Scan(&heads).Error; err != nil {
		return nil, err
	}
	if len(heads) == 0 {
		return nil, nil
	}
	runs := make([]runRow, len(heads))
	runIDs := make([]string, len(heads))
	byID := map[string]*runRow{}
	for i, h := range heads {
		runs[i] = runRow{ID: h.ID, FromDate: h.FromDate, ToDate: h.ToDate}
		runIDs[i] = h.ID
		byID[h.ID] = &runs[i]
	}

	var entries []struct {
		RunID     string
		Kind      string
		TypeID    *string
		IsSavings bool
		PayeeID   *string
		Name      string
		Amount    float64
	}
	if err := db.Raw(`SELECT m.pay_run_id AS run_id, m.kind, m.deduction_type_id AS type_id, m.is_savings, m.payee_id,
			MAX(COALESCE(t.name, m.description)) AS name, SUM(m.amount) AS amount
		FROM member_transactions m LEFT JOIN deduction_types t ON t.id = m.deduction_type_id
		WHERE m.sacco_id = ? AND m.pay_run_id IN ? AND m.kind IN ('MILK', 'DEDUCTION', 'PAYOUT') AND m.voided_at IS NULL
		GROUP BY m.pay_run_id, m.kind, m.deduction_type_id, m.is_savings, m.payee_id
		ORDER BY MAX(COALESCE(t.priority, 0)), MAX(COALESCE(t.name, m.description))`, l.saccoID, runIDs).Scan(&entries).Error; err != nil {
		return nil, err
	}
	for _, e := range entries {
		r := byID[e.RunID]
		switch e.Kind {
		case "MILK":
			r.Milk += e.Amount
		case "DEDUCTION":
			r.Deductions = append(r.Deductions, runDeduction{TypeID: e.TypeID, Name: e.Name, Savings: e.IsSavings, PayeeID: e.PayeeID, Amount: -e.Amount})
		case "PAYOUT":
			r.Net += -e.Amount
		}
	}

	var paid []struct {
		RunID     string
		PaidAt    time.Time
		PaidDate  time.Time
		AccountID *string
		Amount    float64
		Farmers   int
	}
	// One journal per payment batch: the farmers marked paid together share
	// the moment they were marked, so a later batch never changes an
	// earlier journal.
	if err := db.Raw(`SELECT pay_run_id AS run_id, paid_at, CAST(paid_at AS DATE) AS paid_date, cash_account_id AS account_id,
			SUM(net) AS amount, COUNT(*) AS farmers
		FROM pay_run_lines
		WHERE sacco_id = ? AND pay_run_id IN ? AND paid_at IS NOT NULL
		GROUP BY pay_run_id, paid_at, cash_account_id
		ORDER BY paid_at`, l.saccoID, runIDs).Scan(&paid).Error; err != nil {
		return nil, err
	}
	for _, p := range paid {
		r := byID[p.RunID]
		r.Paid = append(r.Paid, runPaid{Batch: p.PaidAt.Format("20060102T150405.000000"), PaidDate: p.PaidDate, AccountID: p.AccountID, Amount: p.Amount, Farmers: p.Farmers})
	}

	out := make([]record, len(runs))
	for i, r := range runs {
		out[i] = runRule(r, l.cash)
	}
	return out, nil
}

func loadCashAccounts(l *loader, ids []string) ([]record, error) {
	var rows []cashAccountRow
	q := l.db.WithContext(l.ctx).Table("cash_accounts").Select("id, name, opening_balance, opening_date").
		Where("sacco_id = ?", l.saccoID)
	q = l.scope(q, "id", "", "opening_date", ids)
	if err := q.Order("created_at, name").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]record, len(rows))
	for i, r := range rows {
		out[i] = cashAccountRule(r)
	}
	return out, nil
}

func loadIncome(l *loader, ids []string) ([]record, error) {
	var rows []incomeRow
	q := l.db.WithContext(l.ctx).Table("other_income i").
		Select(`i.id, i.income_date, i.category_id, COALESCE(c.name, 'Other income') AS category, i.payer, i.amount,
			i.cash_account_id AS account_id, i.reference, (i.voided_at IS NOT NULL) AS voided`).
		Joins("LEFT JOIN income_categories c ON c.id = i.category_id").
		Where("i.sacco_id = ?", l.saccoID)
	q = l.scope(q, "i.id", "i.voided_at IS NULL", "i.income_date", ids)
	if err := q.Order("i.income_date, i.created_at").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]record, len(rows))
	for i, r := range rows {
		out[i] = incomeRule(r, l.cash)
	}
	return out, nil
}

func loadBills(l *loader, ids []string) ([]record, error) {
	var rows []billRow
	q := l.db.WithContext(l.ctx).Table("bills b").
		Select(`b.id, b.bill_date, b.category_id, COALESCE(c.name, 'Expense') AS category, COALESCE(s.name, 'a supplier') AS supplier,
			b.amount, b.reference, (b.voided_at IS NOT NULL) AS voided`).
		Joins("LEFT JOIN expense_categories c ON c.id = b.category_id").
		Joins("LEFT JOIN suppliers s ON s.id = b.supplier_id").
		Where("b.sacco_id = ?", l.saccoID)
	q = l.scope(q, "b.id", "b.voided_at IS NULL", "b.bill_date", ids)
	if err := q.Order("b.bill_date, b.created_at").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]record, len(rows))
	for i, r := range rows {
		out[i] = billRule(r)
	}
	return out, nil
}

func loadSupplierPayments(l *loader, ids []string) ([]record, error) {
	var rows []supplierPayRow
	q := l.db.WithContext(l.ctx).Table("supplier_payments p").
		Select(`p.id, p.payment_date, p.kind, p.supplier_id, COALESCE(s.name, 'a supplier') AS supplier, p.amount,
			p.cash_account_id AS account_id, p.reference, (p.voided_at IS NOT NULL) AS voided`).
		Joins("LEFT JOIN suppliers s ON s.id = p.supplier_id").
		Where("p.sacco_id = ?", l.saccoID)
	q = l.scope(q, "p.id", "p.voided_at IS NULL", "p.payment_date", ids)
	if err := q.Order("p.payment_date, p.created_at").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]record, len(rows))
	for i, r := range rows {
		out[i] = supplierPayRule(r, l.cash)
	}
	return out, nil
}

func loadShareEntries(l *loader, ids []string) ([]record, error) {
	var rows []shareRow
	q := l.db.WithContext(l.ctx).Table("share_entries e").
		Select(`e.id, e.entry_date, e.kind, e.deduction_type_id AS type_id,
			COALESCE(mb.first_name || ' ' || mb.last_name, 'a member') AS farmer, e.amount,
			e.cash_account_id AS account_id, e.reference, (e.voided_at IS NOT NULL) AS voided`).
		Joins("LEFT JOIN members mb ON mb.id = e.member_id").
		Where("e.sacco_id = ?", l.saccoID)
	q = l.scope(q, "e.id", "e.voided_at IS NULL", "e.entry_date", ids)
	if err := q.Order("e.entry_date, e.created_at").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]record, len(rows))
	for i, r := range rows {
		out[i] = shareRule(r, l.cash)
	}
	return out, nil
}
