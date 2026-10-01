package app

import (
	"fmt"
	"strings"
	"testing"

	"github.com/danielgtaylor/huma/v2"
	"github.com/danielgtaylor/huma/v2/humatest"
	"github.com/go-chi/chi/v5"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/internal/auth"
	"github.com/codetheuri/tusk/internal/jobs"
	"github.com/codetheuri/tusk/pkg/logger"
)

// Every password a person chooses has the same minimum length, whichever
// route sets it (the app, the console, a new Sacco): auth.MinPasswordLength.
func TestPasswordRulesMatch(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file::memory:"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	_, api := humatest.New(t)
	cfg := &config.Config{JWTSecret: "test-secret-that-is-long-enough-000000", AppReleasesDir: t.TempDir()}
	registerModules(api, chi.NewRouter(), db, cfg, logger.NewConsoleLogger(), jobs.NewRunner(db, logger.NewConsoleLogger()))

	checked := 0
	var walk func(where string, s *huma.Schema)
	walk = func(where string, s *huma.Schema) {
		if s == nil {
			return
		}
		if s.Ref != "" {
			return // reached through Components below
		}
		for name, prop := range s.Properties {
			at := where + "." + name
			// A password someone chooses; signing in and "current password"
			// take whatever the password already is.
			if strings.Contains(name, "password") && name != "current_password" && !strings.HasSuffix(where, "LoginRequest") {
				checked++
				if prop.MinLength == nil || *prop.MinLength != auth.MinPasswordLength {
					got := "none"
					if prop.MinLength != nil {
						got = fmt.Sprint(*prop.MinLength)
					}
					t.Errorf("%s: minLength %s, want %d (auth.MinPasswordLength)", at, got, auth.MinPasswordLength)
				}
			}
			walk(at, prop)
		}
		walk(where+"[]", s.Items)
	}
	for name, s := range api.OpenAPI().Components.Schemas.Map() {
		walk(name, s)
	}
	if checked < 6 {
		t.Fatalf("only %d password fields found; the walk is missing some", checked)
	}
}

func TestCheckPasswordLength(t *testing.T) {
	if err := auth.CheckPasswordLength("abc"); err == nil {
		t.Error("3 characters accepted")
	}
	if err := auth.CheckPasswordLength("abcd"); err != nil {
		t.Errorf("4 characters refused: %v", err)
	}
	if err := auth.CheckPasswordLength("ñañ"); err == nil {
		t.Error("counted bytes, not characters")
	}
}
