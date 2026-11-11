package ledger

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// JournalFilter narrows the journal list.
type JournalFilter struct {
	From, To  string
	Kind      string // AUTO, MANUAL or "" for both
	AccountID string
	Search    string // a number (J-12 or 12) or words in the memo
	Page      int
	Limit     int
}

// JournalList is a page of journals.
type JournalList struct {
	From     string    `json:"from_date"`
	To       string    `json:"to_date"`
	Journals []Journal `json:"journals"`
	Total    int64     `json:"total" doc:"Journals matching, on every page"`
	Page     int       `json:"page"`
	Limit    int       `json:"limit"`
}

// Journals lists journals over a period (default this month), newest
// first, without their lines.
func (s *Service) Journals(ctx context.Context, f JournalFilter) (*JournalList, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	if _, err := s.started(ctx, db, saccoID); err != nil {
		return nil, err
	}
	today := s.today()
	from, err := parseDay(f.From, time.Date(today.Year(), today.Month(), 1, 0, 0, 0, 0, time.UTC))
	if err != nil {
		return nil, err
	}
	to, err := parseDay(f.To, today)
	if err != nil {
		return nil, err
	}
	if f.Limit <= 0 || f.Limit > 200 {
		f.Limit = 50
	}
	if f.Page <= 0 {
		f.Page = 1
	}
	q := db.Model(&Journal{}).Where("journals.sacco_id = ? AND journals.journal_date BETWEEN ? AND ?",
		saccoID, from.Format(dateLayout), to.Format(dateLayout))
	switch strings.ToUpper(f.Kind) {
	case string(KindAuto), string(KindManual):
		q = q.Where("journals.kind = ?", strings.ToUpper(f.Kind))
	}
	if f.AccountID != "" {
		q = q.Where("EXISTS (SELECT 1 FROM journal_lines l WHERE l.journal_id = journals.id AND l.account_id = ?)", f.AccountID)
	}
	if term := strings.TrimSpace(f.Search); term != "" {
		num := strings.TrimPrefix(strings.ToUpper(term), "J-")
		if isDigits(num) {
			q = q.Where("journals.number = ?", num)
		} else {
			q = q.Where("LOWER(journals.memo) LIKE ? OR LOWER(COALESCE(journals.reference, '')) LIKE ?",
				"%"+strings.ToLower(term)+"%", "%"+strings.ToLower(term)+"%")
		}
	}
	out := &JournalList{From: from.Format(dateLayout), To: to.Format(dateLayout), Journals: []Journal{}, Page: f.Page, Limit: f.Limit}
	if err := q.Count(&out.Total).Error; err != nil {
		return nil, err
	}
	err = q.Order("journals.journal_date DESC, journals.number DESC").
		Offset((f.Page - 1) * f.Limit).Limit(f.Limit).Find(&out.Journals).Error
	return out, err
}

// Journal loads one journal with its lines, who made it and what reversed it.
func (s *Service) Journal(ctx context.Context, id string) (*Journal, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	return findJournal(ctx, s.db, saccoID, id)
}

func findJournal(ctx context.Context, db *gorm.DB, saccoID, id string) (*Journal, error) {
	var j Journal
	err := db.WithContext(ctx).Table("journals").Select("journals.*, users.username AS created_by").
		Joins("LEFT JOIN users ON users.id = journals.created_by_id").
		Where("journals.sacco_id = ? AND journals.id = ?", saccoID, id).Take(&j).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("%w: journal not found", ErrNotFound)
	}
	if err != nil {
		return nil, err
	}
	if err := db.WithContext(ctx).Table("journal_lines l").
		Select("l.*, a.code AS account_code, a.name AS account_name").
		Joins("JOIN ledger_accounts a ON a.id = l.account_id").
		Where("l.journal_id = ?", j.ID).Order("l.line_no").Scan(&j.Lines).Error; err != nil {
		return nil, err
	}
	number := func(id *string) *int64 {
		if id == nil {
			return nil
		}
		var n int64
		if db.WithContext(ctx).Model(&Journal{}).Select("number").Where("id = ?", *id).Scan(&n).Error != nil {
			return nil
		}
		return &n
	}
	j.ReversesNumber, j.ReversedByNumber = number(j.ReversesID), number(j.ReversedByID)
	return &j, nil
}

// JournalLineRequest is one line of a manual journal: a debit or a credit.
type JournalLineRequest struct {
	AccountID string  `json:"account_id"`
	Debit     float64 `json:"debit,omitempty" minimum:"0"`
	Credit    float64 `json:"credit,omitempty" minimum:"0"`
	Memo      string  `json:"memo,omitempty" maxLength:"200"`
}

// JournalRequest is a manual journal.
type JournalRequest struct {
	Date      string               `json:"date" doc:"YYYY-MM-DD, from the start of the books to today"`
	Memo      string               `json:"memo" maxLength:"300" doc:"What the journal is for"`
	Reference string               `json:"reference,omitempty" maxLength:"100"`
	Lines     []JournalLineRequest `json:"lines" minItems:"2" maxItems:"50"`
}

// CreateJournal records the accountant's own journal. It must balance and
// may not use accounts kept from records (customers, farmers, pay due, cash
// accounts): those change only through the records, so the books keep
// agreeing with them.
func (s *Service) CreateJournal(ctx context.Context, req *JournalRequest) (*Journal, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	memo := strings.TrimSpace(req.Memo)
	if len(memo) < 3 {
		return nil, fmt.Errorf("%w: say what the journal is for", ErrInvalid)
	}
	day, err := time.Parse(dateLayout, strings.TrimSpace(req.Date))
	if err != nil {
		return nil, fmt.Errorf("%w: choose the journal's date", ErrInvalid)
	}
	if day.After(s.today()) {
		return nil, fmt.Errorf("%w: a journal cannot be dated in the future", ErrInvalid)
	}
	if len(req.Lines) < 2 {
		return nil, fmt.Errorf("%w: a journal needs at least one debit and one credit", ErrInvalid)
	}
	var id string
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		b, err := s.started(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		if day.Before(b.StartDate) {
			return fmt.Errorf("%w: the books start on %s; a journal cannot be dated before that", ErrInvalid, b.StartDate.Format("2 Jan 2006"))
		}
		c, err := loadChart(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		j := &Journal{Kind: KindManual, JournalDate: day, Memo: memo}
		if ref := strings.TrimSpace(req.Reference); ref != "" {
			j.Reference = &ref
		}
		var dr, cr float64
		for i, l := range req.Lines {
			a := c.accounts[l.AccountID]
			if a == nil {
				return fmt.Errorf("%w: line %d: choose an account", ErrInvalid, i+1)
			}
			if !a.IsActive {
				return fmt.Errorf("%w: line %d: %s is switched off", ErrInvalid, i+1, a.Name)
			}
			if what := c.kept(a.ID); what != "" {
				return fmt.Errorf("%w: line %d: %s follows %s; record the payment, sale, expense or transfer instead",
					ErrInvalid, i+1, a.Name, strings.ToLower(what[:1])+what[1:])
			}
			debit, credit := round2(l.Debit), round2(l.Credit)
			if (debit > 0) == (credit > 0) {
				return fmt.Errorf("%w: line %d: give either a debit or a credit", ErrInvalid, i+1)
			}
			dr, cr = dr+debit, cr+credit
			line := Line{AccountID: a.ID, Debit: debit, Credit: credit}
			if m := strings.TrimSpace(l.Memo); m != "" {
				line.Memo = &m
			}
			j.Lines = append(j.Lines, line)
		}
		if !same(dr, cr) {
			return fmt.Errorf("%w: debits (KES %.2f) and credits (KES %.2f) must be equal", ErrInvalid, dr, cr)
		}
		e := &engine{ctx: ctx, db: tx, saccoID: saccoID, actor: actor(ctx)}
		if err := e.write(j); err != nil {
			return err
		}
		if err := e.finish(); err != nil {
			return err
		}
		id = j.ID
		return audit.Record(tx, audit.Entry{SaccoID: saccoID, EntityType: "journal", EntityID: j.ID, Action: audit.ActionCreate,
			ActorID: middleware.GetUserID(ctx), NewValues: map[string]any{"number": j.Number, "date": req.Date, "memo": memo, "total": j.Total}})
	})
	if err != nil {
		return nil, err
	}
	return findJournal(ctx, s.db, saccoID, id)
}

// ReverseRequest takes back a manual journal.
type ReverseRequest struct {
	Reason string `json:"reason" doc:"Why it is being reversed"`
	Date   string `json:"date,omitempty" doc:"YYYY-MM-DD; default the journal's own date"`
}

// ReverseJournal posts a journal that takes back one of the accountant's
// journals. Journals from records are taken back by voiding or correcting
// the record, which reverses them by itself.
func (s *Service) ReverseJournal(ctx context.Context, id string, req *ReverseRequest) (*Journal, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	reason := strings.TrimSpace(req.Reason)
	if len(reason) < 3 {
		return nil, fmt.Errorf("%w: give the reason for reversing the journal", ErrInvalid)
	}
	var newID string
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		b, err := s.started(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		var j Journal
		if err := tx.Preload("Lines", func(q *gorm.DB) *gorm.DB { return q.Order("line_no") }).
			Where("sacco_id = ? AND id = ?", saccoID, id).Take(&j).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return fmt.Errorf("%w: journal not found", ErrNotFound)
			}
			return err
		}
		if j.Kind != KindManual {
			return fmt.Errorf("%w: J-%d follows a record; void or correct the record and its journal is reversed with it", ErrConflict, j.Number)
		}
		if j.ReversesID != nil {
			return fmt.Errorf("%w: J-%d is itself a reversal", ErrConflict, j.Number)
		}
		if j.ReversedByID != nil {
			return fmt.Errorf("%w: J-%d was reversed already", ErrConflict, j.Number)
		}
		day, err := parseDay(req.Date, j.JournalDate)
		if err != nil {
			return err
		}
		if day.Before(b.StartDate) || day.After(s.today()) {
			return fmt.Errorf("%w: choose a day from %s to today", ErrInvalid, b.StartDate.Format("2 Jan 2006"))
		}
		e := &engine{ctx: ctx, db: tx, saccoID: saccoID, actor: actor(ctx)}
		r, err := e.reverse(&j, day, reason, actor(ctx))
		if err != nil {
			return err
		}
		if err := e.finish(); err != nil {
			return err
		}
		newID = r.ID
		return audit.Record(tx, audit.Entry{SaccoID: saccoID, EntityType: "journal", EntityID: j.ID, Action: audit.ActionVoid,
			ActorID: middleware.GetUserID(ctx), Reason: &reason, NewValues: map[string]any{"reversed_by": r.Number}})
	})
	if err != nil {
		return nil, err
	}
	return findJournal(ctx, s.db, saccoID, newID)
}
