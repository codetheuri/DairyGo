package report

import (
	"context"
	"sort"
	"time"

	"github.com/codetheuri/tusk/pkg/reconcile"
)

// LedgerDay is the Sacco's milk for one day of a ledger period, so a bad day
// shows without stepping through the period. Transfers between collectors
// cancel out at this level and are left out.
type LedgerDay struct {
	Date            string  `json:"date"`
	CollectedLitres float64 `json:"collected_litres"`
	SoldLitres      float64 `json:"sold_litres"`
	SpoiledLitres   float64 `json:"spoiled_litres"`
	SalesKES        float64 `json:"sales_kes"`
	reconcile.Result
}

// dayFlows is one day's totals from one kind of record.
type dayFlows struct {
	Day        time.Time
	Litres     float64
	Amount     float64
	Collectors int64
}

// mergeDays joins the day totals of intake, sales and spoilage, oldest day
// first, and balances each day: the Sacco allows tolerance litres per
// collector who took milk that day, as for the whole period.
func mergeDays(intake, sales, spoilage []dayFlows, tolerance float64) []LedgerDay {
	byDate := map[string]*LedgerDay{}
	collectors := map[string]int64{}
	get := func(d time.Time) *LedgerDay {
		key := d.Format(reconcile.DateLayout)
		if row, ok := byDate[key]; ok {
			return row
		}
		row := &LedgerDay{Date: key}
		byDate[key] = row
		return row
	}
	for _, f := range intake {
		row := get(f.Day)
		row.CollectedLitres += f.Litres
		collectors[row.Date] += f.Collectors
	}
	for _, f := range sales {
		row := get(f.Day)
		row.SoldLitres += f.Litres
		row.SalesKES += f.Amount
	}
	for _, f := range spoilage {
		get(f.Day).SpoiledLitres += f.Litres
	}
	days := make([]LedgerDay, 0, len(byDate))
	for _, row := range byDate {
		row.CollectedLitres = round2(row.CollectedLitres)
		row.SoldLitres = round2(row.SoldLitres)
		row.SpoiledLitres = round2(row.SpoiledLitres)
		row.SalesKES = round2(row.SalesKES)
		row.Result = reconcile.Compute(row.CollectedLitres, row.SoldLitres, row.SpoiledLitres,
			tolerance*float64(collectors[row.Date]))
		days = append(days, *row)
	}
	sort.Slice(days, func(i, j int) bool { return days[i].Date < days[j].Date })
	return days
}

// ledgerDays totals the Sacco's intake, sales and spoilage per day of the
// period: three grouped queries on the dated, indexed columns.
func (r *Repository) ledgerDays(ctx context.Context, saccoID, from, to string, tolerance float64) ([]LedgerDay, error) {
	scan := func(table, dateCol, sel, extra string) ([]dayFlows, error) {
		var rows []dayFlows
		q := r.db.WithContext(ctx).Table(table).
			Select(dateCol+" AS day, "+sel).
			Where("sacco_id = ? AND deleted_at IS NULL AND "+dateCol+" BETWEEN ? AND ?", saccoID, from, to)
		if extra != "" {
			q = q.Where(extra)
		}
		return rows, q.Group(dateCol).Scan(&rows).Error
	}
	intake, err := scan("milk_collections", "collection_date",
		"SUM(quantity_litres) AS litres, COUNT(DISTINCT collector_id) AS collectors", "status <> 'REJECTED'")
	if err != nil {
		return nil, err
	}
	sales, err := scan("milk_sales", "sale_date",
		"SUM(quantity_litres) AS litres, SUM(total_amount) AS amount", "voided_at IS NULL")
	if err != nil {
		return nil, err
	}
	spoilage, err := scan("milk_spoilage", "spoilage_date", "SUM(quantity_litres) AS litres", "")
	if err != nil {
		return nil, err
	}
	return mergeDays(intake, sales, spoilage, tolerance), nil
}
