package collection

import (
	"context"
	"fmt"

	"github.com/codetheuri/tusk/pkg/response"
)

type CustomerIDInput struct {
	ID string `path:"id" doc:"Customer id"`
}

type SetCustomerPriceInput struct {
	ID   string `path:"id" doc:"Customer id"`
	Body SetCustomerPriceRequest
}

type VoidCustomerPriceInput struct {
	ID      string `path:"id" doc:"Customer id"`
	PriceID string `path:"price_id" doc:"The schedule row to cancel"`
	Body    VoidCustomerPriceRequest
}

type CustomerPricesOutput struct {
	Body response.Data[CustomerPriceInfo]
}

type CustomerPriceResultOutput struct {
	Body response.Data[CustomerPriceResult]
}

func (h *Handler) CustomerPrices(ctx context.Context, in *CustomerIDInput) (*CustomerPricesOutput, error) {
	info, err := h.service.CustomerPrices(ctx, in.ID)
	if err != nil {
		return nil, toHTTPError(err)
	}
	out := &CustomerPricesOutput{}
	out.Body.Success, out.Body.Message, out.Body.Data = true, "Customer's price", *info
	return out, nil
}

func (h *Handler) SetCustomerPrice(ctx context.Context, in *SetCustomerPriceInput) (*CustomerPriceResultOutput, error) {
	res, err := h.service.SetCustomerPrice(ctx, in.ID, &in.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return customerPriceResult(res), nil
}

func (h *Handler) VoidCustomerPrice(ctx context.Context, in *VoidCustomerPriceInput) (*CustomerPriceResultOutput, error) {
	res, err := h.service.VoidCustomerPrice(ctx, in.ID, in.PriceID, &in.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return customerPriceResult(res), nil
}

func customerPriceResult(res *CustomerPriceResult) *CustomerPriceResultOutput {
	out := &CustomerPriceResultOutput{}
	out.Body.Success, out.Body.Data = true, *res
	switch {
	case res.Preview:
		out.Body.Message = fmt.Sprintf("%d sales would be repriced", res.Repriced)
	case res.Repriced > 0:
		out.Body.Message = fmt.Sprintf("Saved; %d sales repriced", res.Repriced)
	default:
		out.Body.Message = "Saved"
	}
	return out
}
