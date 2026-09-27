package web

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// The console page must be embedded; a missing index.html makes the file
// server fall back to a directory listing.
func TestPlatformHandlerServesIndex(t *testing.T) {
	rec := httptest.NewRecorder()
	PlatformHandler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `src="app.js"`) {
		t.Fatalf("expected the console page, got %d: %.200s", rec.Code, rec.Body.String())
	}
}
