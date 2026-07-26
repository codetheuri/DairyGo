package collection

import (
	"context"
	"errors"
	"fmt"
	

	"github.com/codetheuri/tusk/pkg/query"
	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// --- PRICING REPOSITORY METHODS ---

func (r *Repository) CreatePrice(ctx context.Context, p *MilkPrice) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// Deactivate current active price for this sacco
		if err := tx.Model(&MilkPrice{}).Scopes(query.TenantScope(ctx)).Where("is_active = ?", true).Update("is_active", false).Error; err != nil {
			return err
		}
		p.IsActive = true
		return tx.Create(p).Error
	})
}

func (r *Repository) GetActivePrice(ctx context.Context) (*MilkPrice, error) {
	var p MilkPrice
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("is_active = ?", true).Order("effective_date DESC").First(&p).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("no active milk price configured for this Sacco")
		}
		return nil, err
	}
	return &p, nil
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

func (r *Repository) CreateCollection(ctx context.Context, c *MilkCollection) error {
	return r.db.WithContext(ctx).Create(c).Error
}

func (r *Repository) FindCollectionByID(ctx context.Context, id string) (*MilkCollection, error) {
	var c MilkCollection
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&c).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("milk collection record not found")
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

func (r *Repository) UpdateCollection(ctx context.Context, c *MilkCollection) error {
	return r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Save(c).Error
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
	return query.Paginate[MilkCollection](ctx, session, q, cfg)
}

func (r *Repository) UpdateCollectionStatus(ctx context.Context, id string, status CollectionStatus, notes *string) error {
	updates := map[string]interface{}{"status": status}
	if notes != nil {
		updates["notes"] = *notes
	}
	return r.db.WithContext(ctx).Model(&MilkCollection{}).Scopes(query.TenantScope(ctx)).Where("id = ?", id).Updates(updates).Error
}

// --- SALES REPOSITORY METHODS ---

func (r *Repository) CreateSale(ctx context.Context, s *MilkSale) error {
	return r.db.WithContext(ctx).Create(s).Error
}

func (r *Repository) FindSaleByID(ctx context.Context, id string) (*MilkSale, error) {
	var s MilkSale
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&s).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("milk sale record not found")
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
			"payment_status": "milk_sales.payment_status",
			"payment_method": "milk_sales.payment_method",
			"sale_date":      "milk_sales.sale_date",
		},
	}
	session := r.db.Model(&MilkSale{}).Scopes(query.TenantScope(ctx))
	return query.Paginate[MilkSale](ctx, session, q, cfg)
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
	return query.Paginate[MilkSpoilage](ctx, session, q, cfg)
}

// --- RECONCILIATION SUMMARY METHOD ---

func (r *Repository) GetCollectorReconciliation(ctx context.Context, collectorID uint, dateStr string) (*CollectorReconciliation, error) {
	recon := &CollectorReconciliation{
		CollectorID: collectorID,
		Date:        dateStr,
	}

	// 1. Sum Total Collected
	var collectionResult struct {
		TotalLitres float64 `gorm:"total_litres"`
		TotalAmount float64 `gorm:"total_amount"`
	}
	err := r.db.WithContext(ctx).Model(&MilkCollection{}).
		Scopes(query.TenantScope(ctx)).
		Where("collector_id = ? AND DATE(collection_date) = ? AND status != 'REJECTED'", collectorID, dateStr).
		Select("COALESCE(SUM(quantity_litres), 0) as total_litres, COALESCE(SUM(total_amount), 0) as total_amount").
		Scan(&collectionResult).Error
	if err != nil {
		return nil, err
	}
	recon.TotalCollectedLitres = collectionResult.TotalLitres
	recon.TotalPurchasesAmount = collectionResult.TotalAmount

	// 2. Sum Total Sold
	var salesResult struct {
		TotalLitres float64 `gorm:"total_litres"`
		TotalAmount float64 `gorm:"total_amount"`
	}
	err = r.db.WithContext(ctx).Model(&MilkSale{}).
		Scopes(query.TenantScope(ctx)).
		Where("collector_id = ? AND DATE(sale_date) = ?", collectorID, dateStr).
		Select("COALESCE(SUM(quantity_litres), 0) as total_litres, COALESCE(SUM(total_amount), 0) as total_amount").
		Scan(&salesResult).Error
	if err != nil {
		return nil, err
	}
	recon.TotalSoldLitres = salesResult.TotalLitres
	recon.TotalSalesAmount = salesResult.TotalAmount

	// 3. Sum Total Spoiled
	var spoiledLitres float64
	err = r.db.WithContext(ctx).Model(&MilkSpoilage{}).
		Scopes(query.TenantScope(ctx)).
		Where("collector_id = ? AND DATE(spoilage_date) = ?", collectorID, dateStr).
		Select("COALESCE(SUM(quantity_litres), 0)").
		Scan(&spoiledLitres).Error
	if err != nil {
		return nil, err
	}
	recon.TotalSpoiledLitres = spoiledLitres

	// 4. Net Delivered to Station = Total Collected - Total Sold - Total Spoiled
	recon.NetDeliveredLitres = recon.TotalCollectedLitres - recon.TotalSoldLitres - recon.TotalSpoiledLitres
	if recon.NetDeliveredLitres < 0 {
		recon.NetDeliveredLitres = 0
	}

	// Fetch collector user's username/name if available
	var userStruct struct {
		Username string `gorm:"username"`
	}
	if err := r.db.WithContext(ctx).Table("users").Where("id = ?", collectorID).Select("username").Take(&userStruct).Error; err == nil {
		recon.CollectorName = userStruct.Username
	}

	return recon, nil
}
