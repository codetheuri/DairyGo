package auth

import "github.com/codetheuri/tusk/pkg/response"

type ChangeStaffRoleRequest struct {
	RoleID uint    `json:"role_id" doc:"1 = Sacco Administrator, 2 = Milk Collector, 3 = Board Member / Executive"`
	Reason *string `json:"reason,omitempty" maxLength:"255" doc:"Why (kept in the audit trail)"`
}

type ChangeStaffRoleInput struct {
	UserID uint `path:"user_id" doc:"User ID"`
	Body   ChangeStaffRoleRequest
}

type RemoveStaffInput struct {
	UserID uint   `path:"user_id" doc:"User ID"`
	Reason string `query:"reason" maxLength:"255" doc:"Why (kept in the audit trail)"`
}

type StaffUserData struct {
	User *User `json:"user"`
}

type StaffUserOutput struct {
	Body response.Data[StaffUserData]
}
