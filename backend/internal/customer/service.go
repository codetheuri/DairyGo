package customer

import (
	"context"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/authz"
	"github.com/codetheuri/tusk/pkg/query"
)

// Domain errors, mapped to HTTP status codes by the handler.
var (
	ErrNotFound = errors.New("not found")
	ErrConflict = errors.New("conflict")
	ErrLocked   = errors.New("locked")
)

const (
	dateLayout          = "2006-01-02"
	auditEntityCustomer = "customer"
	auditEntityPayment  = "customer_payment"
)

var validTypes = map[Type]bool{
	TypeCooler: true, TypeProcessor: true, TypeHotel: true, TypeShop: true, TypeIndividual: true, TypeOther: true,
}

var validMethods = map[PaymentMethod]bool{
	MethodCash: true, MethodMpesa: true, MethodBankTransfer: true, MethodCheque: true,
}

// Service holds the customer and ledger business rules.
type Service struct {
	repo  *Repository
	authz *authz.Evaluator
}

// NewService creates a customer service. The evaluator decides who may see
// balances (customers.statement.read).
func NewService(repo *Repository, evaluator *authz.Evaluator) *Service {
	return &Service{repo: repo, authz: evaluator}
}

// canSeeBalances reports whether the caller may see what customers owe.
// Collectors can find and add customers but do not see their balances.
func (s *Service) canSeeBalances(ctx context.Context) bool {
	sub, ok := authz.DefaultSubjectExtractor(ctx)
	if !ok {
		return false
	}
	allowed, err := s.authz.IsAuthorized(ctx, sub, authz.RequirePermissionPolicy{Permission: PermCustomerStatementRead})
	return err == nil && allowed
}

// Create adds a customer to the caller's Sacco. Phone numbers are unique per Sacco,
// so a collector searching by phone finds the existing customer instead of a duplicate.
func (s *Service) Create(ctx context.Context, req *CreateCustomerRequest) (*Customer, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok {
		return nil, fmt.Errorf("sacco context is required")
	}

	c := &Customer{
		ID:           uuid.New().String(),
		SaccoID:      saccoID,
		Name:         strings.TrimSpace(req.Name),
		Phone:        normalizePhone(req.Phone),
		CustomerType: TypeOther,
		Status:       StatusActive,
		Notes:        req.Notes,
	}
	if req.CustomerType != nil && *req.CustomerType != "" {
		c.CustomerType = Type(strings.ToUpper(*req.CustomerType))
	}
	if err := validateCustomer(c, req.DefaultPricePerLitre); err != nil {
		return nil, err
	}
	c.DefaultPricePerLitre = roundPtr(req.DefaultPricePerLitre)
	if err := s.ensurePhoneFree(ctx, saccoID, c.Phone, ""); err != nil {
		return nil, err
	}

	userID := middleware.GetUserID(ctx)
	if userID > 0 {
		c.CreatedByID = &userID
	}

	entry := audit.Entry{
		SaccoID: saccoID, EntityType: auditEntityCustomer, EntityID: c.ID,
		Action: audit.ActionCreate, ActorID: userID, NewValues: c,
	}
	if err := s.repo.Create(ctx, c, entry); err != nil {
		return nil, fmt.Errorf("failed to create customer: %w", err)
	}
	if s.canSeeBalances(ctx) {
		zero := 0.0
		c.Balance = &zero
	}
	return c, nil
}

// Update edits a customer's details.
func (s *Service) Update(ctx context.Context, id string, req *UpdateCustomerRequest) (*Customer, error) {
	c, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	before := *c

	if req.Name != nil {
		c.Name = strings.TrimSpace(*req.Name)
	}
	if req.Phone != nil {
		c.Phone = normalizePhone(req.Phone)
	}
	if req.CustomerType != nil && *req.CustomerType != "" {
		c.CustomerType = Type(strings.ToUpper(*req.CustomerType))
	}
	if req.DefaultPricePerLitre != nil {
		if *req.DefaultPricePerLitre == 0 {
			c.DefaultPricePerLitre = nil // 0 clears the default price
		} else {
			c.DefaultPricePerLitre = roundPtr(req.DefaultPricePerLitre)
		}
	}
	if req.Notes != nil {
		c.Notes = req.Notes
	}
	if err := validateCustomer(c, c.DefaultPricePerLitre); err != nil {
		return nil, err
	}
	if err := s.ensurePhoneFree(ctx, c.SaccoID, c.Phone, c.ID); err != nil {
		return nil, err
	}

	entry := audit.Entry{
		SaccoID: c.SaccoID, EntityType: auditEntityCustomer, EntityID: c.ID,
		Action: audit.ActionUpdate, ActorID: middleware.GetUserID(ctx), OldValues: before, NewValues: c,
	}
	if err := s.repo.Update(ctx, c, entry); err != nil {
		return nil, fmt.Errorf("failed to update customer: %w", err)
	}
	return s.withBalance(ctx, c)
}

// SetStatus activates or deactivates a customer. Inactive customers keep their
// ledger and can still pay, but no new sales can be recorded for them.
func (s *Service) SetStatus(ctx context.Context, id string, status Status) (*Customer, error) {
	if status != StatusActive && status != StatusInactive {
		return nil, fmt.Errorf("status must be ACTIVE or INACTIVE")
	}
	c, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	before := *c
	c.Status = status

	entry := audit.Entry{
		SaccoID: c.SaccoID, EntityType: auditEntityCustomer, EntityID: c.ID,
		Action: audit.ActionStatus, ActorID: middleware.GetUserID(ctx), OldValues: before, NewValues: c,
	}
	if err := s.repo.Update(ctx, c, entry); err != nil {
		return nil, fmt.Errorf("failed to update customer status: %w", err)
	}
	return s.withBalance(ctx, c)
}

// Get returns a customer with its current balance.
func (s *Service) Get(ctx context.Context, id string) (*Customer, error) {
	c, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	return s.withBalance(ctx, c)
}

// List returns a page of customers, with balances for callers allowed to see them.
func (s *Service) List(ctx context.Context, q query.Query) ([]Customer, query.Meta, error) {
	customers, meta, err := s.repo.List(ctx, q)
	if err != nil || len(customers) == 0 || !s.canSeeBalances(ctx) {
		return customers, meta, err
	}

	ids := make([]string, len(customers))
	for i, c := range customers {
		ids[i] = c.ID
	}
	balances, err := s.repo.Balances(ctx, customers[0].SaccoID, ids)
	if err != nil {
		return nil, meta, err
	}
	byID := make(map[string]float64, len(balances))
	for _, b := range balances {
		byID[b.CustomerID] = b.Balance
	}
	for i := range customers {
		b := byID[customers[i].ID]
		customers[i].Balance = &b
	}
	return customers, meta, nil
}

// Balances lists what customers owe, largest first. owingOnly drops customers
// whose balance is zero.
func (s *Service) Balances(ctx context.Context, owingOnly bool) ([]Balance, float64, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok {
		return nil, 0, fmt.Errorf("sacco context is required")
	}
	all, err := s.repo.Balances(ctx, saccoID, nil)
	if err != nil {
		return nil, 0, err
	}

	result := make([]Balance, 0, len(all))
	var totalOwed float64
	for _, b := range all {
		if b.Balance > 0 {
			totalOwed += b.Balance
		}
		if owingOnly && b.Balance == 0 {
			continue
		}
		result = append(result, b)
	}
	return result, round2(totalOwed), nil
}

// RecordPayment records money received from a customer. Payments reduce the
// running balance; they are not matched to individual sales.
func (s *Service) RecordPayment(ctx context.Context, customerID string, req *RecordPaymentRequest) (*Payment, error) {
	c, err := s.repo.FindByID(ctx, customerID)
	if err != nil {
		return nil, err
	}
	if req.Amount <= 0 {
		return nil, fmt.Errorf("amount must be greater than zero")
	}

	paymentDate := today()
	if req.PaymentDate != nil && strings.TrimSpace(*req.PaymentDate) != "" {
		paymentDate, err = time.ParseInLocation(dateLayout, strings.TrimSpace(*req.PaymentDate), time.Local)
		if err != nil {
			return nil, fmt.Errorf("invalid payment_date format, expected YYYY-MM-DD")
		}
	}
	if paymentDate.After(today()) {
		return nil, fmt.Errorf("payment_date cannot be in the future")
	}

	method := MethodCash
	if req.Method != nil && *req.Method != "" {
		method = PaymentMethod(strings.ToUpper(*req.Method))
	}
	if !validMethods[method] {
		return nil, fmt.Errorf("method must be CASH, MPESA, BANK_TRANSFER or CHEQUE")
	}

	userID := middleware.GetUserID(ctx)
	p := &Payment{
		ID:          uuid.New().String(),
		SaccoID:     c.SaccoID,
		CustomerID:  c.ID,
		Amount:      round2(req.Amount),
		PaymentDate: paymentDate,
		Method:      method,
		Reference:   trimmedOrNil(req.Reference),
		Notes:       req.Notes,
	}
	if userID > 0 {
		p.RecordedByID = &userID
	}
	if req.CashAccountID != nil && *req.CashAccountID != "" {
		if err := s.repo.CheckCashAccount(ctx, c.SaccoID, *req.CashAccountID); err != nil {
			return nil, err
		}
		p.CashAccountID = req.CashAccountID
	}

	entry := audit.Entry{
		SaccoID: c.SaccoID, EntityType: auditEntityPayment, EntityID: p.ID,
		Action: audit.ActionCreate, ActorID: userID, NewValues: p,
	}
	if err := s.repo.CreatePayment(ctx, p, entry); err != nil {
		return nil, fmt.Errorf("failed to record payment: %w", err)
	}
	return p, nil
}

// VoidPayment cancels a payment recorded in error. The payment stays on record
// for the audit trail but no longer reduces the balance.
func (s *Service) VoidPayment(ctx context.Context, paymentID string, reason string) (*Payment, error) {
	reasonPtr := trimmedOrNil(&reason)
	if reasonPtr == nil {
		return nil, fmt.Errorf("a reason is required to void a payment")
	}
	p, err := s.repo.FindPaymentByID(ctx, paymentID)
	if err != nil {
		return nil, err
	}
	if p.VoidedAt != nil {
		return nil, fmt.Errorf("%w: payment is already voided", ErrLocked)
	}

	before := *p
	now := time.Now()
	p.VoidedAt = &now
	p.VoidReason = reasonPtr

	entry := audit.Entry{
		SaccoID: p.SaccoID, EntityType: auditEntityPayment, EntityID: p.ID,
		Action: audit.ActionVoid, ActorID: middleware.GetUserID(ctx), Reason: reasonPtr,
		OldValues: before, NewValues: p,
	}
	if err := s.repo.VoidPayment(ctx, p, entry); err != nil {
		return nil, fmt.Errorf("failed to void payment: %w", err)
	}
	return p, nil
}

// Statement builds a customer's ledger for a period. The period defaults to the
// current month up to today.
func (s *Service) Statement(ctx context.Context, customerID, fromStr, toStr string) (*Statement, error) {
	c, err := s.repo.FindByID(ctx, customerID)
	if err != nil {
		return nil, err
	}
	from, to, err := parsePeriod(fromStr, toStr)
	if err != nil {
		return nil, err
	}

	opening, err := s.repo.OpeningBalance(ctx, c.SaccoID, c.ID, from)
	if err != nil {
		return nil, err
	}
	events, err := s.repo.LedgerEvents(ctx, c.SaccoID, c.ID, from, to)
	if err != nil {
		return nil, err
	}
	lines, debit, credit, closing := buildStatement(opening, events)

	if c, err = s.withBalance(ctx, c); err != nil {
		return nil, err
	}
	return &Statement{
		Customer:       c,
		FromDate:       from.Format(dateLayout),
		ToDate:         to.Format(dateLayout),
		OpeningBalance: opening,
		TotalDebit:     debit,
		TotalCredit:    credit,
		ClosingBalance: closing,
		Lines:          lines,
	}, nil
}

// History returns the audit trail of a customer.
func (s *Service) History(ctx context.Context, customerID string) ([]audit.Log, error) {
	c, err := s.repo.FindByID(ctx, customerID)
	if err != nil {
		return nil, err
	}
	return s.repo.History(ctx, c.SaccoID, auditEntityCustomer, c.ID)
}

// withBalance fills in the customer's balance when the caller may see it.
func (s *Service) withBalance(ctx context.Context, c *Customer) (*Customer, error) {
	if !s.canSeeBalances(ctx) {
		return c, nil
	}
	balances, err := s.repo.Balances(ctx, c.SaccoID, []string{c.ID})
	if err != nil {
		return nil, err
	}
	b := 0.0
	if len(balances) == 1 {
		b = balances[0].Balance
	}
	c.Balance = &b
	return c, nil
}

func (s *Service) ensurePhoneFree(ctx context.Context, saccoID string, phone *string, selfID string) error {
	if phone == nil {
		return nil
	}
	existing, err := s.repo.FindByPhone(ctx, saccoID, *phone)
	if err != nil {
		return err
	}
	if existing != nil && existing.ID != selfID {
		return fmt.Errorf("%w: customer %q already uses phone %s", ErrConflict, existing.Name, *phone)
	}
	return nil
}

func validateCustomer(c *Customer, defaultPrice *float64) error {
	if len(c.Name) < 2 {
		return fmt.Errorf("customer name must be at least 2 characters")
	}
	if !validTypes[c.CustomerType] {
		return fmt.Errorf("customer_type must be COOLER, PROCESSOR, HOTEL, SHOP, INDIVIDUAL or OTHER")
	}
	if defaultPrice != nil && *defaultPrice < 0 {
		return fmt.Errorf("default_price_per_litre cannot be negative")
	}
	return nil
}

// parsePeriod parses an inclusive date range, defaulting to month-to-date.
func parsePeriod(fromStr, toStr string) (time.Time, time.Time, error) {
	now := today()
	from := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local)
	to := now
	var err error
	if strings.TrimSpace(fromStr) != "" {
		if from, err = time.ParseInLocation(dateLayout, strings.TrimSpace(fromStr), time.Local); err != nil {
			return from, to, fmt.Errorf("invalid from_date format, expected YYYY-MM-DD")
		}
	}
	if strings.TrimSpace(toStr) != "" {
		if to, err = time.ParseInLocation(dateLayout, strings.TrimSpace(toStr), time.Local); err != nil {
			return from, to, fmt.Errorf("invalid to_date format, expected YYYY-MM-DD")
		}
	}
	if from.After(to) {
		return from, to, fmt.Errorf("from_date cannot be after to_date")
	}
	return from, to, nil
}

// today is midnight at the start of the current local day.
func today() time.Time {
	now := time.Now()
	return time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.Local)
}

// normalizePhone trims a phone number and removes inner spaces; blank becomes nil.
func normalizePhone(phone *string) *string {
	if phone == nil {
		return nil
	}
	p := strings.ReplaceAll(strings.TrimSpace(*phone), " ", "")
	if p == "" {
		return nil
	}
	return &p
}

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

func roundPtr(v *float64) *float64 {
	if v == nil {
		return nil
	}
	r := math.Round(*v*100) / 100
	return &r
}
