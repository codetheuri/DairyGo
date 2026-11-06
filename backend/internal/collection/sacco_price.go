package collection

import (
	"context"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
)

// A new Sacco buying price from a date. The price applies to milk from that
// date, including milk already recorded and not yet paid: pricedOn is the
// same rule for a new intake, a farmer's own price and this. So a price set
// on 6 Nov "from 1 Oct" moves all unpaid milk since 1 Oct to it, each record
// with a history line. Months a pay run has closed never change, and farmers
// on their own price stay on it.

const auditEntityMilkPrice = "milk_price"

// SaccoPriceResult is a saved (or previewed) Sacco price and what it reprices.
type SaccoPriceResult struct {
	Price       *MilkPrice `json:"price"`
	Preview     bool       `json:"preview"`
	Repriced    int        `json:"repriced" doc:"Unpaid milk records whose price changes"`
	Farmers     int        `json:"farmers" doc:"Farmers whose pay changes"`
	Litres      float64    `json:"litres" doc:"Litres repriced, rejected milk left out"`
	ValueChange float64    `json:"value_change" doc:"KES added to what farmers are owed (negative = taken off), rejected milk left out"`
	OwnPrice    int        `json:"own_price_farmers" doc:"Farmers with milk in the period who stay on their own price"`
	PaidThrough string     `json:"paid_through,omitempty" doc:"Set when the date falls in a closed period: milk up to this day is paid and keeps its price"`
}

// saccoReprice works out which of the milk records change under the
// schedules, and fills in the result's totals. own holds each farmer's price
// rows, sorted; sacco is sorted too.
func saccoReprice(milk []MilkCollection, own map[string][]MemberPrice, sacco []MilkPrice, res *SaccoPriceResult) []priceChange {
	var out []priceChange
	farmers, onOwn := map[string]bool{}, map[string]bool{}
	var litres, change float64
	for _, c := range milk {
		price, isOwn, ok := pricedOn(c.CollectionDate.Format(dateLayout), own[c.MemberID], sacco)
		if isOwn {
			onOwn[c.MemberID] = true
		}
		if !ok || price == c.PricePerLitre {
			continue
		}
		total := math.Round(c.QuantityLitres*price*100) / 100
		out = append(out, priceChange{Collection: c, NewPrice: price, NewTotal: total})
		if c.Status != StatusRejected {
			farmers[c.MemberID] = true
			litres += c.QuantityLitres
			change += total - c.TotalAmount
		}
	}
	res.Repriced, res.Farmers, res.OwnPrice = len(out), len(farmers), len(onOwn)
	res.Litres, res.ValueChange = math.Round(litres*100)/100, math.Round(change*100)/100
	return out
}

// lastRowOn is the row that sets the price on exactly day, if any: entered
// last among a day's rows. sacco is sorted.
func lastRowOn(sacco []MilkPrice, day string) *MilkPrice {
	for i := len(sacco) - 1; i >= 0; i-- {
		if sacco[i].EffectiveDate.Format(dateLayout) == day {
			return &sacco[i]
		}
	}
	return nil
}

// SetPrice adds a buying price to the Sacco's schedule and reprices unpaid
// milk from its date. With preview nothing is saved: the result says what
// would change. Entering the price already set for that date adds no second
// row and only reprices, so milk recorded before this rule existed can be
// brought to a price already on the schedule.
func (s *Service) SetPrice(ctx context.Context, req *SetPriceRequest) (*SaccoPriceResult, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("sacco context is required")
	}
	if req.PricePerLitre <= 0 {
		return nil, fmt.Errorf("price per litre must be greater than zero")
	}
	now := time.Now()
	effective := now
	if req.EffectiveDate != nil && strings.TrimSpace(*req.EffectiveDate) != "" {
		parsed, err := time.ParseInLocation(dateLayout, strings.TrimSpace(*req.EffectiveDate), time.Local)
		if err != nil {
			return nil, fmt.Errorf("invalid effective_date format, expected YYYY-MM-DD")
		}
		effective = parsed
	}
	day, today := effective.Format(dateLayout), now.Format(dateLayout)
	price := math.Round(req.PricePerLitre*100) / 100

	sacco, err := s.repo.SaccoPriceRows(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	sortSchedules(nil, sacco)
	actor := middleware.GetUserID(ctx)
	row, added := lastRowOn(sacco, day), (*MilkPrice)(nil)
	if row == nil || row.PricePerLitre != price {
		row = &MilkPrice{ID: uuid.New().String(), SaccoID: saccoID, PricePerLitre: price,
			EffectiveDate: effective, IsActive: true, CreatedAt: now}
		if actor > 0 {
			row.CreatedByID = &actor
		}
		added = row
		sacco = append(sacco, *row)
		sortSchedules(nil, sacco)
	}

	res := &SaccoPriceResult{Price: row, Preview: req.Preview}
	from := day
	closed, err := s.repo.PayrollClosedThrough(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	if closed != nil && day <= closed.Format(dateLayout) {
		res.PaidThrough = closed.Format(dateLayout)
		from = closed.AddDate(0, 0, 1).Format(dateLayout)
	}
	var changes []priceChange
	if from <= today {
		milk, err := s.repo.MilkFrom(ctx, saccoID, from)
		if err != nil {
			return nil, err
		}
		own, err := s.repo.AllMemberPriceRows(ctx, saccoID)
		if err != nil {
			return nil, err
		}
		changes = saccoReprice(milk, own, sacco, res)
	}
	reason := strings.TrimSpace(req.Reason)
	if !req.Preview && len(changes) > 0 && day < today && len(reason) < 3 {
		return nil, fmt.Errorf("this changes %d milk records already saved, so say why (reason). If the app does not ask, update it", len(changes))
	}
	if req.Preview {
		return res, nil
	}

	why := fmt.Sprintf("Sacco price from %s: KES %.2f", effective.Format("2 Jan 2006"), price)
	if reason != "" {
		why += " (" + reason + ")"
	}
	var entries []audit.Entry
	if added != nil {
		entries = append(entries, audit.Entry{SaccoID: saccoID, EntityType: auditEntityMilkPrice, EntityID: row.ID,
			Action: audit.ActionCreate, ActorID: actor, Reason: &why, NewValues: row})
	}
	for _, c := range changes {
		entries = append(entries, audit.Entry{
			SaccoID: saccoID, EntityType: auditEntityCollection, EntityID: c.Collection.ID, Action: audit.ActionUpdate,
			ActorID: actor, Reason: &why,
			OldValues: map[string]float64{"price_per_litre": c.Collection.PricePerLitre, "total_amount": c.Collection.TotalAmount},
			NewValues: map[string]float64{"price_per_litre": c.NewPrice, "total_amount": c.NewTotal},
		})
	}
	if err := s.repo.SaveSaccoPrice(ctx, added, changes, entries); err != nil {
		return nil, fmt.Errorf("failed to save milk price: %w", err)
	}
	return res, nil
}
