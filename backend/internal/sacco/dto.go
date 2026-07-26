package sacco

import (
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/response"
)

// CreateSaccoRequest defines the parameters required to provision a new Sacco.
type CreateSaccoRequest struct {
	Code      string  `json:"code" minLength:"2" doc:"Unique Sacco code identifier (e.g. KIKUYU-DAIRY)"`
	Name      string  `json:"name" minLength:"3" doc:"Official Sacco business name"`
	Email     *string `json:"email,omitempty" format:"email" doc:"Official email address"`
	Phone     *string `json:"phone,omitempty" doc:"Official contact phone number"`
	Address   *string `json:"address,omitempty" doc:"Physical location address"`
	AdminUser struct {
		Username string  `json:"username" minLength:"3" doc:"Administrator username"`
		Email    string  `json:"email" format:"email" doc:"Administrator email address"`
		Phone    *string `json:"phone,omitempty" doc:"Administrator phone number"`
		Password string  `json:"password" minLength:"8" doc:"Administrator password"`
	} `json:"admin_user" doc:"Initial Sacco Administrator user details"`
}

type CreateSaccoInput struct {
	Body CreateSaccoRequest
}

type UpdateSaccoRequest struct {
	Name    *string `json:"name,omitempty" minLength:"3" doc:"Updated Sacco name"`
	Email   *string `json:"email,omitempty" format:"email" doc:"Updated Sacco email"`
	Phone   *string `json:"phone,omitempty" doc:"Updated Sacco phone"`
	Address *string `json:"address,omitempty" doc:"Updated physical address"`
}

type UpdateSaccoInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body UpdateSaccoRequest
}

type UpdateSaccoStatusRequest struct {
	Status Status `json:"status" enum:"ACTIVE,INACTIVE,SUSPENDED" doc:"New operational status"`
}

type UpdateSaccoStatusInput struct {
	ID   string `path:"id" doc:"Sacco UUID"`
	Body UpdateSaccoStatusRequest
}

type SaccoIDInput struct {
	ID string `path:"id" doc:"Sacco UUID"`
}

type ListSaccosInput struct {
	Page    int    `query:"page" doc:"Page number (default 1)"`
	PerPage int    `query:"per_page" doc:"Items per page (default 20)"`
	Search  string `query:"search" doc:"Search by Sacco code, name, email or phone"`
	Sort    string `query:"sort" doc:"Sort field e.g. -created_at or name"`
	Status  string `query:"status" doc:"Filter by status (ACTIVE, INACTIVE, SUSPENDED)"`
}

type SaccoData struct {
	Sacco *Sacco `json:"sacco"`
}

type SaccoOutput struct {
	Body response.Data[SaccoData]
}

type ListSaccosData struct {
	Saccos []Sacco    `json:"saccos"`
	Meta   query.Meta `json:"meta"`
}

type ListSaccosOutput struct {
	Body response.Data[ListSaccosData]
}

type UpdateSettingsRequest struct {
	Currency          *string `json:"currency,omitempty" doc:"Operating currency code (e.g. KES, UGX, USD)"`
	MilkUnit          *string `json:"milk_unit,omitempty" doc:"Unit of milk measurement (e.g. LITRES, KG)"`
	MorningCutoffTime *string `json:"morning_cutoff_time,omitempty" doc:"Morning collection cutoff time (HH:MM:SS)"`
	EveningCutoffTime *string `json:"evening_cutoff_time,omitempty" doc:"Evening collection cutoff time (HH:MM:SS)"`
}

type UpdateSettingsInput struct {
	Body UpdateSettingsRequest
}

type SettingsData struct {
	Settings *SaccoSettings `json:"settings"`
}

type SettingsOutput struct {
	Body response.Data[SettingsData]
}

type GetCurrentSaccoInput struct{}
