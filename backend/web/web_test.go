package web

import (
	"net/http"
	"net/http/httptest"
	"regexp"
	"strconv"
	"strings"
	"testing"

	"github.com/codetheuri/tusk/internal/auth"
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

// The console asks for the same password length as the API and the app.
func TestConsolePasswordRuleMatchesAPI(t *testing.T) {
	js, err := files.ReadFile("platform/app.js")
	if err != nil {
		t.Fatal(err)
	}
	m := regexp.MustCompile(`const PASSWORD_MIN = (\d+);`).FindSubmatch(js)
	if m == nil {
		t.Fatal("app.js has no PASSWORD_MIN")
	}
	if got := string(m[1]); got != strconv.Itoa(auth.MinPasswordLength) {
		t.Errorf("console PASSWORD_MIN = %s, want %d (auth.MinPasswordLength)", got, auth.MinPasswordLength)
	}
	if regexp.MustCompile(`minlength: \d`).Match(js) {
		t.Error("a password field sets its own length instead of PASSWORD_MIN")
	}
}
