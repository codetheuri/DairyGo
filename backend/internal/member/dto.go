package member

import (
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/response"
)

type CreateMemberRequest struct {
	MembershipNumber  *string `json:"membership_number,omitempty" doc:"Optional membership number (auto-generated if omitted)"`
	FirstName         string  `json:"first_name" minLength:"2" doc:"Farmer first name"`
	LastName          string  `json:"last_name" minLength:"2" doc:"Farmer last name"`
	NationalID        *string `json:"national_id,omitempty" doc:"National ID or passport number"`
	Phone             string  `json:"phone" minLength:"10" doc:"Primary phone number"`
	Email             *string `json:"email,omitempty" format:"email" doc:"Optional email address"`
	Gender            *string `json:"gender,omitempty" enum:"MALE,FEMALE,OTHER" doc:"Gender identifier"`
	Location          *string `json:"location,omitempty" doc:"Village / Sub-County / Route location"`
	MpesaNumber       *string `json:"mpesa_number,omitempty" doc:"Mobile money payment phone number"`
	MpesaName         *string `json:"mpesa_name,omitempty" doc:"M-Pesa registered account holder name"`
	BankName          *string `json:"bank_name,omitempty" doc:"Bank name for direct deposit"`
	BankAccountNumber *string `json:"bank_account_number,omitempty" doc:"Bank account number"`
	BankBranch        *string `json:"bank_branch,omitempty" doc:"Bank branch name"`
}

type CreateMemberInput struct {
	Body CreateMemberRequest
}

type UpdateMemberRequest struct {
	FirstName         *string `json:"first_name,omitempty" minLength:"2" doc:"Farmer first name"`
	LastName          *string `json:"last_name,omitempty" minLength:"2" doc:"Farmer last name"`
	NationalID        *string `json:"national_id,omitempty" doc:"National ID"`
	Phone             *string `json:"phone,omitempty" minLength:"10" doc:"Phone number"`
	Email             *string `json:"email,omitempty" format:"email" doc:"Email address"`
	Gender            *string `json:"gender,omitempty" doc:"Gender"`
	Location          *string `json:"location,omitempty" doc:"Location"`
	MpesaNumber       *string `json:"mpesa_number,omitempty" doc:"M-Pesa phone number"`
	MpesaName         *string `json:"mpesa_name,omitempty" doc:"M-Pesa account name"`
	BankName          *string `json:"bank_name,omitempty" doc:"Bank name"`
	BankAccountNumber *string `json:"bank_account_number,omitempty" doc:"Bank account number"`
	BankBranch        *string `json:"bank_branch,omitempty" doc:"Bank branch"`
}

type UpdateMemberInput struct {
	ID   string `path:"id" doc:"Member UUID"`
	Body UpdateMemberRequest
}

type UpdateMemberStatusRequest struct {
	Status Status `json:"status" enum:"ACTIVE,INACTIVE,SUSPENDED" doc:"New operational status"`
}

type UpdateMemberStatusInput struct {
	ID   string `path:"id" doc:"Member UUID"`
	Body UpdateMemberStatusRequest
}

type MemberIDInput struct {
	ID string `path:"id" doc:"Member UUID"`
}

type ListMembersInput struct {
	Page    int    `query:"page" doc:"Page number (default 1)"`
	PerPage int    `query:"per_page" doc:"Items per page (default 20)"`
	Search  string `query:"search" doc:"Search by membership number, name, phone, or national ID"`
	Sort    string `query:"sort" doc:"Sort field e.g. -created_at or membership_number"`
	Status  string `query:"status" doc:"Filter by status (ACTIVE, INACTIVE, SUSPENDED)"`
}

type MemberData struct {
	Member *Member `json:"member"`
}

type MemberOutput struct {
	Body response.Data[MemberData]
}

type ListMembersData struct {
	Members []Member   `json:"members"`
	Meta    query.Meta `json:"meta"`
}

type ListMembersOutput struct {
	Body response.Data[ListMembersData]
}
