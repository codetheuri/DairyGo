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
