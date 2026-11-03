package payout

import (
	"strings"
	"testing"
)

func TestCheckMerge(t *testing.T) {
	cases := []struct {
		name string
		req  MergeRequest
		want string
	}{
		{"fine", MergeRequest{FromMemberID: "a", ToMemberID: "b", Reason: "Same farmer"}, ""},
		{"no wrong farmer", MergeRequest{ToMemberID: "b", Reason: "Same farmer"}, "choose the farmer"},
		{"same farmer twice", MergeRequest{FromMemberID: "a", ToMemberID: "a", Reason: "Same farmer"}, "two different"},
		{"no reason", MergeRequest{FromMemberID: "a", ToMemberID: "b", Reason: " ok "}, "say why"},
	}
	for _, c := range cases {
		why, err := checkMerge(&c.req)
		switch {
		case c.want == "" && err != nil:
			t.Errorf("%s: %v", c.name, err)
		case c.want == "" && why != "Same farmer":
			t.Errorf("%s: reason = %q, want it trimmed", c.name, why)
		case c.want != "" && (err == nil || !strings.Contains(err.Error(), c.want)):
			t.Errorf("%s: err = %v, want %q", c.name, err, c.want)
		}
	}
}
