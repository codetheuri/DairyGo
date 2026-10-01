package payout

import (
	"testing"
	"time"
)

func TestPayslipSMS(t *testing.T) {
	mpesa := PayMpesa
	jane := PayRunLine{Litres: 400, Gross: 20000, Entries: -4500, Deductions: 2013, Net: 13487}
	if got, want := payslipSMS("Maru Dairy", "Sep 2026", jane),
		"Maru Dairy: Sep 2026 pay. Milk 400L KES 20,000. Less KES 6,513. Net KES 13,487."; got != want {
		t.Errorf("got  %q\nwant %q", got, want)
	}
	now := time.Now()
	jane.PaidAt, jane.PaidMethod = &now, &mpesa
	if got := payslipSMS("Maru Dairy", "Sep 2026", jane); got[len(got)-15:] != "Sent to M-Pesa." {
		t.Errorf("paid by M-Pesa: %q", got)
	}
	peter := PayRunLine{Litres: 20, Gross: 1000, Entries: -800, Deductions: 1500, Net: 0, Closing: -1300}
	if got, want := payslipSMS("Maru Dairy", "Sep 2026", peter),
		"Maru Dairy: Sep 2026 pay. Milk 20L KES 1,000. Less KES 1,000. Net KES 0. You owe KES 1,300."; got != want {
		t.Errorf("got  %q\nwant %q", got, want)
	}
	for _, l := range []PayRunLine{jane, peter} {
		if n := len(payslipSMS("Maru Dairy Farmers Co-operative Society", "1 Oct – 15 Oct 2026", l)); n > 160 {
			t.Errorf("SMS is %d characters; keep it to one message", n)
		}
	}
}

func TestMpesaPhone(t *testing.T) {
	for in, want := range map[string]string{
		"0712345678": "254712345678", "+254712345678": "254712345678", "254712345678": "254712345678",
		"0112 345 678": "254112345678", "712345678": "254712345678", "": "",
	} {
		if got := mpesaPhone(in); got != want {
			t.Errorf("mpesaPhone(%q) = %q, want %q", in, got, want)
		}
	}
}
