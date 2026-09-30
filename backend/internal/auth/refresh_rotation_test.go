package auth

import (
	"testing"
	"time"
)

func TestRefreshDecision(t *testing.T) {
	now := time.Now()
	ago := func(d time.Duration) *time.Time { v := now.Add(-d); return &v }
	valid := now.Add(time.Hour)

	cases := []struct {
		name  string
		token RefreshToken
		want  refreshVerdict
	}{
		{"fresh token", RefreshToken{ExpiresAt: valid}, refreshAllowed},
		{"expired (idle too long)", RefreshToken{ExpiresAt: now.Add(-time.Second)}, refreshRejected},
		{"logged out", RefreshToken{ExpiresAt: valid, RevokedAt: ago(time.Minute)}, refreshRejected},
		{"rotated a moment ago: lost response, retry allowed", RefreshToken{ExpiresAt: valid, ReplacedAt: ago(30 * time.Second)}, refreshAllowed},
		{"rotated long ago: reuse, possibly stolen", RefreshToken{ExpiresAt: valid, ReplacedAt: ago(refreshReuseGrace + time.Second)}, refreshReused},
		{"revoked wins over reuse", RefreshToken{ExpiresAt: valid, RevokedAt: ago(time.Hour), ReplacedAt: ago(time.Hour)}, refreshRejected},
	}
	for _, c := range cases {
		if got := refreshDecision(&c.token, now); got != c.want {
			t.Errorf("%s: got %v, want %v", c.name, got, c.want)
		}
	}
}
