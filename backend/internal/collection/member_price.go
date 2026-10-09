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

const auditEntityMemberPrice = "member_price"

// MemberPrice is one row of a farmer's own price schedule. The latest row on
// or before a day sets that day's price; a nil PricePerLitre means the
// Sacco's price applies again from EffectiveDate.
type MemberPrice struct {
	ID            string     `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SaccoID       string     `json:"sacco_id" gorm:"type:varchar(36);not null"`
	MemberID      string     `json:"member_id" gorm:"type:varchar(36);not null"`
	PricePerLitre *float64   `json:"price_per_litre" doc:"The farmer's price; empty = back to the Sacco's price"`
	EffectiveDate time.Time  `json:"effective_date" gorm:"type:date"`
	Reason        *string    `json:"reason,omitempty"`
	IsActive      bool       `json:"is_active"`
	VoidedAt      *time.Time `json:"voided_at,omitempty"`
	VoidReason    *string    `json:"void_reason,omitempty"`
	CreatedByID   *uint      `json:"created_by_id,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
}

func (MemberPrice) TableName() string { return "member_prices" }

// pricedOn is the buying price for day (YYYY-MM-DD): the farmer's own price
// in force then, or else the Sacco's. Both schedules are sorted oldest first.
// ok is false when no price applies at all.
func pricedOn(day string, own []MemberPrice, sacco []MilkPrice) (price float64, isOwn, ok bool) {
	for i := len(own) - 1; i >= 0; i-- {
		if own[i].EffectiveDate.Format(dateLayout) <= day {
			if own[i].PricePerLitre != nil {
				return *own[i].PricePerLitre, true, true
			}
			break // back to the Sacco's price from this date
		}
	}
	for i := len(sacco) - 1; i >= 0; i-- {
		if sacco[i].EffectiveDate.Format(dateLayout) <= day {
			return sacco[i].PricePerLitre, false, true
		}
	}
	return 0, false, false
}

// priceChange is one collection whose price a schedule change alters.
type priceChange struct {
	Collection MilkCollection
	NewPrice   float64
	NewTotal   float64
}

// repriceChanges works out which of a farmer's unpaid collections change
// price under the schedules, and their new totals.
func repriceChanges(collections []MilkCollection, own []MemberPrice, sacco []MilkPrice) []priceChange {
	var out []priceChange
	for _, c := range collections {
		price, _, ok := pricedOn(c.CollectionDate.Format(dateLayout), own, sacco)
		if !ok || price == c.PricePerLitre {
			continue
		}
		out = append(out, priceChange{
			Collection: c, NewPrice: price,
			NewTotal: math.Round(c.QuantityLitres*price*100) / 100,
		})
	}
	return out
}

func sortSchedules(own []MemberPrice, sacco []MilkPrice) {
	sort.SliceStable(own, func(i, j int) bool {
		if !own[i].EffectiveDate.Equal(own[j].EffectiveDate) {
			return own[i].EffectiveDate.Before(own[j].EffectiveDate)
		}
		return own[i].CreatedAt.Before(own[j].CreatedAt)
	})
	sort.SliceStable(sacco, func(i, j int) bool {
		if !sacco[i].EffectiveDate.Equal(sacco[j].EffectiveDate) {
			return sacco[i].EffectiveDate.Before(sacco[j].EffectiveDate)
		}
		return sacco[i].CreatedAt.Before(sacco[j].CreatedAt)
	})
}

// schedules loads a farmer's own price rows and the Sacco's prices, sorted.
func (s *Service) schedules(ctx context.Context, saccoID, memberID string) ([]MemberPrice, []MilkPrice, error) {
	own, err := s.repo.MemberPriceRows(ctx, saccoID, memberID)
	if err != nil {
		return nil, nil, err
	}
	sacco, err := s.repo.SaccoPriceRows(ctx, saccoID)
	if err != nil {
		return nil, nil, err
	}
	sortSchedules(own, sacco)
	return own, sacco, nil
}

// priceFor is the price a farmer's milk on day is bought at.
func (s *Service) priceFor(ctx context.Context, saccoID, memberID string, day time.Time) (float64, bool, error) {
	own, sacco, err := s.schedules(ctx, saccoID, memberID)
	if err != nil {
		return 0, false, err
	}
	price, isOwn, ok := pricedOn(day.Format(dateLayout), own, sacco)
	if !ok {
		return 0, false, fmt.Errorf("no milk price configured for this Sacco on %s", day.Format(dateLayout))
	}
	return price, isOwn, nil
}

// MemberPriceInfo is a farmer's price today and their own price schedule.
type MemberPriceInfo struct {
	Today      float64       `json:"price_today" doc:"What this farmer's milk is bought at today"`
	Own        bool          `json:"own_price" doc:"True when that is the farmer's own price, not the Sacco's"`
	SaccoToday float64       `json:"sacco_price_today"`
	Schedule   []MemberPrice `json:"schedule" doc:"The farmer's own price rows, newest first"`
}

// MemberPrices returns a farmer's price today and their schedule.
func (s *Service) MemberPrices(ctx context.Context, memberID string) (*MemberPriceInfo, error) {
	saccoID, err := s.farmerSacco(ctx, memberID)
	if err != nil {
		return nil, err
	}
	own, sacco, err := s.schedules(ctx, saccoID, memberID)
	if err != nil {
		return nil, err
	}
	today := time.Now().Format(dateLayout)
	info := &MemberPriceInfo{Schedule: make([]MemberPrice, 0, len(own))}
	info.Today, info.Own, _ = pricedOn(today, own, sacco)
	info.SaccoToday, _, _ = pricedOn(today, nil, sacco)
	for i := len(own) - 1; i >= 0; i-- {
		info.Schedule = append(info.Schedule, own[i])
	}
	return info, nil
}

// PriceForDay is what a farmer's milk on day is bought at, for the intake
// form.
func (s *Service) PriceForDay(ctx context.Context, memberID, day string) (float64, bool, error) {
	saccoID, err := s.farmerSacco(ctx, memberID)
	if err != nil {
		return 0, false, err
	}
	d := time.Now()
	if strings.TrimSpace(day) != "" {
		if d, err = time.ParseInLocation(dateLayout, strings.TrimSpace(day), time.Local); err != nil {
			return 0, false, fmt.Errorf("invalid date, expected YYYY-MM-DD")
		}
	}
	return s.priceFor(ctx, saccoID, memberID, d)
}

// MemberPriceResult is a saved (or previewed) price change and how many of
// the farmer's unpaid milk records it reprices.
type MemberPriceResult struct {
	Price    *MemberPrice `json:"price,omitempty"`
	Repriced int          `json:"repriced" doc:"Unpaid milk records whose price changes"`
	Preview  bool         `json:"preview"`
}

// SetMemberPrice adds a row to a farmer's price schedule and reprices their
// unpaid milk from its date. With preview, nothing is saved: the result says
// how many records would change.
func (s *Service) SetMemberPrice(ctx context.Context, memberID string, req *SetMemberPriceRequest) (*MemberPriceResult, error) {
	saccoID, err := s.farmerSacco(ctx, memberID)
	if err != nil {
		return nil, err
	}
	day, err := time.ParseInLocation(dateLayout, strings.TrimSpace(req.EffectiveDate), time.Local)
	if err != nil {
		return nil, fmt.Errorf("give the date the price starts (effective_date, YYYY-MM-DD)")
	}
	var price *float64
	switch {
	case req.BackToSaccoPrice:
	case req.PricePerLitre == nil || *req.PricePerLitre <= 0:
		return nil, fmt.Errorf("give the farmer's price per litre, or choose the Sacco's price again")
	default:
		p := math.Round(*req.PricePerLitre*100) / 100
		price = &p
	}
	reason := strings.TrimSpace(req.Reason)
	if len(reason) < 3 {
		return nil, fmt.Errorf("say why (reason), e.g. Agreed at the board meeting")
	}
	actor := middleware.GetUserID(ctx)
	row := &MemberPrice{
		ID: uuid.New().String(), SaccoID: saccoID, MemberID: memberID, PricePerLitre: price,
		EffectiveDate: day, Reason: &reason, IsActive: true, CreatedByID: &actor, CreatedAt: time.Now(),
	}
	label := "the Sacco's price"
	if price != nil {
		label = fmt.Sprintf("KES %.2f", *price)
	}
	why := fmt.Sprintf("Farmer price from %s: %s (%s)", day.Format("2 Jan 2006"), label, reason)
	return s.changeSchedule(ctx, saccoID, memberID, row, nil, why, req.Preview, audit.Entry{
		SaccoID: saccoID, EntityType: auditEntityMemberPrice, EntityID: row.ID, Action: audit.ActionCreate,
		ActorID: actor, Reason: &reason, NewValues: row,
	})
}

// VoidMemberPrice cancels a row of a farmer's schedule entered in error and
// reprices their unpaid milk accordingly.
func (s *Service) VoidMemberPrice(ctx context.Context, memberID, priceID, reason string) (*MemberPriceResult, error) {
	saccoID, err := s.farmerSacco(ctx, memberID)
	if err != nil {
		return nil, err
	}
	reason = strings.TrimSpace(reason)
	if len(reason) < 3 {
		return nil, fmt.Errorf("say why the price is cancelled (reason)")
	}
	row, err := s.repo.FindMemberPrice(ctx, saccoID, memberID, priceID)
	if err != nil {
		return nil, err
	}
	now := time.Now()
	row.IsActive, row.VoidedAt, row.VoidReason = false, &now, &reason
	why := fmt.Sprintf("Farmer price from %s cancelled (%s)", row.EffectiveDate.Format("2 Jan 2006"), reason)
	actor := middleware.GetUserID(ctx)
	return s.changeSchedule(ctx, saccoID, memberID, nil, row, why, false, audit.Entry{
		SaccoID: saccoID, EntityType: auditEntityMemberPrice, EntityID: row.ID, Action: audit.ActionVoid,
		ActorID: actor, Reason: &reason, NewValues: row,
	})
}

// changeSchedule applies an added (added) or voided (voided) row: works out
// the farmer's unpaid milk whose price changes, and saves the row, the new
// prices and their history together.
func (s *Service) changeSchedule(ctx context.Context, saccoID, memberID string, added, voided *MemberPrice,
	why string, preview bool, entry audit.Entry) (*MemberPriceResult, error) {
	own, sacco, err := s.schedules(ctx, saccoID, memberID)
	if err != nil {
		return nil, err
	}
	if added != nil {
		own = append(own, *added)
	}
	if voided != nil {
		kept := own[:0]
		for _, r := range own {
			if r.ID != voided.ID {
				kept = append(kept, r)
			}
		}
		own = kept
	}
	sortSchedules(own, sacco)
	closed, err := s.repo.PayrollClosedThrough(ctx, saccoID)
	if err != nil {
		return nil, err
	}
	open, err := s.repo.UnpaidCollections(ctx, saccoID, memberID, closed)
	if err != nil {
		return nil, err
	}
	changes := repriceChanges(open, own, sacco)
	result := &MemberPriceResult{Price: added, Repriced: len(changes), Preview: preview}
	if voided != nil {
		result.Price = voided
	}
	if preview {
		return result, nil
	}
	actor := middleware.GetUserID(ctx)
	entries := []audit.Entry{entry}
	for _, c := range changes {
		entries = append(entries, audit.Entry{
			SaccoID: saccoID, EntityType: auditEntityCollection, EntityID: c.Collection.ID, Action: audit.ActionUpdate,
			ActorID: actor, Reason: &why,
			OldValues: map[string]float64{"price_per_litre": c.Collection.PricePerLitre, "total_amount": c.Collection.TotalAmount},
			NewValues: map[string]float64{"price_per_litre": c.NewPrice, "total_amount": c.NewTotal},
		})
	}
	if err := s.repo.SaveMemberPrice(ctx, added, voided, changes, entries); err != nil {
		return nil, err
	}
	return result, nil
}

// farmerSacco checks the farmer is in the caller's Sacco and returns it.
func (s *Service) farmerSacco(ctx context.Context, memberID string) (string, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return "", fmt.Errorf("sacco context is required")
	}
	if _, err := s.repo.FindMemberForCollection(ctx, memberID); err != nil {
		return "", err
	}
	return saccoID, nil
}
