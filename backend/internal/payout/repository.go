package payout

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/query"
)

// Repository stores deductions, farmer accounts and pay runs. It reads
// members, milk_collections and sacco_settings directly rather than
// depending on those modules.
type Repository struct {
	db *gorm.DB
}

// NewRepository creates a payout repository.
func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func notFound(err error, what string) error {
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return fmt.Errorf("%w: %s not found", ErrNotFound, what)
	}
	return err
}

// --- settings ---

// Settings is what the payout module reads from sacco_settings.
type Settings struct {
	AdvanceMax    *float64
	ClosedThrough *time.Time
}

// Settings reads a Sacco's advance limit and closed-through date.
func (r *Repository) Settings(ctx context.Context, saccoID string) (Settings, error) {
	var row struct {
		AdvanceMaxPerPeriod  *float64
		PayrollClosedThrough *time.Time
	}
	err := r.db.WithContext(ctx).Table("sacco_settings").
		Select("advance_max_per_period, payroll_closed_through").
		Where("sacco_id = ?", saccoID).Take(&row).Error
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return Settings{}, err
	}
	return Settings{AdvanceMax: row.AdvanceMaxPerPeriod, ClosedThrough: row.PayrollClosedThrough}, nil
}

// --- deduction types ---

// ListTypes returns the Sacco's deduction types in the order they are taken.
func (r *Repository) ListTypes(ctx context.Context, activeOnly bool) ([]DeductionType, error) {
	var out []DeductionType
	q := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx))
	if activeOnly {
		q = q.Where("is_active = ?", true)
	}
	err := q.Order("priority, name").Find(&out).Error
	return out, err
}

// FindType loads a deduction type of the caller's Sacco.
func (r *Repository) FindType(ctx context.Context, id string) (*DeductionType, error) {
	var t DeductionType
	if err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&t).Error; err != nil {
		return nil, notFound(err, "deduction")
	}
	return &t, nil
}

// TypeNameTaken reports whether another deduction type of the Sacco has this name.
func (r *Repository) TypeNameTaken(ctx context.Context, saccoID, name, exceptID string) (bool, error) {
	var n int64
	err := r.db.WithContext(ctx).Model(&DeductionType{}).
		Where("sacco_id = ? AND LOWER(name) = LOWER(?) AND id <> ?", saccoID, name, exceptID).Count(&n).Error
	return n > 0, err
}

// TypeUsed reports whether a deduction type was ever taken from a farmer.
func (r *Repository) TypeUsed(ctx context.Context, id string) (bool, error) {
	var n int64
	err := r.db.WithContext(ctx).Model(&Transaction{}).Where("deduction_type_id = ?", id).Count(&n).Error
	return n > 0, err
}

// SaveType creates or updates a deduction type with its audit entry.
func (r *Repository) SaveType(ctx context.Context, t *DeductionType, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(t).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// DeleteType removes a deduction type that was never used.
func (r *Repository) DeleteType(ctx context.Context, t *DeductionType, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("deduction_type_id = ?", t.ID).Delete(&MemberDeduction{}).Error; err != nil {
			return err
		}
		if err := tx.Delete(t).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// --- per-farmer settings ---

// MemberDeductions returns a farmer's own settings for deduction types.
func (r *Repository) MemberDeductions(ctx context.Context, memberID string) ([]MemberDeduction, error) {
	var out []MemberDeduction
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("member_id = ?", memberID).Find(&out).Error
	return out, err
}

// SaveMemberDeduction creates or updates a farmer's setting for one deduction type.
func (r *Repository) SaveMemberDeduction(ctx context.Context, md *MemberDeduction, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(md).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// FindMemberDeduction loads a farmer's setting for a deduction type, or nil.
func (r *Repository) FindMemberDeduction(ctx context.Context, memberID, typeID string) (*MemberDeduction, error) {
	var md MemberDeduction
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).
		Where("member_id = ? AND deduction_type_id = ?", memberID, typeID).First(&md).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &md, err
}

// --- farmers ---

// Farmer is what the payout module needs to know about a member.
type Farmer struct {
	ID                string
	MembershipNumber  string
	FirstName         string
	LastName          string
	Phone             string
	MpesaNumber       *string
	BankName          *string
	BankAccountNumber *string
}

// Name is the farmer's full name.
func (f Farmer) Name() string { return f.FirstName + " " + f.LastName }

const farmerColumns = "id, membership_number, first_name, last_name, phone, mpesa_number, bank_name, bank_account_number"

// FindFarmer loads a farmer of the caller's Sacco.
func (r *Repository) FindFarmer(ctx context.Context, id string) (*Farmer, error) {
	var f Farmer
	err := r.db.WithContext(ctx).Table("members").Select(farmerColumns).
		Scopes(query.TenantScope(ctx)).Where("id = ? AND deleted_at IS NULL", id).Take(&f).Error
	if err != nil {
		return nil, notFound(err, "farmer")
	}
	return &f, nil
}

// Farmers loads farmers by id, removed ones included: a farmer removed after
// delivering milk is still owed for it.
func (r *Repository) Farmers(ctx context.Context, saccoID string, ids []string) (map[string]Farmer, error) {
	out := map[string]Farmer{}
	for start := 0; start < len(ids); start += 500 {
		end := min(start+500, len(ids))
		var rows []Farmer
		err := r.db.WithContext(ctx).Table("members").Select(farmerColumns).
			Where("sacco_id = ? AND id IN ?", saccoID, ids[start:end]).Find(&rows).Error
		if err != nil {
			return nil, err
		}
		for _, f := range rows {
			out[f.ID] = f
		}
	}
	return out, nil
}

// --- account entries ---

// AddTransaction writes one account entry with its audit entry.
func (r *Repository) AddTransaction(ctx context.Context, t *Transaction, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(t).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// FindTransaction loads an account entry of the caller's Sacco.
func (r *Repository) FindTransaction(ctx context.Context, id string) (*Transaction, error) {
	var t Transaction
	if err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&t).Error; err != nil {
		return nil, notFound(err, "entry")
	}
	return &t, nil
}

// VoidTransaction cancels an entry that no pay run has settled.
func (r *Repository) VoidTransaction(ctx context.Context, t *Transaction, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		res := tx.Model(&Transaction{}).Where("id = ? AND voided_at IS NULL AND pay_run_id IS NULL", t.ID).
			Updates(map[string]any{"voided_at": t.VoidedAt, "void_reason": t.VoidReason, "updated_at": time.Now()})
		if res.Error != nil {
			return res.Error
		}
		if res.RowsAffected == 0 {
			return fmt.Errorf("%w: this entry was settled by a pay run or voided already", ErrLocked)
		}
		return audit.Record(tx, entry)
	})
}

// OpenAdvances is the total of a farmer's advances not yet recovered by a pay run.
func (r *Repository) OpenAdvances(ctx context.Context, saccoID, memberID string) (float64, error) {
	var total float64
	err := r.db.WithContext(ctx).Model(&Transaction{}).Select("COALESCE(SUM(-amount), 0)").
		Where("sacco_id = ? AND member_id = ? AND kind = ? AND pay_run_id IS NULL AND voided_at IS NULL", saccoID, memberID, KindAdvance).
		Scan(&total).Error
	return total, err
}

// MilkValue is a farmer's milk value over a period (non-rejected collections).
func (r *Repository) MilkValue(ctx context.Context, saccoID, memberID string, from, to time.Time) (litres, gross float64, err error) {
	var row struct{ Litres, Gross float64 }
	err = r.db.WithContext(ctx).Table("milk_collections").
		Select("COALESCE(SUM(quantity_litres), 0) AS litres, COALESCE(SUM(total_amount), 0) AS gross").
		Where("sacco_id = ? AND member_id = ? AND deleted_at IS NULL AND status <> 'REJECTED' AND collection_date BETWEEN ? AND ?",
			saccoID, memberID, from.Format(dateLayout), to.Format(dateLayout)).
		Scan(&row).Error
	return row.Litres, row.Gross, err
}

// Balance is a farmer's account balance before a day, and their share
// balance (savings deductions) to date.
func (r *Repository) Balance(ctx context.Context, saccoID, memberID string, before *time.Time) (balance, shares float64, err error) {
	var row struct{ Balance, Shares float64 }
	q := r.db.WithContext(ctx).Model(&Transaction{}).
		Select("COALESCE(SUM(amount), 0) AS balance, COALESCE(SUM(CASE WHEN is_savings THEN -amount ELSE 0 END), 0) AS shares").
		Where("sacco_id = ? AND member_id = ? AND voided_at IS NULL", saccoID, memberID)
	if before != nil {
		q = q.Where("entry_date < ?", before.Format(dateLayout))
	}
	err = q.Scan(&row).Error
	return row.Balance, row.Shares, err
}

// Transactions lists a farmer's entries over a period, voided ones included,
// oldest first.
func (r *Repository) Transactions(ctx context.Context, saccoID, memberID string, from, to time.Time) ([]Transaction, error) {
	var out []Transaction
	err := r.db.WithContext(ctx).
		Where("sacco_id = ? AND member_id = ? AND entry_date BETWEEN ? AND ?", saccoID, memberID, from.Format(dateLayout), to.Format(dateLayout)).
		Order("entry_date, created_at").Find(&out).Error
	return out, err
}

// EntryRow is an account entry with its farmer, for lists across farmers.
type EntryRow struct {
	Transaction
	MembershipNumber string `json:"membership_number"`
	FarmerName       string `json:"farmer_name"`
}

// ListEntries lists advances, charges or adjustments across farmers.
func (r *Repository) ListEntries(ctx context.Context, saccoID string, kind Kind, from, to time.Time, openOnly bool) ([]EntryRow, error) {
	var out []EntryRow
	q := r.db.WithContext(ctx).Table("member_transactions t").
		Select("t.*, m.membership_number, m.first_name || ' ' || m.last_name AS farmer_name").
		Joins("JOIN members m ON m.id = t.member_id").
		Where("t.sacco_id = ? AND t.kind = ? AND t.entry_date BETWEEN ? AND ?", saccoID, kind, from.Format(dateLayout), to.Format(dateLayout))
	if openOnly {
		q = q.Where("t.pay_run_id IS NULL AND t.voided_at IS NULL")
	}
	err := q.Order("t.entry_date DESC, t.created_at DESC").Limit(500).Scan(&out).Error
	return out, err
}

// --- pay run inputs (one grouped query each, whatever the number of farmers) ---

type milkRow struct {
	MemberID string
	Litres   float64
	Gross    float64
}

// milkByFarmer sums each farmer's non-rejected milk in a period.
func (r *Repository) milkByFarmer(ctx context.Context, saccoID string, from, to time.Time) ([]milkRow, error) {
	var rows []milkRow
	err := r.db.WithContext(ctx).Table("milk_collections").
		Select("member_id, SUM(quantity_litres) AS litres, SUM(total_amount) AS gross").
		Where("sacco_id = ? AND deleted_at IS NULL AND status <> 'REJECTED' AND collection_date BETWEEN ? AND ?",
			saccoID, from.Format(dateLayout), to.Format(dateLayout)).
		Group("member_id").Scan(&rows).Error
	return rows, err
}

type sumRow struct {
	MemberID string
	Total    float64
}

// settledBalances is each farmer's balance from approved pay runs (arrears).
func (r *Repository) settledBalances(ctx context.Context, saccoID string) ([]sumRow, error) {
	var rows []sumRow
	err := r.db.WithContext(ctx).Model(&Transaction{}).Select("member_id, SUM(amount) AS total").
		Where("sacco_id = ? AND voided_at IS NULL AND pay_run_id IS NOT NULL", saccoID).
		Group("member_id").Having("SUM(amount) <> 0").Scan(&rows).Error
	return rows, err
}

// openEntries is each farmer's advances, charges and adjustments waiting for
// a pay run, recorded up to cutoff.
func (r *Repository) openEntries(ctx context.Context, saccoID string, cutoff time.Time) ([]sumRow, error) {
	var rows []sumRow
	err := r.db.WithContext(ctx).Model(&Transaction{}).Select("member_id, SUM(amount) AS total").
		Where("sacco_id = ? AND voided_at IS NULL AND pay_run_id IS NULL AND kind IN ? AND created_at <= ?", saccoID,
			[]Kind{KindAdvance, KindCharge, KindAdjustment}, cutoff).
		Group("member_id").Scan(&rows).Error
	return rows, err
}

type takenRow struct {
	MemberID        string
	DeductionTypeID string
	Total           float64
	LastDate        string
}

// takenSoFar is how much each farmer paid towards each deduction type, and when last.
func (r *Repository) takenSoFar(ctx context.Context, saccoID string) ([]takenRow, error) {
	var rows []takenRow
	err := r.db.WithContext(ctx).Model(&Transaction{}).
		Select("member_id, deduction_type_id, SUM(-amount) AS total, MAX(entry_date) AS last_date").
		Where("sacco_id = ? AND voided_at IS NULL AND kind = ? AND deduction_type_id IS NOT NULL", saccoID, KindDeduction).
		Group("member_id, deduction_type_id").Scan(&rows).Error
	return rows, err
}

// --- pay runs ---

// LatestRun is the Sacco's most recent run that is not cancelled, or nil.
func (r *Repository) LatestRun(ctx context.Context, saccoID string) (*PayRun, error) {
	var run PayRun
	err := r.db.WithContext(ctx).Where("sacco_id = ? AND status <> ?", saccoID, RunCancelled).
		Order("to_date DESC, created_at DESC").First(&run).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &run, err
}

// FindRun loads a pay run of the caller's Sacco.
func (r *Repository) FindRun(ctx context.Context, id string) (*PayRun, error) {
	var run PayRun
	if err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&run).Error; err != nil {
		return nil, notFound(err, "pay run")
	}
	return &run, nil
}

// ListRuns lists the Sacco's pay runs, newest first.
func (r *Repository) ListRuns(ctx context.Context, saccoID string, limit int) ([]PayRun, error) {
	var out []PayRun
	err := r.db.WithContext(ctx).Where("sacco_id = ?", saccoID).
		Order("to_date DESC, created_at DESC").Limit(limit).Find(&out).Error
	return out, err
}

// Lines lists a run's lines, with their deductions, by membership number.
// search matches name, number or phone.
func (r *Repository) Lines(ctx context.Context, runID, search string, unpaidOnly bool) ([]PayRunLine, error) {
	var out []PayRunLine
	q := r.db.WithContext(ctx).Preload("Items").Where("pay_run_id = ?", runID)
	if search != "" {
		like := "%" + search + "%"
		q = q.Where("LOWER(farmer_name) LIKE LOWER(?) OR membership_number LIKE ? OR phone LIKE ?", like, like, like)
	}
	if unpaidOnly {
		q = q.Where("paid_at IS NULL AND net > 0")
	}
	err := q.Order("membership_number, farmer_name").Find(&out).Error
	return out, err
}

// FindLine loads one line of a run.
func (r *Repository) FindLine(ctx context.Context, runID, lineID string) (*PayRunLine, error) {
	var l PayRunLine
	err := r.db.WithContext(ctx).Preload("Items").Where("pay_run_id = ? AND id = ?", runID, lineID).First(&l).Error
	if err != nil {
		return nil, notFound(err, "farmer's pay")
	}
	return &l, nil
}

// LineForMember loads a farmer's line in a run.
func (r *Repository) LineForMember(ctx context.Context, runID, memberID string) (*PayRunLine, error) {
	var l PayRunLine
	err := r.db.WithContext(ctx).Preload("Items").Where("pay_run_id = ? AND member_id = ?", runID, memberID).First(&l).Error
	if err != nil {
		return nil, notFound(err, "farmer's pay")
	}
	return &l, nil
}

// Transaction runs fn with a repository bound to one database transaction,
// for the steps of working out, approving, paying and cancelling a run.
func (r *Repository) Transaction(ctx context.Context, fn func(tx *Repository) error) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		return fn(&Repository{db: tx})
	})
}

// allMemberDeductions is every farmer's own deduction settings in a Sacco.
func (r *Repository) allMemberDeductions(ctx context.Context, saccoID string) ([]MemberDeduction, error) {
	var out []MemberDeduction
	err := r.db.WithContext(ctx).Where("sacco_id = ?", saccoID).Find(&out).Error
	return out, err
}

// activeTypes is the Sacco's switched-on deduction types.
func (r *Repository) activeTypes(ctx context.Context, saccoID string) ([]DeductionType, error) {
	var out []DeductionType
	err := r.db.WithContext(ctx).Where("sacco_id = ? AND is_active = ?", saccoID, true).
		Order("priority, name").Find(&out).Error
	return out, err
}

// CreateRun saves a new run.
func (r *Repository) CreateRun(ctx context.Context, run *PayRun) error {
	return r.db.WithContext(ctx).Create(run).Error
}

// SaveRun saves a run's totals and status.
func (r *Repository) SaveRun(ctx context.Context, run *PayRun) error {
	return r.db.WithContext(ctx).Save(run).Error
}

// MoveRun changes a run's status only if it is still in the expected one,
// so two people approving or cancelling at once cannot both succeed.
func (r *Repository) MoveRun(ctx context.Context, id string, from, to RunStatus, fields map[string]any) error {
	updates := map[string]any{"status": to, "updated_at": time.Now()}
	for k, v := range fields {
		updates[k] = v
	}
	res := r.db.WithContext(ctx).Model(&PayRun{}).Where("id = ? AND status = ?", id, from).Updates(updates)
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return fmt.Errorf("%w: the pay run changed meanwhile; reload it", ErrConflict)
	}
	return nil
}

// ReplaceLines deletes a run's lines and saves new ones with their items.
func (r *Repository) ReplaceLines(ctx context.Context, runID string, lines []PayRunLine) error {
	db := r.db.WithContext(ctx)
	if err := db.Where("line_id IN (?)", db.Model(&PayRunLine{}).Select("id").Where("pay_run_id = ?", runID)).
		Delete(&LineItem{}).Error; err != nil {
		return err
	}
	if err := db.Where("pay_run_id = ?", runID).Delete(&PayRunLine{}).Error; err != nil {
		return err
	}
	if len(lines) == 0 {
		return nil
	}
	return db.CreateInBatches(lines, 200).Error
}

// DeleteRun removes a draft run and its lines.
func (r *Repository) DeleteRun(ctx context.Context, runID string) error {
	if err := r.ReplaceLines(ctx, runID, nil); err != nil {
		return err
	}
	return r.db.WithContext(ctx).Delete(&PayRun{}, "id = ?", runID).Error
}

// PostEntries writes a run's account entries and marks the advances,
// charges and adjustments it recovered (those recorded up to cutoff, as
// when it was worked out) as settled by it.
func (r *Repository) PostEntries(ctx context.Context, saccoID, runID string, cutoff time.Time, entries []Transaction) error {
	db := r.db.WithContext(ctx)
	if err := db.Model(&Transaction{}).
		Where("sacco_id = ? AND pay_run_id IS NULL AND voided_at IS NULL AND kind IN ? AND created_at <= ?", saccoID,
			[]Kind{KindAdvance, KindCharge, KindAdjustment}, cutoff).
		Updates(map[string]any{"pay_run_id": runID, "updated_at": time.Now()}).Error; err != nil {
		return err
	}
	if len(entries) == 0 {
		return nil
	}
	return db.CreateInBatches(entries, 200).Error
}

// UnpostEntries undoes PostEntries for a cancelled run.
func (r *Repository) UnpostEntries(ctx context.Context, runID string) error {
	db := r.db.WithContext(ctx)
	if err := db.Where("pay_run_id = ? AND kind IN ?", runID, []Kind{KindMilk, KindDeduction, KindPayout}).
		Delete(&Transaction{}).Error; err != nil {
		return err
	}
	return db.Model(&Transaction{}).Where("pay_run_id = ?", runID).
		Updates(map[string]any{"pay_run_id": nil, "updated_at": time.Now()}).Error
}

// SetClosedThrough moves the date up to which milk records are locked.
func (r *Repository) SetClosedThrough(ctx context.Context, saccoID string, day *time.Time) error {
	var v any
	if day != nil {
		v = day.Format(dateLayout)
	}
	return r.db.WithContext(ctx).Table("sacco_settings").Where("sacco_id = ?", saccoID).
		Updates(map[string]any{"payroll_closed_through": v, "updated_at": time.Now()}).Error
}

// MarkLinePaid records how a farmer was paid, once, and notes it on their
// net-pay account entry.
func (r *Repository) MarkLinePaid(ctx context.Context, l *PayRunLine) error {
	db := r.db.WithContext(ctx)
	res := db.Model(&PayRunLine{}).Where("id = ? AND paid_at IS NULL", l.ID).Updates(map[string]any{
		"paid_at": l.PaidAt, "paid_method": l.PaidMethod, "paid_reference": l.PaidReference,
		"paid_by_id": l.PaidByID, "updated_at": time.Now(),
	})
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return fmt.Errorf("%w: %s is already marked paid", ErrConflict, l.FarmerName)
	}
	return db.Model(&Transaction{}).Where("pay_run_id = ? AND member_id = ? AND kind = ?", l.PayRunID, l.MemberID, KindPayout).
		Updates(map[string]any{"method": l.PaidMethod, "reference": l.PaidReference, "updated_at": time.Now()}).Error
}

// PaidTotals counts a run's paid lines.
func (r *Repository) PaidTotals(ctx context.Context, runID string) (count int, total float64, unpaid int, err error) {
	var row struct {
		Count  int
		Total  float64
		Unpaid int
	}
	err = r.db.WithContext(ctx).Model(&PayRunLine{}).
		Select("COUNT(CASE WHEN paid_at IS NOT NULL THEN 1 END) AS count, COALESCE(SUM(CASE WHEN paid_at IS NOT NULL THEN net ELSE 0 END), 0) AS total, COUNT(CASE WHEN paid_at IS NULL AND net > 0 THEN 1 END) AS unpaid").
		Where("pay_run_id = ?", runID).Scan(&row).Error
	return row.Count, row.Total, row.Unpaid, err
}

// RecordAudit writes an audit entry in this repository's transaction.
func (r *Repository) RecordAudit(ctx context.Context, e audit.Entry) error {
	return audit.Record(r.db.WithContext(ctx), e)
}
