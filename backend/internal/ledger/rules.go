package ledger

import (
	"fmt"
	"sort"
	"strings"
	"time"
)

// What each record posts. The rules are plain functions of the record, so
// they can be tested without a database; sources.go reads the records.
//
//	Sale                 Dr Customers (unpaid part), Dr cash (paid part)   Cr Milk sales
//	Customer payment     Dr cash                                           Cr Customers
//	Expense              Dr the category's account                         Cr cash
//	Transfer             Dr cash (to)                                      Cr cash (from)
//	Advance              Dr Farmers' accounts                              Cr cash
//	Charge               Dr Farmers' accounts                              Cr Charges to farmers
//	Adjustment (+)       Dr Adjustments                                    Cr Farmers' accounts
//	Pay run approved     Dr Milk bought                                    Cr Farmers' accounts
//	                     Dr Farmers' accounts (deductions)                 Cr each deduction's account
//	                     Dr Farmers' accounts (net pay)                    Cr Farmers' pay due
//	Farmers' pay sent    Dr Farmers' pay due                               Cr cash
//	Cash account opened  Dr the cash account                               Cr Opening balances
//
// "Cash" is the account the money went through. With none named it is
// Money not in an account; dated before the account's opening date it is
// Opening balances, because the opening balance already holds it (the
// cashbook counts nothing before that date either).

// Source types: what a journal was posted from.
const (
	SrcSale        = "sale"
	SrcPayment     = "customer_payment"
	SrcExpense     = "expense"
	SrcTransfer    = "transfer"
	SrcFarmerEntry = "farmer_entry"
	SrcPayRun      = "pay_run"
	SrcCashAccount = "cash_account"
	SrcBooks       = "books" // the opening journal
)

// SourceLabels name source types for people.
var SourceLabels = map[string]string{
	SrcSale: "Milk sale", SrcPayment: "Customer payment", SrcExpense: "Expense", SrcTransfer: "Money moved between accounts",
	SrcFarmerEntry: "Farmer's account", SrcPayRun: "Farmers' pay", SrcCashAccount: "Account opening balance", SrcBooks: "Opening balances",
}

// pline is a line of a posting: positive amounts are debits, negative
// credits.
type pline struct {
	link   string
	amount float64
	memo   string
}

// posting is a journal a record should have.
type posting struct {
	key   string // which of the record's journals ("" when it has one)
	date  time.Time
	memo  string
	ref   *string
	lines []pline
}

func (p *posting) dr(link string, amount float64, memo string) {
	if amount = round2(amount); amount != 0 {
		p.lines = append(p.lines, pline{link, amount, memo})
	}
}

func (p *posting) cr(link string, amount float64, memo string) { p.dr(link, -amount, memo) }

// nets sums the posting's lines by link, leaving out what nets to zero.
func nets(lines []pline) map[string]float64 {
	out := map[string]float64{}
	for _, l := range lines {
		out[l.link] = round2(out[l.link] + l.amount)
	}
	for k, v := range out {
		if v == 0 {
			delete(out, k)
		}
	}
	return out
}

// balanced says the debits equal the credits.
func balanced(lines []pline) bool {
	var sum float64
	for _, l := range lines {
		sum += l.amount
	}
	return same(sum, 0)
}

// record is one source record and the journals it should have. date is the
// record's own date, so a record from before the books start is known even
// when it posts nothing (voided).
type record struct {
	id       string
	date     time.Time
	postings []posting
}

// cashInfo is what the rules need to know about the Sacco's cash accounts.
type cashInfo map[string]time.Time // id → opening date

// cash is the link money through account (nil: none named) on day posts to.
func (ci cashInfo) cash(account *string, day time.Time) string {
	if account == nil || *account == "" {
		return roleKey(RoleNoAccount)
	}
	if opened, ok := ci[*account]; ok && day.Before(opened) {
		return roleKey(RoleOpening)
	}
	return cashKey(*account)
}

type saleRow struct {
	ID        string
	SaleDate  time.Time
	BuyerName string
	Litres    float64
	Total     float64
	Paid      float64
	AccountID *string
	Voided    bool
}

func saleRule(r saleRow, ci cashInfo) record {
	rec := record{id: r.ID, date: r.SaleDate}
	if r.Voided {
		return rec
	}
	p := posting{date: r.SaleDate, memo: fmt.Sprintf("Milk sale: %s, %s L", r.BuyerName, litres(r.Litres))}
	p.dr(roleKey(RoleCustomers), r.Total-r.Paid, "Owed by the customer")
	p.dr(ci.cash(r.AccountID, r.SaleDate), r.Paid, "Paid at the sale")
	p.cr(roleKey(RoleMilkSales), r.Total, "")
	rec.postings = append(rec.postings, p)
	return rec
}

type paymentRow struct {
	ID          string
	PaymentDate time.Time
	Customer    string
	Amount      float64
	AccountID   *string
	Reference   *string
	Voided      bool
}

func paymentRule(r paymentRow, ci cashInfo) record {
	rec := record{id: r.ID, date: r.PaymentDate}
	if r.Voided {
		return rec
	}
	p := posting{date: r.PaymentDate, memo: "Payment from " + r.Customer, ref: r.Reference}
	p.dr(ci.cash(r.AccountID, r.PaymentDate), r.Amount, "")
	p.cr(roleKey(RoleCustomers), r.Amount, "")
	rec.postings = append(rec.postings, p)
	return rec
}

type expenseRow struct {
	ID          string
	ExpenseDate time.Time
	CategoryID  string
	Category    string
	Payee       string
	Amount      float64
	AccountID   *string
	Reference   *string
	Voided      bool
}

func expenseRule(r expenseRow, ci cashInfo) record {
	rec := record{id: r.ID, date: r.ExpenseDate}
	if r.Voided {
		return rec
	}
	p := posting{date: r.ExpenseDate, memo: r.Category + ": " + r.Payee, ref: r.Reference}
	p.dr(categoryKey(r.CategoryID), r.Amount, "")
	p.cr(ci.cash(r.AccountID, r.ExpenseDate), r.Amount, "")
	rec.postings = append(rec.postings, p)
	return rec
}

type transferRow struct {
	ID           string
	TransferDate time.Time
	FromID       string
	ToID         string
	FromName     string
	ToName       string
	Amount       float64
	Reference    *string
	Voided       bool
}

func transferRule(r transferRow, ci cashInfo) record {
	rec := record{id: r.ID, date: r.TransferDate}
	if r.Voided {
		return rec
	}
	p := posting{date: r.TransferDate, memo: fmt.Sprintf("Moved from %s to %s", r.FromName, r.ToName), ref: r.Reference}
	p.dr(ci.cash(&r.ToID, r.TransferDate), r.Amount, "")
	p.cr(ci.cash(&r.FromID, r.TransferDate), r.Amount, "")
	rec.postings = append(rec.postings, p)
	return rec
}

type entryRow struct {
	ID          string
	EntryDate   time.Time
	Kind        string
	Amount      float64 // signed: positive means the Sacco owes the farmer more
	Farmer      string
	Description string
	AccountID   *string
	Reference   *string
	Voided      bool
}

func entryRule(r entryRow, ci cashInfo) record {
	rec := record{id: r.ID, date: r.EntryDate}
	if r.Voided {
		return rec
	}
	p := posting{date: r.EntryDate, ref: r.Reference}
	farmers := roleKey(RoleFarmers)
	switch r.Kind {
	case "ADVANCE":
		p.memo = "Advance to " + r.Farmer
		p.dr(farmers, -r.Amount, "")
		p.cr(ci.cash(r.AccountID, r.EntryDate), -r.Amount, "")
	case "CHARGE":
		p.memo = withDetail("Charge to "+r.Farmer, r.Description)
		p.dr(farmers, -r.Amount, "")
		p.cr(roleKey(RoleCharges), -r.Amount, "")
	case "ADJUSTMENT":
		p.memo = withDetail("Adjustment for "+r.Farmer, r.Description)
		p.dr(roleKey(RoleAdjustments), r.Amount, "")
		p.cr(farmers, r.Amount, "")
	default:
		return rec // milk, deductions and net pay post with their pay run
	}
	rec.postings = append(rec.postings, p)
	return rec
}

type runDeduction struct {
	TypeID *string
	Name   string
	Amount float64 // taken from farmers (positive)
}

type runPaid struct {
	Batch     string // when the farmers were marked paid, telling batches apart
	PaidDate  time.Time
	AccountID *string
	Amount    float64
	Farmers   int
}

type runRow struct {
	ID         string
	FromDate   time.Time
	ToDate     time.Time
	Milk       float64
	Deductions []runDeduction
	Net        float64
	Paid       []runPaid
}

func runRule(r runRow, ci cashInfo) record {
	rec := record{id: r.ID, date: r.ToDate}
	label := runLabel(r.FromDate, r.ToDate)
	farmers := roleKey(RoleFarmers)
	p := posting{key: "approved", date: r.ToDate, memo: "Farmers' pay " + label + ": milk, deductions and net pay"}
	p.dr(roleKey(RoleMilkPurchases), r.Milk, "Milk")
	p.cr(farmers, r.Milk, "Milk")
	for _, d := range r.Deductions {
		link := roleKey(RoleCharges)
		if d.TypeID != nil && *d.TypeID != "" {
			link = deductionKey(*d.TypeID)
		}
		p.dr(farmers, d.Amount, d.Name)
		p.cr(link, d.Amount, d.Name)
	}
	p.dr(farmers, r.Net, "Net pay")
	p.cr(roleKey(RolePayDue), r.Net, "Net pay")
	if len(p.lines) > 0 {
		rec.postings = append(rec.postings, p)
	}
	for _, paid := range r.Paid {
		account := "none"
		if paid.AccountID != nil {
			account = *paid.AccountID
		}
		q := posting{key: "paid:" + paid.Batch + ":" + account, date: paid.PaidDate,
			memo: fmt.Sprintf("Farmers' pay %s sent (%s)", label, plural(paid.Farmers, "farmer"))}
		q.dr(roleKey(RolePayDue), paid.Amount, "")
		q.cr(ci.cash(paid.AccountID, paid.PaidDate), paid.Amount, "")
		rec.postings = append(rec.postings, q)
	}
	return rec
}

type cashAccountRow struct {
	ID             string
	Name           string
	OpeningBalance float64
	OpeningDate    time.Time
}

func cashAccountRule(r cashAccountRow) record {
	rec := record{id: r.ID, date: r.OpeningDate}
	p := posting{date: r.OpeningDate, memo: "Opening balance: " + r.Name}
	p.dr(cashKey(r.ID), r.OpeningBalance, "")
	p.cr(roleKey(RoleOpening), r.OpeningBalance, "")
	if len(p.lines) > 0 {
		rec.postings = append(rec.postings, p)
	}
	return rec
}

// openingRule sums everything posted before the books start into one
// journal on the start date. Income and expenses before then are the
// surplus already made, so they go to Retained surplus; typeOf gives each
// link's account type.
func openingRule(start time.Time, before []posting, typeOf func(link string) (Type, error)) (posting, error) {
	sum := map[string]float64{}
	retained := roleKey(RoleRetained)
	for _, p := range before {
		for _, l := range p.lines {
			t, err := typeOf(l.link)
			if err != nil {
				return posting{}, err
			}
			link := l.link
			if t == Income || t == Expense {
				link = retained
			}
			sum[link] = round2(sum[link] + l.amount)
		}
	}
	links := make([]string, 0, len(sum))
	for k := range sum {
		links = append(links, k)
	}
	sort.Strings(links)
	p := posting{date: start, memo: "Balances on " + start.Format("2 Jan 2006") + " from everything recorded before the books started"}
	for _, k := range links {
		memo := ""
		if k == retained {
			memo = "Income less expenses before the books started"
		}
		p.dr(k, sum[k], memo)
	}
	return p, nil
}

// runLabel names a pay run's period: "Oct 2026" for a whole month,
// otherwise "1 Oct – 15 Oct 2026".
func runLabel(f, t time.Time) string {
	if f.Day() == 1 && t.AddDate(0, 0, 1).Day() == 1 && f.Month() == t.Month() && f.Year() == t.Year() {
		return f.Format("Jan 2006")
	}
	return f.Format("2 Jan") + " – " + t.Format("2 Jan 2006")
}

func litres(v float64) string {
	s := strings.TrimRight(fmt.Sprintf("%.2f", v), "0")
	return strings.TrimSuffix(s, ".")
}

func plural(n int, word string) string {
	if n == 1 {
		return "1 " + word
	}
	return fmt.Sprintf("%d %ss", n, word)
}

func withDetail(s, detail string) string {
	if detail = strings.TrimSpace(detail); detail != "" {
		return s + ": " + detail
	}
	return s
}
