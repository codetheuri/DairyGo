package report

import (
	"context"
	"math"
	"time"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/query"
	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// GetFarmerPayoutStatements queries aggregated payroll & intake records per farmer.
func (r *Repository) GetFarmerPayoutStatements(ctx context.Context, fromDate, toDate time.Time, memberID string, page, perPage int) ([]FarmerPayoutStatement, query.Meta, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)

	type queryResult struct {
		MemberID             string  `gorm:"member_id"`
		MembershipNumber     string  `gorm:"membership_number"`
		FirstName            string  `gorm:"first_name"`
		LastName             string  `gorm:"last_name"`
		Phone                string  `gorm:"phone"`
		MpesaNumber          *string `gorm:"mpesa_number"`
		BankAccountNumber    *string `gorm:"bank_account_number"`
		BankName             *string `gorm:"bank_name"`
		TotalLitres          float64 `gorm:"total_litres"`
		GrossAmountOwed      float64 `gorm:"gross_amount_owed"`
		CollectionsCount     int64   `gorm:"collections_count"`
	}

	session := r.db.WithContext(ctx).Table("members").
		Select("members.id as member_id, members.membership_number, members.first_name, members.last_name, members.phone, members.mpesa_number, members.bank_account_number, members.bank_name, COALESCE(SUM(milk_collections.quantity_litres), 0) as total_litres, COALESCE(SUM(milk_collections.total_amount), 0) as gross_amount_owed, COUNT(milk_collections.id) as collections_count").
		Joins("JOIN milk_collections ON milk_collections.member_id = members.id AND milk_collections.deleted_at IS NULL AND milk_collections.status != 'REJECTED' AND DATE(milk_collections.collection_date) BETWEEN ? AND ?", fromDate.Format("2006-01-02"), toDate.Format("2006-01-02")).
		Where("members.sacco_id = ? AND members.deleted_at IS NULL", saccoID)

	if memberID != "" {
		session = session.Where("members.id = ?", memberID)
	}

	session = session.Group("members.id, members.membership_number, members.first_name, members.last_name, members.phone, members.mpesa_number, members.bank_account_number, members.bank_name")

	// Count total matching members for pagination
	var totalRecords int64
	var countResults []struct{ MemberID string }
	r.db.WithContext(ctx).Table("members").
		Joins("JOIN milk_collections ON milk_collections.member_id = members.id AND milk_collections.deleted_at IS NULL AND milk_collections.status != 'REJECTED' AND DATE(milk_collections.collection_date) BETWEEN ? AND ?", fromDate.Format("2006-01-02"), toDate.Format("2006-01-02")).
		Where("members.sacco_id = ? AND members.deleted_at IS NULL", saccoID).
		Group("members.id").Scan(&countResults)
	totalRecords = int64(len(countResults))

	if page <= 0 {
		page = 1
	}
	if perPage <= 0 {
		perPage = 20
	}
	offset := (page - 1) * perPage

	var results []queryResult
	err := session.Order("members.membership_number ASC").Limit(perPage).Offset(offset).Scan(&results).Error
	if err != nil {
		return nil, query.Meta{}, err
	}

	statements := make([]FarmerPayoutStatement, len(results))
	for i, res := range results {
		avgPrice := 0.0
		if res.TotalLitres > 0 {
			avgPrice = math.Round((res.GrossAmountOwed/res.TotalLitres)*100) / 100
		}

		statements[i] = FarmerPayoutStatement{
			MemberID:             res.MemberID,
			MembershipNumber:     res.MembershipNumber,
			FarmerName:           res.FirstName + " " + res.LastName,
			Phone:                res.Phone,
			MpesaNumber:          res.MpesaNumber,
			BankAccountNumber:    res.BankAccountNumber,
			BankName:             res.BankName,
			TotalLitres:          math.Round(res.TotalLitres*100) / 100,
			AveragePricePerLitre: avgPrice,
			GrossAmountOwed:      math.Round(res.GrossAmountOwed*100) / 100,
			CollectionsCount:     res.CollectionsCount,
			FromDate:             fromDate,
			ToDate:               toDate,
		}
	}

	totalPages := int(math.Ceil(float64(totalRecords) / float64(perPage)))
	meta := query.Meta{
		Page:        page,
		PerPage:     perPage,
		Total:       totalRecords,
		TotalPages:  totalPages,
		HasNext:     page < totalPages,
		HasPrevious: page > 1,
	}

	return statements, meta, nil
}

// GetSaccoReconciliationLedger computes Sacco-wide intake, field sales, spoilage, and coolant station delivery.
func (r *Repository) GetSaccoReconciliationLedger(ctx context.Context, fromDateStr, toDateStr string) (*SaccoReconciliationLedger, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)

	ledger := &SaccoReconciliationLedger{
		SaccoID:  saccoID,
		FromDate: fromDateStr,
		ToDate:   toDateStr,
	}

	// 1. Total Farmer Intake
	var intakeResult struct {
		TotalLitres    float64 `gorm:"total_litres"`
		TotalLiability float64 `gorm:"total_liability"`
	}
	r.db.WithContext(ctx).Table("milk_collections").
		Where("sacco_id = ? AND deleted_at IS NULL AND status != 'REJECTED' AND DATE(collection_date) BETWEEN ? AND ?", saccoID, fromDateStr, toDateStr).
		Select("COALESCE(SUM(quantity_litres), 0) as total_litres, COALESCE(SUM(total_amount), 0) as total_liability").
		Scan(&intakeResult)

	ledger.TotalFarmerIntakeLitres = math.Round(intakeResult.TotalLitres*100) / 100
	ledger.TotalFarmerLiabilityKES = math.Round(intakeResult.TotalLiability*100) / 100

	// 2. Total Field Sales
	var salesResult struct {
		TotalLitres  float64 `gorm:"total_litres"`
		TotalRevenue float64 `gorm:"total_revenue"`
	}
	r.db.WithContext(ctx).Table("milk_sales").
		Where("sacco_id = ? AND deleted_at IS NULL AND DATE(sale_date) BETWEEN ? AND ?", saccoID, fromDateStr, toDateStr).
		Select("COALESCE(SUM(quantity_litres), 0) as total_litres, COALESCE(SUM(total_amount), 0) as total_revenue").
		Scan(&salesResult)

	ledger.TotalFieldSalesLitres = math.Round(salesResult.TotalLitres*100) / 100
	ledger.TotalFieldSalesRevenueKES = math.Round(salesResult.TotalRevenue*100) / 100

	// 3. Total Spoilage
	var spoiledLitres float64
	r.db.WithContext(ctx).Table("milk_spoilage").
		Where("sacco_id = ? AND deleted_at IS NULL AND DATE(spoilage_date) BETWEEN ? AND ?", saccoID, fromDateStr, toDateStr).
		Select("COALESCE(SUM(quantity_litres), 0)").
		Scan(&spoiledLitres)

	ledger.TotalSpoilageLitres = math.Round(spoiledLitres*100) / 100

	// 4. Net Coolant Station Intake = Total Intake - Field Sales - Spoilage
	netCoolant := ledger.TotalFarmerIntakeLitres - ledger.TotalFieldSalesLitres - ledger.TotalSpoilageLitres
	if netCoolant < 0 {
		netCoolant = 0
	}
	ledger.NetCoolantStationLitres = math.Round(netCoolant*100) / 100

	// Mathematical Balancing Validation
	discrepancy := math.Abs((ledger.TotalFieldSalesLitres + ledger.TotalSpoilageLitres + ledger.NetCoolantStationLitres) - ledger.TotalFarmerIntakeLitres)
	ledger.DiscrepancyLitres = math.Round(discrepancy*100) / 100
	ledger.IsBalanced = discrepancy < 0.01

	// Fetch Collectors Audit Summaries for this period
	collectors, _, err := r.GetCollectorAuditSummaries(ctx, fromDateStr, toDateStr, 0, 1, 100)
	if err == nil {
		ledger.CollectorsSummary = collectors
	}

	// Fetch Sacco Name
	var saccoName string
	r.db.WithContext(ctx).Table("saccos").Where("id = ?", saccoID).Select("name").Scan(&saccoName)
	ledger.SaccoName = saccoName

	return ledger, nil
}

// GetCollectorAuditSummaries queries performance and transit metrics for collectors.
func (r *Repository) GetCollectorAuditSummaries(ctx context.Context, fromDateStr, toDateStr string, collectorID uint, page, perPage int) ([]CollectorAuditSummary, query.Meta, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)

	// Fetch active collectors in this Sacco
	type collectorRow struct {
		ID       uint   `gorm:"id"`
		Username string `gorm:"username"`
	}

	session := r.db.WithContext(ctx).Table("users").Select("users.id, users.username").Where("users.sacco_id = ?", saccoID)
	if collectorID > 0 {
		session = session.Where("users.id = ?", collectorID)
	}

	var collectors []collectorRow
	if err := session.Find(&collectors).Error; err != nil {
		return nil, query.Meta{}, err
	}

	summaries := make([]CollectorAuditSummary, 0, len(collectors))

	for _, c := range collectors {
		// Sum intake
		var intake struct {
			Litres      float64 `gorm:"litres"`
			Amount      float64 `gorm:"amount"`
			FarmerCount int64   `gorm:"farmer_count"`
		}
		r.db.WithContext(ctx).Table("milk_collections").
			Where("sacco_id = ? AND collector_id = ? AND status != 'REJECTED' AND deleted_at IS NULL AND DATE(collection_date) BETWEEN ? AND ?", saccoID, c.ID, fromDateStr, toDateStr).
			Select("COALESCE(SUM(quantity_litres), 0) as litres, COALESCE(SUM(total_amount), 0) as amount, COUNT(DISTINCT member_id) as farmer_count").
			Scan(&intake)

		// Sum sales
		var sales struct {
			Litres  float64 `gorm:"litres"`
			Revenue float64 `gorm:"revenue"`
		}
		r.db.WithContext(ctx).Table("milk_sales").
			Where("sacco_id = ? AND collector_id = ? AND deleted_at IS NULL AND DATE(sale_date) BETWEEN ? AND ?", saccoID, c.ID, fromDateStr, toDateStr).
			Select("COALESCE(SUM(quantity_litres), 0) as litres, COALESCE(SUM(total_amount), 0) as revenue").
			Scan(&sales)

		// Sum spoilage
		var spoiledLitres float64
		r.db.WithContext(ctx).Table("milk_spoilage").
			Where("sacco_id = ? AND collector_id = ? AND deleted_at IS NULL AND DATE(spoilage_date) BETWEEN ? AND ?", saccoID, c.ID, fromDateStr, toDateStr).
			Select("COALESCE(SUM(quantity_litres), 0)").
			Scan(&spoiledLitres)

		netDelivered := intake.Litres - sales.Litres - spoiledLitres
		if netDelivered < 0 {
			netDelivered = 0
		}

		// Only include collectors who have activity or if specific collector requested
		if intake.Litres > 0 || sales.Litres > 0 || spoiledLitres > 0 || collectorID > 0 {
			summaries = append(summaries, CollectorAuditSummary{
				CollectorID:          c.ID,
				CollectorName:        c.Username,
				TotalCollectedLitres: math.Round(intake.Litres*100) / 100,
				TotalPurchasesAmount: math.Round(intake.Amount*100) / 100,
				TotalSoldLitres:      math.Round(sales.Litres*100) / 100,
				TotalSalesRevenue:    math.Round(sales.Revenue*100) / 100,
				TotalSpoiledLitres:   math.Round(spoiledLitres*100) / 100,
				NetDeliveredLitres:   math.Round(netDelivered*100) / 100,
				FarmersServicedCount: intake.FarmerCount,
			})
		}
	}

	totalRecords := int64(len(summaries))
	meta := query.Meta{
		Page:        1,
		PerPage:     len(summaries),
		Total:       totalRecords,
		TotalPages:  1,
		HasNext:     false,
		HasPrevious: false,
	}

	return summaries, meta, nil
}
