package dashboard

// ExecutiveSummaryCards holds real-time aggregated metrics for Sacco Admins & Board Members.
type ExecutiveSummaryCards struct {
	TodayCollectedLitres          float64 `json:"today_collected_litres"`
	TodaySalesLitres              float64 `json:"today_sales_litres"`
	TodaySpoilageLitres           float64 `json:"today_spoilage_litres"`
	TodayNetCoolantStationLitres float64 `json:"today_net_coolant_station_litres"`
	MonthCollectedLitres          float64 `json:"month_collected_litres"`
	MonthPayoutLiabilityKES       float64 `json:"month_payout_liability_kes"`
	MonthSalesRevenueKES          float64 `json:"month_sales_revenue_kes"`
	ActiveMembersCount            int64   `json:"active_members_count"`
	ActiveCollectorsCount         int64   `json:"active_collectors_count"`
}

// DailyTrendPoint holds time-series metrics for intake vs sales vs spoilage charts.
type DailyTrendPoint struct {
	Date              string  `json:"date"`
	CollectedLitres   float64 `json:"collected_litres"`
	SalesLitres       float64 `json:"sales_litres"`
	SpoilageLitres    float64 `json:"spoilage_litres"`
	NetCoolantLitres float64 `json:"net_coolant_litres"`
}

// ExecutiveDashboardData represents full data structure for executive overview.
type ExecutiveDashboardData struct {
	SummaryCards ExecutiveSummaryCards `json:"summary_cards"`
	IntakeTrend  []DailyTrendPoint     `json:"intake_trend"`
}

// CollectorDashboardData represents real-time mobile dashboard metrics for a field collector.
type CollectorDashboardData struct {
	CollectorID                   uint    `json:"collector_id"`
	CollectorName                 string  `json:"collector_name"`
	Date                          string  `json:"date"`
	TodayCollectedLitres          float64 `json:"today_collected_litres"`
	TodayPurchasesAmount          float64 `json:"today_purchases_amount"`
	TodayFarmersServiced          int64   `json:"today_farmers_serviced"`
	TodaySoldLitres               float64 `json:"today_sold_litres"`
	TodaySalesRevenue             float64 `json:"today_sales_revenue"`
	TodaySpoiledLitres            float64 `json:"today_spoiled_litres"`
	TodayNetStationDeliveryLitres float64 `json:"today_net_station_delivery_litres"`
}
