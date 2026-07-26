package dashboard

import (
	"context"
	"math"
	"time"

	"github.com/codetheuri/tusk/internal/middleware"
	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// GetExecutiveDashboard calculates executive metrics and daily trend chart data.
func (r *Repository) GetExecutiveDashboard(ctx context.Context, days int) (*ExecutiveDashboardData, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)
	now := time.Now()
	todayStr := now.Format("2006-01-02")
	monthStartStr := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location()).Format("2006-01-02")

	cards := ExecutiveSummaryCards{}

	// 1. Today's Collections
	var todayIntake struct {
		Litres float64 `gorm:"litres"`
	}
	r.db.WithContext(ctx).Table("milk_collections").
		Where("sacco_id = ? AND status != 'REJECTED' AND deleted_at IS NULL AND DATE(collection_date) = ?", saccoID, todayStr).
		Select("COALESCE(SUM(quantity_litres), 0) as litres").
		Scan(&todayIntake)
	cards.TodayCollectedLitres = math.Round(todayIntake.Litres*100) / 100

	// 2. Today's Field Sales
	var todaySales float64
	r.db.WithContext(ctx).Table("milk_sales").
		Where("sacco_id = ? AND deleted_at IS NULL AND DATE(sale_date) = ?", saccoID, todayStr).
		Select("COALESCE(SUM(quantity_litres), 0)").
		Scan(&todaySales)
	cards.TodaySalesLitres = math.Round(todaySales*100) / 100

	// 3. Today's Spoilage
	var todaySpoilage float64
	r.db.WithContext(ctx).Table("milk_spoilage").
		Where("sacco_id = ? AND deleted_at IS NULL AND DATE(spoilage_date) = ?", saccoID, todayStr).
		Select("COALESCE(SUM(quantity_litres), 0)").
		Scan(&todaySpoilage)
	cards.TodaySpoilageLitres = math.Round(todaySpoilage*100) / 100

	// Net Station Intake today
	netToday := cards.TodayCollectedLitres - cards.TodaySalesLitres - cards.TodaySpoilageLitres
	if netToday < 0 {
		netToday = 0
	}
	cards.TodayNetCoolantStationLitres = math.Round(netToday*100) / 100

	// 4. Month-to-Date Collections & Payout Liability
	var monthIntake struct {
		Litres    float64 `gorm:"litres"`
		Liability float64 `gorm:"liability"`
	}
	r.db.WithContext(ctx).Table("milk_collections").
		Where("sacco_id = ? AND status != 'REJECTED' AND deleted_at IS NULL AND DATE(collection_date) BETWEEN ? AND ?", saccoID, monthStartStr, todayStr).
		Select("COALESCE(SUM(quantity_litres), 0) as litres, COALESCE(SUM(total_amount), 0) as liability").
		Scan(&monthIntake)
	cards.MonthCollectedLitres = math.Round(monthIntake.Litres*100) / 100
	cards.MonthPayoutLiabilityKES = math.Round(monthIntake.Liability*100) / 100

	// 5. Month-to-Date Field Sales Revenue
	var monthSalesRevenue float64
	r.db.WithContext(ctx).Table("milk_sales").
		Where("sacco_id = ? AND deleted_at IS NULL AND DATE(sale_date) BETWEEN ? AND ?", saccoID, monthStartStr, todayStr).
		Select("COALESCE(SUM(total_amount), 0)").
		Scan(&monthSalesRevenue)
	cards.MonthSalesRevenueKES = math.Round(monthSalesRevenue*100) / 100

	// 6. Active Members Count
	var activeMembers int64
	r.db.WithContext(ctx).Table("members").
		Where("sacco_id = ? AND status = 'ACTIVE' AND deleted_at IS NULL", saccoID).
		Count(&activeMembers)
	cards.ActiveMembersCount = activeMembers

	// 7. Active Collectors Count
	var activeCollectors int64
	r.db.WithContext(ctx).Table("user_roles").
		Joins("JOIN users ON users.id = user_roles.user_id").
		Where("users.sacco_id = ? AND user_roles.role_id = 2 AND users.is_active = true", saccoID).
		Count(&activeCollectors)
	cards.ActiveCollectorsCount = activeCollectors

	// Generate Daily Trend Chart Series
	if days <= 0 {
		days = 7
	}
	if days > 30 {
		days = 30
	}

	trendPoints := make([]DailyTrendPoint, 0, days)
	for i := days - 1; i >= 0; i-- {
		targetDateStr := now.AddDate(0, 0, -i).Format("2006-01-02")

		var dIntake float64
		r.db.WithContext(ctx).Table("milk_collections").
			Where("sacco_id = ? AND status != 'REJECTED' AND deleted_at IS NULL AND DATE(collection_date) = ?", saccoID, targetDateStr).
			Select("COALESCE(SUM(quantity_litres), 0)").
			Scan(&dIntake)

		var dSales float64
		r.db.WithContext(ctx).Table("milk_sales").
			Where("sacco_id = ? AND deleted_at IS NULL AND DATE(sale_date) = ?", saccoID, targetDateStr).
			Select("COALESCE(SUM(quantity_litres), 0)").
			Scan(&dSales)

		var dSpoilage float64
		r.db.WithContext(ctx).Table("milk_spoilage").
			Where("sacco_id = ? AND deleted_at IS NULL AND DATE(spoilage_date) = ?", saccoID, targetDateStr).
			Select("COALESCE(SUM(quantity_litres), 0)").
			Scan(&dSpoilage)

		net := dIntake - dSales - dSpoilage
		if net < 0 {
			net = 0
		}

		trendPoints = append(trendPoints, DailyTrendPoint{
			Date:              targetDateStr,
			CollectedLitres:   math.Round(dIntake*100) / 100,
			SalesLitres:       math.Round(dSales*100) / 100,
			SpoilageLitres:    math.Round(dSpoilage*100) / 100,
			NetCoolantLitres: math.Round(net*100) / 100,
		})
	}

	return &ExecutiveDashboardData{
		SummaryCards: cards,
		IntakeTrend:  trendPoints,
	}, nil
}

// GetCollectorDashboard computes real-time mobile dashboard metrics for a field collector.
func (r *Repository) GetCollectorDashboard(ctx context.Context, collectorID uint, dateStr string) (*CollectorDashboardData, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)

	data := &CollectorDashboardData{
		CollectorID: collectorID,
		Date:        dateStr,
	}

	// 1. Intake
	var intake struct {
		Litres      float64 `gorm:"litres"`
		Amount      float64 `gorm:"amount"`
		FarmerCount int64   `gorm:"farmer_count"`
	}
	r.db.WithContext(ctx).Table("milk_collections").
		Where("sacco_id = ? AND collector_id = ? AND status != 'REJECTED' AND deleted_at IS NULL AND DATE(collection_date) = ?", saccoID, collectorID, dateStr).
		Select("COALESCE(SUM(quantity_litres), 0) as litres, COALESCE(SUM(total_amount), 0) as amount, COUNT(DISTINCT member_id) as farmer_count").
		Scan(&intake)

	data.TodayCollectedLitres = math.Round(intake.Litres*100) / 100
	data.TodayPurchasesAmount = math.Round(intake.Amount*100) / 100
	data.TodayFarmersServiced = intake.FarmerCount

	// 2. Field Sales
	var sales struct {
		Litres  float64 `gorm:"litres"`
		Revenue float64 `gorm:"revenue"`
	}
	r.db.WithContext(ctx).Table("milk_sales").
		Where("sacco_id = ? AND collector_id = ? AND deleted_at IS NULL AND DATE(sale_date) = ?", saccoID, collectorID, dateStr).
		Select("COALESCE(SUM(quantity_litres), 0) as litres, COALESCE(SUM(total_amount), 0) as revenue").
		Scan(&sales)

	data.TodaySoldLitres = math.Round(sales.Litres*100) / 100
	data.TodaySalesRevenue = math.Round(sales.Revenue*100) / 100

	// 3. Spoilage
	var spoiledLitres float64
	r.db.WithContext(ctx).Table("milk_spoilage").
		Where("sacco_id = ? AND collector_id = ? AND deleted_at IS NULL AND DATE(spoilage_date) = ?", saccoID, collectorID, dateStr).
		Select("COALESCE(SUM(quantity_litres), 0)").
		Scan(&spoiledLitres)

	data.TodaySpoiledLitres = math.Round(spoiledLitres*100) / 100

	netStation := data.TodayCollectedLitres - data.TodaySoldLitres - data.TodaySpoiledLitres
	if netStation < 0 {
		netStation = 0
	}
	data.TodayNetStationDeliveryLitres = math.Round(netStation*100) / 100

	// Collector username
	var username string
	r.db.WithContext(ctx).Table("users").Where("id = ?", collectorID).Select("username").Scan(&username)
	data.CollectorName = username

	return data, nil
}
