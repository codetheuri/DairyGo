package ledger

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Role is a ledger account the records post to by what it is for rather
// than by a cash account, category or deduction.
type Role string

const (
	RoleNoAccount     Role = "NO_ACCOUNT"     // money recorded without naming an account
	RoleCustomers     Role = "CUSTOMERS"      // what customers owe
	RoleFarmers       Role = "FARMERS"        // farmers' accounts: what they owe the Sacco
	RolePayDue        Role = "PAY_DUE"        // farmers' pay approved, not yet sent
	RoleRetained      Role = "RETAINED"       // surplus from earlier years
	RoleOpening       Role = "OPENING"        // the other side of opening balances
	RoleMilkSales     Role = "MILK_SALES"     // milk sold
	RoleCharges       Role = "CHARGES"        // charges to farmers (feeds, services)
	RoleMilkPurchases Role = "MILK_PURCHASES" // milk bought from farmers
	RoleAdjustments   Role = "ADJUSTMENTS"    // corrections to farmers' accounts
)

// seed is an account every chart starts with.
type seed struct {
	Code string
	Name string
	Type Type
	Role Role // empty for a plain account
	Desc string
}

// seedChart is a new chart: one account per role, and a few plain ones the
// accountant is likely to need. Accounts for each cash account, expense
// category and deduction are added beside them (see linkSpecs).
var seedChart = []seed{
	{"1099", "Money not in an account", Asset, RoleNoAccount, "Payments recorded without naming the cash, bank or M-Pesa account"},
	{"1200", "Customers", Asset, RoleCustomers, "What customers owe: milk sold on credit less their payments"},
	{"1300", "Farmers' accounts", Asset, RoleFarmers, "What farmers owe the Sacco: advances and charges not yet taken from pay"},
	{"1500", "Fixed assets", Asset, "", "Buildings, coolers, motorbikes and other things the Sacco owns"},
	{"2000", "Farmers' pay due", Liability, RolePayDue, "Farmers' pay approved and not yet sent"},
	{"2100", "Suppliers", Liability, "", "What the Sacco owes suppliers"},
	{"2200", "Loans", Liability, "", "Money the Sacco has borrowed"},
	{"3200", "Retained surplus", Equity, RoleRetained, "Surplus kept from earlier periods"},
	{"3900", "Opening balances", Equity, RoleOpening, "The other side of the accounts' opening balances"},
	{"4000", "Milk sales", Income, RoleMilkSales, "Milk sold to customers"},
	{"4200", "Charges to farmers", Income, RoleCharges, "Feeds, AI, vet services and items charged to farmers"},
	{"4300", "Other income", Income, "", ""},
	{"5000", "Milk bought from farmers", Expense, RoleMilkPurchases, "Farmers' milk, from approved pay runs"},
	{"5100", "Adjustments to farmers' accounts", Expense, RoleAdjustments, "Corrections that change what farmers are owed"},
}

func seedFor(r Role) (seed, bool) {
	for _, s := range seedChart {
		if s.Role == r {
			return s, true
		}
	}
	return seed{}, false
}

// Link keys name what a record posts for.
func roleKey(r Role) string         { return "role:" + string(r) }
func cashKey(id string) string      { return "cash_account:" + id }
func categoryKey(id string) string  { return "expense_category:" + id }
func deductionKey(id string) string { return "deduction_type:" + id }
func splitKey(k string) (kind, id string) {
	kind, id, _ = strings.Cut(k, ":")
	return kind, id
}

// keptRoles follow the records: their balances must equal what the records
// say, so manual journals cannot post to them. Cash accounts are kept too.
var keptRoles = map[Role]string{
	RoleCustomers: "Customers' balances", RoleFarmers: "Farmers' accounts",
	RolePayDue: "Approved farmers' pay not yet sent", RoleNoAccount: "Payments recorded without an account",
}

// allowedTypes are the account types a link may point to.
func allowedTypes(key string) []Type {
	kind, id := splitKey(key)
	switch kind {
	case "cash_account":
		return []Type{Asset}
	case "expense_category":
		return []Type{Expense, Asset}
	case "deduction_type":
		return []Type{Income, Equity, Liability}
	case "role":
		if s, ok := seedFor(Role(id)); ok {
			return []Type{s.Type}
		}
	}
	return nil
}

// chart is a Sacco's accounts and links, loaded once per piece of work.
// Missing links (a new cash account, category or deduction) get their own
// account when first needed.
type chart struct {
	ctx      context.Context
	db       *gorm.DB
	saccoID  string
	links    map[string]string // link key → account id
	accounts map[string]*LedgerAccount
	codes    map[string]bool
}

func loadChart(ctx context.Context, db *gorm.DB, saccoID string) (*chart, error) {
	c := &chart{ctx: ctx, db: db, saccoID: saccoID, links: map[string]string{},
		accounts: map[string]*LedgerAccount{}, codes: map[string]bool{}}
	var accounts []LedgerAccount
	if err := db.WithContext(ctx).Where("sacco_id = ?", saccoID).Find(&accounts).Error; err != nil {
		return nil, err
	}
	for i := range accounts {
		c.accounts[accounts[i].ID] = &accounts[i]
		c.codes[accounts[i].Code] = true
	}
	var links []Link
	if err := db.WithContext(ctx).Where("sacco_id = ?", saccoID).Find(&links).Error; err != nil {
		return nil, err
	}
	for _, l := range links {
		c.links[l.LinkKey] = l.AccountID
	}
	return c, nil
}

func (c *chart) nextCode(base int) string {
	for n := base; ; n++ {
		if code := strconv.Itoa(n); !c.codes[code] {
			return code
		}
	}
}

func (c *chart) create(code, name string, t Type, desc string) (*LedgerAccount, error) {
	if c.codes[code] {
		return nil, fmt.Errorf("%w: account code %s is taken", ErrConflict, code)
	}
	a := &LedgerAccount{ID: uuid.New().String(), SaccoID: c.saccoID, Code: code, Name: name, Type: t, IsActive: true}
	if desc != "" {
		a.Description = &desc
	}
	if err := c.db.WithContext(c.ctx).Create(a).Error; err != nil {
		return nil, err
	}
	c.accounts[a.ID], c.codes[code] = a, true
	return a, nil
}

func (c *chart) link(key, accountID string) error {
	if err := c.db.WithContext(c.ctx).Save(&Link{SaccoID: c.saccoID, LinkKey: key, AccountID: accountID}).Error; err != nil {
		return err
	}
	c.links[key] = accountID
	return nil
}

// account is the account a link key posts to, made when first needed.
func (c *chart) account(key string) (*LedgerAccount, error) {
	if id, ok := c.links[key]; ok {
		if a, ok := c.accounts[id]; ok {
			return a, nil
		}
	}
	code, name, t, desc, err := c.spec(key)
	if err != nil {
		return nil, err
	}
	base, _ := strconv.Atoi(code)
	if c.codes[code] {
		code = c.nextCode(base)
	}
	a, err := c.create(code, name, t, desc)
	if err != nil {
		return nil, err
	}
	return a, c.link(key, a.ID)
}

// spec is the account a link key gets when it has none: the role's seed, or
// one named after the cash account, category or deduction, with the next
// free code in its range.
func (c *chart) spec(key string) (code, name string, t Type, desc string, err error) {
	kind, id := splitKey(key)
	db := c.db.WithContext(c.ctx)
	switch kind {
	case "role":
		s, ok := seedFor(Role(id))
		if !ok {
			return "", "", "", "", fmt.Errorf("ledger: unknown role %q", id)
		}
		return s.Code, s.Name, s.Type, s.Desc, nil
	case "cash_account":
		var row struct{ Name string }
		if err := db.Table("cash_accounts").Select("name").Where("id = ? AND sacco_id = ?", id, c.saccoID).Take(&row).Error; err != nil {
			return "", "", "", "", fmt.Errorf("ledger: cash account %s: %w", id, err)
		}
		return c.nextCode(1001), row.Name, Asset, "", nil
	case "expense_category":
		var row struct{ Name string }
		if err := db.Table("expense_categories").Select("name").Where("id = ? AND sacco_id = ?", id, c.saccoID).Take(&row).Error; err != nil {
			return "", "", "", "", fmt.Errorf("ledger: expense category %s: %w", id, err)
		}
		return c.nextCode(6001), row.Name, Expense, "", nil
	case "deduction_type":
		var row struct {
			Name      string
			IsSavings bool
		}
		// Deleted deductions stay in pay runs, so they are read too.
		if err := db.Table("deduction_types").Select("name, is_savings").Where("id = ? AND sacco_id = ?", id, c.saccoID).Take(&row).Error; err != nil {
			return "", "", "", "", fmt.Errorf("ledger: deduction %s: %w", id, err)
		}
		if row.IsSavings {
			return c.nextCode(3001), row.Name, Equity, "Taken from farmers' pay; the farmers' own", nil
		}
		return c.nextCode(4101), row.Name, Income, "Taken from farmers' pay", nil
	}
	return "", "", "", "", fmt.Errorf("ledger: unknown link %q", key)
}

// seedAll gives a Sacco its chart: the seed accounts (when it has none),
// and an account for each cash account, expense category and deduction.
func (c *chart) seedAll() error {
	for _, s := range seedChart {
		if s.Role != "" {
			if _, err := c.account(roleKey(s.Role)); err != nil {
				return err
			}
			continue
		}
		if !c.codes[s.Code] {
			if _, err := c.create(s.Code, s.Name, s.Type, s.Desc); err != nil {
				return err
			}
		}
	}
	db := c.db.WithContext(c.ctx)
	lists := []struct {
		sql string
		key func(string) string
	}{
		{"SELECT id FROM cash_accounts WHERE sacco_id = ? ORDER BY created_at, name", cashKey},
		{"SELECT id FROM expense_categories WHERE sacco_id = ? ORDER BY created_at, name", categoryKey},
		{"SELECT id FROM deduction_types WHERE sacco_id = ? AND deleted_at IS NULL ORDER BY priority, name", deductionKey},
	}
	for _, l := range lists {
		var ids []string
		if err := db.Raw(l.sql, c.saccoID).Scan(&ids).Error; err != nil {
			return err
		}
		for _, id := range ids {
			if _, err := c.account(l.key(id)); err != nil {
				return err
			}
		}
	}
	return nil
}

// kept says what an account follows when records keep it (so manual
// journals cannot use it), or "" when it is free to use.
func (c *chart) kept(accountID string) string {
	for key, id := range c.links {
		if id != accountID {
			continue
		}
		kind, rest := splitKey(key)
		if kind == "cash_account" {
			return "A cash account's cashbook"
		}
		if kind == "role" {
			if what, ok := keptRoles[Role(rest)]; ok {
				return what
			}
		}
	}
	return ""
}
