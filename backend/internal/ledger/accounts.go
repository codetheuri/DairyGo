package ledger

import (
	"context"
	"fmt"
	"regexp"
	"sort"
	"strings"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// --- the chart of accounts ---

// Accounts lists the chart by code with each balance now.
func (s *Service) Accounts(ctx context.Context) ([]LedgerAccount, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	if _, err := s.started(ctx, db, saccoID); err != nil {
		return nil, err
	}
	c, err := loadChart(ctx, db, saccoID)
	if err != nil {
		return nil, err
	}
	net, err := balances(ctx, db, saccoID, nil)
	if err != nil {
		return nil, err
	}
	var used []string
	if err := db.Table("journal_lines").Distinct("account_id").Where("sacco_id = ?", saccoID).Pluck("account_id", &used).Error; err != nil {
		return nil, err
	}
	isUsed := map[string]bool{}
	for _, id := range used {
		isUsed[id] = true
	}
	out := make([]LedgerAccount, 0, len(c.accounts))
	for _, a := range c.accounts {
		row := *a
		row.Balance = net[a.ID]
		if !a.Type.DebitNormal() {
			row.Balance = -row.Balance
		}
		row.Balance = round2(row.Balance)
		row.Used = isUsed[a.ID]
		row.KeptBy = c.kept(a.ID)
		row.Kept = row.KeptBy != ""
		out = append(out, row)
	}
	sort.Slice(out, func(i, k int) bool { return codeLess(out[i].Code, out[k].Code) })
	return out, nil
}

// codeLess orders codes as numbers when both are numbers ("900" before
// "1000"), otherwise as text.
func codeLess(a, b string) bool {
	if len(a) != len(b) && isDigits(a) && isDigits(b) {
		return len(a) < len(b)
	}
	return a < b
}

func isDigits(s string) bool {
	for _, r := range s {
		if r < '0' || r > '9' {
			return false
		}
	}
	return s != ""
}

var codePattern = regexp.MustCompile(`^[A-Za-z0-9.\-]{1,20}$`)

// AccountRequest adds or changes an account.
type AccountRequest struct {
	Code        string  `json:"code" maxLength:"20" doc:"Up to 20 letters, digits, dots or dashes, e.g. 6100"`
	Name        string  `json:"name" maxLength:"120"`
	Type        Type    `json:"type,omitempty" enum:"ASSET,LIABILITY,EQUITY,INCOME,EXPENSE" doc:"Needed for a new account; can change only while nothing has posted to it"`
	Description *string `json:"description,omitempty"`
	IsActive    *bool   `json:"is_active,omitempty" doc:"False switches it off: nothing new can post to it; its history stays"`
}

// SaveAccount adds an account (id "") or changes one.
func (s *Service) SaveAccount(ctx context.Context, id string, req *AccountRequest) (*LedgerAccount, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	code, name := strings.TrimSpace(req.Code), strings.TrimSpace(req.Name)
	if !codePattern.MatchString(code) {
		return nil, fmt.Errorf("%w: give the account a code of up to 20 letters or digits, e.g. 6100", ErrInvalid)
	}
	if len(name) < 2 {
		return nil, fmt.Errorf("%w: give the account a name", ErrInvalid)
	}
	var saved LedgerAccount
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if _, err := s.started(ctx, tx, saccoID); err != nil {
			return err
		}
		c, err := loadChart(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		entry := audit.Entry{SaccoID: saccoID, EntityType: "ledger_account", ActorID: middleware.GetUserID(ctx)}
		var a *LedgerAccount
		if id == "" {
			if !req.Type.Valid() {
				return fmt.Errorf("%w: choose what the account records: asset, liability, equity, income or expense", ErrInvalid)
			}
			if c.codes[code] {
				return fmt.Errorf("%w: code %s is already used", ErrConflict, code)
			}
			desc := ""
			if req.Description != nil {
				desc = strings.TrimSpace(*req.Description)
			}
			if a, err = c.create(code, name, req.Type, desc); err != nil {
				return err
			}
			entry.Action = audit.ActionCreate
		} else {
			a = c.accounts[id]
			if a == nil {
				return fmt.Errorf("%w: account not found", ErrNotFound)
			}
			before := *a
			if code != a.Code && c.codes[code] {
				return fmt.Errorf("%w: code %s is already used", ErrConflict, code)
			}
			if req.Type != "" && req.Type != a.Type {
				if !req.Type.Valid() {
					return fmt.Errorf("%w: choose asset, liability, equity, income or expense", ErrInvalid)
				}
				var n int64
				if err := tx.Model(&Line{}).Where("account_id = ?", a.ID).Count(&n).Error; err != nil {
					return err
				}
				if n > 0 {
					return fmt.Errorf("%w: entries have posted to %s, so what it records cannot change; add a new account instead", ErrConflict, a.Name)
				}
				if err := linkAllows(c, a.ID, req.Type); err != nil {
					return err
				}
				a.Type = req.Type
			}
			if req.IsActive != nil && !*req.IsActive && a.IsActive {
				if linked := linkedTo(c, a.ID); linked != "" {
					return fmt.Errorf("%w: %s posts to this account; point it at another account first (Where records post)", ErrConflict, linked)
				}
			}
			a.Code, a.Name = code, name
			if req.Description != nil {
				d := strings.TrimSpace(*req.Description)
				a.Description = &d
				if d == "" {
					a.Description = nil
				}
			}
			if req.IsActive != nil {
				a.IsActive = *req.IsActive
			}
			a.UpdatedAt = time.Now()
			if err := tx.Save(a).Error; err != nil {
				return err
			}
			entry.Action, entry.OldValues = audit.ActionUpdate, before
		}
		entry.EntityID, entry.NewValues = a.ID, a
		saved = *a
		return audit.Record(tx, entry)
	})
	if err != nil {
		return nil, err
	}
	return &saved, nil
}

// linkedTo names something that posts to an account, or "" when nothing does.
func linkedTo(c *chart, accountID string) string {
	for key, id := range c.links {
		if id == accountID {
			return linkName(c, key)
		}
	}
	return ""
}

// keptByOther says an account is kept by a role, or by records of another
// kind than kind.
func keptByOther(c *chart, accountID, kind string) bool {
	for key, id := range c.links {
		if id != accountID {
			continue
		}
		k, rest := splitKey(key)
		if k == "role" {
			if _, ok := keptRoles[Role(rest)]; ok {
				return true
			}
		}
		if (k == "cash_account" || k == "payee") && k != kind {
			return true
		}
	}
	return false
}

// linkAllows checks every link to an account accepts type t.
func linkAllows(c *chart, accountID string, t Type) error {
	for key, id := range c.links {
		if id != accountID {
			continue
		}
		ok := false
		for _, at := range allowedTypes(key) {
			ok = ok || at == t
		}
		if !ok {
			return fmt.Errorf("%w: %s posts to this account and needs another type", ErrConflict, linkName(c, key))
		}
	}
	return nil
}

// --- where records post ---

// LinkRow is one kind of record and the account it posts to.
type LinkRow struct {
	Key          string `json:"key"`
	Group        string `json:"group" doc:"CASH_ACCOUNTS, EXPENSE_CATEGORIES, DEDUCTIONS or RECORDS"`
	Name         string `json:"name"`
	Detail       string `json:"detail,omitempty"`
	AccountID    string `json:"account_id"`
	AccountCode  string `json:"account_code"`
	AccountName  string `json:"account_name"`
	AllowedTypes []Type `json:"allowed_types"`
}

// linkName names a link key for people, using the record's current name.
func linkName(c *chart, key string) string {
	kind, id := splitKey(key)
	db := c.db.WithContext(c.ctx)
	var name string
	switch kind {
	case "role":
		if s, ok := seedFor(Role(id)); ok {
			return s.Name
		}
	case "cash_account":
		db.Table("cash_accounts").Select("name").Where("id = ?", id).Scan(&name)
	case "expense_category":
		db.Table("expense_categories").Select("name").Where("id = ?", id).Scan(&name)
	case "income_category":
		db.Table("income_categories").Select("name").Where("id = ?", id).Scan(&name)
	case "deduction_type", "savings":
		db.Table("deduction_types").Select("name").Where("id = ?", id).Scan(&name)
	case "payee":
		db.Table("suppliers").Select("name").Where("id = ?", id).Scan(&name)
	}
	if name == "" {
		return key
	}
	return name
}

var roleDetail = map[Role]string{
	RoleCustomers: "Milk sold on credit, less customers' payments", RoleFarmers: "Advances, charges and adjustments; milk and deductions from pay runs",
	RolePayDue: "Net pay when a pay run is approved, until it is sent", RoleNoAccount: "Money recorded without naming an account",
	RoleMilkSales: "Every milk sale", RoleMilkPurchases: "Farmers' milk when a pay run is approved", RoleCharges: "Charges to farmers",
	RoleAdjustments: "Adjustments to farmers' accounts", RoleOpening: "Opening balances: cash accounts, shares and the accountant's own", RoleRetained: "Income less expenses before the books started",
	RoleSuppliers: "Bills, until they are paid", RoleShareCapital: "Opening shares and refunds; savings deductions start here too",
}

// Links lists where each kind of record posts: every cash account, expense
// category and deduction, and the accounts the records use by role.
func (s *Service) Links(ctx context.Context) ([]LinkRow, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	db := s.db.WithContext(ctx)
	if _, err := s.started(ctx, db, saccoID); err != nil {
		return nil, err
	}
	var out []LinkRow
	err = db.Transaction(func(tx *gorm.DB) error {
		c, err := loadChart(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		// A new cash account, category or deduction gets its account here,
		// so the list is complete before anything has posted.
		if err := c.seedAll(); err != nil {
			return err
		}
		type item struct {
			ID, Name, Detail string
		}
		groups := []struct {
			group string
			sql   string
			key   func(string) string
		}{
			{"CASH_ACCOUNTS", `SELECT id, name, CASE kind WHEN 'MPESA' THEN 'M-Pesa' WHEN 'BANK' THEN 'Bank' ELSE 'Cash' END
				|| CASE WHEN is_active THEN '' ELSE ' (switched off)' END AS detail
				FROM cash_accounts WHERE sacco_id = ? ORDER BY created_at, name`, cashKey},
			{"EXPENSE_CATEGORIES", `SELECT id, name, CASE WHEN is_active THEN '' ELSE 'Switched off' END AS detail
				FROM expense_categories WHERE sacco_id = ? ORDER BY name`, categoryKey},
			{"INCOME_CATEGORIES", `SELECT id, name, CASE WHEN is_active THEN '' ELSE 'Switched off' END AS detail
				FROM income_categories WHERE sacco_id = ? ORDER BY name`, incomeCategoryKey},
			{"DEDUCTIONS", `SELECT id, name, 'Kept by the Sacco' AS detail
				FROM deduction_types WHERE sacco_id = ? AND deleted_at IS NULL AND goes_to = 'INCOME' ORDER BY priority, name`, deductionKey},
			{"DEDUCTIONS", `SELECT id, name, 'Savings (the farmers'' own)' AS detail
				FROM deduction_types WHERE sacco_id = ? AND deleted_at IS NULL AND goes_to = 'SAVINGS' ORDER BY priority, name`, savingsKey},
			{"PAYEES", `SELECT s.id, s.name, 'Taken from farmers'' pay: ' || STRING_AGG(t.name, ', ' ORDER BY t.priority, t.name) AS detail
				FROM suppliers s JOIN deduction_types t ON t.payee_id = s.id AND t.deleted_at IS NULL
				WHERE s.sacco_id = ? GROUP BY s.id, s.name ORDER BY s.name`, payeeKey},
		}
		row := func(group, key, name, detail string) error {
			a, err := c.account(key)
			if err != nil {
				return err
			}
			out = append(out, LinkRow{Key: key, Group: group, Name: name, Detail: detail, AccountID: a.ID,
				AccountCode: a.Code, AccountName: a.Name, AllowedTypes: allowedTypes(key)})
			return nil
		}
		for _, g := range groups {
			var items []item
			if err := tx.Raw(g.sql, saccoID).Scan(&items).Error; err != nil {
				return err
			}
			for _, it := range items {
				if err := row(g.group, g.key(it.ID), it.Name, it.Detail); err != nil {
					return err
				}
			}
		}
		for _, sd := range seedChart {
			if sd.Role != "" {
				if err := row("RECORDS", roleKey(sd.Role), sd.Name, roleDetail[sd.Role]); err != nil {
					return err
				}
			}
		}
		return nil
	})
	return out, err
}

// SetLinkRequest points a kind of record at another account.
type SetLinkRequest struct {
	Key       string `json:"key" doc:"From the list, e.g. expense_category:<id> or role:CUSTOMERS"`
	AccountID string `json:"account_id"`
}

// SetLink changes where a kind of record posts from now on. Journals
// already posted stay where they are; the accountant moves an old balance
// with a manual journal if they want it moved.
func (s *Service) SetLink(ctx context.Context, req *SetLinkRequest) ([]LinkRow, error) {
	saccoID, err := s.saccoID(ctx)
	if err != nil {
		return nil, err
	}
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if _, err := s.started(ctx, tx, saccoID); err != nil {
			return err
		}
		c, err := loadChart(ctx, tx, saccoID)
		if err != nil {
			return err
		}
		key := strings.TrimSpace(req.Key)
		allowed := allowedTypes(key)
		if allowed == nil {
			return fmt.Errorf("%w: unknown kind of record", ErrInvalid)
		}
		if _, err := c.account(key); err != nil { // the record exists and is the Sacco's
			return fmt.Errorf("%w: unknown kind of record", ErrInvalid)
		}
		a := c.accounts[req.AccountID]
		if a == nil {
			return fmt.Errorf("%w: account not found", ErrNotFound)
		}
		if !a.IsActive {
			return fmt.Errorf("%w: %s is switched off", ErrConflict, a.Name)
		}
		ok := false
		for _, t := range allowed {
			ok = ok || t == a.Type
		}
		if !ok {
			return fmt.Errorf("%w: %s must post to %s account", ErrInvalid, linkName(c, key), typeList(allowed))
		}
		old := c.links[key]
		if old == a.ID {
			return nil
		}
		// An account kept from records takes only those records, or the
		// check against them would fail; cash accounts may share one.
		// Cash accounts may share an account with each other, and payees
		// with each other, since the check sums them by account.
		kind, _ := splitKey(key)
		if what := c.kept(a.ID); what != "" && ((kind != "cash_account" && kind != "payee") || keptByOther(c, a.ID, kind)) {
			return fmt.Errorf("%w: %s follows %s; choose another account", ErrConflict, a.Name, strings.ToLower(what[:1])+what[1:])
		}
		if err := c.link(key, a.ID); err != nil {
			return err
		}
		_, recordID := splitKey(key)
		return audit.Record(tx, audit.Entry{SaccoID: saccoID, EntityType: "ledger_link", EntityID: recordID, Action: audit.ActionUpdate,
			ActorID: middleware.GetUserID(ctx), OldValues: map[string]any{"key": key, "account_id": old},
			NewValues: map[string]any{"key": key, "account_id": a.ID}})
	})
	if err != nil {
		return nil, err
	}
	return s.Links(ctx)
}

func typeList(ts []Type) string {
	words := map[Type]string{Asset: "an asset", Liability: "a liability", Equity: "an equity", Income: "an income", Expense: "an expense"}
	parts := make([]string, len(ts))
	for i, t := range ts {
		parts[i] = words[t]
	}
	if len(parts) == 1 {
		return parts[0]
	}
	return strings.Join(parts[:len(parts)-1], ", ") + " or " + strings.TrimPrefix(strings.TrimPrefix(parts[len(parts)-1], "an "), "a ")
}
