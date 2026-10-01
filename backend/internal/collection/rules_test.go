package collection

import (
	"errors"
	"testing"
	"time"
)

func TestCanEditCollection(t *testing.T) {
	now := time.Now()
	today := now.Format(dateLayout)
	yesterday := now.AddDate(0, 0, -1)

	collector := actor{userID: 7}
	otherCollector := actor{userID: 8}
	admin := actor{userID: 1, canManage: true}

	record := func(status CollectionStatus, createdAt time.Time) *MilkCollection {
		return &MilkCollection{CollectorID: 7, Status: status, CreatedAt: createdAt}
	}

	tests := []struct {
		name    string
		actor   actor
		c       *MilkCollection
		wantErr error
	}{
		{"collector edits own same-day submitted", collector, record(StatusSubmitted, now), nil},
		{"collector cannot edit yesterday's record", collector, record(StatusSubmitted, yesterday), ErrLocked},
		{"collector cannot edit another collector's record", otherCollector, record(StatusSubmitted, now), ErrForbidden},
		{"collector cannot edit adjusted record", collector, record(StatusAdjusted, now), ErrLocked},
		{"collector cannot edit verified record", collector, record(StatusVerified, now), ErrLocked},
		{"admin edits old submitted record", admin, record(StatusSubmitted, yesterday), nil},
		{"admin edits adjusted record", admin, record(StatusAdjusted, yesterday), nil},
		{"admin cannot edit verified record", admin, record(StatusVerified, now), ErrLocked},
		{"admin cannot edit rejected record", admin, record(StatusRejected, now), ErrLocked},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := canEditCollection(tt.actor, tt.c, today)
			if tt.wantErr == nil && err != nil {
				t.Fatalf("expected no error, got %v", err)
			}
			if tt.wantErr != nil && !errors.Is(err, tt.wantErr) {
				t.Fatalf("expected %v, got %v", tt.wantErr, err)
			}
		})
	}
}

func TestValidateStatusTransition(t *testing.T) {
	tests := []struct {
		from, to CollectionStatus
		ok       bool
	}{
		{StatusSubmitted, StatusVerified, true},
		{StatusSubmitted, StatusRejected, true},
		{StatusSubmitted, StatusAdjusted, true},
		{StatusAdjusted, StatusVerified, true},
		{StatusAdjusted, StatusRejected, true},
		{StatusVerified, StatusAdjusted, true},
		{StatusRejected, StatusAdjusted, true},
		{StatusVerified, StatusRejected, false},
		{StatusVerified, StatusSubmitted, false},
		{StatusRejected, StatusVerified, false},
		{StatusSubmitted, StatusSubmitted, false},
	}

	for _, tt := range tests {
		t.Run(string(tt.from)+"->"+string(tt.to), func(t *testing.T) {
			err := validateStatusTransition(tt.from, tt.to)
			if tt.ok && err != nil {
				t.Fatalf("expected allowed, got %v", err)
			}
			if !tt.ok && !errors.Is(err, ErrLocked) {
				t.Fatalf("expected ErrLocked, got %v", err)
			}
		})
	}
}

func TestSettleSale(t *testing.T) {
	f := func(v float64) *float64 { return &v }
	tests := []struct {
		name       string
		total      float64
		amountPaid *float64
		method     string
		wantPaid   float64
		wantStatus string
		wantMethod string
		wantErr    bool
	}{
		{"default is paid in full cash", 1000, nil, "", 1000, SalePaid, "CASH", false},
		{"mpesa in full", 1000, nil, "MPESA", 1000, SalePaid, "MPESA", false},
		{"credit defaults to nothing paid", 1000, nil, "CREDIT", 0, SaleCredit, "CREDIT", false},
		{"zero paid becomes credit", 1000, f(0), "CASH", 0, SaleCredit, "CREDIT", false},
		{"partial payment", 1000, f(400), "MPESA", 400, SalePartial, "MPESA", false},
		{"exact payment", 1000, f(1000), "CASH", 1000, SalePaid, "CASH", false},
		{"overpayment rejected", 1000, f(1200), "CASH", 0, "", "", true},
		{"negative rejected", 1000, f(-1), "CASH", 0, "", "", true},
		{"paid with credit method rejected", 1000, f(300), "CREDIT", 0, "", "", true},
		{"unknown method rejected", 1000, nil, "BARTER", 0, "", "", true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			paid, status, method, err := settleSale(tt.total, tt.amountPaid, tt.method)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("expected error, got paid=%v status=%v", paid, status)
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if paid != tt.wantPaid || status != tt.wantStatus || method != tt.wantMethod {
				t.Fatalf("got (%v, %s, %s), want (%v, %s, %s)", paid, status, method, tt.wantPaid, tt.wantStatus, tt.wantMethod)
			}
		})
	}
}

func TestCanEditSale(t *testing.T) {
	now := time.Now()
	today := now.Format(dateLayout)
	voided := now

	tests := []struct {
		name    string
		actor   actor
		sale    *MilkSale
		wantErr error
	}{
		{"collector edits own same-day sale", actor{userID: 7}, &MilkSale{CollectorID: 7, CreatedAt: now}, nil},
		{"collector cannot edit yesterday's sale", actor{userID: 7}, &MilkSale{CollectorID: 7, CreatedAt: now.AddDate(0, 0, -1)}, ErrLocked},
		{"collector cannot edit another's sale", actor{userID: 8}, &MilkSale{CollectorID: 7, CreatedAt: now}, ErrForbidden},
		{"admin edits old sale", actor{userID: 1, canManage: true}, &MilkSale{CollectorID: 7, CreatedAt: now.AddDate(0, 0, -9)}, nil},
		{"nobody edits voided sale", actor{userID: 1, canManage: true}, &MilkSale{CollectorID: 7, CreatedAt: now, VoidedAt: &voided}, ErrLocked},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := canEditSale(tt.actor, tt.sale, today)
			if tt.wantErr == nil && err != nil {
				t.Fatalf("expected no error, got %v", err)
			}
			if tt.wantErr != nil && !errors.Is(err, tt.wantErr) {
				t.Fatalf("expected %v, got %v", tt.wantErr, err)
			}
		})
	}
}

func TestResolveUnitPrice(t *testing.T) {
	f := func(v float64) *float64 { return &v }
	if p, err := resolveUnitPrice(f(55.555), f(50)); err != nil || p != 55.56 {
		t.Fatalf("requested price should win and round: %v %v", p, err)
	}
	if p, err := resolveUnitPrice(nil, f(50)); err != nil || p != 50 {
		t.Fatalf("customer default expected: %v %v", p, err)
	}
	if _, err := resolveUnitPrice(nil, nil); err == nil {
		t.Fatal("expected error when no price is available")
	}
	if _, err := resolveUnitPrice(f(0), f(50)); err == nil {
		t.Fatal("expected error for zero requested price")
	}
}

func TestSupplyRule(t *testing.T) {
	tests := []struct {
		status         string
		wantReactivate bool
		wantErr        bool
	}{
		{"ACTIVE", false, false},
		{"INACTIVE", true, false},
		{"SUSPENDED", false, true},
		{"", false, true},
	}
	for _, tt := range tests {
		reactivate, err := supplyRule(tt.status)
		if reactivate != tt.wantReactivate || (err != nil) != tt.wantErr {
			t.Errorf("supplyRule(%q) = %v, %v; want %v, error %v", tt.status, reactivate, err, tt.wantReactivate, tt.wantErr)
		}
		if err != nil && !errors.Is(err, ErrLocked) {
			t.Errorf("supplyRule(%q) error %v is not ErrLocked", tt.status, err)
		}
	}
}

func TestUserMessage(t *testing.T) {
	_, err := supplyRule("SUSPENDED")
	if got := userMessage(err, ErrLocked); got != "This farmer is suspended and cannot supply milk; an administrator must make them active first" {
		t.Errorf("userMessage = %q", got)
	}
	if got := userMessage(ErrNotFound, ErrNotFound); got != "Not found" {
		t.Errorf("bare sentinel = %q", got)
	}
}

func TestCheckPeriodOpen(t *testing.T) {
	closed := time.Date(2026, 9, 30, 0, 0, 0, 0, time.UTC)
	for day, locked := range map[string]bool{"2026-09-29": true, "2026-09-30": true, "2026-10-01": false} {
		d, _ := time.ParseInLocation(dateLayout, day, time.Local)
		err := checkPeriodOpen(d, &closed)
		if got := errors.Is(err, ErrLocked); got != locked {
			t.Errorf("%s: locked = %v, want %v (%v)", day, got, locked, err)
		}
	}
	if err := checkPeriodOpen(time.Now(), nil); err != nil {
		t.Errorf("before any pay run: %v", err)
	}
}
