package superadmin

import (
	"github.com/codetheuri/tusk/internal/auth"
	"github.com/codetheuri/tusk/internal/member"
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/response"
)

type OverviewInput struct{}

type OverviewOutput struct {
	Body response.Data[*Overview]
}

type SaccoIDInput struct {
	ID string `path:"id" doc:"Sacco UUID"`
}

type StaffData struct {
	Users []StaffUser `json:"users"`
}

type StaffOutput struct {
	Body response.Data[StaffData]
}

type AddStaffRequest struct {
	Username  string  `json:"username" minLength:"3" doc:"Login username"`
	Email     string  `json:"email" format:"email" doc:"Email address"`
	Phone     *string `json:"phone,omitempty" doc:"Phone number"`
	FirstName string  `json:"first_name" doc:"First name"`
	LastName  string  `json:"last_name" doc:"Last name"`
	Password  string  `json:"password" minLength:"8" doc:"Initial password"`
	RoleID    uint    `json:"role_id" doc:"1 = Sacco Administrator, 2 = Milk Collector, 3 = Board Member / Executive"`
}

type AddStaffInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body AddStaffRequest
}

type UserData struct {
	User *auth.User `json:"user"`
}

type UserOutput struct {
	Body response.Data[UserData]
}

type UserIDInput struct {
	ID uint `path:"id" doc:"User ID"`
}

type UserStatusInput struct {
	ID   uint `path:"id" doc:"User ID"`
	Body struct {
		IsActive bool    `json:"is_active" doc:"false deactivates the account and ends its sessions"`
		Reason   *string `json:"reason,omitempty" doc:"Why (kept in the audit trail)"`
	}
}

type UserRoleInput struct {
	ID   uint `path:"id" doc:"User ID"`
	Body struct {
		RoleID uint    `json:"role_id" doc:"1 = Sacco Administrator, 2 = Milk Collector, 3 = Board Member / Executive"`
		Reason *string `json:"reason,omitempty" maxLength:"255" doc:"Why (kept in the audit trail)"`
	}
}

type RemoveUserInput struct {
	ID     uint   `path:"id" doc:"User ID"`
	Reason string `query:"reason" maxLength:"255" doc:"Why (kept in the audit trail)"`
}

type ResetPasswordInput struct {
	ID   uint `path:"id" doc:"User ID"`
	Body struct {
		NewPassword string `json:"new_password" minLength:"8" doc:"New password to give the user"`
	}
}

type MessageOutput struct {
	Body response.Data[map[string]any]
}

type SaccoMembersInput struct {
	ID      string `path:"id" doc:"Sacco UUID"`
	Page    int    `query:"page" doc:"Page number"`
	PerPage int    `query:"per_page" doc:"Items per page"`
	Search  string `query:"search" doc:"Search by membership number, name, phone or national ID"`
	Status  string `query:"status" doc:"ACTIVE, INACTIVE or SUSPENDED"`
}

type MembersData struct {
	Members []member.Member `json:"members"`
	Meta    query.Meta      `json:"meta"`
}

type MembersOutput struct {
	Body response.Data[MembersData]
}

type AddMemberInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body member.CreateMemberRequest
}

type MemberOutput struct {
	Body response.Data[map[string]*member.Member]
}

type LogsInput struct {
	SaccoID    string `query:"sacco_id" doc:"Only this Sacco"`
	EntityType string `query:"entity_type" doc:"Audit: milk_collection, milk_sale, customer, customer_payment, user, sacco"`
	Action     string `query:"action" doc:"Audit: CREATE, UPDATE, STATUS, VOID, DELETE"`
	Level      string `query:"level" doc:"Errors: WARN (4xx) or ERROR (5xx)"`
	Status     string `query:"status" doc:"Errors: status code or class (e.g. 500, 4xx); SMS: SENT, FAILED"`
	Search     string `query:"search" doc:"Errors: path or message; SMS: phone"`
	FromDate   string `query:"from_date" doc:"From date (YYYY-MM-DD)"`
	ToDate     string `query:"to_date" doc:"To date (YYYY-MM-DD)"`
	Page       int    `query:"page" doc:"Page number"`
	PerPage    int    `query:"per_page" doc:"Items per page (max 200)"`
}

func (in *LogsInput) filter() LogFilter {
	return LogFilter{
		SaccoID: in.SaccoID, EntityType: in.EntityType, Action: in.Action, Level: in.Level,
		Status: in.Status, Search: in.Search, FromDate: in.FromDate, ToDate: in.ToDate,
		Page: in.Page, PerPage: in.PerPage,
	}
}

type LogsData[T any] struct {
	Logs []T        `json:"logs"`
	Meta query.Meta `json:"meta"`
}

type AuditLogsOutput struct {
	Body response.Data[LogsData[AuditEntry]]
}

type SystemLogsOutput struct {
	Body response.Data[LogsData[SystemLog]]
}

type SMSLogsOutput struct {
	Body response.Data[LogsData[SMSEntry]]
}
