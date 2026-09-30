package collection

import (
	"errors"
	"testing"
	"time"
)

func TestCanChangeTransfer(t *testing.T) {
	today := time.Now()
	yesterday := today.AddDate(0, 0, -1)
	todayStr := today.Format(dateLayout)
	voided := today

	sender := actor{userID: 7}
	receiver := actor{userID: 8}
	admin := actor{userID: 1, canManage: true}

	transfer := func(created time.Time, voidedAt *time.Time) *MilkTransfer {
		return &MilkTransfer{FromCollectorID: 7, ToCollectorID: 8, CreatedAt: created, VoidedAt: voidedAt}
	}

	tests := []struct {
		name string
		a    actor
		t    *MilkTransfer
		want error
	}{
		{"sender, same day", sender, transfer(today, nil), nil},
		{"sender, next day", sender, transfer(yesterday, nil), ErrLocked},
		{"receiver cannot change it", receiver, transfer(today, nil), ErrForbidden},
		{"admin, any day", admin, transfer(yesterday, nil), nil},
		{"cancelled is locked, even for admins", admin, transfer(today, &voided), ErrLocked},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := canChangeTransfer(tt.a, tt.t, todayStr)
			if tt.want == nil && err != nil || tt.want != nil && !errors.Is(err, tt.want) {
				t.Fatalf("got %v, want %v", err, tt.want)
			}
		})
	}
}

func TestTransferDayAndLitres(t *testing.T) {
	now := time.Date(2026, 9, 30, 18, 0, 0, 0, time.Local)
	if d, err := transferDay(nil, now); err != nil || d.Format(dateLayout) != "2026-09-30" {
		t.Fatalf("default: %v %v", d, err)
	}
	past := "2026-09-29"
	if _, err := transferDay(&past, now); err != nil {
		t.Fatalf("yesterday: %v", err)
	}
	future := "2026-10-01"
	if _, err := transferDay(&future, now); err == nil {
		t.Fatal("a future date must be refused")
	}
	bad := "30/09/2026"
	if _, err := transferDay(&bad, now); err == nil {
		t.Fatal("a malformed date must be refused")
	}

	if l, err := transferLitres(20.456); err != nil || l != 20.46 {
		t.Fatalf("rounding: %v %v", l, err)
	}
	for _, q := range []float64{0, -5} {
		if _, err := transferLitres(q); err == nil {
			t.Fatalf("%v litres must be refused", q)
		}
	}
}
