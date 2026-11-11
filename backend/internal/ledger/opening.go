package ledger

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/response"
)

// Opening balances. The books' opening journal (dated the start date) is
// worked out from every record dated before it: cash accounts' opening
// balances, what customers and farmers owed, shares, bills. What no record
// holds (a cooler bought years ago, a bank loan) the accountant types in
// here, one amount per account; Opening balances takes the other side, and
// the opening journal is posted again with them.

// OpeningLine is one of the accountant's opening balances.
type OpeningLine struct {
	ID          string    `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID     string    `json:"-" gorm:"type:varchar(36)"`
	AccountID   string    `json:"account_id" gorm:"type:varchar(36)"`
	Debit       float64   `json:"debit"`
	Credit      float64   `json:"credit"`
	Memo        *string   `json:"memo,omitempty"`
	CreatedByID *uint     `json:"-"`
	CreatedAt   time.Time `json:"-"`
	UpdatedAt   time.Time `json:"updated_at"`

	AccountCode string `json:"account_code,omitempty" gorm:"->;-:migration"`
	AccountName string `json:"account_name,omitempty" gorm:"->;-:migration"`
	AccountType Type   `json:"account_type,omitempty" gorm:"->;-:migration"`
}

// TableName sets the database table name.
func (OpeningLine) TableName() string { return "ledger_opening_lines" }

// OpeningBalances is the opening journal as posted, and the accountant's
// own lines in it.
type OpeningBalances struct {
	StartDate time.Time     `json:"start_date"`
	Journal   *Journal      `json:"journal,omitempty" doc:"The opening journal now; none when nothing came before the start"`
	Own       []OpeningLine `json:"own" doc:"Balances the accountant typed in"`
}

// OpeningLineRequest sets one account's opening balance.
type OpeningLineRequest struct {
	AccountID string  `json:"account_id"`
	Debit     float64 `json:"debit,omitempty" minimum:"0" doc:"For an asset"`
	Credit    float64 `json:"credit,omitempty" minimum:"0" doc:"For a liability or equity"`
	Memo      string  `json:"memo,omitempty" maxLength:"500"`
}

// OpeningBalances reads the opening journal and the accountant's lines.
func (s *Service) OpeningBalances(ctx context.Context) (*OpeningBalances, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	b, err := s.started(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	out := &OpeningBalances{StartDate: b.StartDate, Own: []OpeningLine{}}
	if err := db.Table("ledger_opening_lines o").Select("o.*, a.code AS account_code, a.name AS account_name, a.type AS account_type").
		Joins("JOIN ledger_accounts a ON a.id = o.account_id").Where("o.sacco_id = ?", saccoID).
		Order("a.code").Scan(&out.Own).Error; err != nil {
		return nil, err
	}
	var id string
	if err := db.Table("journals").Select("id").
		Where("sacco_id = ? AND source_type = ? AND reverses_id IS NULL AND reversed_by_id IS NULL", saccoID, SrcBooks).
		Order("number DESC").Limit(1).Scan(&id).Error; err != nil {
		return nil, err
	}
	if id != "" {
		if out.Journal, err = findJournal(ctx, db, saccoID, id); err != nil {
			return nil, err
		}
	}
	return out, nil
}

// SetOpeningLine sets an account's opening balance (0 removes it) and posts
// the opening journal again.
func (s *Service) SetOpeningLine(ctx context.Context, req *OpeningLineRequest) (*OpeningBalances, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	debit, credit := round2(req.Debit), round2(req.Credit)
	if debit < 0 || credit < 0 || (debit > 0 && credit > 0) {
		return nil, fmt.Errorf("%w: give a debit or a credit, not both", ErrInvalid)
	}
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if _, err := s.started(ctx, tx, saccoID); err != nil {
			return err
		}
		c, err := loadChart(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		a := c.accounts[req.AccountID]
		if a == nil {
			return fmt.Errorf("%w: account not found", ErrNotFound)
		}
		if err := openingAllowed(c, a); err != nil {
			return err
		}
		var line OpeningLine
		found := tx.Where("sacco_id = ? AND account_id = ?", saccoID, a.ID).Limit(1).Find(&line).RowsAffected > 0
		before := line
		action := audit.ActionUpdate
		switch {
		case debit == 0 && credit == 0 && !found:
			return nil
		case debit == 0 && credit == 0:
			if err := tx.Delete(&line).Error; err != nil {
				return err
			}
			action = audit.ActionDelete
		default:
			if !found {
				line = OpeningLine{ID: uuid.New().String(), SaccoID: saccoID, AccountID: a.ID, CreatedByID: actor(ctx)}
				action = audit.ActionCreate
			}
			line.Debit, line.Credit = debit, credit
			line.Memo = nil
			if m := strings.TrimSpace(req.Memo); m != "" {
				line.Memo = &m
			}
			if err := tx.Save(&line).Error; err != nil {
				return err
			}
		}
		// The history line also brings the opening journal up to date (see
		// hook.go).
		en := audit.Entry{SaccoID: saccoID, EntityType: "ledger_opening", EntityID: line.ID, Action: action,
			ActorID: middleware.GetUserID(ctx), NewValues: map[string]any{"account": a.Code + " " + a.Name, "debit": debit, "credit": credit}}
		if found {
			en.OldValues = map[string]any{"account": a.Code + " " + a.Name, "debit": before.Debit, "credit": before.Credit}
		}
		return audit.Record(tx, en)
	})
	if err != nil {
		return nil, err
	}
	return s.OpeningBalances(ctx)
}

// openingAllowed checks an account can take a typed-in opening balance:
// a balance sheet account no record keeps (those come from the records
// before the start), and not Opening balances itself.
func openingAllowed(c *chart, a *LedgerAccount) error {
	if !a.IsActive {
		return fmt.Errorf("%w: %s is switched off", ErrConflict, a.Name)
	}
	if a.Type == Income || a.Type == Expense {
		return fmt.Errorf("%w: opening balances are for assets, liabilities and equity; income and expenses before the start are in Retained surplus", ErrInvalid)
	}
	if c.links[roleKey(RoleOpening)] == a.ID {
		return fmt.Errorf("%w: %s takes the other side of every opening balance", ErrInvalid, a.Name)
	}
	if what := c.kept(a.ID); what != "" {
		return fmt.Errorf("%w: %s follows %s; its opening balance comes from the records dated before the start",
			ErrConflict, a.Name, strings.ToLower(what[:1])+what[1:])
	}
	return nil
}

// --- HTTP ---

type OpeningBalancesData struct {
	Opening *OpeningBalances `json:"opening"`
}

type OpeningBalancesOutput struct {
	Body response.Data[OpeningBalancesData]
}

type SetOpeningLineInput struct {
	Body OpeningLineRequest
}

func (h *Handler) OpeningBalances(ctx context.Context, _ *struct{}) (*OpeningBalancesOutput, error) {
	o, err := h.service.OpeningBalances(ctx)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &OpeningBalancesOutput{}
	out.Body.Success, out.Body.Message = true, "Opening balances"
	out.Body.Data.Opening = o
	return out, nil
}

func (h *Handler) SetOpeningLine(ctx context.Context, in *SetOpeningLineInput) (*OpeningBalancesOutput, error) {
	o, err := h.service.SetOpeningLine(ctx, &in.Body)
	if err != nil {
		return nil, h.toHTTPError(err)
	}
	out := &OpeningBalancesOutput{}
	out.Body.Success, out.Body.Message = true, "Opening balance saved"
	out.Body.Data.Opening = o
	return out, nil
}
