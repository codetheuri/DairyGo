package collection

import (
	"context"
	"fmt"
)

func (h *Handler) MemberPrices(ctx context.Context, in *MemberIDInput) (*MemberPricesOutput, error) {
	info, err := h.service.MemberPrices(ctx, in.ID)
	if err != nil {
		return nil, toHTTPError(err)
	}
	out := &MemberPricesOutput{}
	out.Body.Success, out.Body.Message, out.Body.Data = true, "Farmer's buying price", *info
	return out, nil
}

func (h *Handler) MemberPriceForDay(ctx context.Context, in *MemberPriceForDayInput) (*MemberDayPriceOutput, error) {
	price, own, err := h.service.PriceForDay(ctx, in.ID, in.Date)
	if err != nil {
		return nil, toHTTPError(err)
	}
	out := &MemberDayPriceOutput{}
	out.Body.Success, out.Body.Message = true, "Buying price"
	out.Body.Data = MemberDayPrice{PricePerLitre: price, Own: own}
	return out, nil
}

func (h *Handler) SetMemberPrice(ctx context.Context, in *SetMemberPriceInput) (*MemberPriceResultOutput, error) {
	res, err := h.service.SetMemberPrice(ctx, in.ID, &in.Body)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return priceResult(res), nil
}

func (h *Handler) VoidMemberPrice(ctx context.Context, in *VoidMemberPriceInput) (*MemberPriceResultOutput, error) {
	res, err := h.service.VoidMemberPrice(ctx, in.ID, in.PriceID, in.Body.Reason)
	if err != nil {
		return nil, toHTTPError(err)
	}
	return priceResult(res), nil
}

func priceResult(res *MemberPriceResult) *MemberPriceResultOutput {
	out := &MemberPriceResultOutput{}
	out.Body.Success, out.Body.Data = true, *res
	switch {
	case res.Preview:
		out.Body.Message = fmt.Sprintf("%d milk records would be repriced", res.Repriced)
	case res.Repriced > 0:
		out.Body.Message = fmt.Sprintf("Saved; %d milk records repriced. Work out any draft pay run again.", res.Repriced)
	default:
		out.Body.Message = "Saved"
	}
	return out
}
