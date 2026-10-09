package payout

import (
	"context"
	"fmt"
	"sort"
	"time"
)

// RateLine is the milk a farmer was paid for at one price in a pay run:
// "300 L @ 42 = 12,600". A month with a price change has two.
type RateLine struct {
	Rate   float64 `json:"rate" doc:"Price per litre"`
	Litres float64 `json:"litres"`
	Amount float64 `json:"amount"`
}

type rateRow struct {
	MemberID      string
	PricePerLitre float64
	Litres        float64
	Amount        float64
}

// ratesByFarmer is each farmer's milk in a period split by the price it was
// recorded at, the same collections (not rejected) that make up gross pay.
func (r *Repository) ratesByFarmer(ctx context.Context, saccoID string, from, to time.Time, memberID string) (map[string][]RateLine, error) {
	var rows []rateRow
	q := r.db.WithContext(ctx).Table("milk_collections").
		Select("member_id, price_per_litre, SUM(quantity_litres) AS litres, SUM(total_amount) AS amount").
		Where("sacco_id = ? AND deleted_at IS NULL AND status <> 'REJECTED' AND collection_date BETWEEN ? AND ?",
			saccoID, from.Format(dateLayout), to.Format(dateLayout))
	if memberID != "" {
		q = q.Where("member_id = ?", memberID)
	}
	if err := q.Group("member_id, price_per_litre").Scan(&rows).Error; err != nil {
		return nil, err
	}
	out := map[string][]RateLine{}
	for _, x := range rows {
		out[x.MemberID] = append(out[x.MemberID], RateLine{Rate: round2(x.PricePerLitre), Litres: round2(x.Litres), Amount: round2(x.Amount)})
	}
	for id := range out {
		sort.Slice(out[id], func(i, j int) bool { return out[id][i].Rate < out[id][j].Rate })
	}
	return out, nil
}

// applyRates gives each line its rates, and the rate to show in one cell:
// the price when there was one, otherwise gross ÷ litres, flagged as mixed.
func applyRates(lines []PayRunLine, rates map[string][]RateLine) {
	for i := range lines {
		l := &lines[i]
		l.Rates = rates[l.MemberID]
		if l.Rates == nil {
			l.Rates = []RateLine{}
		}
		switch {
		case len(l.Rates) == 1:
			l.Rate = l.Rates[0].Rate
		case l.Litres > 0:
			l.Rate = round2(l.Gross / l.Litres)
			l.MixedRates = len(l.Rates) > 1
		}
	}
}

// rateText is the register's Rate cell: "42.00", or "43.25*" for an average.
func rateText(l PayRunLine) string {
	if l.Rate == 0 {
		return ""
	}
	if l.MixedRates {
		return fmt.Sprintf("%.2f*", l.Rate)
	}
	return fmt.Sprintf("%.2f", l.Rate)
}

// withRates loads the rates for lines of a run.
func (s *Service) withRates(ctx context.Context, run *PayRun, lines []PayRunLine, memberID string) error {
	rates, err := s.repo.ratesByFarmer(ctx, run.SaccoID, run.FromDate, run.ToDate, memberID)
	if err != nil {
		return err
	}
	applyRates(lines, rates)
	return nil
}
