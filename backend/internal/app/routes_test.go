package app

import (
	"testing"

	"github.com/danielgtaylor/huma/v2/humatest"
	"github.com/go-chi/chi/v5"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/pkg/logger"
)

// Every module registers without a panic: Huma refuses, for example, two
// response types that get the same schema name, and the API would not start.
func TestAllRoutesRegister(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file::memory:"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	_, api := humatest.New(t)
	cfg := &config.Config{JWTSecret: "test-secret-that-is-long-enough-000000", AppReleasesDir: t.TempDir()}
	defer func() {
		if p := recover(); p != nil {
			t.Fatalf("registering routes panicked: %v", p)
		}
	}()
	registerModules(api, chi.NewRouter(), db, cfg, logger.NewConsoleLogger())
}
