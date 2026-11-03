// Package payto decides where a farmer's pay goes, one rule for the farmer
// record, the payout reports and the payment lists (migration 00029). A
// farmer is paid by exactly one method: M-Pesa on their M-Pesa number (their
// phone when none is set), or bank to their account. Details missing for the
// chosen method never fall back to the other.
package payto

import (
	"strings"
	"unicode"
)

const (
	MPesa = "MPESA"
	Bank  = "BANK"
)

// Method normalises a stored or requested method; anything else is "".
func Method(m string) string {
	switch strings.ToUpper(strings.TrimSpace(m)) {
	case MPesa, "M-PESA":
		return MPesa
	case Bank:
		return Bank
	}
	return ""
}

// Details is what a farmer is paid on.
type Details struct {
	Method      string
	Phone       string
	MpesaNumber *string
	BankName    *string
	Account     *string
	Branch      *string
}

func val(p *string) string {
	if p == nil {
		return ""
	}
	return strings.TrimSpace(*p)
}

func digits(s string) int {
	n := 0
	for _, r := range s {
		if unicode.IsDigit(r) {
			n++
		}
	}
	return n
}

// MpesaPhone is the number M-Pesa pay goes to: the M-Pesa number, else the
// phone; "" when neither has a full number.
func (d Details) MpesaPhone() string {
	for _, n := range []string{val(d.MpesaNumber), strings.TrimSpace(d.Phone)} {
		if digits(n) >= 10 {
			return n
		}
	}
	return ""
}

// Ready reports whether the chosen method has what it needs.
func (d Details) Ready() bool {
	if Method(d.Method) == Bank {
		return val(d.Account) != ""
	}
	return d.MpesaPhone() != ""
}

// Describe is where the pay goes, e.g. "M-Pesa 0712345678" or "Equity
// 0160… Rumuruti", or what is missing.
func (d Details) Describe() string {
	if Method(d.Method) == Bank {
		if val(d.Account) == "" {
			return "Bank: account missing"
		}
		bank := val(d.BankName)
		if bank == "" {
			bank = "Bank"
		}
		return strings.TrimSpace(bank + " " + val(d.Account) + " " + val(d.Branch))
	}
	if p := d.MpesaPhone(); p != "" {
		return "M-Pesa " + p
	}
	return "M-Pesa: number missing"
}
