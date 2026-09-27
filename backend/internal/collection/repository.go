package collection

import (
	"context"
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
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

// helper to populate collector usernames
func (r *Repository) populateCollectorNames(ctx context.Context, collectorIDs []uint) map[uint]string {
	nameMap := make(map[uint]string)
	if len(collectorIDs) == 0 {
		return nameMap
	}
	var userRows []struct {
		ID       uint   `gorm:"id"`
		Username string `gorm:"username"`
	}
	if err := r.db.WithContext(ctx).Table("users").Where("id IN ?", collectorIDs).Select("id", "username").Scan(&userRows).Error; err == nil {
		for _, u := range userRows {
			nameMap[u.ID] = u.Username
		}
	}
	return nameMap
}

// --- PRICING REPOSITORY METHODS ---

// CreatePrice adds a price to the Sacco's rate schedule. Older prices stay
// active: the price for a date is chosen by effective_date (see GetPriceForDate).
func (r *Repository) CreatePrice(ctx context.Context, p *MilkPrice) error {
	p.IsActive = true
	return r.db.WithContext(ctx).Create(p).Error
}

// GetPriceForDate returns the price in force on date (YYYY-MM-DD): the latest
// non-voided price whose effective_date falls on or before that day.
func (r *Repository) GetPriceForDate(ctx context.Context, date time.Time) (*MilkPrice, error) {
	nextDay := date.AddDate(0, 0, 1).Format(dateLayout)

	var p MilkPrice
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).
		Where("is_active = ? AND effective_date < ?", true, nextDay).
		Order("effective_date DESC, created_at DESC").
		First(&p).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("no milk price configured for this Sacco on %s", date.Format(dateLayout))
		}
		return nil, err
	}
	return &p, nil
}

// GetActivePrice returns the price in force today.
func (r *Repository) GetActivePrice(ctx context.Context) (*MilkPrice, error) {
	return r.GetPriceForDate(ctx, time.Now())
}

// collectionMember is the subset of a farmer record needed to record a collection.
type collectionMember struct {
	ID        string
	Status    string
	Phone     string
	FirstName string
	LastName  string
}

// FindMemberForCollection loads a farmer from the caller's Sacco.
func (r *Repository) FindMemberForCollection(ctx context.Context, memberID string) (*collectionMember, error) {
	var m collectionMember
	err := r.db.WithContext(ctx).Table("members").
		Scopes(query.TenantScope(ctx)).
		Select("id, status, phone, first_name, last_name").
		Where("id = ? AND deleted_at IS NULL", memberID).
		Take(&m).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("%w: member not found in this Sacco", ErrNotFound)
		}
		return nil, err
	}
	return &m, nil
}

func (r *Repository) ListPrices(ctx context.Context, q query.Query) ([]MilkPrice, query.Meta, error) {
	cfg := query.Config{
		DefaultSort:    "-effective_date",
		DefaultPerPage: 20,
		MaxPerPage:     100,
		AllowedSorts: map[string]string{
			"effective_date": "milk_prices.effective_date",
			"created_at":     "milk_prices.created_at",
		},
	}
	session := r.db.Model(&MilkPrice{}).Scopes(query.TenantScope(ctx))
	return query.Paginate[MilkPrice](ctx, session, q, cfg)
}

// --- COLLECTION REPOSITORY METHODS ---

// CreateCollection saves a new collection and its CREATE audit entry atomically.
func (r *Repository) CreateCollection(ctx context.Context, c *MilkCollection, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(c).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

func (r *Repository) FindCollectionByID(ctx context.Context, id string) (*MilkCollection, error) {
	var c MilkCollection
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&c).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("%w: milk collection record not found", ErrNotFound)
		}
		return nil, err
	}
	return &c, nil
}

func (r *Repository) FindByMemberAndDate(ctx context.Context, saccoID, memberID, dateStr string, shift Shift) (*MilkCollection, error) {
	var c MilkCollection
	err := r.db.WithContext(ctx).Where("sacco_id = ? AND member_id = ? AND DATE(collection_date) = ? AND shift = ?", saccoID, memberID, dateStr, shift).First(&c).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("collection not found")
		}
		return nil, err
	}
	return &c, nil
}

// UpdateCollection saves an edited collection and its audit entry atomically.
func (r *Repository) UpdateCollection(ctx context.Context, c *MilkCollection, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Scopes(query.TenantScope(ctx)).Save(c).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// CollectionHistory returns the audit trail of one collection, oldest first.
func (r *Repository) CollectionHistory(ctx context.Context, c *MilkCollection) ([]audit.Log, error) {
	return audit.List(ctx, r.db, c.SaccoID, auditEntityCollection, c.ID)
}

func (r *Repository) ListCollections(ctx context.Context, q query.Query) ([]MilkCollection, query.Meta, error) {
	cfg := query.Config{
		DefaultSort:    "-collection_date",
		DefaultPerPage: 20,
		MaxPerPage:     100,
		AllowedSorts: map[string]string{
			"id":              "milk_collections.id",
			"collection_date": "milk_collections.collection_date",
			"quantity_litres": "milk_collections.quantity_litres",
			"total_amount":    "milk_collections.total_amount",
			"created_at":      "milk_collections.created_at",
		},
		AllowedSearches: []string{"milk_collections.notes"},
		AllowedFilters: map[string]string{
			"member_id":       "milk_collections.member_id",
			"collector_id":    "milk_collections.collector_id",
			"shift":           "milk_collections.shift",
			"status":          "milk_collections.status",
			"collection_date": "milk_collections.collection_date",
		},
	}
	session := r.db.Model(&MilkCollection{}).Scopes(query.TenantScope(ctx))

	// Enforce Role-Based Scoping: Collectors only see their own collections unless authorized Admin/Executive
	if !middleware.IsSuperUser(ctx) && !middleware.IsExecutiveOrAdmin(ctx) {
		collectorID := middleware.GetUserID(ctx)
		if collectorID > 0 {
			session = session.Where("milk_collections.collector_id = ?", collectorID)
		}
	}

	collections, meta, err := query.Paginate[MilkCollection](ctx, session, q, cfg)
	if err != nil {
		return nil, meta, err
	}

	// Populate collector_name for each item
	if len(collections) > 0 {
		ids := make([]uint, 0, len(collections))
		for _, c := range collections {
			ids = append(ids, c.CollectorID)
		}
		namesMap := r.populateCollectorNames(ctx, ids)
		for i := range collections {
			collections[i].CollectorName = namesMap[collections[i].CollectorID]
		}
	}

	return collections, meta, nil
}

// UpdateCollectionStatus changes a collection's status and saves the audit entry atomically.
func (r *Repository) UpdateCollectionStatus(ctx context.Context, id string, status CollectionStatus, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Model(&MilkCollection{}).Scopes(query.TenantScope(ctx)).Where("id = ?", id).Update("status", status).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// --- SALES REPOSITORY METHODS ---

// saleCustomer is the subset of a customer record needed to record a sale.
type saleCustomer struct {
	ID                   string
	Name                 string
	Phone                *string
	CustomerType         string
	Status               string
	DefaultPricePerLitre *float64
}

// FindCustomerForSale loads a customer from the caller's Sacco.
func (r *Repository) FindCustomerForSale(ctx context.Context, customerID string) (*saleCustomer, error) {
	var c saleCustomer
	err := r.db.WithContext(ctx).Table("customers").
		Scopes(query.TenantScope(ctx)).
		Select("id, name, phone, customer_type, status, default_price_per_litre").
		Where("id = ? AND deleted_at IS NULL", customerID).
		Take(&c).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("%w: customer not found in this Sacco", ErrNotFound)
		}
		return nil, err
	}
	return &c, nil
}

// CreateSale saves a sale and its audit entry atomically.
func (r *Repository) CreateSale(ctx context.Context, s *MilkSale, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(s).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// UpdateSale saves an edited or voided sale and its audit entry atomically.
func (r *Repository) UpdateSale(ctx context.Context, s *MilkSale, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Scopes(query.TenantScope(ctx)).Save(s).Error; err != nil {
			return err
		}
		return audit.Record(tx, entry)
	})
}

// SaleHistory returns the audit trail of one sale, oldest first.
func (r *Repository) SaleHistory(ctx context.Context, s *MilkSale) ([]audit.Log, error) {
	return audit.List(ctx, r.db, s.SaccoID, auditEntitySale, s.ID)
}

func (r *Repository) FindSaleByID(ctx context.Context, id string) (*MilkSale, error) {
	var s MilkSale
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&s).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("%w: milk sale record not found", ErrNotFound)
		}
		return nil, err
	}
	return &s, nil
}

func (r *Repository) ListSales(ctx context.Context, q query.Query) ([]MilkSale, query.Meta, error) {
	cfg := query.Config{
		DefaultSort:    "-sale_date",
		DefaultPerPage: 20,
		MaxPerPage:     100,
		AllowedSorts: map[string]string{
			"sale_date":       "milk_sales.sale_date",
			"quantity_litres": "milk_sales.quantity_litres",
			"total_amount":    "milk_sales.total_amount",
			"created_at":      "milk_sales.created_at",
		},
		AllowedSearches: []string{"milk_sales.buyer_name", "milk_sales.buyer_phone", "milk_sales.notes"},
		AllowedFilters: map[string]string{
			"collector_id":   "milk_sales.collector_id",
			"customer_id":    "milk_sales.customer_id",
			"payment_status": "milk_sales.payment_status",
			"payment_method": "milk_sales.payment_method",
			"sale_date":      "milk_sales.sale_date",
		},
	}
	session := r.db.Model(&MilkSale{}).Scopes(query.TenantScope(ctx))

	// Enforce Role-Based Scoping: Collectors only see their own sales unless authorized Admin/Executive
	if !middleware.IsSuperUser(ctx) && !middleware.IsExecutiveOrAdmin(ctx) {
		collectorID := middleware.GetUserID(ctx)
		if collectorID > 0 {
			session = session.Where("milk_sales.collector_id = ?", collectorID)
		}
	}

	sales, meta, err := query.Paginate[MilkSale](ctx, session, q, cfg)
	if err != nil {
		return nil, meta, err
	}

	// Populate collector_name for each sale item
	if len(sales) > 0 {
		ids := make([]uint, 0, len(sales))
		for _, s := range sales {
			ids = append(ids, s.CollectorID)
		}
		namesMap := r.populateCollectorNames(ctx, ids)
		customerIDs := make([]string, 0, len(sales))
		for _, s := range sales {
			customerIDs = append(customerIDs, s.CustomerID)
		}
		typesMap := r.customerTypes(ctx, customerIDs)
		for i := range sales {
			sales[i].CollectorName = namesMap[sales[i].CollectorID]
			sales[i].CustomerType = typesMap[sales[i].CustomerID]
		}
	}

	return sales, meta, nil
}

// customerTypes maps customer IDs to their type, for labelling sales in lists.
func (r *Repository) customerTypes(ctx context.Context, ids []string) map[string]string {
	types := make(map[string]string, len(ids))
	var rows []struct {
		ID           string
		CustomerType string
	}
	if err := r.db.WithContext(ctx).Table("customers").Select("id, customer_type").Where("id IN ?", ids).Scan(&rows).Error; err == nil {
		for _, row := range rows {
			types[row.ID] = row.CustomerType
		}
	}
	return types
}

// --- SPOILAGE REPOSITORY METHODS ---

func (r *Repository) CreateSpoilage(ctx context.Context, sp *MilkSpoilage) error {
	return r.db.WithContext(ctx).Create(sp).Error
}

func (r *Repository) ListSpoilage(ctx context.Context, q query.Query) ([]MilkSpoilage, query.Meta, error) {
	cfg := query.Config{
		DefaultSort:    "-spoilage_date",
		DefaultPerPage: 20,
		MaxPerPage:     100,
		AllowedSorts: map[string]string{
			"spoilage_date":   "milk_spoilage.spoilage_date",
			"quantity_litres": "milk_spoilage.quantity_litres",
		},
		AllowedSearches: []string{"milk_spoilage.reason", "milk_spoilage.notes"},
		AllowedFilters: map[string]string{
			"collector_id":  "milk_spoilage.collector_id",
			"spoilage_date": "milk_spoilage.spoilage_date",
		},
	}
	session := r.db.Model(&MilkSpoilage{}).Scopes(query.TenantScope(ctx))

	// Enforce Role-Based Scoping: Collectors only see their own spoilage unless authorized Admin/Executive
	if !middleware.IsSuperUser(ctx) && !middleware.IsExecutiveOrAdmin(ctx) {
		collectorID := middleware.GetUserID(ctx)
		if collectorID > 0 {
			session = session.Where("milk_spoilage.collector_id = ?", collectorID)
		}
	}

	spoilages, meta, err := query.Paginate[MilkSpoilage](ctx, session, q, cfg)
	if err != nil {
		return nil, meta, err
	}

	// Populate collector_name for each spoilage item
	if len(spoilages) > 0 {
		ids := make([]uint, 0, len(spoilages))
		for _, sp := range spoilages {
			ids = append(ids, sp.CollectorID)
		}
		namesMap := r.populateCollectorNames(ctx, ids)
		for i := range spoilages {
			spoilages[i].CollectorName = namesMap[spoilages[i].CollectorID]
		}
	}

	return spoilages, meta, nil
}

// --- RECONCILIATION SUMMARY METHOD ---

// GetCollectorReconciliation balances one collector's day. Queries use plain
// date equality (not DATE(col)) so the (sacco_id, collector_id, date) indexes apply.
func (r *Repository) GetCollectorReconciliation(ctx context.Context, collectorID uint, dateStr string) (*CollectorReconciliation, error) {
	saccoID, _ := middleware.GetSaccoID(ctx)
	day, err := time.ParseInLocation(dateLayout, dateStr, time.Local)
	if err != nil {
		return nil, fmt.Errorf("invalid date format, expected YYYY-MM-DD")
	}

	recon := &CollectorReconciliation{CollectorID: collectorID, Date: dateStr}

	var intake struct {
		Litres float64
		Amount float64
	}
	err = r.db.WithContext(ctx).Table("milk_collections").
		Select("COALESCE(SUM(quantity_litres), 0) AS litres, COALESCE(SUM(total_amount), 0) AS amount").
		Where("sacco_id = ? AND collector_id = ? AND collection_date = ? AND status <> 'REJECTED' AND deleted_at IS NULL", saccoID, collectorID, dateStr).
		Scan(&intake).Error
	if err != nil {
		return nil, err
	}

	var sales struct {
		Litres  float64
		Revenue float64
		Paid    float64
	}
	err = r.db.WithContext(ctx).Table("milk_sales").
		Select("COALESCE(SUM(quantity_litres), 0) AS litres, COALESCE(SUM(total_amount), 0) AS revenue, COALESCE(SUM(amount_paid), 0) AS paid").
		Where("sacco_id = ? AND collector_id = ? AND sale_date = ? AND deleted_at IS NULL AND voided_at IS NULL", saccoID, collectorID, dateStr).
		Scan(&sales).Error
	if err != nil {
		return nil, err
	}

	var spoiled float64
	err = r.db.WithContext(ctx).Table("milk_spoilage").
		Select("COALESCE(SUM(quantity_litres), 0)").
		Where("sacco_id = ? AND collector_id = ? AND spoilage_date = ? AND deleted_at IS NULL", saccoID, collectorID, dateStr).
		Scan(&spoiled).Error
	if err != nil {
		return nil, err
	}

	byType, err := reconcile.SalesByCustomerType(ctx, r.db, saccoID, day, day, collectorID)
	if err != nil {
		return nil, err
	}

	recon.TotalCollectedLitres = round2(intake.Litres)
	recon.TotalPurchasesAmount = round2(intake.Amount)
	recon.TotalSoldLitres = round2(sales.Litres)
	recon.TotalSalesAmount = round2(sales.Revenue)
	recon.CashReceivedAmount = round2(sales.Paid)
	recon.CreditSalesAmount = round2(sales.Revenue - sales.Paid)
	recon.TotalSpoiledLitres = round2(spoiled)
	recon.SalesByCustomerType = byType
	recon.Result = reconcile.Compute(intake.Litres, sales.Litres, spoiled, reconcile.ToleranceLitres(ctx, r.db, saccoID))

	var username string
	r.db.WithContext(ctx).Table("users").Where("id = ?", collectorID).Select("username").Scan(&username)
	recon.CollectorName = username

	return recon, nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
