package collection

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

// A customer's selling price over time (migration 00028). A Sacco admin
// (customers.prices.manage) sets a price from a date, as far back as the
// customer's first day; the customer's sales from that date sold at the
// agreed price are repriced, with a history line each. Sales whose price was
// typed by hand (a discount on the day) and voided sales never change. Sales
// paid in full are repriced only when the person saving says so: the cash
// received stays as it was, so the customer then owes the difference, or is
// in credit for it.

const auditEntityCustomerPrice = "customer_price"

// permCustomersRead is the customer module's read permission (named here to
// keep the packages apart).
const permCustomersRead = "customers.read"

// CustomerPrice is one row of a customer's price schedule.
type CustomerPrice struct {
	ID            string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID       string     `json:"sacco_id" gorm:"type:varchar(36);not null"`
	CustomerID    string     `json:"customer_id" gorm:"type:varchar(36);not null"`
	PricePerLitre float64    `json:"price_per_litre"`
	EffectiveDate time.Time  `json:"effective_date" gorm:"type:date"`
	Reason        *string    `json:"reason,omitempty"`
	IsActive      bool       `json:"is_active"`
	VoidedAt      *time.Time `json:"voided_at,omitempty"`
	VoidReason    *string    `json:"void_reason,omitempty"`
	CreatedByID   *uint      `json:"created_by_id,omitempty"`
	CreatedBy     string     `json:"created_by,omitempty" gorm:"-"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
}

func (CustomerPrice) TableName() string { return "customer_prices" }

// customerPriceOn is a customer's price on day (YYYY-MM-DD): the latest row
// on or before it (rows sorted oldest first), else fallback, the agreed
// price, when there is one.
func customerPriceOn(day string, rows []CustomerPrice, fallback *float64) (float64, bool) {
	for i := len(rows) - 1; i >= 0; i-- {
		if rows[i].EffectiveDate.Format(dateLayout) <= day {
			return rows[i].PricePerLitre, true
		}
	}
	if fallback != nil && *fallback > 0 {
		return *fallback, true
	}
	return 0, false
}

func sortCustomerPrices(rows []CustomerPrice) {
	sort.SliceStable(rows, func(i, j int) bool {
		if !rows[i].EffectiveDate.Equal(rows[j].EffectiveDate) {
			return rows[i].EffectiveDate.Before(rows[j].EffectiveDate)
		}
		return rows[i].CreatedAt.Before(rows[j].CreatedAt)
	})
}

// saleReprice is one sale a schedule change reprices.
type saleReprice struct {
	Sale      MilkSale
	NewPrice  float64
	NewTotal  float64
	NewStatus string
	PaidFull  bool
}

// RepriceSummary says what a price change does to a customer's sales.
type RepriceSummary struct {
	CreditSales  int     `json:"credit_sales" doc:"Sales not fully paid that are repriced"`
	CreditChange float64 `json:"credit_change" doc:"How much those change what the customer owes (KES)"`
	PaidSales    int     `json:"paid_sales" doc:"Sales paid in full at the old price"`
	PaidChange   float64 `json:"paid_change" doc:"What repricing those too would add (KES; minus = the customer is in credit)"`
	Handtyped    int     `json:"handtyped_sales" doc:"Sales at a price typed on the day; never repriced"`
}

// repriceSales works out the change from schedule before to after for each
// sale: only sales at the old scheduled price for their day change. All
// sales, paid in full or not, are returned; the caller decides.
func repriceSales(sales []MilkSale, before, after []CustomerPrice, fallback *float64) ([]saleReprice, RepriceSummary) {
	var out []saleReprice
	var sum RepriceSummary
	for _, s := range sales {
		if s.VoidedAt != nil {
			continue
		}
		day := s.SaleDate.Format(dateLayout)
		oldP, okOld := customerPriceOn(day, before, fallback)
		newP, okNew := customerPriceOn(day, after, fallback)
		if !okNew || (okOld && newP == oldP) {
			continue
		}
		if !okOld || s.UnitPrice != oldP {
			sum.Handtyped++
			continue
		}
		total := math.Round(s.QuantityLitres*newP*100) / 100
		r := saleReprice{Sale: s, NewPrice: newP, NewTotal: total,
			PaidFull: s.TotalAmount > 0 && s.AmountPaid >= s.TotalAmount}
		// The cash received stays; the status follows the new total.
		switch {
		case s.AmountPaid == 0:
			r.NewStatus = SaleCredit
		case s.AmountPaid < total:
			r.NewStatus = SalePartial
		default:
			r.NewStatus = SalePaid
		}
		change := total - s.TotalAmount
		if r.PaidFull {
			sum.PaidSales++
			sum.PaidChange += change
		} else {
			sum.CreditSales++
			sum.CreditChange += change
		}
		out = append(out, r)
	}
	sum.CreditChange = math.Round(sum.CreditChange*100) / 100
	sum.PaidChange = math.Round(sum.PaidChange*100) / 100
	return out, sum
}

// CustomerPriceInfo is a customer's price today and their schedule.
type CustomerPriceInfo struct {
	Today     *float64        `json:"price_today,omitempty" doc:"The customer's price today; empty when none is agreed"`
	FirstDay  string          `json:"first_day" doc:"The earliest date a price can start: the customer's first day"`
	Schedule  []CustomerPrice `json:"schedule" doc:"Active rows, newest first"`
	Cancelled []CustomerPrice `json:"cancelled" doc:"Rows cancelled in error, newest first"`
}

// customerSchedule loads a customer of the caller's Sacco and their active
// price rows, sorted oldest first.
func (s *Service) customerSchedule(ctx context.Context, customerID string) (*priceCustomer, []CustomerPrice, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, nil, fmt.Errorf("sacco context is required")
	}
	c, err := s.repo.FindPriceCustomer(ctx, saccoID, customerID)
	if err != nil {
		return nil, nil, err
	}
	rows, err := s.repo.CustomerPriceRows(ctx, saccoID, customerID, true)
	if err != nil {
		return nil, nil, err
	}
	sortCustomerPrices(rows)
	return c, rows, nil
}

// salePriceFor is the agreed price of a customer's sale on day, for a sale
// recorded without a typed price.
func (s *Service) salePriceFor(ctx context.Context, c *saleCustomer, day time.Time) (*float64, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)
	rows, err := s.repo.CustomerPriceRows(ctx, saccoID, c.ID, true)
	if err != nil {
		return nil, err
	}
	sortCustomerPrices(rows)
	if p, ok := customerPriceOn(day.Format(dateLayout), rows, c.DefaultPricePerLitre); ok {
		return &p, nil
	}
	return nil, nil
}

// CustomerPrices returns a customer's price today and their schedule.
func (s *Service) CustomerPrices(ctx context.Context, customerID string) (*CustomerPriceInfo, error) {
	c, rows, err := s.customerSchedule(ctx, customerID)
	if err != nil {
		return nil, err
	}
	all, err := s.repo.CustomerPriceRows(ctx, c.SaccoID, customerID, false)
	if err != nil {
		return nil, err
	}
	info := &CustomerPriceInfo{FirstDay: c.FirstDay().Format(dateLayout), Schedule: []CustomerPrice{}, Cancelled: []CustomerPrice{}}
	if p, ok := customerPriceOn(time.Now().Format(dateLayout), rows, c.DefaultPricePerLitre); ok {
		info.Today = &p
	}
	s.repo.nameCreators(ctx, all)
	sort.SliceStable(all, func(i, j int) bool {
		if !all[i].EffectiveDate.Equal(all[j].EffectiveDate) {
			return all[i].EffectiveDate.After(all[j].EffectiveDate)
		}
		return all[i].CreatedAt.After(all[j].CreatedAt)
	})
	for _, r := range all {
		if r.IsActive {
			info.Schedule = append(info.Schedule, r)
		} else {
			info.Cancelled = append(info.Cancelled, r)
		}
	}
	return info, nil
}

// SetCustomerPriceRequest sets a customer's price from a date.
type SetCustomerPriceRequest struct {
	PricePerLitre float64 `json:"price_per_litre" doc:"KES per litre"`
	EffectiveDate string  `json:"effective_date" doc:"YYYY-MM-DD, from the customer's first day. Their sales from this day at the agreed price are repriced"`
	Reason        string  `json:"reason" doc:"Why, e.g. New contract from October"`
	IncludePaid   bool    `json:"include_paid,omitempty" doc:"Also reprice sales paid in full at the old price (the cash received stays; the customer owes or is in credit for the difference)"`
	Preview       bool    `json:"preview,omitempty" doc:"Only say what would change; save nothing"`
}

// CustomerPriceResult is a saved (or previewed) change and what it does.
type CustomerPriceResult struct {
	Price    *CustomerPrice `json:"price,omitempty"`
	Summary  RepriceSummary `json:"summary"`
	Repriced int            `json:"repriced" doc:"Sales repriced (or that would be)"`
	Preview  bool           `json:"preview"`
}

// SetCustomerPrice adds a row to a customer's price schedule and reprices
// their sales from its date.
func (s *Service) SetCustomerPrice(ctx context.Context, customerID string, req *SetCustomerPriceRequest) (*CustomerPriceResult, error) {
	c, rows, err := s.customerSchedule(ctx, customerID)
	if err != nil {
		return nil, err
	}
	day, err := time.ParseInLocation(dateLayout, strings.TrimSpace(req.EffectiveDate), time.Local)
	if err != nil {
		return nil, fmt.Errorf("give the date the price starts (effective_date, YYYY-MM-DD)")
	}
	if first := c.FirstDay(); day.Before(first) {
		return nil, fmt.Errorf("%s was added on %s; the price can start from then", c.Name, first.Format("2 Jan 2006"))
	}
	if req.PricePerLitre <= 0 {
		return nil, fmt.Errorf("give the price per litre")
	}
	reason := strings.TrimSpace(req.Reason)
	if len(reason) < 3 {
		return nil, fmt.Errorf("say why (reason), e.g. New contract from October")
	}
	actor := middleware.GetUserID(ctx)
	now := time.Now()
	price := math.Round(req.PricePerLitre*100) / 100
	added := []CustomerPrice{{
		ID: uuid.New().String(), SaccoID: c.SaccoID, CustomerID: c.ID, PricePerLitre: price,
		EffectiveDate: day, Reason: &reason, IsActive: true, CreatedByID: &actor, CreatedAt: now,
	}}
	// The first change keeps the price agreed before it, from the first day,
	// so that earlier sales keep a known price.
	if len(rows) == 0 && c.DefaultPricePerLitre != nil && *c.DefaultPricePerLitre > 0 && day.After(c.FirstDay()) {
		before := "Agreed price before the price history"
		added = append([]CustomerPrice{{
			ID: uuid.New().String(), SaccoID: c.SaccoID, CustomerID: c.ID, PricePerLitre: *c.DefaultPricePerLitre,
			EffectiveDate: c.FirstDay(), Reason: &before, IsActive: true, CreatedByID: &actor, CreatedAt: now.Add(-time.Second),
		}}, added...)
	}
	after := append(append([]CustomerPrice{}, rows...), added...)
	sortCustomerPrices(after)
	why := fmt.Sprintf("Customer price from %s: KES %.2f (%s)", day.Format("2 Jan 2006"), price, reason)
	entries := []audit.Entry{}
	for i := range added {
		entries = append(entries, audit.Entry{
			SaccoID: c.SaccoID, EntityType: auditEntityCustomerPrice, EntityID: added[i].ID,
			Action: audit.ActionCreate, ActorID: actor, Reason: added[i].Reason, NewValues: added[i],
		})
	}
	res, err := s.applyCustomerSchedule(ctx, c, rows, after, added, nil, why, req.IncludePaid, req.Preview, entries)
	if err != nil {
		return nil, err
	}
	res.Price = &added[len(added)-1]
	return res, nil
}

// VoidCustomerPriceRequest cancels a schedule row entered in error.
type VoidCustomerPriceRequest struct {
	Reason      string `json:"reason" doc:"Why it is cancelled"`
	IncludePaid bool   `json:"include_paid,omitempty" doc:"Also reprice sales paid in full"`
	Preview     bool   `json:"preview,omitempty"`
}

// VoidCustomerPrice cancels a row and reprices the customer's sales back.
func (s *Service) VoidCustomerPrice(ctx context.Context, customerID, priceID string, req *VoidCustomerPriceRequest) (*CustomerPriceResult, error) {
	c, rows, err := s.customerSchedule(ctx, customerID)
	if err != nil {
		return nil, err
	}
	reason := strings.TrimSpace(req.Reason)
	if len(reason) < 3 {
		return nil, fmt.Errorf("say why the price is cancelled (reason)")
	}
	var voided *CustomerPrice
	after := make([]CustomerPrice, 0, len(rows))
	for i := range rows {
		if rows[i].ID == priceID {
			v := rows[i]
			voided = &v
			continue
		}
		after = append(after, rows[i])
	}
	if voided == nil {
		return nil, fmt.Errorf("%w: price not found, or already cancelled", ErrNotFound)
	}
	now := time.Now()
	voided.IsActive, voided.VoidedAt, voided.VoidReason = false, &now, &reason
	actor := middleware.GetUserID(ctx)
	why := fmt.Sprintf("Customer price from %s cancelled (%s)", voided.EffectiveDate.Format("2 Jan 2006"), reason)
	res, err := s.applyCustomerSchedule(ctx, c, rows, after, nil, voided, why, req.IncludePaid, req.Preview, []audit.Entry{{
		SaccoID: c.SaccoID, EntityType: auditEntityCustomerPrice, EntityID: voided.ID,
		Action: audit.ActionVoid, ActorID: actor, Reason: &reason, NewValues: voided,
	}})
	if err != nil {
		return nil, err
	}
	res.Price = voided
	return res, nil
}

// applyCustomerSchedule reprices the customer's sales from schedule before
// to after and, unless previewing, saves the rows, the sales, the agreed
// price in force today and every history line together.
func (s *Service) applyCustomerSchedule(ctx context.Context, c *priceCustomer, before, after, added []CustomerPrice,
	voided *CustomerPrice, why string, includePaid, preview bool, entries []audit.Entry) (*CustomerPriceResult, error) {
	from := earliestChange(added, voided)
	sales, err := s.repo.CustomerSalesFrom(ctx, c.SaccoID, c.ID, from)
	if err != nil {
		return nil, err
	}
	changes, sum := repriceSales(sales, before, after, c.DefaultPricePerLitre)
	kept := changes[:0]
	for _, ch := range changes {
		if !ch.PaidFull || includePaid {
			kept = append(kept, ch)
		}
	}
	res := &CustomerPriceResult{Summary: sum, Repriced: len(kept), Preview: preview}
	if preview {
		return res, nil
	}
	actor := middleware.GetUserID(ctx)
	for _, ch := range kept {
		entries = append(entries, audit.Entry{
			SaccoID: c.SaccoID, EntityType: auditEntitySale, EntityID: ch.Sale.ID, Action: audit.ActionUpdate,
			ActorID: actor, Reason: &why,
			OldValues: map[string]any{"unit_price": ch.Sale.UnitPrice, "total_amount": ch.Sale.TotalAmount, "payment_status": ch.Sale.PaymentStatus},
			NewValues: map[string]any{"unit_price": ch.NewPrice, "total_amount": ch.NewTotal, "payment_status": ch.NewStatus},
		})
	}
	// The agreed price shown on the customer and used for new sales is the
	// one in force today (unchanged when nothing applies yet).
	today, ok := customerPriceOn(time.Now().Format(dateLayout), after, nil)
	var agreed *float64
	if ok {
		agreed = &today
	}
	if err := s.repo.SaveCustomerPrice(ctx, c.ID, added, voided, kept, agreed, entries); err != nil {
		return nil, err
	}
	return res, nil
}

// earliestChange is the first day a change can reprice from.
func earliestChange(added []CustomerPrice, voided *CustomerPrice) time.Time {
	var from time.Time
	for i, r := range added {
		if i == 0 || r.EffectiveDate.Before(from) {
			from = r.EffectiveDate
		}
	}
	if voided != nil && (from.IsZero() || voided.EffectiveDate.Before(from)) {
		from = voided.EffectiveDate
	}
	return from
}
