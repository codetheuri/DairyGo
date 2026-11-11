package finance

import (
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/audit"
)

// Bank reconciliation. The accountant imports the bank's (or M-Pesa's)
// statement for one of the Sacco's accounts and matches each of its lines to
// a movement in that account's cashbook. What is left over is the work:
// lines in the bank with nothing in DairyGo (bank charges, interest, a
// deposit not recorded: record them, then match), and movements in DairyGo
// the bank has not shown (a cheque not yet cleared, or a mistake).
//
// A cashbook movement is named by its match key: source|record id|date
// (farmers' pay is one movement per pay run and day, as the cashbook shows
// it). Each movement matches at most one statement line.

// BankStatement is a statement imported for an account.
type BankStatement struct {
	ID             string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID        string    `json:"-" gorm:"type:varchar(36)"`
	CashAccountID  string    `json:"cash_account_id" gorm:"type:varchar(36)"`
	FileName       *string   `json:"file_name,omitempty"`
	FromDate       time.Time `json:"from_date" gorm:"type:date"`
	ToDate         time.Time `json:"to_date" gorm:"type:date"`
	Lines          int       `json:"lines"`
	ClosingBalance *float64  `json:"closing_balance,omitempty" doc:"The statement's last balance, when it shows balances"`
	ImportedByID   *uint     `json:"-"`
	CreatedAt      time.Time `json:"created_at"`

	Matched int `json:"matched" gorm:"->;-:migration"`
}

// TableName sets the database table name.
func (BankStatement) TableName() string { return "bank_statements" }

// BankLine is one line of an imported statement.
type BankLine struct {
	ID            string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	StatementID   string     `json:"statement_id" gorm:"type:varchar(36)"`
	SaccoID       string     `json:"-" gorm:"type:varchar(36)"`
	CashAccountID string     `json:"-" gorm:"type:varchar(36)"`
	LineNo        int        `json:"line_no"`
	LineDate      time.Time  `json:"date" gorm:"type:date"`
	Description   string     `json:"description"`
	Reference     *string    `json:"reference,omitempty"`
	Amount        float64    `json:"amount" doc:"Positive: money into the account"`
	Balance       *float64   `json:"balance,omitempty"`
	MatchKey      *string    `json:"match_key,omitempty"`
	MatchedByID   *uint      `json:"-"`
	MatchedAt     *time.Time `json:"matched_at,omitempty"`

	// The cashbook movement it is matched to; filled for the screen.
	Movement *Movement `json:"movement,omitempty" gorm:"-"`
}

// TableName sets the database table name.
func (BankLine) TableName() string { return "bank_statement_lines" }

// Key names a cashbook movement for matching.
func (m Movement) Key() string {
	return string(m.Source) + "|" + m.RefID + "|" + m.Date.Format(dateLayout)
}

// Reconciliation is a statement against the cashbook over its dates.
type Reconciliation struct {
	Statement *BankStatement `json:"statement"`
	Account   *CashAccount   `json:"account"`
	Lines     []BankLine     `json:"lines" doc:"Every line, matched or not, in the statement's order"`
	// In DairyGo, not on any statement line: in the statement's dates.
	BookOnly        []Movement `json:"book_only"`
	Matched         int        `json:"matched"`
	BankOnly        int        `json:"bank_only" doc:"Lines with nothing in DairyGo"`
	BankOnlyTotal   float64    `json:"bank_only_total"`
	BookOnlyTotal   float64    `json:"book_only_total" doc:"Money in less money out in DairyGo the bank has not shown"`
	BookBalance     float64    `json:"book_balance" doc:"The cashbook balance at the end of the statement's last day"`
	StatementDiffer *float64   `json:"difference,omitempty" doc:"Statement closing balance less the cashbook balance, when the statement shows balances"`
}

// StatementImport is what importing a statement did (or would do).
type StatementImport struct {
	Statement  *BankStatement `json:"statement,omitempty"`
	Preview    bool           `json:"preview"`
	Lines      int            `json:"lines" doc:"New lines"`
	Duplicates int            `json:"already_imported" doc:"Lines already imported from another statement (left out)"`
	From       string         `json:"from_date,omitempty"`
	To         string         `json:"to_date,omitempty"`
	MoneyIn    float64        `json:"money_in"`
	MoneyOut   float64        `json:"money_out"`
	Problems   []string       `json:"problems"`
	AutoMatch  int            `json:"matched" doc:"Lines matched straight away"`
}

// StatementRequest imports a statement.
type StatementRequest struct {
	File     string `json:"file" doc:"The statement as base64 or a data: URL (CSV or Excel)"`
	FileName string `json:"file_name,omitempty" maxLength:"200"`
	Preview  bool   `json:"preview,omitempty" doc:"Only read the file and say what it holds"`
}

// --- reading ---

// accountMovements is an account's movements between two days (within its
// opening date), by key.
func (s *Service) accountMovements(ctx context.Context, saccoID string, a *CashAccount, from, to time.Time) ([]Movement, error) {
	all, err := s.repo.Movements(ctx, saccoID, a, to)
	if err != nil {
		return nil, err
	}
	out := all[:0]
	for _, m := range all {
		if !m.Date.Before(from) {
			out = append(out, m)
		}
	}
	return out, nil
}

// matchedKeys is every movement of an account matched to a statement line.
func (s *Service) matchedKeys(ctx context.Context, accountID string) (map[string]bool, error) {
	var keys []string
	if err := s.repo.db.WithContext(ctx).Table("bank_statement_lines").Where("cash_account_id = ? AND match_key IS NOT NULL", accountID).
		Pluck("match_key", &keys).Error; err != nil {
		return nil, err
	}
	out := make(map[string]bool, len(keys))
	for _, k := range keys {
		out[k] = true
	}
	return out, nil
}

func (s *Service) findStatement(ctx context.Context, saccoID, id string) (*BankStatement, error) {
	var st BankStatement
	err := s.repo.db.WithContext(ctx).Where("sacco_id = ? AND id = ?", saccoID, id).Take(&st).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("%w: statement not found", ErrNotFound)
	}
	return &st, err
}

// Statements lists an account's imported statements, newest first.
func (s *Service) Statements(ctx context.Context, accountID string) ([]BankStatement, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	if _, err := s.repo.FindAccount(ctx, accountID); err != nil {
		return nil, err
	}
	var out []BankStatement
	err = s.repo.db.WithContext(ctx).Table("bank_statements s").
		Select("s.*, (SELECT COUNT(*) FROM bank_statement_lines l WHERE l.statement_id = s.id AND l.match_key IS NOT NULL) AS matched").
		Where("s.sacco_id = ? AND s.cash_account_id = ?", saccoID, accountID).Order("s.to_date DESC, s.created_at DESC").Scan(&out).Error
	if out == nil {
		out = []BankStatement{}
	}
	return out, err
}

// Reconcile is a statement against the account's cashbook.
func (s *Service) Reconcile(ctx context.Context, statementID string) (*Reconciliation, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	st, err := s.findStatement(ctx, saccoID, statementID)
	if err != nil {
		return nil, err
	}
	a, err := s.repo.FindAccount(ctx, st.CashAccountID)
	if err != nil {
		return nil, err
	}
	out := &Reconciliation{Statement: st, Account: a, BookOnly: []Movement{}}
	if err := s.repo.db.WithContext(ctx).Where("statement_id = ?", st.ID).Order("line_no").Find(&out.Lines).Error; err != nil {
		return nil, err
	}
	// Movements a little either side, so lines matched across the edges are
	// described too.
	moves, err := s.accountMovements(ctx, saccoID, a, st.FromDate.AddDate(0, 0, -31), st.ToDate.AddDate(0, 0, 31))
	if err != nil {
		return nil, err
	}
	byKey := map[string]Movement{}
	for _, m := range moves {
		byKey[m.Key()] = m
	}
	for i := range out.Lines {
		l := &out.Lines[i]
		if l.MatchKey == nil {
			out.BankOnly++
			out.BankOnlyTotal += l.Amount
			continue
		}
		out.Matched++
		if m, ok := byKey[*l.MatchKey]; ok {
			m.MatchKey = m.Key()
			l.Movement = &m
		}
	}
	matched, err := s.matchedKeys(ctx, a.ID)
	if err != nil {
		return nil, err
	}
	for _, m := range moves {
		if m.Date.Before(st.FromDate) || m.Date.After(st.ToDate) || matched[m.Key()] {
			continue
		}
		m.MatchKey = m.Key()
		out.BookOnly = append(out.BookOnly, m)
		out.BookOnlyTotal += m.In - m.Out
	}
	out.BankOnlyTotal, out.BookOnlyTotal = round2(out.BankOnlyTotal), round2(out.BookOnlyTotal)
	all, err := s.repo.Movements(ctx, saccoID, a, st.ToDate)
	if err != nil {
		return nil, err
	}
	balance := a.OpeningBalance
	for _, m := range all {
		balance += m.In - m.Out
	}
	out.BookBalance = round2(balance)
	if st.ClosingBalance != nil {
		d := round2(*st.ClosingBalance - out.BookBalance)
		out.StatementDiffer = &d
	}
	return out, nil
}

// Candidates are the account's movements a statement line may be matched
// to: not matched yet, the same amount in the same direction, within a week
// either side, nearest first.
func (s *Service) Candidates(ctx context.Context, lineID string) ([]Movement, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	l, a, err := s.findLine(ctx, saccoID, lineID)
	if err != nil {
		return nil, err
	}
	moves, err := s.accountMovements(ctx, saccoID, a, l.LineDate.AddDate(0, 0, -7), l.LineDate.AddDate(0, 0, 7))
	if err != nil {
		return nil, err
	}
	matched, err := s.matchedKeys(ctx, a.ID)
	if err != nil {
		return nil, err
	}
	out := []Movement{}
	for _, m := range moves {
		if !matched[m.Key()] && sameMoney(m, l.Amount) {
			m.MatchKey = m.Key()
			out = append(out, m)
		}
	}
	sort.SliceStable(out, func(i, k int) bool { return dayGap(out[i].Date, l.LineDate) < dayGap(out[k].Date, l.LineDate) })
	return out, nil
}

func sameMoney(m Movement, amount float64) bool {
	return math.Abs(m.In-m.Out-amount) < 0.005
}

func dayGap(a, b time.Time) float64 { return math.Abs(a.Sub(b).Hours()) }

func (s *Service) findLine(ctx context.Context, saccoID, id string) (*BankLine, *CashAccount, error) {
	var l BankLine
	err := s.repo.db.WithContext(ctx).Where("sacco_id = ? AND id = ?", saccoID, id).Take(&l).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil, fmt.Errorf("%w: statement line not found", ErrNotFound)
	}
	if err != nil {
		return nil, nil, err
	}
	a, err := s.repo.FindAccount(ctx, l.CashAccountID)
	return &l, a, err
}

// --- importing ---

// ImportStatement reads a statement for an account and saves its lines,
// leaving out lines already imported (statements may overlap), then
// matches what it can.
func (s *Service) ImportStatement(ctx context.Context, accountID string, req *StatementRequest) (*StatementImport, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	a, err := s.repo.FindAccount(ctx, accountID)
	if err != nil {
		return nil, err
	}
	raw := req.File
	if i := strings.Index(raw, ","); strings.HasPrefix(raw, "data:") && i > 0 {
		raw = raw[i+1:]
	}
	data, err := base64.StdEncoding.DecodeString(raw)
	if err != nil || len(data) == 0 {
		return nil, fmt.Errorf("%w: attach the statement (CSV or Excel)", ErrInvalid)
	}
	if len(data) > 5<<20 {
		return nil, fmt.Errorf("%w: the file must be under 5 MB", ErrInvalid)
	}
	parsed, problems := ParseStatement(data)
	out := &StatementImport{Preview: req.Preview || len(problems) > 0, Problems: problems}
	if out.Problems == nil {
		out.Problems = []string{}
	}
	if len(parsed) == 0 {
		return out, nil
	}
	// Lines already imported (an overlapping statement) are left out.
	var have []struct {
		LineDate    time.Time
		Amount      float64
		Reference   *string
		Description string
	}
	from, to := parsed[0].Date, parsed[0].Date
	for _, p := range parsed {
		if p.Date.Before(from) {
			from = p.Date
		}
		if p.Date.After(to) {
			to = p.Date
		}
	}
	if err := s.repo.db.WithContext(ctx).Table("bank_statement_lines").Select("line_date, amount, reference, description").
		Where("cash_account_id = ? AND line_date BETWEEN ? AND ?", a.ID, from.Format(dateLayout), to.Format(dateLayout)).
		Scan(&have).Error; err != nil {
		return nil, err
	}
	key := func(d time.Time, amount float64, ref, desc string) string {
		return fmt.Sprintf("%s|%.2f|%s|%s", d.Format(dateLayout), amount, strings.ToUpper(ref), strings.ToUpper(desc))
	}
	seen := map[string]int{}
	for _, h := range have {
		ref := ""
		if h.Reference != nil {
			ref = *h.Reference
		}
		seen[key(h.LineDate, round2(h.Amount), ref, h.Description)]++
	}
	var fresh []ParsedLine
	for _, p := range parsed {
		k := key(p.Date, p.Amount, p.Reference, p.Description)
		if seen[k] > 0 {
			seen[k]--
			out.Duplicates++
			continue
		}
		fresh = append(fresh, p)
		if p.Amount > 0 {
			out.MoneyIn += p.Amount
		} else {
			out.MoneyOut -= p.Amount
		}
	}
	out.Lines, out.From, out.To = len(fresh), from.Format(dateLayout), to.Format(dateLayout)
	out.MoneyIn, out.MoneyOut = round2(out.MoneyIn), round2(out.MoneyOut)
	if out.Preview || len(fresh) == 0 {
		return out, nil
	}
	st := &BankStatement{ID: uuid.New().String(), SaccoID: saccoID, CashAccountID: a.ID, FromDate: from, ToDate: to,
		Lines: len(fresh), ImportedByID: actor(ctx), CreatedAt: time.Now()}
	if name := strings.TrimSpace(req.FileName); name != "" {
		st.FileName = &name
	}
	// The closing balance is the balance on the last line in date order.
	last := parsed[len(parsed)-1]
	if parsed[0].Date.After(last.Date) {
		last = parsed[0] // newest first, as M-Pesa lists them
	}
	st.ClosingBalance = last.Balance
	lines := make([]BankLine, len(fresh))
	for i, p := range fresh {
		lines[i] = BankLine{ID: uuid.New().String(), StatementID: st.ID, SaccoID: saccoID, CashAccountID: a.ID, LineNo: i + 1,
			LineDate: p.Date, Description: p.Description, Amount: p.Amount, Balance: p.Balance}
		if p.Reference != "" {
			ref := p.Reference
			lines[i].Reference = &ref
		}
	}
	err = s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(st).Error; err != nil {
			return err
		}
		if err := tx.CreateInBatches(lines, 200).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry(saccoID, "bank_statement", st.ID, audit.ActionCreate, ctx, nil,
			map[string]any{"account": a.Name, "from": out.From, "to": out.To, "lines": st.Lines, "file": st.FileName}))
	})
	if err != nil {
		return nil, err
	}
	out.Statement = st
	if out.AutoMatch, err = s.autoMatch(ctx, saccoID, st, a); err != nil {
		return nil, err
	}
	return out, nil
}

// DeleteStatement removes an imported statement and its matches (imported
// by mistake); the cashbook is not touched.
func (s *Service) DeleteStatement(ctx context.Context, id string) error {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return err
	}
	st, err := s.findStatement(ctx, saccoID, id)
	if err != nil {
		return err
	}
	return s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Delete(&BankStatement{}, "id = ?", st.ID).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry(saccoID, "bank_statement", st.ID, audit.ActionDelete, ctx, st, nil))
	})
}

// --- matching ---

// AutoMatch matches every unmatched line of a statement that has exactly
// one candidate: the same amount within three days, a reference in common
// deciding between several.
func (s *Service) AutoMatch(ctx context.Context, statementID string) (int, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return 0, err
	}
	st, err := s.findStatement(ctx, saccoID, statementID)
	if err != nil {
		return 0, err
	}
	a, err := s.repo.FindAccount(ctx, st.CashAccountID)
	if err != nil {
		return 0, err
	}
	return s.autoMatch(ctx, saccoID, st, a)
}

func (s *Service) autoMatch(ctx context.Context, saccoID string, st *BankStatement, a *CashAccount) (int, error) {
	var lines []BankLine
	if err := s.repo.db.WithContext(ctx).Where("statement_id = ? AND match_key IS NULL", st.ID).Order("line_date, line_no").
		Find(&lines).Error; err != nil {
		return 0, err
	}
	moves, err := s.accountMovements(ctx, saccoID, a, st.FromDate.AddDate(0, 0, -3), st.ToDate.AddDate(0, 0, 3))
	if err != nil {
		return 0, err
	}
	taken, err := s.matchedKeys(ctx, a.ID)
	if err != nil {
		return 0, err
	}
	pairs := map[string]string{} // line id → movement key
	for _, l := range lines {
		var near, byRef []Movement
		for _, m := range moves {
			if taken[m.Key()] || !sameMoney(m, l.Amount) || dayGap(m.Date, l.LineDate) > 72 {
				continue
			}
			near = append(near, m)
			if sharesReference(m, l) {
				byRef = append(byRef, m)
			}
		}
		pick := near
		if len(byRef) > 0 {
			pick = byRef
		}
		if len(pick) != 1 {
			continue // none, or too many to choose between: the accountant decides
		}
		k := pick[0].Key()
		taken[k] = true
		pairs[l.ID] = k
	}
	if len(pairs) == 0 {
		return 0, nil
	}
	now, by := time.Now(), actor(ctx)
	err = s.repo.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		for id, k := range pairs {
			if err := tx.Model(&BankLine{}).Where("id = ? AND match_key IS NULL", id).
				Updates(map[string]any{"match_key": k, "matched_at": now, "matched_by_id": by}).Error; err != nil {
				return err
			}
		}
		return nil
	})
	return len(pairs), err
}

// sharesReference says a movement and a statement line carry the same
// reference (an M-Pesa code, a cheque number).
func sharesReference(m Movement, l BankLine) bool {
	if m.Reference == nil || strings.TrimSpace(*m.Reference) == "" {
		return false
	}
	ref := strings.ToUpper(strings.TrimSpace(*m.Reference))
	if l.Reference != nil && strings.EqualFold(strings.TrimSpace(*l.Reference), ref) {
		return true
	}
	return len(ref) >= 4 && strings.Contains(strings.ToUpper(l.Description), ref)
}

// Match matches a statement line to a cashbook movement of the same
// account and amount.
func (s *Service) Match(ctx context.Context, lineID, key string) (*BankLine, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	l, a, err := s.findLine(ctx, saccoID, lineID)
	if err != nil {
		return nil, err
	}
	if l.MatchKey != nil {
		return nil, fmt.Errorf("%w: this line is matched already; unmatch it first", ErrConflict)
	}
	parts := strings.Split(key, "|")
	if len(parts) != 3 {
		return nil, fmt.Errorf("%w: choose a movement from the cashbook", ErrInvalid)
	}
	day, err := time.Parse(dateLayout, parts[2])
	if err != nil {
		return nil, fmt.Errorf("%w: choose a movement from the cashbook", ErrInvalid)
	}
	moves, err := s.accountMovements(ctx, saccoID, a, day, day)
	if err != nil {
		return nil, err
	}
	var m *Movement
	for i := range moves {
		if moves[i].Key() == key {
			m = &moves[i]
		}
	}
	if m == nil {
		return nil, fmt.Errorf("%w: that movement is not in %s's cashbook", ErrNotFound, a.Name)
	}
	if !sameMoney(*m, l.Amount) {
		return nil, fmt.Errorf("%w: the amounts differ (statement %s, cashbook %s)", ErrInvalid, money(l.Amount), money(m.In-m.Out))
	}
	now := time.Now()
	res := s.repo.db.WithContext(ctx).Model(&BankLine{}).Where("id = ? AND match_key IS NULL", l.ID).
		Updates(map[string]any{"match_key": key, "matched_at": now, "matched_by_id": actor(ctx)})
	if res.Error != nil {
		if strings.Contains(res.Error.Error(), "uq_bank_statement_lines_match") {
			return nil, fmt.Errorf("%w: that movement is matched to another line already", ErrConflict)
		}
		return nil, res.Error
	}
	m.MatchKey = key
	l.MatchKey, l.MatchedAt, l.Movement = &key, &now, m
	return l, nil
}

// Unmatch undoes a match.
func (s *Service) Unmatch(ctx context.Context, lineID string) (*BankLine, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	l, _, err := s.findLine(ctx, saccoID, lineID)
	if err != nil {
		return nil, err
	}
	if err := s.repo.db.WithContext(ctx).Model(&BankLine{}).Where("id = ?", l.ID).
		Updates(map[string]any{"match_key": nil, "matched_at": nil, "matched_by_id": nil}).Error; err != nil {
		return nil, err
	}
	l.MatchKey, l.MatchedAt = nil, nil
	return l, nil
}
