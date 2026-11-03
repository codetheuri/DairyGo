package payout

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// One farmer registered twice. A collector records Janet under a wrong name
// ("Janet Kamunya") and later under the right one ("Janet Murage"), so her
// milk is split across two farmers. DairyGo support (the platform console)
// merges the wrong farmer into the right one, with a reason:
//
//   - milk not yet paid (dated after payroll_closed_through) moves, keeping
//     its date, litres and price;
//   - advances, charges and adjustments no pay run has taken yet move;
//   - whatever balance is left on the wrong farmer from paid months (a debt
//     carried forward, or pay still due) moves as a pair of adjustments, so
//     the books stay whole;
//   - the wrong farmer is made inactive, never removed: paid months stay as
//     they were paid, under that name.
//
// Every moved record gets a history line with the reason.

const auditEntityCollection = "milk_collection"

// MergeRequest merges a farmer registered twice into the right record.
type MergeRequest struct {
	FromMemberID string `json:"from_member_id" doc:"The farmer recorded under the wrong name; made inactive"`
	ToMemberID   string `json:"to_member_id" doc:"The right farmer, who keeps everything"`
	Reason       string `json:"reason" doc:"Why, kept in each moved record's history"`
	Preview      bool   `json:"preview,omitempty" doc:"Only say what would move; nothing is saved"`
}

// MergeResult says what moved (or would move, for a preview).
type MergeResult struct {
	From         string  `json:"from"`
	To           string  `json:"to"`
	MilkRecords  int     `json:"milk_records" doc:"Milk records not yet paid, moved to the right farmer"`
	Litres       float64 `json:"litres"`
	MilkValue    float64 `json:"milk_value"`
	Entries      int     `json:"entries" doc:"Advances, charges and adjustments not yet taken by a pay run"`
	EntriesTotal float64 `json:"entries_total" doc:"Their total (negative = the farmer owes)"`
	Balance      float64 `json:"balance_moved" doc:"Left on the wrong farmer from paid months, moved as adjustments"`
	PaidRecords  int     `json:"paid_records_left" doc:"Milk records in months already paid; they stay on the wrong farmer"`
	Shares       float64 `json:"shares_left" doc:"Shares saved on the wrong farmer; they stay there"`
	OwnPrice     bool    `json:"own_price_left" doc:"The wrong farmer had their own buying price; it is not moved"`
	OpenFrom     string  `json:"open_from,omitempty" doc:"First day not yet paid; milk from then moves"`
	Preview      bool    `json:"preview"`
}

// mergeFarmer is what the merge reads about each farmer.
type mergeFarmer struct {
	ID               string
	MembershipNumber string
	FirstName        string
	LastName         string
	Status           string
}

func (f mergeFarmer) label() string {
	return strings.TrimSpace(f.MembershipNumber + " " + f.FirstName + " " + f.LastName)
}

// checkMerge validates a merge request before anything is read.
func checkMerge(req *MergeRequest) (string, error) {
	why := strings.TrimSpace(req.Reason)
	switch {
	case req.FromMemberID == "" || req.ToMemberID == "":
		return "", fmt.Errorf("%w: choose the farmer recorded under the wrong name and the right farmer", ErrInvalid)
	case req.FromMemberID == req.ToMemberID:
		return "", fmt.Errorf("%w: choose two different farmers", ErrInvalid)
	case len(why) < 3:
		return "", fmt.Errorf("%w: say why the farmers are being merged (reason)", ErrInvalid)
	}
	return why, nil
}

// MergeFarmers merges a farmer registered twice into the right one.
// Platform operators only.
func (s *Service) MergeFarmers(ctx context.Context, req *MergeRequest) (*MergeResult, error) {
	if !middleware.IsSuperUser(ctx) {
		return nil, fmt.Errorf("%w: only DairyGo support can merge farmers", ErrForbidden)
	}
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	why, err := checkMerge(req)
	if err != nil {
		return nil, err
	}
	settings, err := s.repo.Settings(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	var closed *string
	res := &MergeResult{Preview: req.Preview}
	if c := settings.ClosedThrough; c != nil {
		d := c.Format(dateLayout)
		closed = &d
		res.OpenFrom = c.AddDate(0, 0, 1).Format(dateLayout)
	}
	actor := middleware.GetUserID(ctx)
	err = s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		from, to, err := mergeFarmers(tx, saccoID, req)
		if err != nil {
			return err
		}
		res.From, res.To = from.label(), to.label()
		if err := mergeCount(tx, saccoID, from.ID, closed, res); err != nil {
			return err
		}
		if req.Preview {
			return nil
		}
		change := fmt.Sprintf("Farmer %s → %s", res.From, res.To)
		return mergeApply(tx, saccoID, from, to, closed, why, change, actor, s.now(), s.today(), res)
	})
	if err != nil {
		return nil, err
	}
	return res, nil
}

// mergeFarmers loads both farmers, locked for the merge.
func mergeFarmers(tx *gorm.DB, saccoID string, req *MergeRequest) (from, to mergeFarmer, err error) {
	var rows []mergeFarmer
	err = tx.Table("members").Select("id, membership_number, first_name, last_name, status").
		Where("sacco_id = ? AND id IN ? AND deleted_at IS NULL", saccoID, []string{req.FromMemberID, req.ToMemberID}).
		Clauses(clause.Locking{Strength: "UPDATE"}).Find(&rows).Error
	if err != nil {
		return from, to, err
	}
	for _, r := range rows {
		if r.ID == req.FromMemberID {
			from = r
		} else {
			to = r
		}
	}
	switch {
	case from.ID == "":
		return from, to, fmt.Errorf("%w: the farmer recorded under the wrong name was not found in this Sacco", ErrNotFound)
	case to.ID == "":
		return from, to, fmt.Errorf("%w: the right farmer was not found in this Sacco", ErrNotFound)
	case to.Status != "ACTIVE":
		return from, to, fmt.Errorf("%w: %s is not active; activate them first", ErrInvalid, to.label())
	}
	return from, to, nil
}

// mergeCount fills in what would move from the wrong farmer.
func mergeCount(tx *gorm.DB, saccoID, fromID string, closed *string, res *MergeResult) error {
	var milk struct {
		Open, Paid    int
		Litres, Value float64
	}
	// Before the first pay run nothing is paid: every record is open.
	day := "1900-01-01"
	if closed != nil {
		day = *closed
	}
	err := tx.Table("milk_collections").Select(
		"COUNT(*) FILTER (WHERE collection_date > ?) AS open, "+
			"COUNT(*) FILTER (WHERE collection_date <= ?) AS paid, "+
			"COALESCE(SUM(quantity_litres) FILTER (WHERE collection_date > ? AND status <> 'REJECTED'), 0) AS litres, "+
			"COALESCE(SUM(total_amount) FILTER (WHERE collection_date > ? AND status <> 'REJECTED'), 0) AS value",
		day, day, day, day).
		Where("sacco_id = ? AND member_id = ? AND deleted_at IS NULL", saccoID, fromID).Scan(&milk).Error
	if err != nil {
		return err
	}
	res.MilkRecords, res.PaidRecords, res.Litres, res.MilkValue = milk.Open, milk.Paid, round2(milk.Litres), round2(milk.Value)

	var acct struct {
		Entries                int
		Open, Balance, Savings float64
	}
	err = tx.Table("member_transactions").Select(
		"COUNT(*) FILTER (WHERE pay_run_id IS NULL) AS entries, "+
			"COALESCE(SUM(amount) FILTER (WHERE pay_run_id IS NULL), 0) AS open, "+
			"COALESCE(SUM(amount), 0) AS balance, "+
			"COALESCE(SUM(CASE WHEN is_savings THEN -amount ELSE 0 END), 0) AS savings").
		Where("sacco_id = ? AND member_id = ? AND voided_at IS NULL", saccoID, fromID).Scan(&acct).Error
	if err != nil {
		return err
	}
	res.Entries, res.EntriesTotal = acct.Entries, round2(acct.Open)
	res.Balance, res.Shares = round2(acct.Balance-acct.Open), round2(acct.Savings)

	var prices int64
	err = tx.Table("member_prices").Where("member_id = ? AND is_active", fromID).Count(&prices).Error
	res.OwnPrice = prices > 0
	return err
}

// mergeApply moves the records, writes the balance adjustments and makes the
// wrong farmer inactive, each with a history line.
func mergeApply(tx *gorm.DB, saccoID string, from, to mergeFarmer, closed *string, why, change string,
	actor uint, now, today time.Time, res *MergeResult) error {
	var entries []audit.Entry
	note := func(entity, id string, oldV, newV any) {
		entries = append(entries, audit.Entry{SaccoID: saccoID, EntityType: entity, EntityID: id,
			Action: audit.ActionUpdate, ActorID: actor, Reason: &why, OldValues: oldV, NewValues: newV})
	}
	moved := map[string]any{"member_id": to.ID, "farmer": res.To, "change": change}
	was := map[string]any{"member_id": from.ID, "farmer": res.From}

	// Milk not yet paid.
	q := tx.Table("milk_collections").Where("sacco_id = ? AND member_id = ? AND deleted_at IS NULL", saccoID, from.ID)
	if closed != nil {
		q = q.Where("collection_date > ?", *closed)
	}
	var milkIDs []string
	if err := q.Pluck("id", &milkIDs).Error; err != nil {
		return err
	}
	if len(milkIDs) > 0 {
		if err := tx.Table("milk_collections").Where("id IN ?", milkIDs).
			Updates(map[string]any{"member_id": to.ID, "updated_at": now}).Error; err != nil {
			return err
		}
	}
	for _, id := range milkIDs {
		note(auditEntityCollection, id, was, moved)
	}

	// Advances, charges and adjustments not yet taken.
	var entryIDs []string
	if err := tx.Table("member_transactions").
		Where("sacco_id = ? AND member_id = ? AND pay_run_id IS NULL AND voided_at IS NULL", saccoID, from.ID).
		Pluck("id", &entryIDs).Error; err != nil {
		return err
	}
	if len(entryIDs) > 0 {
		if err := tx.Table("member_transactions").Where("id IN ?", entryIDs).
			Updates(map[string]any{"member_id": to.ID, "updated_at": now}).Error; err != nil {
			return err
		}
	}
	for _, id := range entryIDs {
		note(auditEntry, id, was, moved)
	}

	// The balance left from paid months follows the farmer.
	if res.Balance != 0 {
		desc := func(dir, who string) string { return fmt.Sprintf("Balance %s %s (same farmer): %s", dir, who, why) }
		for _, t := range []*Transaction{
			{MemberID: from.ID, Amount: -res.Balance, Description: desc("moved to", res.To)},
			{MemberID: to.ID, Amount: res.Balance, Description: desc("from", res.From)},
		} {
			t.ID, t.SaccoID, t.Kind, t.EntryDate = uuid.New().String(), saccoID, KindAdjustment, today
			if actor > 0 {
				a := actor
				t.RecordedByID = &a
			}
			if err := tx.Create(t).Error; err != nil {
				return err
			}
			entries = append(entries, audit.Entry{SaccoID: saccoID, EntityType: auditEntry, EntityID: t.ID,
				Action: audit.ActionCreate, ActorID: actor, Reason: &why, NewValues: t})
		}
	}

	// The wrong farmer stays, inactive, with the months already paid.
	if from.Status != "INACTIVE" {
		if err := tx.Table("members").Where("id = ?", from.ID).
			Updates(map[string]any{"status": "INACTIVE", "status_changed_at": now, "updated_at": now}).Error; err != nil {
			return err
		}
		entries = append(entries, audit.Entry{SaccoID: saccoID, EntityType: "member", EntityID: from.ID,
			Action: audit.ActionStatus, ActorID: actor, Reason: &why,
			OldValues: map[string]any{"status": from.Status},
			NewValues: map[string]any{"status": "INACTIVE", "merged_into": res.To}})
	}
	entries = append(entries, audit.Entry{SaccoID: saccoID, EntityType: "member", EntityID: to.ID,
		Action: audit.ActionUpdate, ActorID: actor, Reason: &why,
		NewValues: map[string]any{"merged_from": res.From, "milk_records": res.MilkRecords, "entries": res.Entries,
			"balance_moved": res.Balance}})
	for _, e := range entries {
		if err := audit.Record(tx, e); err != nil {
			return err
		}
	}
	return nil
}
