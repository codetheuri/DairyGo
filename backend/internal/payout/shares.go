package payout

import (
	"context"
	"database/sql"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// A farmer's shares are what savings deductions took from their pay, plus
// shares moved outside pay runs (share_entries):
//
//   - OPENING: shares the farmer held before DairyGo (typed in, or imported
//     from a spreadsheet in the console).
//   - REFUND: shares paid back, from one of the Sacco's accounts, to a
//     member who leaves.
//   - TRANSFER_OUT / TRANSFER_IN: shares moved from one member to another
//     (a member who leaves passes them to a relative); the two sides share a
//     transfer_id and are voided together.
//
// Shares are kept per savings deduction (Shares, Savings…), since each can
// post to its own account in the books; entries with no deduction belong to
// a Sacco that has no savings deduction yet.

// Share entry kinds.
const (
	ShareOpening     = "OPENING"
	ShareRefund      = "REFUND"
	ShareTransferIn  = "TRANSFER_IN"
	ShareTransferOut = "TRANSFER_OUT"
)

const auditShareEntry = "share_entry"

// ShareEntry is shares moved outside a pay run. Amount is signed: positive
// adds to the member's shares.
type ShareEntry struct {
	ID              string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID         string     `json:"sacco_id" gorm:"type:varchar(36);not null"`
	MemberID        string     `json:"member_id" gorm:"type:varchar(36);not null"`
	DeductionTypeID *string    `json:"deduction_type_id,omitempty" gorm:"type:varchar(36)"`
	Kind            string     `json:"kind" doc:"OPENING, REFUND, TRANSFER_IN or TRANSFER_OUT"`
	EntryDate       time.Time  `json:"entry_date" gorm:"type:date"`
	Amount          float64    `json:"amount" doc:"Positive adds to the member's shares"`
	CashAccountID   *string    `json:"cash_account_id,omitempty" gorm:"type:varchar(36)"`
	Reference       *string    `json:"reference,omitempty"`
	Notes           *string    `json:"notes,omitempty"`
	TransferID      *string    `json:"transfer_id,omitempty" gorm:"type:varchar(36)"`
	OtherMemberID   *string    `json:"other_member_id,omitempty" gorm:"type:varchar(36)"`
	RecordedByID    *uint      `json:"recorded_by_id,omitempty"`
	VoidedAt        *time.Time `json:"voided_at,omitempty"`
	VoidReason      *string    `json:"void_reason,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

// TableName sets the database table name.
func (ShareEntry) TableName() string { return "share_entries" }

// ShareLine is one line of a farmer's shares: a savings deduction from a
// pay run, or a share entry.
type ShareLine struct {
	ID          string     `json:"id"`
	Date        time.Time  `json:"date"`
	Kind        string     `json:"kind" doc:"DEDUCTION (from a pay run), OPENING, REFUND, TRANSFER_IN or TRANSFER_OUT"`
	Savings     string     `json:"savings" doc:"The savings deduction"`
	Description string     `json:"description"`
	Amount      float64    `json:"amount" doc:"Positive adds to the shares"`
	Reference   *string    `json:"reference,omitempty"`
	VoidedAt    *time.Time `json:"voided_at,omitempty"`
	VoidReason  *string    `json:"void_reason,omitempty"`
	CreatedAt   time.Time  `json:"-"`
}

// ShareBucket is a farmer's shares in one savings deduction.
type ShareBucket struct {
	DeductionTypeID *string `json:"deduction_type_id,omitempty"`
	Name            string  `json:"name"`
	Balance         float64 `json:"balance"`
}

// Shares is a farmer's shares: the balance, by savings deduction, and every
// line, newest first.
type Shares struct {
	MemberID string        `json:"member_id"`
	Balance  float64       `json:"balance"`
	Buckets  []ShareBucket `json:"by_savings"`
	Lines    []ShareLine   `json:"lines"`
}

// --- repository ---

// ShareEntriesTotal is a member's shares moved outside pay runs.
func (r *Repository) ShareEntriesTotal(ctx context.Context, db *gorm.DB, saccoID, memberID string) (float64, error) {
	var v sql.NullFloat64
	err := db.WithContext(ctx).Raw(`SELECT SUM(amount) FROM share_entries WHERE sacco_id = ? AND member_id = ? AND voided_at IS NULL`,
		saccoID, memberID).Scan(&v).Error
	return v.Float64, err
}

// shareBuckets is a member's shares by savings deduction, read in db.
func shareBuckets(ctx context.Context, db *gorm.DB, saccoID, memberID string) ([]ShareBucket, error) {
	var rows []struct {
		TypeID  string
		Name    *string
		Balance float64
	}
	err := db.WithContext(ctx).Raw(`SELECT x.type_id, MAX(t.name) AS name, SUM(x.amount) AS balance FROM (
			SELECT COALESCE(deduction_type_id, '') AS type_id, -amount AS amount FROM member_transactions
			 WHERE sacco_id = @s AND member_id = @m AND voided_at IS NULL AND kind = 'DEDUCTION' AND is_savings
			UNION ALL
			SELECT COALESCE(deduction_type_id, ''), amount FROM share_entries
			 WHERE sacco_id = @s AND member_id = @m AND voided_at IS NULL) x
		LEFT JOIN deduction_types t ON t.id = x.type_id
		GROUP BY x.type_id ORDER BY MAX(COALESCE(t.priority, 0)), 2`, sql.Named("s", saccoID), sql.Named("m", memberID)).
		Scan(&rows).Error
	out := make([]ShareBucket, 0, len(rows))
	for _, row := range rows {
		b := ShareBucket{Name: "Shares", Balance: round2(row.Balance)}
		if row.TypeID != "" {
			id := row.TypeID
			b.DeductionTypeID = &id
		}
		if row.Name != nil {
			b.Name = *row.Name
		}
		out = append(out, b)
	}
	return out, err
}

// savingsTypes are the Sacco's savings deductions (switched off ones too).
func savingsTypes(ctx context.Context, db *gorm.DB, saccoID string) ([]DeductionType, error) {
	var out []DeductionType
	err := db.WithContext(ctx).Where("sacco_id = ? AND goes_to = ?", saccoID, GoesSavings).Order("priority, name").Find(&out).Error
	return out, err
}

// --- service ---

// Shares is a farmer's shares with every line.
func (s *Service) Shares(ctx context.Context, memberID string) (*Shares, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	if _, err := s.repo.FindFarmer(ctx, memberID); err != nil {
		return nil, err
	}
	db := s.repo.db.WithContext(ctx)
	out := &Shares{MemberID: memberID, Lines: []ShareLine{}}
	if out.Buckets, err = shareBuckets(ctx, db, saccoID, memberID); err != nil {
		return nil, err
	}
	for _, b := range out.Buckets {
		out.Balance += b.Balance
	}
	out.Balance = round2(out.Balance)

	var taken []ShareLine
	if err := db.Raw(`SELECT m.id, m.entry_date AS date, 'DEDUCTION' AS kind, COALESCE(t.name, m.description) AS savings,
			m.description, -m.amount AS amount, m.reference, m.voided_at, m.void_reason, m.created_at
		FROM member_transactions m LEFT JOIN deduction_types t ON t.id = m.deduction_type_id
		WHERE m.sacco_id = ? AND m.member_id = ? AND m.kind = 'DEDUCTION' AND m.is_savings`, saccoID, memberID).
		Scan(&taken).Error; err != nil {
		return nil, err
	}
	var moved []struct {
		ShareEntry
		Savings     *string
		AccountName *string
		OtherName   *string
	}
	if err := db.Raw(`SELECT e.*, t.name AS savings, a.name AS account_name, o.first_name || ' ' || o.last_name AS other_name
		FROM share_entries e
		LEFT JOIN deduction_types t ON t.id = e.deduction_type_id
		LEFT JOIN cash_accounts a ON a.id = e.cash_account_id
		LEFT JOIN members o ON o.id = e.other_member_id
		WHERE e.sacco_id = ? AND e.member_id = ?`, saccoID, memberID).Scan(&moved).Error; err != nil {
		return nil, err
	}
	out.Lines = append(out.Lines, taken...)
	for _, m := range moved {
		l := ShareLine{ID: m.ID, Date: m.EntryDate, Kind: m.Kind, Savings: "Shares", Amount: m.Amount, Reference: m.Reference,
			VoidedAt: m.VoidedAt, VoidReason: m.VoidReason, CreatedAt: m.CreatedAt}
		if m.Savings != nil {
			l.Savings = *m.Savings
		}
		other := ""
		if m.OtherName != nil {
			other = *m.OtherName
		}
		switch m.Kind {
		case ShareOpening:
			l.Description = "Shares held before DairyGo"
		case ShareRefund:
			l.Description = "Refunded"
			if m.AccountName != nil {
				l.Description += " from " + *m.AccountName
			}
		case ShareTransferIn:
			l.Description = "From " + other
		case ShareTransferOut:
			l.Description = "To " + other
		}
		if m.Notes != nil {
			l.Description += ": " + *m.Notes
		}
		out.Lines = append(out.Lines, l)
	}
	sort.SliceStable(out.Lines, func(i, k int) bool {
		a, b := out.Lines[i], out.Lines[k]
		if !a.Date.Equal(b.Date) {
			return a.Date.After(b.Date)
		}
		return a.CreatedAt.After(b.CreatedAt)
	})
	return out, nil
}

// ShareRequest records opening shares, a refund or a transfer.
type ShareRequest struct {
	Amount          float64 `json:"amount" doc:"KES"`
	Date            string  `json:"date,omitempty" doc:"YYYY-MM-DD (default today)"`
	DeductionTypeID string  `json:"deduction_type_id,omitempty" doc:"The savings deduction (needed only when there is more than one)"`
	CashAccountID   string  `json:"cash_account_id,omitempty" doc:"A refund: the account the money came from"`
	ToMemberID      string  `json:"to_member_id,omitempty" doc:"A transfer: the member who receives the shares"`
	Reference       string  `json:"reference,omitempty" maxLength:"100"`
	Notes           string  `json:"notes,omitempty" maxLength:"500"`
}

// OpeningShares records shares a farmer held before DairyGo.
func (s *Service) OpeningShares(ctx context.Context, memberID string, req *ShareRequest) (*ShareEntry, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	f, err := s.repo.FindFarmer(ctx, memberID)
	if err != nil {
		return nil, err
	}
	day, err := s.shareDay(req)
	if err != nil {
		return nil, err
	}
	var e *ShareEntry
	err = s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		typeID, err := openingType(ctx, tx, saccoID, req.DeductionTypeID)
		if err != nil {
			return err
		}
		e = &ShareEntry{ID: uuid.New().String(), SaccoID: saccoID, MemberID: f.ID, DeductionTypeID: typeID, Kind: ShareOpening,
			EntryDate: day, Amount: round2(req.Amount), Reference: trimOrNil(req.Reference), Notes: trimOrNil(req.Notes),
			RecordedByID: actorPtr(ctx)}
		return saveShareEntries(ctx, tx, nil, e)
	})
	return e, err
}

// openingType is the savings deduction opening shares count towards: the
// one asked for, or the Sacco's only one (none when it has none).
func openingType(ctx context.Context, tx *gorm.DB, saccoID, asked string) (*string, error) {
	types, err := savingsTypes(ctx, tx, saccoID)
	if err != nil {
		return nil, err
	}
	if asked = strings.TrimSpace(asked); asked != "" {
		for _, t := range types {
			if t.ID == asked || strings.EqualFold(t.Name, asked) {
				return &t.ID, nil
			}
		}
		return nil, fmt.Errorf("%w: choose one of the Sacco's savings deductions", ErrInvalid)
	}
	switch len(types) {
	case 0:
		return nil, nil
	case 1:
		return &types[0].ID, nil
	}
	names := make([]string, len(types))
	for i, t := range types {
		names[i] = t.Name
	}
	return nil, fmt.Errorf("%w: choose which savings these are (%s)", ErrInvalid, strings.Join(names, ", "))
}

// RefundShares pays a member's shares back from one of the Sacco's
// accounts, all or part.
func (s *Service) RefundShares(ctx context.Context, memberID string, req *ShareRequest) (*ShareEntry, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	f, err := s.repo.FindFarmer(ctx, memberID)
	if err != nil {
		return nil, err
	}
	day, err := s.shareDay(req)
	if err != nil {
		return nil, err
	}
	var acc struct {
		Name        string
		IsActive    bool
		OpeningDate time.Time
	}
	res := s.repo.db.WithContext(ctx).Table("cash_accounts").Select("name, is_active, opening_date").
		Where("sacco_id = ? AND id = ?", saccoID, req.CashAccountID).Scan(&acc)
	if res.Error != nil {
		return nil, res.Error
	}
	if res.RowsAffected == 0 || !acc.IsActive {
		return nil, fmt.Errorf("%w: choose the account the money came from", ErrInvalid)
	}
	if day.Before(acc.OpeningDate) {
		return nil, fmt.Errorf("%w: %s was opened on %s; the refund cannot be earlier", ErrInvalid, acc.Name, acc.OpeningDate.Format("2 Jan 2006"))
	}
	var e *ShareEntry
	err = s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		b, err := takeFrom(ctx, tx, saccoID, f, req)
		if err != nil {
			return err
		}
		account := req.CashAccountID
		e = &ShareEntry{ID: uuid.New().String(), SaccoID: saccoID, MemberID: f.ID, DeductionTypeID: b.DeductionTypeID, Kind: ShareRefund,
			EntryDate: day, Amount: -round2(req.Amount), CashAccountID: &account, Reference: trimOrNil(req.Reference),
			Notes: trimOrNil(req.Notes), RecordedByID: actorPtr(ctx)}
		return saveShareEntries(ctx, tx, nil, e)
	})
	return e, err
}

// TransferShares moves shares from one member to another.
func (s *Service) TransferShares(ctx context.Context, memberID string, req *ShareRequest) ([]ShareEntry, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	from, err := s.repo.FindFarmer(ctx, memberID)
	if err != nil {
		return nil, err
	}
	if req.ToMemberID == memberID {
		return nil, fmt.Errorf("%w: choose another member to receive the shares", ErrInvalid)
	}
	to, err := s.repo.FindFarmer(ctx, req.ToMemberID)
	if err != nil {
		return nil, fmt.Errorf("%w: choose the member who receives the shares", ErrInvalid)
	}
	day, err := s.shareDay(req)
	if err != nil {
		return nil, err
	}
	var out []ShareEntry
	err = s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		b, err := takeFrom(ctx, tx, saccoID, from, req)
		if err != nil {
			return err
		}
		transfer := uuid.New().String()
		amount := round2(req.Amount)
		mk := func(member, other *Farmer, kind string, amount float64) *ShareEntry {
			return &ShareEntry{ID: uuid.New().String(), SaccoID: saccoID, MemberID: member.ID, DeductionTypeID: b.DeductionTypeID,
				Kind: kind, EntryDate: day, Amount: amount, Reference: trimOrNil(req.Reference), Notes: trimOrNil(req.Notes),
				TransferID: &transfer, OtherMemberID: &other.ID, RecordedByID: actorPtr(ctx)}
		}
		outE, inE := mk(from, to, ShareTransferOut, -amount), mk(to, from, ShareTransferIn, amount)
		out = []ShareEntry{*outE, *inE}
		return saveShareEntries(ctx, tx, nil, outE, inE)
	})
	return out, err
}

// takeFrom checks a member has the shares a refund or transfer takes,
// holding the member's row until the transaction ends so two refunds never
// pay the same shares, and returns the savings they come from.
func takeFrom(ctx context.Context, tx *gorm.DB, saccoID string, f *Farmer, req *ShareRequest) (*ShareBucket, error) {
	var lock struct{ ID string }
	if err := tx.WithContext(ctx).Table("members").Clauses(clause.Locking{Strength: "UPDATE"}).Select("id").
		Where("id = ?", f.ID).Scan(&lock).Error; err != nil {
		return nil, err
	}
	buckets, err := shareBuckets(ctx, tx, saccoID, f.ID)
	if err != nil {
		return nil, err
	}
	var b *ShareBucket
	asked := strings.TrimSpace(req.DeductionTypeID)
	var held []ShareBucket
	for i := range buckets {
		if asked != "" && buckets[i].DeductionTypeID != nil && *buckets[i].DeductionTypeID == asked {
			b = &buckets[i]
		}
		if buckets[i].Balance > 0 {
			held = append(held, buckets[i])
		}
	}
	switch {
	case asked != "" && b == nil:
		return nil, fmt.Errorf("%w: %s has no shares in that savings", ErrInvalid, f.Name())
	case asked == "" && len(held) == 0:
		return nil, fmt.Errorf("%w: %s has no shares", ErrConflict, f.Name())
	case asked == "" && len(held) > 1:
		names := make([]string, len(held))
		for i, h := range held {
			names[i] = h.Name
		}
		return nil, fmt.Errorf("%w: choose which savings (%s)", ErrInvalid, strings.Join(names, ", "))
	case asked == "":
		b = &held[0]
	}
	if req.Amount > b.Balance+0.005 {
		return nil, fmt.Errorf("%w: %s has KES %.2f in %s", ErrInvalid, f.Name(), b.Balance, b.Name)
	}
	return b, nil
}

func (s *Service) shareDay(req *ShareRequest) (time.Time, error) {
	day, err := parseDay(req.Date, s.today())
	if err != nil {
		return day, err
	}
	if day.After(s.today()) {
		return day, fmt.Errorf("%w: the date cannot be in the future", ErrInvalid)
	}
	if req.Amount <= 0 {
		return day, fmt.Errorf("%w: the amount must be more than 0", ErrInvalid)
	}
	return day, nil
}

// saveShareEntries saves share entries with their history lines (reason set
// for a void) in tx.
func saveShareEntries(ctx context.Context, tx *gorm.DB, reason *string, entries ...*ShareEntry) error {
	return saveShareEntriesBy(tx, middleware.GetUserID(ctx), reason, entries...)
}

func saveShareEntriesBy(tx *gorm.DB, actor uint, reason *string, entries ...*ShareEntry) error {
	audits := make([]audit.Entry, 0, len(entries))
	for _, e := range entries {
		action := audit.ActionCreate
		if e.VoidedAt != nil {
			action = audit.ActionVoid
		}
		if err := tx.Save(e).Error; err != nil {
			return err
		}
		audits = append(audits, audit.Entry{SaccoID: e.SaccoID, EntityType: auditShareEntry, EntityID: e.ID, Action: action,
			ActorID: actor, NewValues: e, Reason: reason})
	}
	return audit.RecordAll(tx, audits)
}

// VoidShareEntry cancels a share entry recorded in error; both sides of a
// transfer go together. Refused when it would leave a member with fewer
// than no shares (shares since refunded or passed on).
func (s *Service) VoidShareEntry(ctx context.Context, id, reason string) ([]ShareEntry, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	reason = strings.TrimSpace(reason)
	if len(reason) < 3 {
		return nil, fmt.Errorf("%w: give the reason for voiding", ErrInvalid)
	}
	var out []ShareEntry
	err = s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var e ShareEntry
		if err := tx.Where("sacco_id = ? AND id = ?", saccoID, id).First(&e).Error; err != nil {
			return notFound(err, "share entry")
		}
		if e.VoidedAt != nil {
			return fmt.Errorf("%w: already voided", ErrConflict)
		}
		list := []ShareEntry{e}
		if e.TransferID != nil {
			if err := tx.Where("sacco_id = ? AND transfer_id = ? AND id <> ?", saccoID, *e.TransferID, e.ID).Find(&list).Error; err != nil {
				return err
			}
			list = append([]ShareEntry{e}, list...)
		}
		now := s.now()
		ptrs := make([]*ShareEntry, len(list))
		for i := range list {
			list[i].VoidedAt, list[i].VoidReason = &now, &reason
			ptrs[i] = &list[i]
		}
		if err := saveShareEntries(ctx, tx, &reason, ptrs...); err != nil {
			return err
		}
		for _, v := range list {
			if v.Amount <= 0 {
				continue
			}
			buckets, err := shareBuckets(ctx, tx, saccoID, v.MemberID)
			if err != nil {
				return err
			}
			for _, b := range buckets {
				if b.Balance < -0.005 {
					return fmt.Errorf("%w: these shares were refunded or passed on since; void that first", ErrConflict)
				}
			}
		}
		out = list
		return nil
	})
	return out, err
}

// --- import (console) ---

// ShareRow is one line of a spreadsheet of opening shares.
type ShareRow struct {
	Line             int
	MembershipNumber string
	Amount           float64
}

// ShareImport says what importing opening shares did (or would do).
type ShareImport struct {
	Added        int      `json:"added"`
	Total        float64  `json:"total"`
	Savings      string   `json:"savings" doc:"The savings deduction they count towards"`
	Unknown      []string `json:"unknown" doc:"Membership numbers not found"`
	AlreadyThere []string `json:"already_there" doc:"Farmers who already have opening shares (left alone)"`
}

// ImportOpeningShares records opening shares for many farmers at once, by
// membership number. Farmers who already have opening shares are left
// alone, so the same file can be run again. With preview nothing is saved.
func ImportOpeningShares(ctx context.Context, db *gorm.DB, saccoID string, rows []ShareRow, day time.Time, typeID string, actor *uint, preview bool) (*ShareImport, error) {
	out := &ShareImport{Unknown: []string{}, AlreadyThere: []string{}}
	err := db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		t, err := openingType(ctx, tx, saccoID, typeID)
		if err != nil {
			return err
		}
		out.Savings = "Shares"
		if t != nil {
			if err := tx.Table("deduction_types").Select("name").Where("id = ?", *t).Scan(&out.Savings).Error; err != nil {
				return err
			}
		}
		var members []struct{ ID, MembershipNumber string }
		if err := tx.Table("members").Select("id, membership_number").Where("sacco_id = ? AND deleted_at IS NULL", saccoID).
			Scan(&members).Error; err != nil {
			return err
		}
		byNumber := map[string]string{}
		for _, m := range members {
			byNumber[strings.ToUpper(strings.TrimSpace(m.MembershipNumber))] = m.ID
		}
		var have []string
		if err := tx.Table("share_entries").Where("sacco_id = ? AND kind = ? AND voided_at IS NULL", saccoID, ShareOpening).
			Distinct().Pluck("member_id", &have).Error; err != nil {
			return err
		}
		has := map[string]bool{}
		for _, id := range have {
			has[id] = true
		}
		var entries []*ShareEntry
		for _, r := range rows {
			id, ok := byNumber[strings.ToUpper(strings.TrimSpace(r.MembershipNumber))]
			switch {
			case !ok:
				out.Unknown = append(out.Unknown, r.MembershipNumber)
				continue
			case has[id]:
				out.AlreadyThere = append(out.AlreadyThere, r.MembershipNumber)
				continue
			}
			has[id] = true
			entries = append(entries, &ShareEntry{ID: uuid.New().String(), SaccoID: saccoID, MemberID: id, DeductionTypeID: t,
				Kind: ShareOpening, EntryDate: day, Amount: round2(r.Amount), Notes: strPtr("Imported"), RecordedByID: actor})
			out.Added++
			out.Total += r.Amount
		}
		out.Total = round2(out.Total)
		if preview || len(entries) == 0 {
			return nil
		}
		var by uint
		if actor != nil {
			by = *actor
		}
		return saveShareEntriesBy(tx, by, nil, entries...)
	})
	return out, err
}

func strPtr(s string) *string { return &s }
