package collection

import "github.com/codetheuri/tusk/pkg/response"

// SetMemberPriceRequest gives a farmer their own buying price from a date,
// or puts them back on the Sacco's price.
type SetMemberPriceRequest struct {
	PricePerLitre    *float64 `json:"price_per_litre,omitempty" doc:"The farmer's price per litre (leave out with back_to_sacco_price)"`
	BackToSaccoPrice bool     `json:"back_to_sacco_price,omitempty" doc:"From effective_date, pay this farmer the Sacco's price again"`
	EffectiveDate    string   `json:"effective_date" doc:"YYYY-MM-DD. The farmer's milk from this day that is not yet paid is repriced"`
	Reason           string   `json:"reason" doc:"Why, e.g. Agreed at the board meeting"`
	Preview          bool     `json:"preview,omitempty" doc:"Only say how many milk records would be repriced; save nothing"`
}

type MemberIDInput struct {
	ID string `path:"id" doc:"Farmer (member) id"`
}

type MemberPriceForDayInput struct {
	ID   string `path:"id" doc:"Farmer (member) id"`
	Date string `query:"date" doc:"YYYY-MM-DD (default today)"`
}

type SetMemberPriceInput struct {
	ID   string `path:"id" doc:"Farmer (member) id"`
	Body SetMemberPriceRequest
}

type VoidMemberPriceInput struct {
	ID      string `path:"id" doc:"Farmer (member) id"`
	PriceID string `path:"price_id" doc:"The schedule row to cancel"`
	Body    struct {
		Reason string `json:"reason" doc:"Why it is cancelled"`
	}
}

type MemberPricesOutput struct {
	Body response.Data[MemberPriceInfo]
}

type MemberPriceResultOutput struct {
	Body response.Data[MemberPriceResult]
}

// MemberDayPrice is the price a farmer's milk on a day is bought at.
type MemberDayPrice struct {
	PricePerLitre float64 `json:"price_per_litre"`
	Own           bool    `json:"own_price" doc:"True when it is the farmer's own price, not the Sacco's"`
}

type MemberDayPriceOutput struct {
	Body response.Data[MemberDayPrice]
}
