package dashboard

import (
	"context"
	"math"
	"time"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/reconcile"
)

const dateLayout = reconcile.DateLayout

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// dailyTotals is one day of Sacco activity.
type dailyTotals struct {
	collected, liability, sold, revenue, spoiled float64
	collectors                                   int64
}

// GetExecutiveDashboard computes the summary cards and the daily trend with one
// grouped query per table over the whole range, instead of a query per day.
func (r *Repository) GetExecutiveDashboard(ctx context.Context, days int) (*ExecutiveDashboardData, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.Local)
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local)
	trendStart := today.AddDate(0, 0, -(days - 1))

	rangeStart := trendStart
	if monthStart.Before(rangeStart) {
		rangeStart = monthStart
	}

	byDay, err := r.dailyTotals(ctx, saccoID, rangeStart, today)
	if err != nil {
		return nil, err
	}

	tolerance := reconcile.ToleranceLitres(ctx, r.db, saccoID)
	cards := ExecutiveSummaryCards{}

	t := byDay[today.Format(dateLayout)]
	balance := reconcile.Compute(t.collected, t.sold, t.spoiled, tolerance*float64(t.collectors))
	cards.TodayCollectedLitres = round2(t.collected)
	cards.TodaySalesLitres = round2(t.sold)
	cards.TodaySpoilageLitres = round2(t.spoiled)
	cards.TodayUnaccountedLitres = balance.UnaccountedLitres
	cards.TodayBalanceStatus = balance.Status
	r.db.WithContext(ctx).Table("milk_transfers").
		Select("COALESCE(SUM(quantity_litres), 0)").
		Where("sacco_id = ? AND deleted_at IS NULL AND voided_at IS NULL AND transfer_date = ?", saccoID, today.Format(dateLayout)).
		Scan(&cards.TodayTransferredLitres)
	cards.TodayTransferredLitres = round2(cards.TodayTransferredLitres)

	var monthRevenue, monthLiability, monthLitres float64
	for d := monthStart; !d.After(today); d = d.AddDate(0, 0, 1) {
		m := byDay[d.Format(dateLayout)]
		monthLitres += m.collected
		monthLiability += m.liability
		monthRevenue += m.revenue
	}
	cards.MonthCollectedLitres = round2(monthLitres)
	cards.MonthPayoutLiabilityKES = round2(monthLiability)
	cards.MonthSalesRevenueKES = round2(monthRevenue)
	cards.MonthGrossMarginKES = round2(monthRevenue - monthLiability)

	r.db.WithContext(ctx).Table("members").
		Where("sacco_id = ? AND status = 'ACTIVE' AND deleted_at IS NULL", saccoID).
		Count(&cards.ActiveMembersCount)
	r.db.WithContext(ctx).Table("user_roles").
		Joins("JOIN users ON users.id = user_roles.user_id").
		Where("users.sacco_id = ? AND user_roles.role_id = 2 AND users.is_active = true", saccoID).
		Count(&cards.ActiveCollectorsCount)
	cards.ReceivablesKES = reconcile.Receivables(ctx, r.db, saccoID)

	trend := make([]DailyTrendPoint, 0, days)
	for d := trendStart; !d.After(today); d = d.AddDate(0, 0, 1) {
		key := d.Format(dateLayout)
		p := byDay[key]
		trend = append(trend, DailyTrendPoint{
			Date:              key,
			CollectedLitres:   round2(p.collected),
			SalesLitres:       round2(p.sold),
			SpoilageLitres:    round2(p.spoiled),
			UnaccountedLitres: round2(p.collected - p.sold - p.spoiled),
		})
	}

	return &ExecutiveDashboardData{SummaryCards: cards, IntakeTrend: trend}, nil
}

// dailyTotals returns Sacco activity per day in [from, to], keyed by YYYY-MM-DD.
// Days without activity are absent (zero values).
func (r *Repository) dailyTotals(ctx context.Context, saccoID string, from, to time.Time) (map[string]dailyTotals, error) {
	fromStr, toStr := from.Format(dateLayout), to.Format(dateLayout)
	result := map[string]dailyTotals{}

	var intake []struct {
		Day        time.Time
		Litres     float64
		Amount     float64
		Collectors int64
	}
	if err := r.db.WithContext(ctx).Table("milk_collections").
		Select("collection_date AS day, SUM(quantity_litres) AS litres, SUM(total_amount) AS amount, COUNT(DISTINCT collector_id) AS collectors").
		Where("sacco_id = ? AND status <> 'REJECTED' AND deleted_at IS NULL AND collection_date BETWEEN ? AND ?", saccoID, fromStr, toStr).
		Group("collection_date").Scan(&intake).Error; err != nil {
		return nil, err
	}
	for _, row := range intake {
		key := row.Day.Format(dateLayout)
		d := result[key]
		d.collected, d.liability, d.collectors = row.Litres, row.Amount, row.Collectors
		result[key] = d
	}

	var sales []struct {
		Day     time.Time
		Litres  float64
		Revenue float64
	}
	if err := r.db.WithContext(ctx).Table("milk_sales").
		Select("sale_date AS day, SUM(quantity_litres) AS litres, SUM(total_amount) AS revenue").
		Where("sacco_id = ? AND deleted_at IS NULL AND voided_at IS NULL AND sale_date BETWEEN ? AND ?", saccoID, fromStr, toStr).
		Group("sale_date").Scan(&sales).Error; err != nil {
		return nil, err
	}
	for _, row := range sales {
		key := row.Day.Format(dateLayout)
		d := result[key]
		d.sold, d.revenue = row.Litres, row.Revenue
		result[key] = d
	}

	var spoilage []struct {
		Day    time.Time
		Litres float64
	}
	if err := r.db.WithContext(ctx).Table("milk_spoilage").
		Select("spoilage_date AS day, SUM(quantity_litres) AS litres").
		Where("sacco_id = ? AND deleted_at IS NULL AND spoilage_date BETWEEN ? AND ?", saccoID, fromStr, toStr).
		Group("spoilage_date").Scan(&spoilage).Error; err != nil {
		return nil, err
	}
	for _, row := range spoilage {
		key := row.Day.Format(dateLayout)
		d := result[key]
		d.spoiled = row.Litres
		result[key] = d
	}

	return result, nil
}

// GetCollectorDashboard computes a collector's day, transfers included.
func (r *Repository) GetCollectorDashboard(ctx context.Context, collectorID uint, dateStr string) (*CollectorDashboardData, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)
	data := &CollectorDashboardData{CollectorID: collectorID, Date: dateStr}

	var intake struct {
		Litres      float64
		Amount      float64
		FarmerCount int64
	}
	r.db.WithContext(ctx).Table("milk_collections").
		Select("COALESCE(SUM(quantity_litres), 0) AS litres, COALESCE(SUM(total_amount), 0) AS amount, COUNT(DISTINCT member_id) AS farmer_count").
		Where("sacco_id = ? AND collector_id = ? AND status <> 'REJECTED' AND deleted_at IS NULL AND collection_date = ?", saccoID, collectorID, dateStr).
		Scan(&intake)

	var sales struct {
		Litres  float64
		Revenue float64
		Paid    float64
	}
	r.db.WithContext(ctx).Table("milk_sales").
		Select("COALESCE(SUM(quantity_litres), 0) AS litres, COALESCE(SUM(total_amount), 0) AS revenue, COALESCE(SUM(amount_paid), 0) AS paid").
		Where("sacco_id = ? AND collector_id = ? AND deleted_at IS NULL AND voided_at IS NULL AND sale_date = ?", saccoID, collectorID, dateStr).
		Scan(&sales)

	var spoiled float64
	r.db.WithContext(ctx).Table("milk_spoilage").
		Select("COALESCE(SUM(quantity_litres), 0)").
		Where("sacco_id = ? AND collector_id = ? AND deleted_at IS NULL AND spoilage_date = ?", saccoID, collectorID, dateStr).
		Scan(&spoiled)

	var transfers struct {
		Received       float64
		TransferredOut float64
	}
	r.db.WithContext(ctx).Table("milk_transfers").
		Select(`COALESCE(SUM(CASE WHEN to_collector_id = ? THEN quantity_litres ELSE 0 END), 0) AS received,
			COALESCE(SUM(CASE WHEN from_collector_id = ? THEN quantity_litres ELSE 0 END), 0) AS transferred_out`,
			collectorID, collectorID).
		Where("sacco_id = ? AND deleted_at IS NULL AND voided_at IS NULL AND transfer_date = ?", saccoID, dateStr).
		Where("(from_collector_id = ? OR to_collector_id = ?)", collectorID, collectorID).
		Scan(&transfers)

	balance := reconcile.Balance(reconcile.Flows{
		Collected: intake.Litres, Received: transfers.Received,
		Sold: sales.Litres, TransferredOut: transfers.TransferredOut, Spoiled: spoiled,
	}, reconcile.ToleranceLitres(ctx, r.db, saccoID))
	data.TodayReceivedLitres = round2(transfers.Received)
	data.TodayTransferredOutLitres = round2(transfers.TransferredOut)
	data.TodayCollectedLitres = round2(intake.Litres)
	data.TodayPurchasesAmount = round2(intake.Amount)
	data.TodayFarmersServiced = intake.FarmerCount
	data.TodaySoldLitres = round2(sales.Litres)
	data.TodaySalesRevenue = round2(sales.Revenue)
	data.TodayCashReceived = round2(sales.Paid)
	data.TodaySpoiledLitres = round2(spoiled)
	data.TodayUnaccountedLitres = balance.UnaccountedLitres
	data.TodayBalanceStatus = balance.Status

	r.db.WithContext(ctx).Table("users").Where("id = ?", collectorID).Select("username").Scan(&data.CollectorName)
	return data, nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
