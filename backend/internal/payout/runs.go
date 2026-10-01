package payout

import (
	"context"
	"fmt"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// MaxRunDays is the longest period one pay run may cover.
const MaxRunDays = 93

// DefaultPeriod is the period the next pay run should cover: from the day
// after the last closed one (or the start of last month) to the end of that
// month, but not past today.
func (s *Service) DefaultPeriod(ctx context.Context) (from, to time.Time, err error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return
	}
	settings, err := s.repo.Settings(ctx, saccoID)
	if err != nil {
		return
	}
	today := s.today()
	if settings.ClosedThrough != nil {
		from = settings.ClosedThrough.AddDate(0, 0, 1)
	} else {
		from = time.Date(today.Year(), today.Month()-1, 1, 0, 0, 0, 0, time.UTC)
	}
	to = time.Date(from.Year(), from.Month()+1, 0, 0, 0, 0, 0, time.UTC)
	if to.After(today) {
		to = today
	}
	return from, to, nil
}

// checkPeriod applies the rules for a run's dates: no gaps or overlaps with
// paid periods (milk in a gap would be locked unpaid), nothing in the future.
func (s *Service) checkPeriod(from, to time.Time, closed *time.Time) error {
	if from.After(to) {
		return fmt.Errorf("%w: the start date is after the end date", ErrInvalid)
	}
	if to.After(s.today()) {
		return fmt.Errorf("%w: a pay run cannot include days still to come", ErrInvalid)
	}
	if int(to.Sub(from).Hours()/24)+1 > MaxRunDays {
		return fmt.Errorf("%w: a pay run can cover at most %d days", ErrInvalid, MaxRunDays)
	}
	if closed != nil {
		next := closed.AddDate(0, 0, 1)
		if !from.Equal(next) {
			return fmt.Errorf("%w: farmers are paid up to %s, so this pay run must start on %s",
				ErrInvalid, closed.Format("2 Jan 2006"), next.Format("2 Jan 2006"))
		}
	}
	return nil
}

// CreateRun works out a new draft pay run.
func (s *Service) CreateRun(ctx context.Context, req *CreateRunRequest) (*RunDetail, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	defFrom, defTo, err := s.DefaultPeriod(ctx)
	if err != nil {
		return nil, err
	}
	from, err := parseDay(req.FromDate, defFrom)
	if err != nil {
		return nil, err
	}
	to, err := parseDay(req.ToDate, defTo)
	if err != nil {
		return nil, err
	}
	run := &PayRun{ID: uuid.New().String(), SaccoID: saccoID, FromDate: from, ToDate: to, Status: RunDraft,
		Notes: trimOrNil(req.Notes), CreatedByID: actorPtr(ctx)}

	err = s.repo.Transaction(ctx, func(tx *Repository) error {
		settings, err := tx.Settings(ctx, saccoID)
		if err != nil {
			return err
		}
		if err := s.checkPeriod(from, to, settings.ClosedThrough); err != nil {
			return err
		}
		if latest, err := tx.LatestRun(ctx, saccoID); err != nil {
			return err
		} else if latest != nil && latest.Status == RunDraft {
			return fmt.Errorf("%w: finish or discard the pay run for %s first", ErrConflict, periodLabel(latest))
		}
		if err := tx.CreateRun(ctx, run); err != nil {
			return err
		}
		if _, err := s.work(ctx, tx, run, s.now()); err != nil {
			return err
		}
		return tx.RecordAudit(ctx, audit.Entry{SaccoID: saccoID, EntityType: auditPayRun, EntityID: run.ID,
			Action: audit.ActionCreate, ActorID: middleware.GetUserID(ctx), NewValues: run})
	})
	if err != nil {
		return nil, err
	}
	return s.GetRun(ctx, run.ID, "", false)
}

// RecomputeRun works a draft run out again, e.g. after milk records were
// corrected or a deduction changed.
func (s *Service) RecomputeRun(ctx context.Context, id string) (*RunDetail, error) {
	err := s.repo.Transaction(ctx, func(tx *Repository) error {
		run, err := tx.FindRun(ctx, id)
		if err != nil {
			return err
		}
		if run.Status != RunDraft {
			return fmt.Errorf("%w: only a draft pay run can be worked out again", ErrLocked)
		}
		_, err = s.work(ctx, tx, run, s.now())
		return err
	})
	if err != nil {
		return nil, err
	}
	return s.GetRun(ctx, id, "", false)
}

// work computes every farmer's pay for a run and saves the lines and totals.
// Advances, charges and adjustments recorded up to cutoff are included.
func (s *Service) work(ctx context.Context, tx *Repository, run *PayRun, cutoff time.Time) ([]PayRunLine, error) {
	saccoID := run.SaccoID
	milk, err := tx.milkByFarmer(ctx, saccoID, run.FromDate, run.ToDate)
	if err != nil {
		return nil, err
	}
	settled, err := tx.settledBalances(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	open, err := tx.openEntries(ctx, saccoID, cutoff)
	if err != nil {
		return nil, err
	}
	taken, err := tx.takenSoFar(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	types, err := tx.activeTypes(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	settings, err := tx.allMemberDeductions(ctx, saccoID)
	if err != nil {
		return nil, err
	}

	inputs := map[string]*SlipInput{}
	get := func(id string) *SlipInput {
		if inputs[id] == nil {
			inputs[id] = &SlipInput{Taken: map[string]Taken{}}
		}
		return inputs[id]
	}
	for _, m := range milk {
		in := get(m.MemberID)
		in.Litres, in.Gross = m.Litres, m.Gross
	}
	for _, b := range settled {
		get(b.MemberID).Opening = b.Total
	}
	for _, e := range open {
		get(e.MemberID).Entries = e.Total
	}
	year := fmt.Sprint(run.ToDate.Year())
	for _, t := range taken {
		if in, ok := inputs[t.MemberID]; ok {
			in.Taken[t.DeductionTypeID] = Taken{Ever: true, ThisYear: strings.HasPrefix(t.LastDate, year), Total: t.Total}
		}
	}
	own := map[string]map[string]*MemberDeduction{}
	for i := range settings {
		md := &settings[i]
		if own[md.MemberID] == nil {
			own[md.MemberID] = map[string]*MemberDeduction{}
		}
		own[md.MemberID][md.DeductionTypeID] = md
	}

	ids := make([]string, 0, len(inputs))
	for id := range inputs {
		ids = append(ids, id)
	}
	farmers, err := tx.Farmers(ctx, saccoID, ids)
	if err != nil {
		return nil, err
	}

	lines := make([]PayRunLine, 0, len(ids))
	run.Farmers, run.TotalLitres, run.TotalGross, run.TotalDeductions, run.TotalNet = 0, 0, 0, 0, 0
	for _, id := range ids {
		in := inputs[id]
		for _, t := range types {
			if rule, applies := ruleFor(t, own[id][t.ID]); applies {
				in.Rules = append(in.Rules, rule)
			}
		}
		slip := Compute(*in)
		if slip.Gross == 0 && slip.Opening == 0 && slip.Entries == 0 {
			continue
		}
		f := farmers[id]
		line := PayRunLine{
			ID: uuid.New().String(), PayRunID: run.ID, SaccoID: saccoID, MemberID: id,
			MembershipNumber: f.MembershipNumber, FarmerName: strings.TrimSpace(f.Name()), Phone: f.Phone,
			MpesaNumber: f.MpesaNumber, BankName: f.BankName, BankAccountNumber: f.BankAccountNumber,
			Litres: slip.Litres, Gross: slip.Gross, Opening: slip.Opening, Entries: slip.Entries,
			Deductions: slip.Deductions, Net: slip.Net, Closing: slip.Closing,
		}
		for _, it := range slip.Items {
			line.Items = append(line.Items, LineItem{ID: uuid.New().String(), LineID: line.ID,
				DeductionTypeID: it.TypeID, Name: it.Name, Amount: it.Amount, IsSavings: it.Savings})
		}
		lines = append(lines, line)
		run.Farmers++
		run.TotalLitres += slip.Litres
		run.TotalGross += slip.Gross
		run.TotalDeductions += slip.Deductions
		run.TotalNet += slip.Net
	}
	sort.Slice(lines, func(i, j int) bool {
		if lines[i].MembershipNumber != lines[j].MembershipNumber {
			return lines[i].MembershipNumber < lines[j].MembershipNumber
		}
		return lines[i].FarmerName < lines[j].FarmerName
	})
	run.TotalLitres, run.TotalGross = round2(run.TotalLitres), round2(run.TotalGross)
	run.TotalDeductions, run.TotalNet = round2(run.TotalDeductions), round2(run.TotalNet)

	if err := tx.ReplaceLines(ctx, run.ID, lines); err != nil {
		return nil, err
	}
	if err := tx.SaveRun(ctx, run); err != nil {
		return nil, err
	}
	return lines, nil
}

// ApproveRun works the run out one last time and, if the net total is still
// the one the approver saw, writes every farmer's milk, deductions and net
// pay to their accounts, settles their advances and charges, and closes the
// period so its milk records can no longer change.
func (s *Service) ApproveRun(ctx context.Context, id string, expectedNet *float64) (*RunDetail, error) {
	err := s.repo.Transaction(ctx, func(tx *Repository) error {
		run, err := tx.FindRun(ctx, id)
		if err != nil {
			return err
		}
		if run.Status != RunDraft {
			return fmt.Errorf("%w: this pay run is %s", ErrLocked, strings.ToLower(string(run.Status)))
		}
		settings, err := tx.Settings(ctx, run.SaccoID)
		if err != nil {
			return err
		}
		if err := s.checkPeriod(run.FromDate, run.ToDate, settings.ClosedThrough); err != nil {
			return err
		}
		cutoff := s.now()
		lines, err := s.work(ctx, tx, run, cutoff)
		if err != nil {
			return err
		}
		if expectedNet != nil && math.Abs(*expectedNet-run.TotalNet) > 0.005 {
			return fmt.Errorf("%w: the figures changed since you looked (net pay is now KES %.2f); check them again before approving",
				ErrConflict, run.TotalNet)
		}

		entries := make([]Transaction, 0, len(lines)*3)
		label := periodLabel(run)
		add := func(l PayRunLine, kind Kind, amount float64, desc string, typeID *string, savings bool) {
			entries = append(entries, Transaction{ID: uuid.New().String(), SaccoID: run.SaccoID, MemberID: l.MemberID,
				Kind: kind, EntryDate: run.ToDate, Amount: round2(amount), Description: desc,
				DeductionTypeID: typeID, IsSavings: savings, PayRunID: &run.ID, RecordedByID: actorPtr(ctx)})
		}
		for _, l := range lines {
			if l.Gross != 0 {
				add(l, KindMilk, l.Gross, fmt.Sprintf("Milk %s: %s L", label, trimZeros(l.Litres)), nil, false)
			}
			for _, it := range l.Items {
				typeID := it.DeductionTypeID
				add(l, KindDeduction, -it.Amount, it.Name, &typeID, it.IsSavings)
			}
			if l.Net > 0 {
				add(l, KindPayout, -l.Net, "Net pay "+label, nil, false)
			}
		}
		if err := tx.PostEntries(ctx, run.SaccoID, run.ID, cutoff, entries); err != nil {
			return err
		}
		to := run.ToDate
		if err := tx.SetClosedThrough(ctx, run.SaccoID, &to); err != nil {
			return err
		}
		status := RunApproved
		if run.TotalNet == 0 {
			status = RunPaid
		}
		now := s.now()
		fields := map[string]any{"approved_by_id": actorPtr(ctx), "approved_at": now}
		if settings.ClosedThrough != nil {
			fields["previous_closed_to"] = settings.ClosedThrough.Format(dateLayout)
		}
		if err := tx.MoveRun(ctx, run.ID, RunDraft, status, fields); err != nil {
			return err
		}
		return tx.RecordAudit(ctx, audit.Entry{SaccoID: run.SaccoID, EntityType: auditPayRun, EntityID: run.ID,
			Action: audit.ActionStatus, ActorID: middleware.GetUserID(ctx),
			NewValues: map[string]any{"status": status, "farmers": run.Farmers, "total_net": run.TotalNet, "closed_through": to.Format(dateLayout)}})
	})
	if err != nil {
		return nil, err
	}
	return s.GetRun(ctx, id, "", false)
}

// CancelRun discards a draft, or undoes an approved run nobody has been paid
// from yet: its account entries are removed, the advances and charges it
// settled wait for the next run again, and the period reopens. Only the
// latest approved run can be undone.
func (s *Service) CancelRun(ctx context.Context, id, reason string) error {
	reason = strings.TrimSpace(reason)
	return s.repo.Transaction(ctx, func(tx *Repository) error {
		run, err := tx.FindRun(ctx, id)
		if err != nil {
			return err
		}
		entry := audit.Entry{SaccoID: run.SaccoID, EntityType: auditPayRun, EntityID: run.ID, ActorID: middleware.GetUserID(ctx), Reason: &reason}
		switch run.Status {
		case RunDraft:
			entry.Action, entry.OldValues = audit.ActionDelete, run
			if err := tx.DeleteRun(ctx, run.ID); err != nil {
				return err
			}
			return tx.RecordAudit(ctx, entry)
		case RunApproved:
		default:
			return fmt.Errorf("%w: a pay run that is %s cannot be cancelled", ErrLocked, strings.ToLower(string(run.Status)))
		}
		if len(reason) < 3 {
			return fmt.Errorf("%w: give the reason for cancelling an approved pay run", ErrInvalid)
		}
		paid, _, _, err := tx.PaidTotals(ctx, run.ID)
		if err != nil {
			return err
		}
		if paid > 0 {
			return fmt.Errorf("%w: %d farmers are already marked paid in this run; it cannot be cancelled", ErrLocked, paid)
		}
		settings, err := tx.Settings(ctx, run.SaccoID)
		if err != nil {
			return err
		}
		if settings.ClosedThrough == nil || !settings.ClosedThrough.Equal(run.ToDate) {
			return fmt.Errorf("%w: only the latest pay run can be cancelled", ErrLocked)
		}
		if err := tx.UnpostEntries(ctx, run.ID); err != nil {
			return err
		}
		if err := tx.SetClosedThrough(ctx, run.SaccoID, run.PreviousClosedTo); err != nil {
			return err
		}
		if err := tx.MoveRun(ctx, run.ID, RunApproved, RunCancelled,
			map[string]any{"cancelled_at": s.now(), "cancel_reason": reason}); err != nil {
			return err
		}
		entry.Action = audit.ActionStatus
		entry.NewValues = map[string]any{"status": RunCancelled}
		return tx.RecordAudit(ctx, entry)
	})
}

// PayLines marks farmers in an approved run as paid. With no line ids, every
// farmer not yet paid is marked (e.g. after a bulk M-Pesa upload). Farmers
// already paid are left as they were.
func (s *Service) PayLines(ctx context.Context, runID string, req *PayRequest) (*RunDetail, error) {
	method := PayMethod(strings.ToUpper(strings.TrimSpace(req.Method)))
	switch method {
	case PayCash, PayMpesa, PayBank, PayCheck:
	default:
		return nil, fmt.Errorf("%w: choose how the farmers were paid", ErrInvalid)
	}
	ref := trimOrNil(req.Reference)
	if ref == nil && method != PayCash {
		return nil, fmt.Errorf("%w: give the M-Pesa, bank or cheque reference", ErrInvalid)
	}
	paidAt := s.now()
	if req.Date != "" {
		d, err := parseDay(req.Date, s.today())
		if err != nil {
			return nil, err
		}
		if d.After(s.today()) {
			return nil, fmt.Errorf("%w: the payment date cannot be in the future", ErrInvalid)
		}
		paidAt = d
	}
	var account *string
	if req.CashAccountID != "" {
		account = &req.CashAccountID
	}
	err := s.repo.Transaction(ctx, func(tx *Repository) error {
		run, err := tx.FindRun(ctx, runID)
		if err != nil {
			return err
		}
		if account != nil {
			if err := tx.CheckCashAccount(ctx, run.SaccoID, *account); err != nil {
				return fmt.Errorf("%w: %v", ErrInvalid, err)
			}
		}
		if run.Status != RunApproved {
			return fmt.Errorf("%w: farmers are paid once the pay run is approved (it is %s)", ErrLocked, strings.ToLower(string(run.Status)))
		}
		lines, err := tx.Lines(ctx, run.ID, "", true)
		if err != nil {
			return err
		}
		want := map[string]bool{}
		for _, id := range req.LineIDs {
			want[id] = true
		}
		marked := 0
		for i := range lines {
			l := &lines[i]
			if len(want) > 0 && !want[l.ID] {
				continue
			}
			l.PaidAt, l.PaidMethod, l.PaidReference, l.PaidByID = &paidAt, &method, ref, actorPtr(ctx)
			l.CashAccountID = account
			if err := tx.MarkLinePaid(ctx, l); err != nil {
				return err
			}
			marked++
		}
		if marked == 0 {
			if len(want) > 0 {
				return fmt.Errorf("%w: those farmers are already paid or have nothing to be paid", ErrConflict)
			}
			return fmt.Errorf("%w: everyone in this pay run is already paid", ErrConflict)
		}
		count, total, unpaid, err := tx.PaidTotals(ctx, run.ID)
		if err != nil {
			return err
		}
		fields := map[string]any{"paid_count": count, "total_paid": round2(total)}
		if unpaid == 0 {
			if err := tx.MoveRun(ctx, run.ID, RunApproved, RunPaid, fields); err != nil {
				return err
			}
		} else {
			run.PaidCount, run.TotalPaid = count, round2(total)
			if err := tx.SaveRun(ctx, run); err != nil {
				return err
			}
		}
		return tx.RecordAudit(ctx, audit.Entry{SaccoID: run.SaccoID, EntityType: auditPayRun, EntityID: run.ID,
			Action: audit.ActionUpdate, ActorID: middleware.GetUserID(ctx),
			NewValues: map[string]any{"paid": marked, "method": method, "reference": ref}})
	})
	if err != nil {
		return nil, err
	}
	return s.GetRun(ctx, runID, "", false)
}

// RunDetail is a pay run with its farmers' lines.
type RunDetail struct {
	Run   *PayRun      `json:"pay_run"`
	Lines []PayRunLine `json:"lines"`
}

// GetRun loads a run and its lines; search filters by farmer.
func (s *Service) GetRun(ctx context.Context, id, search string, unpaidOnly bool) (*RunDetail, error) {
	run, err := s.repo.FindRun(ctx, id)
	if err != nil {
		return nil, err
	}
	lines, err := s.repo.Lines(ctx, id, strings.TrimSpace(search), unpaidOnly)
	if err != nil {
		return nil, err
	}
	for i := range lines {
		if lines[i].Items == nil {
			lines[i].Items = []LineItem{}
		}
	}
	return &RunDetail{Run: run, Lines: lines}, nil
}

// ListRuns lists the Sacco's pay runs, newest first.
func (s *Service) ListRuns(ctx context.Context) ([]PayRun, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	runs, err := s.repo.ListRuns(ctx, saccoID, 60)
	if runs == nil {
		runs = []PayRun{}
	}
	return runs, err
}

// periodLabel names a run's period: "Oct 2026" for a whole month,
// otherwise "1 Oct – 15 Oct 2026".
func periodLabel(run *PayRun) string {
	f, t := run.FromDate, run.ToDate
	if f.Day() == 1 && t.AddDate(0, 0, 1).Day() == 1 && f.Month() == t.Month() && f.Year() == t.Year() {
		return f.Format("Jan 2006")
	}
	return f.Format("2 Jan") + " – " + t.Format("2 Jan 2006")
}

// trimZeros writes 412.50 as 412.5 and 400.00 as 400.
func trimZeros(v float64) string {
	s := fmt.Sprintf("%.2f", v)
	s = strings.TrimRight(s, "0")
	return strings.TrimSuffix(s, ".")
}
