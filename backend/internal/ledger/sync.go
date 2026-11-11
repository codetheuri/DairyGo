package ledger

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// How the books follow the records. For each record the rules say which
// journals it should have (rules.go); the engine compares them with the
// journals it has and, where they differ, reverses the old journal and posts
// the new one. Run for the records just changed (Sync, from the audit hook)
// or for every record (SyncAll: when the books start, nightly, and on the
// accountant's "bring up to date"), the outcome is the same, so a record a
// hook missed is caught the next time everything is compared.

// Source names a record that may have journals.
type Source struct {
	Type string
	ID   string
}

const chunk = 500

type pending struct {
	srcType string
	srcID   string
	p       posting
}

type engine struct {
	ctx     context.Context
	db      *gorm.DB
	saccoID string
	start   time.Time
	chart   *chart
	load    *loader
	actor   *uint

	openingStale bool
	reversals    []*Journal
	posts        []pending

	locked bool
	number int64
	made   int

	// closed: the books are closed through this day. Journals for records
	// dated then post on the first open day instead (see execute);
	// allowClosed lets the year-end journal be written on the year's last
	// day.
	closed      *time.Time
	allowClosed bool
}

// inClosed says a day is in a closed month.
func (e *engine) inClosed(d time.Time) bool { return e.closed != nil && !d.After(*e.closed) }

// openDay is the first day journals may be dated.
func (e *engine) openDay() time.Time { return e.closed.AddDate(0, 0, 1) }

// findBooks loads a Sacco's books, or nil when they have not started.
func findBooks(ctx context.Context, db *gorm.DB, saccoID string) (*Books, error) {
	var b Books
	err := db.WithContext(ctx).Where("sacco_id = ?", saccoID).Take(&b).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &b, nil
}

// newEngine prepares to bring a Sacco's books up to date; nil when the
// books have not started.
func newEngine(ctx context.Context, db *gorm.DB, saccoID string, actor *uint) (*engine, error) {
	b, err := findBooks(ctx, db, saccoID)
	if err != nil || b == nil {
		return nil, err
	}
	c, err := loadChart(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	l, err := newLoader(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	return &engine{ctx: ctx, db: db, saccoID: saccoID, start: b.StartDate, chart: c, load: l, actor: actor, closed: b.ClosedThrough}, nil
}

// Sync brings the journals of the given records up to date, in db's
// transaction. It does nothing when the Sacco's books have not started.
func Sync(ctx context.Context, db *gorm.DB, saccoID string, sources []Source) error {
	e, err := newEngine(ctx, db, saccoID, nil)
	if err != nil || e == nil {
		return err
	}
	byType := map[string][]string{}
	seen := map[Source]bool{}
	for _, s := range sources {
		if !seen[s] {
			seen[s] = true
			byType[s.Type] = append(byType[s.Type], s.ID)
		}
	}
	// A cash account's opening date decides whether money on either side of
	// it is in the account or in its opening balance, so a change to one
	// compares everything (cash accounts change rarely).
	if _, ok := byType[SrcCashAccount]; ok {
		_, err := e.all()
		return err
	}
	// The accountant's opening balances changed.
	if _, ok := byType[SrcBooks]; ok {
		e.openingStale = true
	}
	for src, ids := range byType {
		load := loaderFor(src)
		if load == nil {
			continue
		}
		for i := 0; i < len(ids); i += chunk {
			part := ids[i:min(i+chunk, len(ids))]
			recs, err := load(e.load, part)
			if err != nil {
				return err
			}
			if err := e.compare(src, part, recs); err != nil {
				return err
			}
		}
	}
	if e.openingStale {
		if err := e.syncOpening(); err != nil {
			return err
		}
	}
	return e.execute()
}

// SyncAll compares every record with the books and returns how many
// journals it made (reversals and new ones). Nothing to do: 0.
func SyncAll(ctx context.Context, db *gorm.DB, saccoID string, actor *uint) (int, error) {
	e, err := newEngine(ctx, db, saccoID, actor)
	if err != nil || e == nil {
		return 0, err
	}
	return e.all()
}

// all compares every record and the opening journal with the books.
func (e *engine) all() (int, error) {
	for _, l := range loaders {
		recs, err := l.load(e.load, nil)
		if err != nil {
			return 0, err
		}
		if err := e.compare(l.src, nil, recs); err != nil {
			return 0, err
		}
	}
	if err := e.syncOpening(); err != nil {
		return 0, err
	}
	if err := e.execute(); err != nil {
		return 0, err
	}
	err := e.db.WithContext(e.ctx).Model(&Books{}).Where("sacco_id = ?", e.saccoID).
		Updates(map[string]any{"synced_at": time.Now(), "updated_at": time.Now()}).Error
	return e.made, err
}

// active loads the journals that stand for records of a type (ids nil: all
// of them), by record and key.
func (e *engine) active(src string, ids []string) (map[string]map[string]*Journal, error) {
	var list []Journal
	q := e.db.WithContext(e.ctx).Preload("Lines").
		Where("sacco_id = ? AND kind = ? AND source_type = ? AND reverses_id IS NULL AND reversed_by_id IS NULL",
			e.saccoID, KindAuto, src)
	if ids != nil {
		q = q.Where("source_id IN ?", ids)
	}
	if err := q.Find(&list).Error; err != nil {
		return nil, err
	}
	out := map[string]map[string]*Journal{}
	for i := range list {
		j := &list[i]
		id, key := deref(j.SourceID), deref(j.SourceKey)
		if out[id] == nil {
			out[id] = map[string]*Journal{}
		}
		out[id][key] = j
	}
	return out, nil
}

// compare lines up records of one type with their journals and notes what
// to reverse and post. Postings dated before the books start belong to the
// opening journal instead.
func (e *engine) compare(src string, ids []string, recs []record) error {
	have, err := e.active(src, ids)
	if err != nil {
		return err
	}
	for _, rec := range recs {
		if rec.date.Before(e.start) {
			e.openingStale = true
		}
		want := map[string]posting{}
		for _, p := range rec.postings {
			if p.date.Before(e.start) {
				e.openingStale = true
				continue
			}
			want[p.key] = p
		}
		e.reconcile(src, rec.id, want, have[rec.id])
		delete(have, rec.id)
	}
	// Journals whose record is gone or no longer stands (voided, deleted,
	// a cancelled pay run's entries removed).
	for id, js := range have {
		e.reconcile(src, id, nil, js)
	}
	return nil
}

func (e *engine) reconcile(src, id string, want map[string]posting, have map[string]*Journal) {
	for key, j := range have {
		if p, ok := want[key]; ok && matches(j, p, e.closed) {
			delete(want, key)
			continue
		}
		e.reversals = append(e.reversals, j)
	}
	for _, p := range want {
		e.posts = append(e.posts, pending{src, id, p})
	}
}

// matches says a journal already says what the posting says: same day and
// the same amount for each link (wording and line order do not matter).
// A posting dated in a closed month is compared by amounts only: its
// journal is either there from before the close, or was posted on the
// first open day, and a closed month cannot be re-dated anyway.
func matches(j *Journal, p posting, closed *time.Time) bool {
	inClosed := closed != nil && !p.date.After(*closed)
	if !inClosed && j.JournalDate.Format(dateLayout) != p.date.Format(dateLayout) {
		return false
	}
	posted := map[string]float64{}
	for _, l := range j.Lines {
		k := deref(l.LinkKey)
		posted[k] = round2(posted[k] + l.Debit - l.Credit)
	}
	for k, v := range posted {
		if v == 0 {
			delete(posted, k)
		}
	}
	want := nets(p.lines)
	if len(posted) != len(want) {
		return false
	}
	for k, v := range want {
		if !same(posted[k], v) {
			return false
		}
	}
	return true
}

// syncOpening works out the opening journal from every record dated before
// the books start and brings it up to date.
func (e *engine) syncOpening() error {
	l := *e.load
	l.before = &e.start
	var before []posting
	for _, ld := range loaders {
		recs, err := ld.load(&l, nil)
		if err != nil {
			return err
		}
		for _, rec := range recs {
			for _, p := range rec.postings {
				if p.date.Before(e.start) {
					before = append(before, p)
				}
			}
		}
	}
	var own []OpeningLine
	if err := e.db.WithContext(e.ctx).Where("sacco_id = ?", e.saccoID).Order("created_at").Find(&own).Error; err != nil {
		return err
	}
	extra := make([]pline, len(own))
	for i, o := range own {
		extra[i] = pline{link: accountKey(o.AccountID), amount: round2(o.Debit - o.Credit)}
	}
	p, err := openingRule(e.start, before, extra, func(link string) (Type, error) {
		a, err := e.chart.account(link)
		if err != nil {
			return "", err
		}
		return a.Type, nil
	})
	if err != nil {
		return err
	}
	rec := record{id: "opening", date: e.start}
	if len(p.lines) > 0 {
		rec.postings = []posting{p}
	}
	return e.compare(SrcBooks, []string{"opening"}, []record{rec})
}

// srcOrder posts an opening first, then the records in loader order.
func srcOrder(src string) int {
	if src == SrcBooks {
		return -1
	}
	for i, l := range loaders {
		if l.src == src {
			return i
		}
	}
	return len(loaders)
}

// execute writes the reversals, then the new journals in date order, so a
// first build numbers journals by date.
func (e *engine) execute() error {
	sort.SliceStable(e.reversals, func(i, k int) bool { return e.reversals[i].Number < e.reversals[k].Number })
	for _, j := range e.reversals {
		day := j.JournalDate
		if e.inClosed(day) {
			day = e.openDay()
		}
		if _, err := e.reverse(j, day, "The record changed or was voided", nil); err != nil {
			return err
		}
	}
	sort.SliceStable(e.posts, func(i, k int) bool {
		a, b := e.posts[i], e.posts[k]
		if !a.p.date.Equal(b.p.date) {
			return a.p.date.Before(b.p.date)
		}
		if srcOrder(a.srcType) != srcOrder(b.srcType) {
			return srcOrder(a.srcType) < srcOrder(b.srcType)
		}
		return a.srcID+a.p.key < b.srcID+b.p.key
	})
	for _, pd := range e.posts {
		if err := e.post(pd); err != nil {
			return err
		}
	}
	return e.finish()
}

// next gives the next journal number, holding the Sacco's books row until
// the transaction ends so two journals never share a number.
func (e *engine) next() (int64, error) {
	if !e.locked {
		if err := e.db.WithContext(e.ctx).Raw("SELECT next_number FROM ledger_books WHERE sacco_id = ? FOR UPDATE", e.saccoID).
			Scan(&e.number).Error; err != nil {
			return 0, err
		}
		e.locked = true
	}
	e.number++
	return e.number, nil
}

func (e *engine) finish() error {
	if !e.locked {
		return nil
	}
	return e.db.WithContext(e.ctx).Model(&Books{}).Where("sacco_id = ?", e.saccoID).
		Updates(map[string]any{"next_number": e.number, "updated_at": time.Now()}).Error
}

// post writes the journal a record should have.
func (e *engine) post(pd pending) error {
	if !balanced(pd.p.lines) {
		return fmt.Errorf("ledger: %s %s does not balance", pd.srcType, pd.srcID)
	}
	j := &Journal{Kind: KindAuto, SourceType: &pd.srcType, SourceID: &pd.srcID, Memo: pd.p.memo, Reference: pd.p.ref, JournalDate: pd.p.date}
	if e.inClosed(pd.p.date) {
		// The record is dated in a closed month: the correction goes on the
		// first open day, so the closed month's figures never change.
		j.JournalDate = e.openDay()
		j.Memo += " (for " + pd.p.date.Format("2 Jan 2006") + ", in a closed month)"
	}
	if pd.p.key != "" {
		key := pd.p.key
		j.SourceKey = &key
	}
	for _, l := range pd.p.lines {
		a, err := e.chart.account(l.link)
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
		if l.memo != "" {
			memo := l.memo
			line.Memo = &memo
		}
		j.Lines = append(j.Lines, line)
	}
	if len(j.Lines) == 0 {
		return nil
	}
	return e.write(j)
}

// write numbers and stores a journal and its lines.
func (e *engine) write(j *Journal) error {
	if e.inClosed(j.JournalDate) && !e.allowClosed {
		return fmt.Errorf("%w: the books are closed through %s; nothing can be dated %s",
			ErrConflict, e.closed.Format("2 Jan 2006"), j.JournalDate.Format("2 Jan 2006"))
	}
	n, err := e.next()
	if err != nil {
		return err
	}
	j.ID, j.SaccoID, j.Number, j.CreatedAt = uuid.New().String(), e.saccoID, n, time.Now()
	if j.CreatedByID == nil {
		j.CreatedByID = e.actor
	}
	j.Total = 0
	for i := range j.Lines {
		l := &j.Lines[i]
		l.ID, l.JournalID, l.SaccoID, l.LineNo, l.JournalDate = uuid.New().String(), j.ID, e.saccoID, i+1, j.JournalDate
		l.Debit, l.Credit = round2(l.Debit), round2(l.Credit)
		j.Total += l.Debit
	}
	j.Total = round2(j.Total)
	if err := e.db.WithContext(e.ctx).Omit("CreatedBy").Create(j).Error; err != nil {
		return err
	}
	e.made++
	return nil
}

// reverse posts a journal that takes j back, dated day, and marks j
// reversed.
func (e *engine) reverse(j *Journal, day time.Time, reason string, actor *uint) (*Journal, error) {
	r := &Journal{Kind: j.Kind, SourceType: j.SourceType, SourceID: j.SourceID, SourceKey: j.SourceKey,
		JournalDate: day, Memo: fmt.Sprintf("Reversal of J-%d: %s", j.Number, j.Memo), Reference: j.Reference,
		ReversesID: &j.ID, Reason: &reason, CreatedByID: actor}
	for _, l := range j.Lines {
		r.Lines = append(r.Lines, Line{AccountID: l.AccountID, LinkKey: l.LinkKey, Debit: l.Credit, Credit: l.Debit, Memo: l.Memo})
	}
	if err := e.write(r); err != nil {
		return nil, err
	}
	res := e.db.WithContext(e.ctx).Model(&Journal{}).Where("id = ? AND reversed_by_id IS NULL", j.ID).Update("reversed_by_id", r.ID)
	if res.Error != nil {
		return nil, res.Error
	}
	if res.RowsAffected == 0 {
		return nil, fmt.Errorf("%w: J-%d was reversed already", ErrConflict, j.Number)
	}
	return r, nil
}

func deref(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
