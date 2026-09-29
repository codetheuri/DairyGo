package report

import (
	"context"
	"math"
	"sort"
	"time"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/reconcile"
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
		MemberID          string  `gorm:"member_id"`
		MembershipNumber  string  `gorm:"membership_number"`
		FirstName         string  `gorm:"first_name"`
		LastName          string  `gorm:"last_name"`
		Phone             string  `gorm:"phone"`
		MpesaNumber       *string `gorm:"mpesa_number"`
		BankAccountNumber *string `gorm:"bank_account_number"`
		BankName          *string `gorm:"bank_name"`
		TotalLitres       float64 `gorm:"total_litres"`
		GrossAmountOwed   float64 `gorm:"gross_amount_owed"`
		CollectionsCount  int64   `gorm:"collections_count"`
	}

	session := r.db.WithContext(ctx).Table("members").
		Select("members.id as member_id, members.membership_number, members.first_name, members.last_name, members.phone, members.mpesa_number, members.bank_account_number, members.bank_name, COALESCE(SUM(milk_collections.quantity_litres), 0) as total_litres, COALESCE(SUM(milk_collections.total_amount), 0) as gross_amount_owed, COUNT(milk_collections.id) as collections_count").
		Joins("JOIN milk_collections ON milk_collections.member_id = members.id AND milk_collections.deleted_at IS NULL AND milk_collections.status != 'REJECTED' AND milk_collections.collection_date BETWEEN ? AND ?", fromDate.Format("2006-01-02"), toDate.Format("2006-01-02")).
		Where("members.sacco_id = ? AND members.deleted_at IS NULL", saccoID)

	if memberID != "" {
		session = session.Where("members.id = ?", memberID)
	}

	session = session.Group("members.id, members.membership_number, members.first_name, members.last_name, members.phone, members.mpesa_number, members.bank_account_number, members.bank_name")

	// Count total matching members for pagination
	var totalRecords int64
	var countResults []struct{ MemberID string }
	r.db.WithContext(ctx).Table("members").
		Joins("JOIN milk_collections ON milk_collections.member_id = members.id AND milk_collections.deleted_at IS NULL AND milk_collections.status != 'REJECTED' AND milk_collections.collection_date BETWEEN ? AND ?", fromDate.Format("2006-01-02"), toDate.Format("2006-01-02")).
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

// GetSaccoReconciliationLedger balances the Sacco's milk and money over a period.
func (r *Repository) GetSaccoReconciliationLedger(ctx context.Context, fromDateStr, toDateStr string) (*SaccoReconciliationLedger, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)
	ledger := &SaccoReconciliationLedger{SaccoID: saccoID, FromDate: fromDateStr, ToDate: toDateStr}

	collectors, err := r.collectorTotals(ctx, saccoID, fromDateStr, toDateStr, 0)
	if err != nil {
		return nil, err
	}

	var collected, liability, sold, revenue, paid, spoiled float64
	var collectorDays int64
	for _, c := range collectors {
		collected += c.TotalCollectedLitres
		liability += c.TotalPurchasesAmount
		sold += c.TotalSoldLitres
		revenue += c.TotalSalesRevenue
		paid += c.CashReceivedAmount
		spoiled += c.TotalSpoiledLitres
		collectorDays += c.ActiveDays
	}

	ledger.TotalFarmerIntakeLitres = round2(collected)
	ledger.TotalFarmerLiabilityKES = round2(liability)
	ledger.TotalSoldLitres = round2(sold)
	ledger.TotalSalesRevenueKES = round2(revenue)
	ledger.CashReceivedKES = round2(paid)
	ledger.CreditSalesKES = round2(revenue - paid)
	ledger.TotalSpoilageLitres = round2(spoiled)
	ledger.GrossMarginKES = round2(revenue - liability)

	tolerance := reconcile.ToleranceLitres(ctx, r.db, saccoID)
	ledger.Result = reconcile.Compute(collected, sold, spoiled, tolerance*float64(collectorDays))
	ledger.ReceivablesKES = reconcile.Receivables(ctx, r.db, saccoID)
	ledger.CollectorsSummary = collectors

	from, _ := time.ParseInLocation(reconcile.DateLayout, fromDateStr, time.Local)
	to, _ := time.ParseInLocation(reconcile.DateLayout, toDateStr, time.Local)
	if ledger.SalesByCustomerType, err = reconcile.SalesByCustomerType(ctx, r.db, saccoID, from, to, 0); err != nil {
		return nil, err
	}

	r.db.WithContext(ctx).Table("saccos").Where("id = ?", saccoID).Select("name").Scan(&ledger.SaccoName)
	return ledger, nil
}

// GetCollectorAuditSummaries balances each collector's milk over a period.
func (r *Repository) GetCollectorAuditSummaries(ctx context.Context, fromDateStr, toDateStr string, collectorID uint, page, perPage int) ([]CollectorAuditSummary, query.Meta, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)
	summaries, err := r.collectorTotals(ctx, saccoID, fromDateStr, toDateStr, collectorID)
	if err != nil {
		return nil, query.Meta{}, err
	}
	meta := query.Meta{
		Page:       1,
		PerPage:    len(summaries),
		Total:      int64(len(summaries)),
		TotalPages: 1,
	}
	return summaries, meta, nil
}

// collectorTotals builds per-collector summaries with three grouped queries
// (collections, sales, spoilage) regardless of the number of collectors.
// Only collectors with activity are returned, unless collectorID is given.
func (r *Repository) collectorTotals(ctx context.Context, saccoID, fromDateStr, toDateStr string, collectorID uint) ([]CollectorAuditSummary, error) {
	scope := func(table, dateCol string) *gorm.DB {
		q := r.db.WithContext(ctx).Table(table).
			Where("sacco_id = ? AND deleted_at IS NULL AND "+dateCol+" BETWEEN ? AND ?", saccoID, fromDateStr, toDateStr)
		if collectorID > 0 {
			q = q.Where("collector_id = ?", collectorID)
		}
		return q.Group("collector_id")
	}

	var intake []struct {
		CollectorID uint
		Litres      float64
		Amount      float64
		Farmers     int64
		Days        int64
	}
	if err := scope("milk_collections", "collection_date").
		Select("collector_id, SUM(quantity_litres) AS litres, SUM(total_amount) AS amount, COUNT(DISTINCT member_id) AS farmers, COUNT(DISTINCT collection_date) AS days").
		Where("status <> 'REJECTED'").
		Scan(&intake).Error; err != nil {
		return nil, err
	}

	var sales []struct {
		CollectorID uint
		Litres      float64
		Revenue     float64
		Paid        float64
	}
	if err := scope("milk_sales", "sale_date").
		Select("collector_id, SUM(quantity_litres) AS litres, SUM(total_amount) AS revenue, SUM(amount_paid) AS paid").
		Where("voided_at IS NULL").
		Scan(&sales).Error; err != nil {
		return nil, err
	}

	var spoilage []struct {
		CollectorID uint
		Litres      float64
	}
	if err := scope("milk_spoilage", "spoilage_date").
		Select("collector_id, SUM(quantity_litres) AS litres").
		Scan(&spoilage).Error; err != nil {
		return nil, err
	}

	byID := map[uint]*CollectorAuditSummary{}
	get := func(id uint) *CollectorAuditSummary {
		if s, ok := byID[id]; ok {
			return s
		}
		s := &CollectorAuditSummary{CollectorID: id}
		byID[id] = s
		return s
	}
	if collectorID > 0 {
		get(collectorID)
	}
	for _, row := range intake {
		s := get(row.CollectorID)
		s.TotalCollectedLitres, s.TotalPurchasesAmount = round2(row.Litres), round2(row.Amount)
		s.FarmersServicedCount, s.ActiveDays = row.Farmers, row.Days
	}
	for _, row := range sales {
		s := get(row.CollectorID)
		s.TotalSoldLitres, s.TotalSalesRevenue, s.CashReceivedAmount = round2(row.Litres), round2(row.Revenue), round2(row.Paid)
	}
	for _, row := range spoilage {
		get(row.CollectorID).TotalSpoiledLitres = round2(row.Litres)
	}

	ids := make([]uint, 0, len(byID))
	for id := range byID {
		ids = append(ids, id)
	}
	names := map[uint]string{}
	if len(ids) > 0 {
		var users []struct {
			ID       uint
			Username string
		}
		r.db.WithContext(ctx).Table("users").Select("id, username").Where("id IN ?", ids).Scan(&users)
		for _, u := range users {
			names[u.ID] = u.Username
		}
	}

	tolerance := reconcile.ToleranceLitres(ctx, r.db, saccoID)
	summaries := make([]CollectorAuditSummary, 0, len(byID))
	for _, s := range byID {
		s.CollectorName = names[s.CollectorID]
		days := s.ActiveDays
		if days == 0 && (s.TotalSoldLitres > 0 || s.TotalSpoiledLitres > 0) {
			days = 1 // sold or spoiled without collecting still gets one day's allowance
		}
		s.Result = reconcile.Compute(s.TotalCollectedLitres, s.TotalSoldLitres, s.TotalSpoiledLitres, tolerance*float64(days))
		s.ToleranceLitres = tolerance
		summaries = append(summaries, *s)
	}
	sort.Slice(summaries, func(i, j int) bool {
		return summaries[i].TotalCollectedLitres > summaries[j].TotalCollectedLitres
	})
	return summaries, nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
