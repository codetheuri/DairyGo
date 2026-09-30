package collection

import (
	"context"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/sms"
)

type Service struct {
	repo       *Repository
	smsService *sms.Service
	authz      *authz.Evaluator
}

// NewService wires the collection service. The authz evaluator is used to
// tell Sacco admins (milk.collections.manage) apart from collectors when
// applying edit rules.
func NewService(repo *Repository, smsService *sms.Service, evaluator *authz.Evaluator) *Service {
	return &Service{repo: repo, smsService: smsService, authz: evaluator}
}

// actorFrom identifies the caller and whether they hold managePerm (e.g.
// milk.collections.manage), which makes them an admin for edit rules.
func (s *Service) actorFrom(ctx context.Context, managePerm string) (actor, error) {
	sub, ok := authz.DefaultSubjectExtractor(ctx)
	if !ok || sub.UserID == 0 {
		return actor{}, fmt.Errorf("%w: authenticated user identity is required", ErrForbidden)
	}
	canManage, err := s.authz.IsAuthorized(ctx, sub, authz.RequirePermissionPolicy{Permission: managePerm})
	if err != nil {
		return actor{}, err
	}
	return actor{userID: sub.UserID, canManage: canManage}, nil
}

// --- PRICING BUSINESS LOGIC ---

// SetPrice adds a buying price to the Sacco's rate schedule. It applies to
// collections dated on or after its effective date.
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
		parsed, err := time.ParseInLocation(dateLayout, strings.TrimSpace(*req.EffectiveDate), time.Local)
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

// auditEntityCollection is the entity_type used for collection audit entries.
const auditEntityCollection = "milk_collection"

// collectionSnapshot is the audited view of a collection's editable values.
type collectionSnapshot struct {
	QuantityLitres float64          `json:"quantity_litres"`
	PricePerLitre  float64          `json:"price_per_litre"`
	TotalAmount    float64          `json:"total_amount"`
	Shift          Shift            `json:"shift"`
	Status         CollectionStatus `json:"status"`
	Notes          *string          `json:"notes,omitempty"`
}

func snapshotOf(c *MilkCollection) collectionSnapshot {
	return collectionSnapshot{
		QuantityLitres: c.QuantityLitres,
		PricePerLitre:  c.PricePerLitre,
		TotalAmount:    c.TotalAmount,
		Shift:          c.Shift,
		Status:         c.Status,
		Notes:          c.Notes,
	}
}

// RecordCollection records milk received from an ACTIVE farmer of the caller's
// Sacco, priced at the rate in force on the collection date.
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

	member, err := s.repo.FindMemberForCollection(ctx, req.MemberID)
	if err != nil {
		return nil, err
	}
	if member.Status != "ACTIVE" {
		return nil, fmt.Errorf("member is %s and cannot supply milk; reactivate the member first", member.Status)
	}

	// Default collection date to today if omitted
	dateStr := time.Now().Format(dateLayout)
	if req.CollectionDate != nil && strings.TrimSpace(*req.CollectionDate) != "" {
		dateStr = strings.TrimSpace(*req.CollectionDate)
	}

	collectionDate, err := time.ParseInLocation(dateLayout, dateStr, time.Local)
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

	// Snapshot the buying price in force on the collection date.
	var pricePerLitre float64
	if req.PricePerLitre != nil && *req.PricePerLitre > 0 && middleware.IsSuperUser(ctx) {
		pricePerLitre = *req.PricePerLitre
	} else {
		price, err := s.repo.GetPriceForDate(ctx, collectionDate)
		if err != nil {
			return nil, fmt.Errorf("cannot record collection: %w", err)
		}
		pricePerLitre = price.PricePerLitre
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

	entry := audit.Entry{
		SaccoID:    saccoID,
		EntityType: auditEntityCollection,
		EntityID:   collection.ID,
		Action:     audit.ActionCreate,
		ActorID:    collectorID,
		NewValues:  snapshotOf(collection),
	}
	if err := s.repo.CreateCollection(ctx, collection, entry); err != nil {
		return nil, fmt.Errorf("failed to record milk collection: %w", err)
	}

	// Send an instant SMS receipt to the farmer if SMS is configured.
	if s.smsService != nil && member.Phone != "" {
		memberName := strings.TrimSpace(member.FirstName + " " + member.LastName)
		msg := fmt.Sprintf("Dear %s, %.2fL of milk collected on %s (%s shift). Rate: KES %.2f/L. Total: KES %.2f.", memberName, collection.QuantityLitres, dateStr, shift, collection.PricePerLitre, collection.TotalAmount)
		s.smsService.SendAsync(&saccoID, member.Phone, msg)
	}

	return collection, nil
}

// UpdateCollection edits quantity, shift or notes, subject to canEditCollection.
// Admin edits must give a reason; every edit is recorded in the audit history.
func (s *Service) UpdateCollection(ctx context.Context, id string, req *UpdateCollectionRequest) (*MilkCollection, error) {
	a, err := s.actorFrom(ctx, PermMilkCollectionsManage)
	if err != nil {
		return nil, err
	}

	collection, err := s.repo.FindCollectionByID(ctx, id)
	if err != nil {
		return nil, err
	}

	if err := canEditCollection(a, collection, time.Now().Format(dateLayout)); err != nil {
		return nil, err
	}

	reason := trimmedOrNil(req.Reason)
	if a.canManage && reason == nil {
		return nil, fmt.Errorf("a reason is required when an admin edits a collection")
	}

	before := snapshotOf(collection)

	if req.QuantityLitres != nil {
		if *req.QuantityLitres <= 0 {
			return nil, fmt.Errorf("quantity in litres must be greater than zero")
		}
		collection.QuantityLitres = math.Round(*req.QuantityLitres*100) / 100
		collection.TotalAmount = math.Round(collection.QuantityLitres*collection.PricePerLitre*100) / 100
	}

	if req.Shift != nil && *req.Shift != "" {
		newShift := Shift(strings.ToUpper(string(*req.Shift)))
		if newShift != collection.Shift {
			dateStr := collection.CollectionDate.Format(dateLayout)
			if existing, err := s.repo.FindByMemberAndDate(ctx, collection.SaccoID, collection.MemberID, dateStr, newShift); err == nil && existing != nil {
				return nil, fmt.Errorf("this member already has a %s collection on %s", newShift, dateStr)
			}
			collection.Shift = newShift
		}
	}

	if req.Notes != nil {
		collection.Notes = req.Notes
	}

	// An admin correction marks the record ADJUSTED so the collector cannot
	// overwrite it; it still needs to be verified afterwards.
	if a.canManage && collection.Status == StatusSubmitted {
		collection.Status = StatusAdjusted
	}

	entry := audit.Entry{
		SaccoID:    collection.SaccoID,
		EntityType: auditEntityCollection,
		EntityID:   collection.ID,
		Action:     audit.ActionUpdate,
		ActorID:    a.userID,
		Reason:     reason,
		OldValues:  before,
		NewValues:  snapshotOf(collection),
	}
	if err := s.repo.UpdateCollection(ctx, collection, entry); err != nil {
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

// UpdateCollectionStatus verifies, rejects, adjusts or reopens a collection
// following allowedTransitions, and records the change in the audit history.
func (s *Service) UpdateCollectionStatus(ctx context.Context, id string, req *UpdateCollectionStatusRequest) (*MilkCollection, error) {
	a, err := s.actorFrom(ctx, PermMilkCollectionsManage)
	if err != nil {
		return nil, err
	}

	collection, err := s.repo.FindCollectionByID(ctx, id)
	if err != nil {
		return nil, err
	}

	if err := validateStatusTransition(collection.Status, req.Status); err != nil {
		return nil, err
	}

	reason := trimmedOrNil(req.Reason)
	if reason == nil {
		reason = trimmedOrNil(req.Notes) // legacy clients send the reason as notes
	}
	if reason == nil && (req.Status == StatusRejected || req.Status == StatusAdjusted) {
		return nil, fmt.Errorf("a reason is required to set status %s", req.Status)
	}

	before := snapshotOf(collection)
	after := before
	after.Status = req.Status

	entry := audit.Entry{
		SaccoID:    collection.SaccoID,
		EntityType: auditEntityCollection,
		EntityID:   collection.ID,
		Action:     audit.ActionStatus,
		ActorID:    a.userID,
		Reason:     reason,
		OldValues:  before,
		NewValues:  after,
	}
	if err := s.repo.UpdateCollectionStatus(ctx, id, req.Status, entry); err != nil {
		return nil, fmt.Errorf("failed to update collection status: %w", err)
	}
	return s.repo.FindCollectionByID(ctx, id)
}

// CollectionHistory returns who created and changed a collection, oldest first.
func (s *Service) CollectionHistory(ctx context.Context, id string) ([]audit.Log, error) {
	collection, err := s.repo.FindCollectionByID(ctx, id)
	if err != nil {
		return nil, err
	}
	return s.repo.CollectionHistory(ctx, collection)
}

// trimmedOrNil returns nil for a missing or blank string.
func trimmedOrNil(s *string) *string {
	if s == nil {
		return nil
	}
	t := strings.TrimSpace(*s)
	if t == "" {
		return nil
	}
	return &t
}

// --- SALES BUSINESS LOGIC ---

// auditEntitySale is the entity_type used for sale audit entries.
const auditEntitySale = "milk_sale"

// saleSnapshot is the audited view of a sale's editable values.
type saleSnapshot struct {
	CustomerID     string     `json:"customer_id"`
	BuyerName      string     `json:"buyer_name"`
	QuantityLitres float64    `json:"quantity_litres"`
	UnitPrice      float64    `json:"unit_price"`
	TotalAmount    float64    `json:"total_amount"`
	AmountPaid     float64    `json:"amount_paid"`
	PaymentStatus  string     `json:"payment_status"`
	PaymentMethod  string     `json:"payment_method"`
	Notes          *string    `json:"notes,omitempty"`
	VoidedAt       *time.Time `json:"voided_at,omitempty"`
}

func saleSnapshotOf(s *MilkSale) saleSnapshot {
	return saleSnapshot{
		CustomerID: s.CustomerID, BuyerName: s.BuyerName, QuantityLitres: s.QuantityLitres,
		UnitPrice: s.UnitPrice, TotalAmount: s.TotalAmount, AmountPaid: s.AmountPaid,
		PaymentStatus: s.PaymentStatus, PaymentMethod: s.PaymentMethod, Notes: s.Notes, VoidedAt: s.VoidedAt,
	}
}

// RecordSale records milk sold to an ACTIVE customer of the caller's Sacco.
// The unit price defaults to the customer's agreed price; what was paid at the
// time of sale is settled by settleSale, and any remainder goes on the
// customer's running balance.
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

	customer, err := s.repo.FindCustomerForSale(ctx, strings.TrimSpace(req.CustomerID))
	if err != nil {
		return nil, err
	}
	if customer.Status != "ACTIVE" {
		return nil, fmt.Errorf("customer %s is %s; reactivate them before recording sales", customer.Name, customer.Status)
	}

	saleDate := time.Now()
	if req.SaleDate != nil && strings.TrimSpace(*req.SaleDate) != "" {
		saleDate, err = time.ParseInLocation(dateLayout, strings.TrimSpace(*req.SaleDate), time.Local)
		if err != nil {
			return nil, fmt.Errorf("invalid sale_date format, expected YYYY-MM-DD")
		}
	}

	unitPrice, err := resolveUnitPrice(req.UnitPrice, customer.DefaultPricePerLitre)
	if err != nil {
		return nil, err
	}

	quantity := math.Round(req.QuantityLitres*100) / 100
	total := math.Round(quantity*unitPrice*100) / 100

	method := ""
	if req.PaymentMethod != nil {
		method = strings.ToUpper(strings.TrimSpace(*req.PaymentMethod))
	}
	paid, status, method, err := settleSale(total, req.AmountPaid, method)
	if err != nil {
		return nil, err
	}

	sale := &MilkSale{
		ID:             uuid.New().String(),
		SaccoID:        saccoID,
		CollectorID:    collectorID,
		CustomerID:     customer.ID,
		CustomerType:   customer.CustomerType,
		SaleDate:       saleDate,
		BuyerName:      customer.Name,
		BuyerPhone:     customer.Phone,
		QuantityLitres: quantity,
		UnitPrice:      unitPrice,
		TotalAmount:    total,
		AmountPaid:     paid,
		PaymentStatus:  status,
		PaymentMethod:  method,
		Notes:          req.Notes,
	}

	entry := audit.Entry{
		SaccoID: saccoID, EntityType: auditEntitySale, EntityID: sale.ID,
		Action: audit.ActionCreate, ActorID: collectorID, NewValues: saleSnapshotOf(sale),
	}
	if err := s.repo.CreateSale(ctx, sale, entry); err != nil {
		return nil, fmt.Errorf("failed to record milk sale: %w", err)
	}

	return sale, nil
}

// UpdateSale corrects a sale, subject to canEditSale. Admin edits need a reason.
func (s *Service) UpdateSale(ctx context.Context, id string, req *UpdateSaleRequest) (*MilkSale, error) {
	a, err := s.actorFrom(ctx, PermMilkSalesManage)
	if err != nil {
		return nil, err
	}
	sale, err := s.repo.FindSaleByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if err := canEditSale(a, sale, time.Now().Format(dateLayout)); err != nil {
		return nil, err
	}
	reason := trimmedOrNil(req.Reason)
	if a.canManage && reason == nil {
		return nil, fmt.Errorf("a reason is required when an admin edits a sale")
	}

	before := saleSnapshotOf(sale)

	if req.CustomerID != nil && strings.TrimSpace(*req.CustomerID) != sale.CustomerID {
		customer, err := s.repo.FindCustomerForSale(ctx, strings.TrimSpace(*req.CustomerID))
		if err != nil {
			return nil, err
		}
		if customer.Status != "ACTIVE" {
			return nil, fmt.Errorf("customer %s is %s", customer.Name, customer.Status)
		}
		sale.CustomerID, sale.BuyerName, sale.BuyerPhone = customer.ID, customer.Name, customer.Phone
	}
	if req.QuantityLitres != nil {
		if *req.QuantityLitres <= 0 {
			return nil, fmt.Errorf("quantity in litres must be greater than zero")
		}
		sale.QuantityLitres = math.Round(*req.QuantityLitres*100) / 100
	}
	if req.UnitPrice != nil {
		if *req.UnitPrice <= 0 {
			return nil, fmt.Errorf("unit price must be greater than zero")
		}
		sale.UnitPrice = math.Round(*req.UnitPrice*100) / 100
	}
	if req.Notes != nil {
		sale.Notes = req.Notes
	}
	sale.TotalAmount = math.Round(sale.QuantityLitres*sale.UnitPrice*100) / 100

	// Re-settle: keep the previous amount paid unless a new one is given, and
	// keep the previous method unless a new one is given.
	amountPaid := sale.AmountPaid
	if req.AmountPaid != nil {
		amountPaid = *req.AmountPaid
	}
	method := sale.PaymentMethod
	if req.PaymentMethod != nil && *req.PaymentMethod != "" {
		method = strings.ToUpper(*req.PaymentMethod)
	}
	if amountPaid > 0 && method == "CREDIT" && req.PaymentMethod == nil {
		method = "CASH"
	}
	paid, status, method, err := settleSale(sale.TotalAmount, &amountPaid, method)
	if err != nil {
		return nil, err
	}
	sale.AmountPaid, sale.PaymentStatus, sale.PaymentMethod = paid, status, method

	entry := audit.Entry{
		SaccoID: sale.SaccoID, EntityType: auditEntitySale, EntityID: sale.ID,
		Action: audit.ActionUpdate, ActorID: a.userID, Reason: reason,
		OldValues: before, NewValues: saleSnapshotOf(sale),
	}
	if err := s.repo.UpdateSale(ctx, sale, entry); err != nil {
		return nil, fmt.Errorf("failed to update sale: %w", err)
	}
	return sale, nil
}

// VoidSale cancels a sale recorded in error. The sale stays on record for the
// audit trail but no longer counts in reconciliation or the customer's balance.
func (s *Service) VoidSale(ctx context.Context, id string, reason string) (*MilkSale, error) {
	reasonPtr := trimmedOrNil(&reason)
	if reasonPtr == nil {
		return nil, fmt.Errorf("a reason is required to void a sale")
	}
	sale, err := s.repo.FindSaleByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if sale.VoidedAt != nil {
		return nil, fmt.Errorf("%w: sale is already voided", ErrLocked)
	}

	before := saleSnapshotOf(sale)
	now := time.Now()
	sale.VoidedAt = &now
	sale.VoidReason = reasonPtr

	entry := audit.Entry{
		SaccoID: sale.SaccoID, EntityType: auditEntitySale, EntityID: sale.ID,
		Action: audit.ActionVoid, ActorID: middleware.GetUserID(ctx), Reason: reasonPtr,
		OldValues: before, NewValues: saleSnapshotOf(sale),
	}
	if err := s.repo.UpdateSale(ctx, sale, entry); err != nil {
		return nil, fmt.Errorf("failed to void sale: %w", err)
	}
	return sale, nil
}

// SaleHistory returns who created and changed a sale, oldest first.
func (s *Service) SaleHistory(ctx context.Context, id string) ([]audit.Log, error) {
	sale, err := s.repo.FindSaleByID(ctx, id)
	if err != nil {
		return nil, err
	}
	return s.repo.SaleHistory(ctx, sale)
}

// resolveUnitPrice uses the requested price, or the customer's agreed price.
func resolveUnitPrice(requested, customerDefault *float64) (float64, error) {
	switch {
	case requested != nil && *requested > 0:
		return math.Round(*requested*100) / 100, nil
	case requested != nil:
		return 0, fmt.Errorf("unit price must be greater than zero")
	case customerDefault != nil && *customerDefault > 0:
		return *customerDefault, nil
	default:
		return 0, fmt.Errorf("unit_price is required: this customer has no agreed price per litre")
	}
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
	if targetCollectorID != nil && *targetCollectorID > 0 && *targetCollectorID != collectorID {
		// Collectors may only reconcile their own shift; supervisors can audit anyone.
		if !middleware.SeesAllRecords(ctx) {
			return nil, fmt.Errorf("you can only view your own reconciliation")
		}
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
