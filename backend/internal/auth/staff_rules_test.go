package auth

import (
	"errors"
	"testing"
)

func TestCanChangeStaff(t *testing.T) {
	admin := StaffAccount{ID: 7, Username: "mary", RoleID: RoleSaccoAdmin, IsActive: true}
	collector := StaffAccount{ID: 8, Username: "john", RoleID: RoleCollector, IsActive: true}

	tests := []struct {
		name        string
		actorID     uint
		target      StaffAccount
		keepsAdmin  bool
		otherAdmins int64
		wantErr     bool
		forbidden   bool
	}{
		{name: "admin removes a collector", actorID: 1, target: collector, otherAdmins: 1},
		{name: "admin makes a collector an admin", actorID: 1, target: collector, keepsAdmin: true, otherAdmins: 1},
		{name: "own account", actorID: 7, target: admin, otherAdmins: 3, wantErr: true, forbidden: true},
		{name: "own account, even keeping the role", actorID: 7, target: admin, keepsAdmin: true, otherAdmins: 3, wantErr: true, forbidden: true},
		{name: "another admin, others remain", actorID: 1, target: admin, otherAdmins: 1},
		{name: "the only admin is demoted or removed", actorID: 99, target: admin, otherAdmins: 0, wantErr: true},
		{name: "the only admin keeps the role", actorID: 99, target: admin, keepsAdmin: true, otherAdmins: 0},
		{
			name:    "a deactivated admin is not the Sacco's working admin",
			actorID: 99, target: StaffAccount{ID: 7, RoleID: RoleSaccoAdmin, IsActive: false}, otherAdmins: 0,
		},
		{name: "only collector in a Sacco without other admins", actorID: 99, target: collector, otherAdmins: 0},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := canChangeStaff(tt.actorID, tt.target, tt.keepsAdmin, tt.otherAdmins)
			if (err != nil) != tt.wantErr {
				t.Fatalf("canChangeStaff() error = %v, wantErr %v", err, tt.wantErr)
			}
			if got := errors.Is(err, ErrStaffForbidden); got != tt.forbidden {
				t.Errorf("forbidden = %v, want %v (err: %v)", got, tt.forbidden, err)
			}
		})
	}
}
