package customer

import (
	"github.com/codetheuri/tusk/pkg/audit"
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/response"
)

// --- CUSTOMER DTOs ---

type CreateCustomerRequest struct {
	Name                 string   `json:"name" minLength:"2" doc:"Customer or business name (e.g. Kiambu Cooler)"`
	Phone                *string  `json:"phone,omitempty" doc:"Contact phone; unique within the Sacco"`
	CustomerType         *string  `json:"customer_type,omitempty" enum:"COOLER,PROCESSOR,HOTEL,SHOP,INDIVIDUAL,OTHER" doc:"Customer type (default OTHER)"`
	DefaultPricePerLitre *float64 `json:"default_price_per_litre,omitempty" doc:"Agreed selling price per litre, prefilled on sales"`
	Notes                *string  `json:"notes,omitempty" doc:"Optional notes"`
}

type CreateCustomerInput struct {
	Body CreateCustomerRequest
}

type UpdateCustomerRequest struct {
	Name                 *string  `json:"name,omitempty" doc:"Customer or business name"`
	Phone                *string  `json:"phone,omitempty" doc:"Contact phone (empty string clears it)"`
	CustomerType         *string  `json:"customer_type,omitempty" enum:"COOLER,PROCESSOR,HOTEL,SHOP,INDIVIDUAL,OTHER" doc:"Customer type"`
	DefaultPricePerLitre *float64 `json:"default_price_per_litre,omitempty" doc:"Agreed selling price per litre (0 clears it)"`
	Notes                *string  `json:"notes,omitempty" doc:"Notes"`
}

type UpdateCustomerInput struct {
	ID   string `path:"id" doc:"Customer UUID"`
	Body UpdateCustomerRequest
}

type UpdateCustomerStatusInput struct {
	ID   string `path:"id" doc:"Customer UUID"`
	Body struct {
		Status Status `json:"status" enum:"ACTIVE,INACTIVE" doc:"New status"`
	}
}

type CustomerIDInput struct {
	ID string `path:"id" doc:"Customer UUID"`
}

type ListCustomersInput struct {
	Page         int    `query:"page" doc:"Page number (default 1)"`
	PerPage      int    `query:"per_page" doc:"Items per page (default 20)"`
	Search       string `query:"search" doc:"Search by name or phone"`
	Status       string `query:"status" doc:"Filter by status (ACTIVE, INACTIVE)"`
	CustomerType string `query:"customer_type" doc:"Filter by customer type"`
	Sort         string `query:"sort" doc:"Sort field (name, -created_at)"`
}

type CustomerData struct {
	Customer *Customer `json:"customer"`
}

type CustomerOutput struct {
	Body response.Data[CustomerData]
}

type ListCustomersData struct {
	Customers []Customer `json:"customers"`
	Meta      query.Meta `json:"meta"`
}

type ListCustomersOutput struct {
	Body response.Data[ListCustomersData]
}

type HistoryData struct {
	History []audit.Log `json:"history"`
}

type HistoryOutput struct {
	Body response.Data[HistoryData]
}

// --- LEDGER DTOs ---

type RecordPaymentRequest struct {
	Amount        float64 `json:"amount" minimum:"0.01" doc:"Amount received"`
	PaymentDate   *string `json:"payment_date,omitempty" doc:"Date received (YYYY-MM-DD), defaults to today"`
	Method        *string `json:"method,omitempty" enum:"CASH,MPESA,BANK_TRANSFER,CHEQUE" doc:"Payment method (default CASH)"`
	Reference     *string `json:"reference,omitempty" doc:"Transaction reference, e.g. M-Pesa code"`
	CashAccountID *string `json:"cash_account_id,omitempty" doc:"The Sacco account the money went into or came from (optional)"`
	Notes         *string `json:"notes,omitempty" doc:"Optional notes"`
}

type RecordPaymentInput struct {
	ID   string `path:"id" doc:"Customer UUID"`
	Body RecordPaymentRequest
}

type VoidPaymentInput struct {
	ID   string `path:"id" doc:"Payment UUID"`
	Body struct {
		Reason string `json:"reason" minLength:"3" doc:"Why the payment is being voided"`
	}
}

type PaymentData struct {
	Payment *Payment `json:"payment"`
}

type PaymentOutput struct {
	Body response.Data[PaymentData]
}

type StatementInput struct {
	ID       string `path:"id" doc:"Customer UUID"`
	FromDate string `query:"from_date" doc:"Start date (YYYY-MM-DD), defaults to the 1st of this month"`
	ToDate   string `query:"to_date" doc:"End date (YYYY-MM-DD), defaults to today"`
}

type StatementData struct {
	Statement *Statement `json:"statement"`
}

type StatementOutput struct {
	Body response.Data[StatementData]
}

type BalancesInput struct {
	OwingOnly bool `query:"owing_only" doc:"Only customers with a non-zero balance"`
}

type BalancesData struct {
	Balances  []Balance `json:"balances"`
	TotalOwed float64   `json:"total_owed" doc:"Sum of positive balances: what customers owe the Sacco"`
}

type BalancesOutput struct {
	Body response.Data[BalancesData]
}
