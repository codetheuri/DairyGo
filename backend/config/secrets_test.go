package config

import (
	"testing"
	"time"
)

func TestValidateJWTSecret(t *testing.T) {
	strong := "0123456789abcdef0123456789abcdef"
	cases := []struct {
		name, secret, mode string
		ok                 bool
	}{
		{"empty", "", "dev", false},
		{"public placeholder", placeholderJWTSecret, "dev", false},
		{"short in production", "short-secret", "prod", false},
		{"short in development", "short-secret", "dev", true},
		{"strong in production", strong, "prod", true},
	}
	for _, c := range cases {
		err := validateJWTSecret(c.secret, c.mode)
		if (err == nil) != c.ok {
			t.Errorf("%s: err = %v, want ok=%v", c.name, err, c.ok)
		}
	}
}

func TestDurationEnv(t *testing.T) {
	t.Setenv("TEST_TTL", "")
	if d, _ := durationEnv("TEST_TTL", time.Hour); d != time.Hour {
		t.Fatalf("default: got %v", d)
	}
	t.Setenv("TEST_TTL", "72h")
	if d, _ := durationEnv("TEST_TTL", time.Hour); d != 72*time.Hour {
		t.Fatalf("72h: got %v", d)
	}
	for _, bad := range []string{"abc", "-1h", "0s"} {
		t.Setenv("TEST_TTL", bad)
		if _, err := durationEnv("TEST_TTL", time.Hour); err == nil {
			t.Errorf("%q should be rejected", bad)
		}
	}
}
