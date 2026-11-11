package finance

import (
	"context"
	"strings"
	"time"

	"gorm.io/gorm"
)

// Which account money went through. Every payment in or out names the Sacco
// account it used, so each account's cashbook and balance are complete. When
// the person recording does not choose one (an older app, a quick sale), the
// money goes to the Sacco's account for that way of paying: cash to its cash
// account, M-Pesa to its M-Pesa account, bank transfers and cheques to its
// bank. With two accounts of a kind, the one opened first is used; the
// person recording can always choose another.

// KindFor is the kind of account money paid by method goes through.
func KindFor(method string) Kind {
	switch strings.ToUpper(strings.TrimSpace(method)) {
	case "MPESA", "M-PESA":
		return KindMpesa
	case "BANK", "BANK_TRANSFER", "CHEQUE", "CHECK":
		return KindBank
	default:
		return KindCash
	}
}

// AccountChoice is an account someone recording money may choose.
type AccountChoice struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Kind      string    `json:"kind"`
	CreatedAt time.Time `json:"-"`
}

// defaultsByKind is the account used for each kind when none is chosen: the
// one opened first. accounts are active ones, oldest first.
func defaultsByKind(accounts []AccountChoice) map[string]string {
	out := map[string]string{}
	for _, a := range accounts {
		if _, ok := out[a.Kind]; !ok {
			out[a.Kind] = a.ID
		}
	}
	return out
}

// activeChoices lists a Sacco's accounts in use, oldest first.
func activeChoices(ctx context.Context, db *gorm.DB, saccoID string) ([]AccountChoice, error) {
	var out []AccountChoice
	err := db.WithContext(ctx).Table("cash_accounts").Select("id, name, kind, created_at").
		Where("sacco_id = ? AND is_active = ?", saccoID, true).
		Order("created_at, name").Scan(&out).Error
	return out, err
}

// AccountFor is the account money paid by method went through: the one
// given (checked to be the Sacco's and in use), or else the Sacco's account
// for that way of paying. Nil when the Sacco keeps no account of that kind,
// so nothing is refused for want of one.
func AccountFor(ctx context.Context, db *gorm.DB, saccoID, given, method string) (*string, error) {
	if given = strings.TrimSpace(given); given != "" {
		if err := ActiveAccount(ctx, db, saccoID, given); err != nil {
			return nil, err
		}
		return &given, nil
	}
	accounts, err := activeChoices(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	if id, ok := defaultsByKind(accounts)[string(KindFor(method))]; ok {
		return &id, nil
	}
	return nil, nil
}

// AccountChoices lists the accounts someone recording money may choose, with
// the one each way of paying goes to when none is chosen.
func (s *Service) AccountChoices(ctx context.Context) ([]AccountChoice, map[string]string, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, nil, err
	}
	accounts, err := activeChoices(ctx, s.repo.db, saccoID)
	if err != nil {
		return nil, nil, err
	}
	if accounts == nil {
		accounts = []AccountChoice{}
	}
	return accounts, defaultsByKind(accounts), nil
}
