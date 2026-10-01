package payout

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// Domain errors, mapped to HTTP status codes by the handler.
var (
	ErrNotFound = errors.New("not found")
	ErrConflict = errors.New("conflict")
	ErrLocked   = errors.New("locked")
	ErrInvalid  = errors.New("invalid")
)

const (
	dateLayout      = "2006-01-02"
	auditDeduction  = "deduction_type"
	auditMemberRule = "member_deduction"
	auditEntry      = "member_transaction"
	auditPayRun     = "pay_run"
)

// Service holds the payout rules.
type Service struct {
	repo        *Repository
	letterheads Letterheads
	messenger   Messenger
	now         func() time.Time
}

// NewService creates a payout service. letterheads (for payslips and
// registers) and messenger (payslip SMS) may be nil.
func NewService(repo *Repository, letterheads Letterheads, messenger Messenger) *Service {
	return &Service{repo: repo, letterheads: letterheads, messenger: messenger, now: time.Now}
}

func (s *Service) saccoID(ctx context.Context) (string, error) {
	id, ok := middleware.GetSaccoID(ctx)
	if !ok || id == "" {
		return "", fmt.Errorf("%w: sacco context is required", ErrInvalid)
	}
	return id, nil
}

func (s *Service) today() time.Time {
	n := s.now().In(time.Local)
	return time.Date(n.Year(), n.Month(), n.Day(), 0, 0, 0, 0, time.UTC)
}

func actorPtr(ctx context.Context) *uint {
	if id := middleware.GetUserID(ctx); id > 0 {
		return &id
	}
	return nil
}

// parseDay reads a YYYY-MM-DD date, or returns def when empty.
func parseDay(v string, def time.Time) (time.Time, error) {
	if strings.TrimSpace(v) == "" {
		return def, nil
	}
	d, err := time.Parse(dateLayout, strings.TrimSpace(v))
	if err != nil {
		return time.Time{}, fmt.Errorf("%w: dates must look like 2026-10-31", ErrInvalid)
	}
	return d, nil
}

// --- deduction types ---

// ListTypes returns the Sacco's deduction types.
func (s *Service) ListTypes(ctx context.Context) ([]DeductionType, error) {
	return s.repo.ListTypes(ctx, false)
}

// validateType checks a deduction type is complete enough to be taken.
// Switched-off types may be left incomplete while being set up.
func validateType(t *DeductionType) error {
	t.Name = strings.TrimSpace(t.Name)
	if len(t.Name) < 2 {
		return fmt.Errorf("%w: give the deduction a name", ErrInvalid)
	}
	switch t.Method {
	case MethodFixed, MethodPercent, MethodPerLitre, MethodTiered:
	default:
		return fmt.Errorf("%w: unknown way of working out the amount %q", ErrInvalid, t.Method)
	}
	switch t.Frequency {
	case FreqEveryRun, FreqOncePerMember, FreqOncePerYear, FreqUntilTarget:
	default:
		return fmt.Errorf("%w: unknown frequency %q", ErrInvalid, t.Frequency)
	}
	if t.AppliesTo != AppliesAll && t.AppliesTo != AppliesEnrolled {
		return fmt.Errorf("%w: applies_to must be ALL or ENROLLED", ErrInvalid)
	}
	if t.Base != BaseGross && t.Base != BaseNet {
		return fmt.Errorf("%w: base must be GROSS or NET", ErrInvalid)
	}
	if t.Base == BaseNet && t.Method != MethodPercent && t.Method != MethodTiered {
		return fmt.Errorf("%w: only a percentage or a tiered fee can be worked out on the net pay", ErrInvalid)
	}
	if t.Amount < 0 || (t.Method == MethodPercent && t.Amount > 100) {
		return fmt.Errorf("%w: the amount must be between 0 and 100 for a percentage, and not negative", ErrInvalid)
	}
	if t.Target != nil && *t.Target < 0 {
		return fmt.Errorf("%w: the target cannot be negative", ErrInvalid)
	}
	if err := validateTiers(t.Tiers); err != nil {
		return err
	}
	if !t.IsActive {
		return nil
	}
	if t.Method == MethodTiered {
		if len(t.Tiers) == 0 {
			return fmt.Errorf("%w: add the fee bands before switching %s on", ErrInvalid, t.Name)
		}
	} else if t.Amount <= 0 && t.AppliesTo == AppliesAll {
		return fmt.Errorf("%w: set the amount before switching %s on", ErrInvalid, t.Name)
	}
	if t.Frequency == FreqUntilTarget && (t.Target == nil || *t.Target <= 0) && t.AppliesTo == AppliesAll {
		return fmt.Errorf("%w: set the target amount before switching %s on", ErrInvalid, t.Name)
	}
	return nil
}

// validateTiers checks fee bands rise and only the last is open-ended.
func validateTiers(tiers Tiers) error {
	last := 0.0
	for i, t := range tiers {
		if t.Fee < 0 {
			return fmt.Errorf("%w: fees cannot be negative", ErrInvalid)
		}
		if t.UpTo == nil {
			if i != len(tiers)-1 {
				return fmt.Errorf("%w: only the last band can have no upper limit", ErrInvalid)
			}
			continue
		}
		if *t.UpTo <= last {
			return fmt.Errorf("%w: each band's upper limit must be higher than the one before", ErrInvalid)
		}
		last = *t.UpTo
	}
	return nil
}

// SaveType creates (id empty) or updates a deduction type.
func (s *Service) SaveType(ctx context.Context, id string, req *DeductionTypeRequest) (*DeductionType, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	t := &DeductionType{
		ID: uuid.New().String(), SaccoID: saccoID, CreatedByID: actorPtr(ctx),
		Method: MethodFixed, Base: BaseGross, Frequency: FreqEveryRun, AppliesTo: AppliesAll, Priority: 50, IsActive: true,
	}
	action := audit.ActionCreate
	var before *DeductionType
	if id != "" {
		if t, err = s.repo.FindType(ctx, id); err != nil {
			return nil, err
		}
		copied := *t
		before = &copied
		action = audit.ActionUpdate
	}
	req.apply(t)
	if err := validateType(t); err != nil {
		return nil, err
	}
	if taken, err := s.repo.TypeNameTaken(ctx, saccoID, t.Name, t.ID); err != nil {
		return nil, err
	} else if taken {
		return nil, fmt.Errorf("%w: there is already a deduction called %s", ErrConflict, t.Name)
	}
	entry := audit.Entry{SaccoID: saccoID, EntityType: auditDeduction, EntityID: t.ID, Action: action,
		ActorID: middleware.GetUserID(ctx), OldValues: before, NewValues: t}
	if err := s.repo.SaveType(ctx, t, entry); err != nil {
		return nil, err
	}
	return t, nil
}

// DeleteType removes a deduction type that was never taken from anyone.
// One that was used must be switched off instead, to keep the history.
func (s *Service) DeleteType(ctx context.Context, id string) error {
	t, err := s.repo.FindType(ctx, id)
	if err != nil {
		return err
	}
	used, err := s.repo.TypeUsed(ctx, id)
	if err != nil {
		return err
	}
	if used {
		return fmt.Errorf("%w: %s has been taken from farmers; switch it off instead of deleting it", ErrLocked, t.Name)
	}
	return s.repo.DeleteType(ctx, t, audit.Entry{SaccoID: t.SaccoID, EntityType: auditDeduction, EntityID: t.ID,
		Action: audit.ActionDelete, ActorID: middleware.GetUserID(ctx), OldValues: t})
}

// --- a farmer's deductions ---

// FarmerDeduction is a deduction type as it applies to one farmer.
type FarmerDeduction struct {
	Type      DeductionType    `json:"deduction"`
	Setting   *MemberDeduction `json:"farmer_setting,omitempty"`
	Applies   bool             `json:"applies" doc:"Whether this farmer pays it"`
	Amount    float64          `json:"amount" doc:"This farmer's amount (or percent, or KES per litre)"`
	Target    *float64         `json:"target_amount,omitempty"`
	PaidSoFar float64          `json:"paid_so_far" doc:"Taken from this farmer so far"`
}

// FarmerDeductions lists every deduction type and how it applies to a farmer.
func (s *Service) FarmerDeductions(ctx context.Context, memberID string) ([]FarmerDeduction, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	if _, err := s.repo.FindFarmer(ctx, memberID); err != nil {
		return nil, err
	}
	types, err := s.repo.ListTypes(ctx, false)
	if err != nil {
		return nil, err
	}
	settings, err := s.repo.MemberDeductions(ctx, memberID)
	if err != nil {
		return nil, err
	}
	taken, err := s.repo.takenSoFar(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	paid := map[string]float64{}
	for _, t := range taken {
		if t.MemberID == memberID {
			paid[t.DeductionTypeID] = t.Total
		}
	}
	byType := map[string]*MemberDeduction{}
	for i := range settings {
		byType[settings[i].DeductionTypeID] = &settings[i]
	}
	out := make([]FarmerDeduction, 0, len(types))
	for _, t := range types {
		rule, applies := ruleFor(t, byType[t.ID])
		fd := FarmerDeduction{Type: t, Setting: byType[t.ID], Applies: applies && t.IsActive, Amount: rule.Amount, PaidSoFar: round2(paid[t.ID])}
		if t.Frequency == FreqUntilTarget {
			target := rule.Target
			fd.Target = &target
		}
		out = append(out, fd)
	}
	return out, nil
}

// SetFarmerDeduction changes how a deduction applies to one farmer: join or
// leave it, or use their own amount or target.
func (s *Service) SetFarmerDeduction(ctx context.Context, memberID, typeID string, req *FarmerDeductionRequest) (*MemberDeduction, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	if _, err := s.repo.FindFarmer(ctx, memberID); err != nil {
		return nil, err
	}
	t, err := s.repo.FindType(ctx, typeID)
	if err != nil {
		return nil, err
	}
	md, err := s.repo.FindMemberDeduction(ctx, memberID, typeID)
	if err != nil {
		return nil, err
	}
	action := audit.ActionUpdate
	var before *MemberDeduction
	if md == nil {
		md = &MemberDeduction{ID: uuid.New().String(), SaccoID: saccoID, MemberID: memberID, DeductionTypeID: t.ID}
		action = audit.ActionCreate
	} else {
		copied := *md
		before = &copied
	}
	md.IsActive = req.Applies
	md.Amount = positiveOrNil(req.Amount)
	md.Target = positiveOrNil(req.Target)
	md.Notes = req.Notes
	if md.Amount != nil && t.Method == MethodPercent && *md.Amount > 100 {
		return nil, fmt.Errorf("%w: a percentage cannot be more than 100", ErrInvalid)
	}
	entry := audit.Entry{SaccoID: saccoID, EntityType: auditMemberRule, EntityID: md.ID, Action: action,
		ActorID: middleware.GetUserID(ctx), OldValues: before, NewValues: md}
	if err := s.repo.SaveMemberDeduction(ctx, md, entry); err != nil {
		return nil, err
	}
	return md, nil
}

func positiveOrNil(v *float64) *float64 {
	if v == nil || *v <= 0 {
		return nil
	}
	r := round2(*v)
	return &r
}

// ruleFor is how a deduction type applies to a farmer given their own
// setting (nil when they have none), and whether it applies at all.
func ruleFor(t DeductionType, md *MemberDeduction) (Rule, bool) {
	r := Rule{TypeID: t.ID, Name: t.Name, Method: t.Method, Base: t.Base, Amount: t.Amount, Tiers: t.Tiers,
		Frequency: t.Frequency, Savings: t.IsSavings, Priority: t.Priority}
	if t.Target != nil {
		r.Target = *t.Target
	}
	applies := t.AppliesTo == AppliesAll
	if md != nil {
		applies = md.IsActive
		if md.Amount != nil {
			r.Amount = *md.Amount
		}
		if md.Target != nil {
			r.Target = *md.Target
		}
	}
	return r, applies
}

// --- advances, charges and adjustments ---

// AdvanceInfo is what an admin sees before giving an advance.
type AdvanceInfo struct {
	MilkSoFar   float64  `json:"milk_value_so_far" doc:"Value of milk delivered since the last pay run"`
	LitresSoFar float64  `json:"litres_so_far"`
	SinceDate   string   `json:"since_date" doc:"First day not yet paid for"`
	OpenAdvance float64  `json:"advances_taken" doc:"Advances taken since the last pay run"`
	Limit       *float64 `json:"limit,omitempty" doc:"Most a farmer may take per pay period; empty = no limit"`
	Available   *float64 `json:"available,omitempty" doc:"What this farmer may still take; empty = no limit"`
	Balance     float64  `json:"balance" doc:"The farmer's account balance now (negative = owes the Sacco)"`
}

// AdvanceInfo shows a farmer's milk so far and how much they may still take.
func (s *Service) AdvanceInfo(ctx context.Context, memberID string) (*AdvanceInfo, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	if _, err := s.repo.FindFarmer(ctx, memberID); err != nil {
		return nil, err
	}
	settings, err := s.repo.Settings(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	since := time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC)
	if settings.ClosedThrough != nil {
		since = settings.ClosedThrough.AddDate(0, 0, 1)
	}
	litres, gross, err := s.repo.MilkValue(ctx, saccoID, memberID, since, s.today())
	if err != nil {
		return nil, err
	}
	open, err := s.repo.OpenAdvances(ctx, saccoID, memberID)
	if err != nil {
		return nil, err
	}
	balance, _, err := s.repo.Balance(ctx, saccoID, memberID, nil)
	if err != nil {
		return nil, err
	}
	info := &AdvanceInfo{MilkSoFar: round2(gross), LitresSoFar: round2(litres), OpenAdvance: round2(open),
		Limit: settings.AdvanceMax, Balance: round2(balance)}
	if settings.ClosedThrough != nil {
		info.SinceDate = since.Format(dateLayout)
	}
	if settings.AdvanceMax != nil {
		left := round2(max(*settings.AdvanceMax-open, 0))
		info.Available = &left
	}
	return info, nil
}

// RecordEntry records an advance, a charge or an adjustment on a farmer's
// account. Advances and charges reduce what the farmer is paid at the next
// pay run; an adjustment may go either way and needs a reason.
func (s *Service) RecordEntry(ctx context.Context, memberID string, kind Kind, req *EntryRequest) (*Transaction, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	farmer, err := s.repo.FindFarmer(ctx, memberID)
	if err != nil {
		return nil, err
	}
	day, err := parseDay(req.Date, s.today())
	if err != nil {
		return nil, err
	}
	if day.After(s.today()) {
		return nil, fmt.Errorf("%w: the date cannot be in the future", ErrInvalid)
	}
	amount := round2(req.Amount)
	desc := strings.TrimSpace(req.Description)
	switch kind {
	case KindAdvance, KindCharge:
		if amount <= 0 {
			return nil, fmt.Errorf("%w: the amount must be more than 0", ErrInvalid)
		}
		amount = -amount
	case KindAdjustment:
		if amount == 0 {
			return nil, fmt.Errorf("%w: the amount cannot be 0", ErrInvalid)
		}
		if len(desc) < 3 {
			return nil, fmt.Errorf("%w: give the reason for the adjustment", ErrInvalid)
		}
	default:
		return nil, fmt.Errorf("%w: unknown entry %s", ErrInvalid, kind)
	}
	if kind == KindCharge && len(desc) < 2 {
		return nil, fmt.Errorf("%w: say what the charge is for (e.g. Dairy meal 2 bags)", ErrInvalid)
	}
	if kind == KindAdvance {
		info, err := s.AdvanceInfo(ctx, memberID)
		if err != nil {
			return nil, err
		}
		if info.Available != nil && -amount > *info.Available {
			return nil, fmt.Errorf("%w: %s can take at most KES %.2f more this period (limit KES %.2f, already taken KES %.2f)",
				ErrInvalid, farmer.Name(), *info.Available, *info.Limit, info.OpenAdvance)
		}
		if desc == "" {
			desc = "Advance"
		}
	}
	t := &Transaction{
		ID: uuid.New().String(), SaccoID: saccoID, MemberID: memberID, Kind: kind, EntryDate: day,
		Amount: amount, Description: desc, Reference: trimOrNil(req.Reference), RecordedByID: actorPtr(ctx),
	}
	if req.Method != "" {
		m := PayMethod(strings.ToUpper(req.Method))
		t.Method = &m
	}
	entry := audit.Entry{SaccoID: saccoID, EntityType: auditEntry, EntityID: t.ID, Action: audit.ActionCreate,
		ActorID: middleware.GetUserID(ctx), NewValues: t}
	if err := s.repo.AddTransaction(ctx, t, entry); err != nil {
		return nil, err
	}
	return t, nil
}

// VoidEntry cancels an advance, charge or adjustment recorded in error.
// Entries already settled by a pay run cannot be voided; record an
// adjustment instead.
func (s *Service) VoidEntry(ctx context.Context, id, reason string) (*Transaction, error) {
	t, err := s.repo.FindTransaction(ctx, id)
	if err != nil {
		return nil, err
	}
	if t.Kind != KindAdvance && t.Kind != KindCharge && t.Kind != KindAdjustment {
		return nil, fmt.Errorf("%w: pay run entries are undone by cancelling the run", ErrLocked)
	}
	if t.VoidedAt != nil {
		return nil, fmt.Errorf("%w: already voided", ErrConflict)
	}
	if t.PayRunID != nil {
		return nil, fmt.Errorf("%w: a pay run has already settled this; record an adjustment instead", ErrLocked)
	}
	reason = strings.TrimSpace(reason)
	if len(reason) < 3 {
		return nil, fmt.Errorf("%w: give the reason for voiding", ErrInvalid)
	}
	before := *t
	now := s.now()
	t.VoidedAt, t.VoidReason = &now, &reason
	entry := audit.Entry{SaccoID: t.SaccoID, EntityType: auditEntry, EntityID: t.ID, Action: audit.ActionVoid,
		ActorID: middleware.GetUserID(ctx), Reason: &reason, OldValues: before, NewValues: t}
	if err := s.repo.VoidTransaction(ctx, t, entry); err != nil {
		return nil, err
	}
	return t, nil
}

// ListEntries lists advances, charges or adjustments across farmers.
func (s *Service) ListEntries(ctx context.Context, kind Kind, from, to string, openOnly bool) ([]EntryRow, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	end, err := parseDay(to, s.today())
	if err != nil {
		return nil, err
	}
	start, err := parseDay(from, end.AddDate(0, -3, 0))
	if err != nil {
		return nil, err
	}
	rows, err := s.repo.ListEntries(ctx, saccoID, kind, start, end, openOnly)
	if rows == nil {
		rows = []EntryRow{}
	}
	return rows, err
}

func trimOrNil(v string) *string {
	v = strings.TrimSpace(v)
	if v == "" {
		return nil
	}
	return &v
}

// --- the farmer's account ---

// AccountLine is one entry of a farmer's statement with the running balance.
type AccountLine struct {
	Transaction
	Balance float64 `json:"balance"`
}

// Account is a farmer's statement over a period.
type Account struct {
	MemberID       string        `json:"member_id"`
	FromDate       string        `json:"from_date"`
	ToDate         string        `json:"to_date"`
	OpeningBalance float64       `json:"opening_balance"`
	ClosingBalance float64       `json:"closing_balance"`
	Lines          []AccountLine `json:"lines"`
	// Now, whatever the period.
	Balance      float64 `json:"balance" doc:"Balance now: negative means the farmer owes the Sacco"`
	ShareBalance float64 `json:"share_balance" doc:"Savings (shares) taken to date"`
	OpenAdvances float64 `json:"open_advances" doc:"Advances to be recovered at the next pay run"`
}

// Account is a farmer's statement: opening balance, every entry with the
// running balance, and the closing balance. Voided entries are listed with
// no effect on the balance.
func (s *Service) Account(ctx context.Context, memberID, from, to string) (*Account, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	if _, err := s.repo.FindFarmer(ctx, memberID); err != nil {
		return nil, err
	}
	end, err := parseDay(to, s.today())
	if err != nil {
		return nil, err
	}
	start, err := parseDay(from, time.Date(end.Year(), 1, 1, 0, 0, 0, 0, time.UTC))
	if err != nil {
		return nil, err
	}
	if start.After(end) {
		return nil, fmt.Errorf("%w: the start date is after the end date", ErrInvalid)
	}
	opening, _, err := s.repo.Balance(ctx, saccoID, memberID, &start)
	if err != nil {
		return nil, err
	}
	rows, err := s.repo.Transactions(ctx, saccoID, memberID, start, end)
	if err != nil {
		return nil, err
	}
	acc := &Account{MemberID: memberID, FromDate: start.Format(dateLayout), ToDate: end.Format(dateLayout),
		OpeningBalance: round2(opening), Lines: make([]AccountLine, 0, len(rows))}
	sort.SliceStable(rows, func(i, j int) bool {
		if !rows[i].EntryDate.Equal(rows[j].EntryDate) {
			return rows[i].EntryDate.Before(rows[j].EntryDate)
		}
		return rows[i].CreatedAt.Before(rows[j].CreatedAt)
	})
	balance := opening
	for _, t := range rows {
		if t.VoidedAt == nil {
			balance = round2(balance + t.Amount)
		}
		acc.Lines = append(acc.Lines, AccountLine{Transaction: t, Balance: balance})
	}
	acc.ClosingBalance = round2(balance)
	if acc.Balance, acc.ShareBalance, err = s.repo.Balance(ctx, saccoID, memberID, nil); err != nil {
		return nil, err
	}
	if acc.OpenAdvances, err = s.repo.OpenAdvances(ctx, saccoID, memberID); err != nil {
		return nil, err
	}
	acc.Balance, acc.ShareBalance, acc.OpenAdvances = round2(acc.Balance), round2(acc.ShareBalance), round2(acc.OpenAdvances)
	return acc, nil
}
