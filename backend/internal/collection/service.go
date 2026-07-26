package collection

import (
	"context"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/sms"
)

type Service struct {
	repo       *Repository
	smsService *sms.Service
}

func NewService(repo *Repository, smsService *sms.Service) *Service {
	return &Service{repo: repo, smsService: smsService}
}

// --- PRICING BUSINESS LOGIC ---

func (s *Service) SetPrice(ctx context.Context, req *SetPriceRequest) (*MilkPrice, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("sacco context is required")
	}

	if req.PricePerLitre <= 0 {
		return nil, fmt.Errorf("price per litre must be greater than zero")
	}

	effectiveDate := time.Now()
	if req.EffectiveDate != nil && strings.TrimSpace(*req.EffectiveDate) != "" {
		parsed, err := time.Parse("2006-01-02", *req.EffectiveDate)
		if err != nil {
			return nil, fmt.Errorf("invalid effective_date format, expected YYYY-MM-DD")
		}
		effectiveDate = parsed
	}

	userID := middleware.GetUserID(ctx)
	var createdByID *uint
	if userID > 0 {
		createdByID = &userID
	}

	price := &MilkPrice{
		ID:            uuid.New().String(),
		SaccoID:       saccoID,
		PricePerLitre: math.Round(req.PricePerLitre*100) / 100,
		EffectiveDate: effectiveDate,
		IsActive:      true,
		CreatedByID:   createdByID,
	}

	if err := s.repo.CreatePrice(ctx, price); err != nil {
		return nil, fmt.Errorf("failed to save milk price: %w", err)
	}

	return price, nil
}

func (s *Service) GetActivePrice(ctx context.Context) (*MilkPrice, error) {
	return s.repo.GetActivePrice(ctx)
}

func (s *Service) ListPrices(ctx context.Context, q query.Query) ([]MilkPrice, query.Meta, error) {
	return s.repo.ListPrices(ctx, q)
}

// --- COLLECTION BUSINESS LOGIC ---

func (s *Service) RecordCollection(ctx context.Context, req *RecordCollectionRequest) (*MilkCollection, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("sacco context is required to record milk collections")
	}

	collectorID := middleware.GetUserID(ctx)
	if collectorID == 0 {
		return nil, fmt.Errorf("authenticated collector identity is required")
	}

	if req.QuantityLitres <= 0 {
		return nil, fmt.Errorf("quantity in litres must be greater than zero")
	}

	// Default collection date to today if omitted
	dateStr := time.Now().Format("2006-01-02")
	if req.CollectionDate != nil && strings.TrimSpace(*req.CollectionDate) != "" {
		dateStr = strings.TrimSpace(*req.CollectionDate)
	}

	collectionDate, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return nil, fmt.Errorf("invalid collection_date format, expected YYYY-MM-DD")
	}

	shift := ShiftMorning
	if req.Shift != nil && *req.Shift != "" {
		shift = Shift(strings.ToUpper(string(*req.Shift)))
	}

	// Restrict recording duplicate collection for the same member, date, and shift
	existing, err := s.repo.FindByMemberAndDate(ctx, saccoID, req.MemberID, dateStr, shift)
	if err == nil && existing != nil {
		return nil, fmt.Errorf("a collection for this member has already been recorded for date '%s' shift '%s'. Please edit the existing record instead", dateStr, shift)
	}

	// Resolve Snapshot Buying Price per Litre
	var pricePerLitre float64
	if req.PricePerLitre != nil && *req.PricePerLitre > 0 && middleware.IsSuperUser(ctx) {
		pricePerLitre = *req.PricePerLitre
	} else {
		activePrice, err := s.repo.GetActivePrice(ctx)
		if err != nil {
			return nil, fmt.Errorf("cannot record collection: %w", err)
		}
		pricePerLitre = activePrice.PricePerLitre
	}

	totalAmount := math.Round(req.QuantityLitres*pricePerLitre*100) / 100

	collection := &MilkCollection{
		ID:             uuid.New().String(),
		SaccoID:        saccoID,
		MemberID:       req.MemberID,
		CollectorID:    collectorID,
		CollectionDate: collectionDate,
		Shift:          shift,
		QuantityLitres: math.Round(req.QuantityLitres*100) / 100,
		PricePerLitre:  pricePerLitre,
		TotalAmount:    totalAmount,
		Status:         StatusSubmitted,
		Notes:          req.Notes,
	}

	if err := s.repo.CreateCollection(ctx, collection); err != nil {
		return nil, fmt.Errorf("failed to record milk collection: %w", err)
	}

	// Trigger Async Instant SMS Receipt to Farmer if SMS service is configured
	if s.smsService != nil {
		go func() {
			var memberPhone, memberName string
			row := s.repo.db.Table("members").Where("id = ?", req.MemberID).Select("phone, CONCAT(first_name, ' ', last_name) as member_name").Row()
			if err := row.Scan(&memberPhone, &memberName); err == nil && memberPhone != "" {
				msg := fmt.Sprintf("Dear %s, %.2fL of milk collected on %s (%s shift). Rate: KES %.2f/L. Total: KES %.2f.", memberName, collection.QuantityLitres, dateStr, shift, collection.PricePerLitre, collection.TotalAmount)
				s.smsService.SendAsync(&saccoID, memberPhone, msg)
			}
		}()
	}

	return collection, nil
}

func (s *Service) UpdateCollection(ctx context.Context, id string, req *UpdateCollectionRequest) (*MilkCollection, error) {
	collection, err := s.repo.FindCollectionByID(ctx, id)
	if err != nil {
		return nil, err
	}

	if req.QuantityLitres != nil {
		if *req.QuantityLitres <= 0 {
			return nil, fmt.Errorf("quantity in litres must be greater than zero")
		}
		collection.QuantityLitres = math.Round(*req.QuantityLitres*100) / 100
		collection.TotalAmount = math.Round(collection.QuantityLitres*collection.PricePerLitre*100) / 100
	}

	if req.Shift != nil && *req.Shift != "" {
		collection.Shift = Shift(strings.ToUpper(string(*req.Shift)))
	}

	if req.Notes != nil {
		collection.Notes = req.Notes
	}

	if err := s.repo.UpdateCollection(ctx, collection); err != nil {
		return nil, fmt.Errorf("failed to update collection: %w", err)
	}

	return collection, nil
}

func (s *Service) GetCollectionByID(ctx context.Context, id string) (*MilkCollection, error) {
	return s.repo.FindCollectionByID(ctx, id)
}

func (s *Service) ListCollections(ctx context.Context, q query.Query) ([]MilkCollection, query.Meta, error) {
	return s.repo.ListCollections(ctx, q)
}

func (s *Service) UpdateCollectionStatus(ctx context.Context, id string, req *UpdateCollectionStatusRequest) (*MilkCollection, error) {
	if err := s.repo.UpdateCollectionStatus(ctx, id, req.Status, req.Notes); err != nil {
		return nil, err
	}
	return s.repo.FindCollectionByID(ctx, id)
}

// --- SALES BUSINESS LOGIC ---

func (s *Service) RecordSale(ctx context.Context, req *RecordSaleRequest) (*MilkSale, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("sacco context is required to record milk sales")
	}

	collectorID := middleware.GetUserID(ctx)
	if collectorID == 0 {
		return nil, fmt.Errorf("authenticated user identity is required")
	}

	if req.QuantityLitres <= 0 {
		return nil, fmt.Errorf("quantity in litres must be greater than zero")
	}
	if req.UnitPrice <= 0 {
		return nil, fmt.Errorf("unit price must be greater than zero")
	}

	saleDate, err := time.Parse("2006-01-02", req.SaleDate)
	if err != nil {
		return nil, fmt.Errorf("invalid sale_date format, expected YYYY-MM-DD")
	}

	paymentStatus := "PAID"
	if req.PaymentStatus != nil && *req.PaymentStatus != "" {
		paymentStatus = strings.ToUpper(*req.PaymentStatus)
	}

	paymentMethod := "CASH"
	if req.PaymentMethod != nil && *req.PaymentMethod != "" {
		paymentMethod = strings.ToUpper(*req.PaymentMethod)
	}

	totalAmount := math.Round(req.QuantityLitres*req.UnitPrice*100) / 100

	sale := &MilkSale{
		ID:             uuid.New().String(),
		SaccoID:        saccoID,
		CollectorID:    collectorID,
		SaleDate:       saleDate,
		BuyerName:      strings.TrimSpace(req.BuyerName),
		BuyerPhone:     req.BuyerPhone,
		QuantityLitres: math.Round(req.QuantityLitres*100) / 100,
		UnitPrice:      math.Round(req.UnitPrice*100) / 100,
		TotalAmount:    totalAmount,
		PaymentStatus:  paymentStatus,
		PaymentMethod:  paymentMethod,
		Notes:          req.Notes,
	}

	if err := s.repo.CreateSale(ctx, sale); err != nil {
		return nil, fmt.Errorf("failed to record milk sale: %w", err)
	}

	return sale, nil
}

func (s *Service) ListSales(ctx context.Context, q query.Query) ([]MilkSale, query.Meta, error) {
	return s.repo.ListSales(ctx, q)
}

// --- SPOILAGE BUSINESS LOGIC ---

func (s *Service) RecordSpoilage(ctx context.Context, req *RecordSpoilageRequest) (*MilkSpoilage, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("sacco context is required")
	}

	collectorID := middleware.GetUserID(ctx)
	if collectorID == 0 {
		return nil, fmt.Errorf("authenticated user identity is required")
	}

	if req.QuantityLitres <= 0 {
		return nil, fmt.Errorf("quantity in litres must be greater than zero")
	}

	spoilageDate, err := time.Parse("2006-01-02", req.SpoilageDate)
	if err != nil {
		return nil, fmt.Errorf("invalid spoilage_date format, expected YYYY-MM-DD")
	}

	spoilage := &MilkSpoilage{
		ID:             uuid.New().String(),
		SaccoID:        saccoID,
		CollectorID:    collectorID,
		SpoilageDate:   spoilageDate,
		QuantityLitres: math.Round(req.QuantityLitres*100) / 100,
		Reason:         strings.TrimSpace(req.Reason),
		Notes:          req.Notes,
	}

	if err := s.repo.CreateSpoilage(ctx, spoilage); err != nil {
		return nil, fmt.Errorf("failed to record milk spoilage: %w", err)
	}

	return spoilage, nil
}

func (s *Service) ListSpoilage(ctx context.Context, q query.Query) ([]MilkSpoilage, query.Meta, error) {
	return s.repo.ListSpoilage(ctx, q)
}

// --- RECONCILIATION SUMMARY ---

func (s *Service) GetReconciliation(ctx context.Context, targetCollectorID *uint, dateStr string) (*CollectorReconciliation, error) {
	collectorID := middleware.GetUserID(ctx)
	if targetCollectorID != nil && *targetCollectorID > 0 {
		collectorID = *targetCollectorID
	}

	if collectorID == 0 {
		return nil, fmt.Errorf("collector identity is required")
	}

	if strings.TrimSpace(dateStr) == "" {
		dateStr = time.Now().Format("2006-01-02")
	}

	return s.repo.GetCollectorReconciliation(ctx, collectorID, dateStr)
}
