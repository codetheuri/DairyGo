package ledger

import (
	"context"
	"database/sql"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/response"
)

// Periods. The accountant closes the books month by month: nothing can then
// be dated in a closed month, so its statements never change. Staff keep
// recording as before; a record dated in a closed month that is changed or
// voided later posts its correction on the first open day (see sync.go).
// Reopening needs a reason and is kept in the history.
//
// At the end of a financial year its income and expenses are moved to
// retained surplus by one journal on the year's last day, so the next year's
// income statement starts from nothing. The year's months are closed with
// it.

// SrcYearEnd is the source of a year-end journal (source_id: the year's
// last day). It follows no record, so a comparison never reverses it.
const SrcYearEnd = "year_end"

// Period event actions.
const (
	EventClose   = "CLOSE"
	EventReopen  = "REOPEN"
	EventYearEnd = "YEAR_END"
)

// PeriodEvent is a close, reopen or year end.
type PeriodEvent struct {
	ID           string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID      string     `json:"-" gorm:"type:varchar(36)"`
	Action       string     `json:"action" doc:"CLOSE, REOPEN or YEAR_END"`
	ThroughDate  *time.Time `json:"through_date,omitempty" gorm:"type:date" doc:"Closed through after it (none: nothing closed)"`
	PreviousDate *time.Time `json:"previous_date,omitempty" gorm:"type:date"`
	Amount       *float64   `json:"amount,omitempty" doc:"YEAR_END: the year's surplus moved to retained surplus"`
	JournalID    *string    `json:"journal_id,omitempty" gorm:"type:varchar(36)"`
	Reason       *string    `json:"reason,omitempty"`
	CreatedByID  *uint      `json:"-"`
	CreatedAt    time.Time  `json:"created_at"`

	CreatedBy string `json:"created_by,omitempty" gorm:"->;-:migration"`
}

// TableName sets the database table name.
func (PeriodEvent) TableName() string { return "ledger_period_events" }

// PeriodMonth is one month of the books.
type PeriodMonth struct {
	From   string `json:"from"`
	To     string `json:"to"`
	Closed bool   `json:"closed"`
	Ended  bool   `json:"ended" doc:"The month is over, so it may be closed"`
}

// PeriodYear is one financial year of the books.
type PeriodYear struct {
	From    string  `json:"from"`
	To      string  `json:"to"`
	Ended   bool    `json:"ended"`
	Closed  bool    `json:"closed" doc:"Its income and expenses are in retained surplus"`
	Surplus float64 `json:"surplus" doc:"Income less expenses for the year (since the books started)"`
}

// Periods is the books' months and years and their history.
type Periods struct {
	StartDate         string        `json:"start_date"`
	ClosedThrough     *string       `json:"closed_through,omitempty"`
	YearClosedThrough *string       `json:"year_closed_through,omitempty"`
	YearStartMonth    int           `json:"year_start_month"`
	Months            []PeriodMonth `json:"months" doc:"From the month the books start to this month, newest first"`
	Years             []PeriodYear  `json:"years" doc:"Financial years the books cover, newest first"`
	History           []PeriodEvent `json:"history" doc:"Closes, reopens and year ends, newest first"`
}

// yearStartMonth is the month the Sacco's financial year starts.
func yearStartMonth(ctx context.Context, db *gorm.DB, saccoID string) (int, error) {
	var month int
	err := db.WithContext(ctx).Table("sacco_settings").Select("COALESCE(MAX(financial_year_start_month), 1)").
		Where("sacco_id = ?", saccoID).Scan(&month).Error
	if month < 1 || month > 12 {
		month = 1
	}
	return month, err
}

func monthEnd(d time.Time) time.Time {
	return time.Date(d.Year(), d.Month()+1, 0, 0, 0, 0, 0, time.UTC)
}

func isMonthEnd(d time.Time) bool { return d.AddDate(0, 0, 1).Day() == 1 }

func after(a time.Time, b *time.Time) bool { return b == nil || a.After(*b) }

// Periods lists the books' months and years with the history.
func (s *Service) Periods(ctx context.Context) (*Periods, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	b, err := s.started(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	month, err := yearStartMonth(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	today := s.today()
	out := &Periods{StartDate: b.StartDate.Format(dateLayout), ClosedThrough: dayPtr(b.ClosedThrough),
		YearClosedThrough: dayPtr(b.YearClosedThrough), YearStartMonth: month, History: []PeriodEvent{}}
	for m := time.Date(b.StartDate.Year(), b.StartDate.Month(), 1, 0, 0, 0, 0, time.UTC); !m.After(today); m = m.AddDate(0, 1, 0) {
		end := monthEnd(m)
		out.Months = append(out.Months, PeriodMonth{From: m.Format(dateLayout), To: end.Format(dateLayout),
			Closed: !after(end, b.ClosedThrough), Ended: end.Before(today)})
	}
	sort.SliceStable(out.Months, func(i, k int) bool { return out.Months[i].From > out.Months[k].From })
	c, err := loadChart(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	for ys := yearStart(b.StartDate, month); !ys.After(today); ys = ys.AddDate(1, 0, 0) {
		ye := ys.AddDate(1, 0, -1)
		mv, err := movements(ctx, db, saccoID, ys, ye, true)
		if err != nil {
			return nil, err
		}
		y := PeriodYear{From: ys.Format(dateLayout), To: ye.Format(dateLayout), Ended: ye.Before(today),
			Closed: !after(ye, b.YearClosedThrough), Surplus: plSurplus(c, mv)}
		out.Years = append(out.Years, y)
	}
	sort.SliceStable(out.Years, func(i, k int) bool { return out.Years[i].From > out.Years[k].From })
	if err := db.Table("ledger_period_events e").Select("e.*, u.username AS created_by").
		Joins("LEFT JOIN users u ON u.id = e.created_by_id").Where("e.sacco_id = ?", saccoID).
		Order("e.created_at DESC").Limit(200).Scan(&out.History).Error; err != nil {
		return nil, err
	}
	return out, nil
}

// plSurplus is income less expenses from net movements.
func plSurplus(c *chart, nets map[string]float64) float64 {
	v := 0.0
	for id, n := range nets {
		if a := c.accounts[id]; a != nil && (a.Type == Income || a.Type == Expense) {
			v -= n
		}
	}
	return round2(v)
}

// CloseRequest closes the books through the end of a month.
type CloseRequest struct {
	Through string `json:"through" doc:"The last day of the last month to close (YYYY-MM-DD)"`
}

// Close closes the books through the end of a month: the books are brought
// up to date first and must balance and agree with the records.
func (s *Service) Close(ctx context.Context, req *CloseRequest) (*Periods, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	through, err := time.Parse(dateLayout, strings.TrimSpace(req.Through))
	if err != nil || !isMonthEnd(through) {
		return nil, fmt.Errorf("%w: choose the last day of a month", ErrInvalid)
	}
	if !through.Before(s.today()) {
		return nil, fmt.Errorf("%w: %s is not over yet", ErrInvalid, through.Format("January 2006"))
	}
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		b, err := s.lockBooks(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		if through.Before(b.StartDate) {
			return fmt.Errorf("%w: the books start on %s", ErrInvalid, b.StartDate.Format("2 Jan 2006"))
		}
		if !after(through, b.ClosedThrough) {
			return fmt.Errorf("%w: the books are already closed through %s", ErrConflict, b.ClosedThrough.Format("2 Jan 2006"))
		}
		if err := s.readyToClose(ctx, tx, saccoID); err != nil {
			return err
		}
		return setClosed(ctx, tx, saccoID, b, &through, b.YearClosedThrough, EventClose, nil, nil, nil)
	})
	if err != nil {
		return nil, err
	}
	return s.Periods(ctx)
}

// lockBooks loads the books, holding the row until the transaction ends.
func (s *Service) lockBooks(ctx context.Context, tx *gorm.DB, saccoID string) (*Books, error) {
	var b Books
	if err := tx.WithContext(ctx).Raw("SELECT * FROM ledger_books WHERE sacco_id = ? FOR UPDATE", saccoID).Scan(&b).Error; err != nil {
		return nil, err
	}
	if b.SaccoID == "" {
		return nil, fmt.Errorf("%w: the books have not been started yet", ErrNotStarted)
	}
	return &b, nil
}

// readyToClose brings the books up to date and checks they balance and agree
// with the records, so nothing is left to post into the months being closed.
func (s *Service) readyToClose(ctx context.Context, tx *gorm.DB, saccoID string) error {
	if _, err := SyncAll(ctx, tx, saccoID, actor(ctx)); err != nil {
		return err
	}
	check, err := s.check(ctx, tx, saccoID)
	if err != nil {
		return err
	}
	if !check.Balanced {
		return fmt.Errorf("%w: debits and credits differ; the books cannot be closed", ErrConflict)
	}
	if !check.Agrees {
		var names []string
		for _, c := range check.Controls {
			if !c.OK {
				names = append(names, c.Name)
			}
		}
		return fmt.Errorf("%w: the books differ from the records (%s); find out why before closing", ErrConflict, strings.Join(names, ", "))
	}
	return nil
}

// setClosed saves the closed dates with a history event and an audit line.
func setClosed(ctx context.Context, tx *gorm.DB, saccoID string, b *Books, through, yearThrough *time.Time,
	action string, reason *string, amount *float64, journalID *string) error {
	if err := tx.Model(&Books{}).Where("sacco_id = ?", saccoID).Updates(map[string]any{
		"closed_through": through, "year_closed_through": yearThrough, "updated_at": time.Now(),
	}).Error; err != nil {
		return err
	}
	ev := &PeriodEvent{ID: uuid.New().String(), SaccoID: saccoID, Action: action, ThroughDate: through,
		PreviousDate: b.ClosedThrough, Amount: amount, JournalID: journalID, Reason: reason,
		CreatedByID: actor(ctx), CreatedAt: time.Now()}
	if err := tx.Create(ev).Error; err != nil {
		return err
	}
	return audit.Record(tx, audit.Entry{SaccoID: saccoID, EntityType: "books_period", EntityID: ev.ID, Action: audit.ActionUpdate,
		ActorID: middleware.GetUserID(ctx), Reason: reason,
		OldValues: map[string]any{"closed_through": dayPtr(b.ClosedThrough), "year_closed_through": dayPtr(b.YearClosedThrough)},
		NewValues: map[string]any{"closed_through": dayPtr(through), "year_closed_through": dayPtr(yearThrough), "action": action}})
}

// ReopenRequest reopens months.
type ReopenRequest struct {
	Through string `json:"through,omitempty" doc:"Closed through after reopening: the end of an earlier month, or empty to reopen every month"`
	Reason  string `json:"reason" doc:"Why the months are reopened (kept in the history)"`
}

// Reopen moves the closed date back. A financial year reopened has its
// year-end journal reversed, so its income and expenses are open again.
func (s *Service) Reopen(ctx context.Context, req *ReopenRequest) (*Periods, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	reason := strings.TrimSpace(req.Reason)
	if len(reason) < 3 {
		return nil, fmt.Errorf("%w: give the reason for reopening", ErrInvalid)
	}
	var through *time.Time
	if v := strings.TrimSpace(req.Through); v != "" {
		d, err := time.Parse(dateLayout, v)
		if err != nil || !isMonthEnd(d) {
			return nil, fmt.Errorf("%w: choose the last day of a month, or nothing to reopen every month", ErrInvalid)
		}
		through = &d
	}
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		b, err := s.lockBooks(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		if b.ClosedThrough == nil {
			return fmt.Errorf("%w: no month is closed", ErrConflict)
		}
		if through != nil && !through.Before(*b.ClosedThrough) {
			return fmt.Errorf("%w: the books are closed through %s; choose an earlier month", ErrInvalid, b.ClosedThrough.Format("2 Jan 2006"))
		}
		if through != nil && through.Before(b.StartDate) {
			through = nil
		}
		yearThrough := b.YearClosedThrough
		if yearThrough != nil && (through == nil || through.Before(*yearThrough)) {
			// Years whose last day is reopened: reverse their year-end
			// journals, each on its own date (now open).
			var ends []Journal
			q := tx.Where("sacco_id = ? AND source_type = ? AND reverses_id IS NULL AND reversed_by_id IS NULL", saccoID, SrcYearEnd)
			if through != nil {
				q = q.Where("journal_date > ?", through.Format(dateLayout))
			}
			if err := q.Preload("Lines").Order("journal_date DESC").Find(&ends).Error; err != nil {
				return err
			}
			e := &engine{ctx: ctx, db: tx, saccoID: saccoID, actor: actor(ctx), closed: through}
			for i := range ends {
				if _, err := e.reverse(&ends[i], ends[i].JournalDate, "The financial year was reopened: "+reason, actor(ctx)); err != nil {
					return err
				}
			}
			if err := e.finish(); err != nil {
				return err
			}
			yearThrough = nil
			if through != nil {
				var last sql.NullTime
				if err := tx.Model(&Journal{}).Select("MAX(journal_date)").
					Where("sacco_id = ? AND source_type = ? AND reverses_id IS NULL AND reversed_by_id IS NULL", saccoID, SrcYearEnd).
					Scan(&last).Error; err != nil {
					return err
				}
				if last.Valid {
					d := time.Date(last.Time.Year(), last.Time.Month(), last.Time.Day(), 0, 0, 0, 0, time.UTC)
					yearThrough = &d
				}
			}
		}
		return setClosed(ctx, tx, saccoID, b, through, yearThrough, EventReopen, &reason, nil, nil)
	})
	if err != nil {
		return nil, err
	}
	return s.Periods(ctx)
}

// YearEndRequest closes a financial year.
type YearEndRequest struct {
	YearEnd string `json:"year_end" doc:"The financial year's last day (YYYY-MM-DD)"`
}

// yearEndRule moves the year's income and expenses (each account's balance
// on its last day) to retained surplus.
func yearEndRule(day time.Time, label string, nets map[string]float64, typeOf map[string]Type) posting {
	p := posting{date: day, memo: "Year end " + label + ": income and expenses to Retained surplus"}
	ids := make([]string, 0, len(nets))
	for id := range nets {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	total := 0.0
	for _, id := range ids {
		if t := typeOf[id]; t != Income && t != Expense {
			continue
		}
		p.dr(accountKey(id), -nets[id], "")
		total += nets[id]
	}
	p.dr(roleKey(RoleRetained), total, "Surplus for the year")
	return p
}

// YearEnd closes a financial year: the books are brought up to date and must
// agree with the records; every month of the year is closed; one journal on
// the year's last day moves its income and expenses to retained surplus.
func (s *Service) YearEnd(ctx context.Context, req *YearEndRequest) (*Periods, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	end, err := time.Parse(dateLayout, strings.TrimSpace(req.YearEnd))
	if err != nil {
		return nil, fmt.Errorf("%w: choose the financial year's last day", ErrInvalid)
	}
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		b, err := s.lockBooks(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		month, err := yearStartMonth(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		start := yearStart(end, month)
		if !start.AddDate(1, 0, -1).Equal(end) {
			return fmt.Errorf("%w: the financial year runs from %s; %s is not its last day", ErrInvalid,
				time.Month(month), end.Format("2 Jan 2006"))
		}
		if !end.Before(s.today()) {
			return fmt.Errorf("%w: the financial year ending %s is not over yet", ErrInvalid, end.Format("2 Jan 2006"))
		}
		if end.Before(b.StartDate) {
			return fmt.Errorf("%w: the books start on %s, after this year", ErrInvalid, b.StartDate.Format("2 Jan 2006"))
		}
		if !after(end, b.YearClosedThrough) {
			return fmt.Errorf("%w: the year ending %s is closed already", ErrConflict, end.Format("2 Jan 2006"))
		}
		prevEnd := start.AddDate(0, 0, -1)
		if !prevEnd.Before(b.StartDate) && after(prevEnd, b.YearClosedThrough) {
			return fmt.Errorf("%w: close the year ending %s first", ErrConflict, prevEnd.Format("2 Jan 2006"))
		}
		if err := s.readyToClose(ctx, tx, saccoID); err != nil {
			return err
		}
		c, err := loadChart(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		v := end.Format(dateLayout)
		nets, err := balances(ctx, tx, saccoID, &v)
		if err != nil {
			return err
		}
		typeOf := map[string]Type{}
		for id, a := range c.accounts {
			typeOf[id] = a.Type
		}
		label := yearLabel(start, end)
		p := yearEndRule(end, label, nets, typeOf)
		surplus := plSurplus(c, nets)
		e := &engine{ctx: ctx, db: tx, saccoID: saccoID, chart: c, actor: actor(ctx), closed: b.ClosedThrough, allowClosed: true}
		var journalID *string
		if len(p.lines) > 0 {
			src := SrcYearEnd
			j := &Journal{Kind: KindAuto, SourceType: &src, SourceID: &v, Memo: p.memo, JournalDate: end}
			for _, l := range p.lines {
				a, err := c.account(l.link)
				if err != nil {
					return err
				}
				link := l.link
				line := Line{AccountID: a.ID, LinkKey: &link}
				if l.amount > 0 {
					line.Debit = l.amount
				} else {
					line.Credit = -l.amount
				}
				j.Lines = append(j.Lines, line)
			}
			if err := e.write(j); err != nil {
				return err
			}
			if err := e.finish(); err != nil {
				return err
			}
			journalID = &j.ID
		}
		through := b.ClosedThrough
		if after(end, through) {
			through = &end
		}
		return setClosed(ctx, tx, saccoID, b, through, &end, EventYearEnd, nil, &surplus, journalID)
	})
	if err != nil {
		return nil, err
	}
	return s.Periods(ctx)
}

// yearLabel is "2026", or "Jul 2026 – Jun 2027".
func yearLabel(from, to time.Time) string {
	if from.Month() == time.January {
		return fmt.Sprint(from.Year())
	}
	return from.Format("Jan 2006") + " – " + to.Format("Jan 2006")
}

// --- HTTP ---

type PeriodsData struct {
	Periods *Periods `json:"periods"`
}

type PeriodsOutput struct {
	Body response.Data[PeriodsData]
}

type CloseInput struct{ Body CloseRequest }

type ReopenInput struct{ Body ReopenRequest }

type YearEndInput struct{ Body YearEndRequest }

func periodsOut(p *Periods, msg string) *PeriodsOutput {
	out := &PeriodsOutput{}
	out.Body.Success, out.Body.Message = true, msg
	out.Body.Data.Periods = p
	return out
}

func (h *Handler) Periods(ctx context.Context, _ *struct{}) (*PeriodsOutput, error) {
	p, err := h.service.Periods(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return periodsOut(p, "Months and years"), nil
}

func (h *Handler) Close(ctx context.Context, in *CloseInput) (*PeriodsOutput, error) {
	p, err := h.service.Close(ctx, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return periodsOut(p, "Closed"), nil
}

func (h *Handler) Reopen(ctx context.Context, in *ReopenInput) (*PeriodsOutput, error) {
	p, err := h.service.Reopen(ctx, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return periodsOut(p, "Reopened"), nil
}

func (h *Handler) YearEnd(ctx context.Context, in *YearEndInput) (*PeriodsOutput, error) {
	p, err := h.service.YearEnd(ctx, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	return periodsOut(p, "Financial year closed"), nil
}
