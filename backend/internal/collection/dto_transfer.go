package collection

import (
	"github.com/codetheuri/tusk/pkg/query"
	"github.com/codetheuri/tusk/pkg/response"
)

// --- TRANSFER DTOs ---

type RecordTransferRequest struct {
	ToCollectorID   uint    `json:"to_collector_id" minimum:"1" doc:"The collector receiving the milk (see /milk-transfers/recipients)"`
	QuantityLitres  float64 `json:"quantity_litres" minimum:"0.01" doc:"Litres handed over"`
	TransferDate    *string `json:"transfer_date,omitempty" doc:"Day of the handover (YYYY-MM-DD), defaults to today; not in the future"`
	FromCollectorID *uint   `json:"from_collector_id,omitempty" doc:"Admins only: the collector giving the milk; defaults to the caller"`
	Notes           *string `json:"notes,omitempty" doc:"Optional, e.g. where it was handed over"`
}

type RecordTransferInput struct {
	Body RecordTransferRequest
}

type UpdateTransferRequest struct {
	ToCollectorID  *uint    `json:"to_collector_id,omitempty" doc:"Corrected receiver"`
	QuantityLitres *float64 `json:"quantity_litres,omitempty" doc:"Corrected litres"`
	Notes          *string  `json:"notes,omitempty" doc:"Updated notes"`
	Reason         *string  `json:"reason,omitempty" doc:"Why it is changed (required when an admin changes another collector's transfer)"`
}

type UpdateTransferInput struct {
	ID   string `path:"id" doc:"Transfer UUID"`
	Body UpdateTransferRequest
}

type CancelTransferInput struct {
	ID   string `path:"id" doc:"Transfer UUID"`
	Body struct {
		Reason string `json:"reason" minLength:"3" doc:"Why the transfer is cancelled"`
	}
}

type TransferIDInput struct {
	ID string `path:"id" doc:"Transfer UUID"`
}

type ListTransfersInput struct {
	Page          int    `query:"page" doc:"Page number (default 1)"`
	PerPage       int    `query:"per_page" doc:"Items per page (default 30, max 100)"`
	CollectorID   uint   `query:"collector_id" doc:"Transfers sent or received by this collector"`
	Direction     string `query:"direction" enum:"in,out," doc:"With collector_id: in (received) or out (sent)"`
	FromDate      string `query:"from_date" doc:"From date (YYYY-MM-DD)"`
	ToDate        string `query:"to_date" doc:"To date (YYYY-MM-DD)"`
	IncludeVoided bool   `query:"include_cancelled" doc:"Include cancelled transfers"`
}

type TransferData struct {
	Transfer *MilkTransfer `json:"transfer"`
}

type TransferOutput struct {
	Body response.Data[TransferData]
}

type ListTransfersData struct {
	Transfers []MilkTransfer `json:"transfers"`
	Meta      query.Meta     `json:"meta"`
}

type ListTransfersOutput struct {
	Body response.Data[ListTransfersData]
}

type TransferRecipientsInput struct{}

type TransferRecipientsData struct {
	Collectors []TransferRecipient `json:"collectors"`
}

type TransferRecipientsOutput struct {
	Body response.Data[TransferRecipientsData]
}
