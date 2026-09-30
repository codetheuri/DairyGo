package appupdate

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/danielgtaylor/huma/v2"
	"github.com/danielgtaylor/huma/v2/adapters/humachi"
	"github.com/go-chi/chi/v5"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/response"
)

type testLogger struct {
	mu     sync.Mutex
	errors []string
}

func (l *testLogger) Debug(string, ...any) {}
func (l *testLogger) Info(string, ...any)  {}
func (l *testLogger) Warn(string, ...any)  {}
func (l *testLogger) Fatal(msg string, err error, _ ...any) {
	l.Error(msg, err)
}
func (l *testLogger) Error(msg string, err error, _ ...any) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.errors = append(l.errors, msg+": "+err.Error())
}

// publish writes an APK per ABI and latest.json into dir, as release.sh does.
func publish(t *testing.T, dir string, build, minBuild int, apks map[string]string) {
	t.Helper()
	m := Manifest{
		Version:     "1.4.0",
		Build:       build,
		MinBuild:    minBuild,
		Notes:       "Update from inside the app.\n<script>alert(1)</script>",
		PublishedAt: time.Date(2026, 9, 30, 8, 0, 0, 0, time.UTC),
		Files:       map[string]File{},
	}
	for abi, content := range apks {
		name := "DairyGo-v1.4.0-" + abi + ".apk"
		if err := os.WriteFile(filepath.Join(dir, name), []byte(content), 0o644); err != nil {
			t.Fatal(err)
		}
		sum := sha256.Sum256([]byte(content))
		m.Files[abi] = File{Name: name, SHA256: hex.EncodeToString(sum[:]), Size: int64(len(content))}
	}
	writeManifest(t, dir, m)
}

func writeManifest(t *testing.T, dir string, m Manifest) {
	t.Helper()
	raw, _ := json.Marshal(m)
	path := filepath.Join(dir, ManifestName)
	if err := os.WriteFile(path, raw, 0o644); err != nil {
		t.Fatal(err)
	}
	// A distinct modification time, as a later publish would have.
	later := time.Now().Add(time.Duration(m.Build) * time.Second)
	_ = os.Chtimes(path, later, later)
}

func TestStoreNoRelease(t *testing.T) {
	_, err := NewStore(t.TempDir()).Latest()
	if !errors.Is(err, ErrNoRelease) {
		t.Fatalf("want ErrNoRelease, got %v", err)
	}
}

func TestStoreRejectsBrokenManifests(t *testing.T) {
	cases := map[string]func(m *Manifest){
		"min build above build": func(m *Manifest) { m.MinBuild = m.Build + 1 },
		"no version":            func(m *Manifest) { m.Version = "" },
		"path in file name": func(m *Manifest) {
			f := m.Files["arm64"]
			f.Name = "../secret.apk"
			m.Files["arm64"] = f
		},
		"partly copied APK": func(m *Manifest) {
			f := m.Files["arm64"]
			f.Size++
			m.Files["arm64"] = f
		},
		"bad checksum": func(m *Manifest) {
			f := m.Files["arm64"]
			f.SHA256 = "abc"
			m.Files["arm64"] = f
		},
		"unknown phone type": func(m *Manifest) { m.Files["x86"] = m.Files["arm64"] },
	}
	for name, breakIt := range cases {
		t.Run(name, func(t *testing.T) {
			dir := t.TempDir()
			publish(t, dir, 10, 10, map[string]string{"arm64": "apk-bytes"})
			m, err := NewStore(dir).Latest()
			if err != nil {
				t.Fatal(err)
			}
			broken := *m
			broken.Files = map[string]File{}
			for k, v := range m.Files {
				broken.Files[k] = v
			}
			breakIt(&broken)
			writeManifest(t, dir, broken)
			if _, err := NewStore(dir).Latest(); err == nil {
				t.Fatal("want an error")
			}
		})
	}
}

func TestStoreSeesNewRelease(t *testing.T) {
	dir := t.TempDir()
	store := NewStore(dir)
	publish(t, dir, 10, 9, map[string]string{"arm64": "one"})
	if m, _ := store.Latest(); m == nil || m.Build != 10 {
		t.Fatalf("got %+v", m)
	}
	publish(t, dir, 11, 9, map[string]string{"arm64": "two"})
	if m, _ := store.Latest(); m == nil || m.Build != 11 {
		t.Fatalf("a new publish needs no restart; got %+v", m)
	}
}

// server runs the routes behind the same wrapping middleware as the app.
func server(t *testing.T, dir string) (*httptest.Server, *testLogger) {
	t.Helper()
	response.SetupHuma()
	log := &testLogger{}
	r := chi.NewRouter()
	r.Use(middleware.Logger(log))
	api := humachi.New(r, huma.DefaultConfig("test", "1"))
	RegisterRoutes(api, r, NewStore(dir), log)
	srv := httptest.NewUnstartedServer(r)
	srv.Config.WriteTimeout = 10 * time.Second
	srv.Start()
	t.Cleanup(srv.Close)
	return srv, log
}

func TestVersion(t *testing.T) {
	dir := t.TempDir()
	srv, _ := server(t, dir)

	res, err := http.Get(srv.URL + "/api/v1/app/version")
	if err != nil {
		t.Fatal(err)
	}
	res.Body.Close()
	if res.StatusCode != http.StatusNotFound {
		t.Fatalf("nothing published: want 404, got %d", res.StatusCode)
	}

	publish(t, dir, 10, 9, map[string]string{"arm64": "arm64-apk", "armv7": "armv7-apk"})
	res, err = http.Get(srv.URL + "/api/v1/app/version?scheme=2")
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	var body response.Data[ReleaseInfo]
	if err := json.NewDecoder(res.Body).Decode(&body); err != nil {
		t.Fatal(err)
	}
	got := body.Data
	sum := sha256.Sum256([]byte("arm64-apk"))
	if res.StatusCode != http.StatusOK || got.Build != 10 || got.MinBuild != 9 ||
		got.Files["arm64"].URL != "/app/download/arm64" ||
		got.Files["arm64"].SHA256 != hex.EncodeToString(sum[:]) ||
		got.Files["armv7"].Size != int64(len("armv7-apk")) {
		t.Fatalf("got %d %+v", res.StatusCode, got)
	}
}

func TestDownload(t *testing.T) {
	dir := t.TempDir()
	apk := strings.Repeat("0123456789", 1000)
	publish(t, dir, 10, 9, map[string]string{"arm64": apk})
	srv, log := server(t, dir)

	res, err := http.Get(srv.URL + "/app/download/arm64")
	if err != nil {
		t.Fatal(err)
	}
	got, _ := io.ReadAll(res.Body)
	res.Body.Close()
	if res.StatusCode != http.StatusOK || string(got) != apk {
		t.Fatalf("got %d, %d bytes", res.StatusCode, len(got))
	}
	if ct := res.Header.Get("Content-Type"); ct != "application/vnd.android.package-archive" {
		t.Errorf("Content-Type %q: phones would not open it with the installer", ct)
	}
	if cd := res.Header.Get("Content-Disposition"); cd != `attachment; filename="DairyGo-1.4.0.apk"` {
		t.Errorf("Content-Disposition %q", cd)
	}
	if len(log.errors) > 0 {
		t.Errorf("the write deadline must be extendable through the middleware: %v", log.errors)
	}

	// An interrupted download continues from where it stopped.
	req, _ := http.NewRequest(http.MethodGet, srv.URL+"/app/download/arm64", nil)
	req.Header.Set("Range", "bytes=4000-")
	req.Header.Set("If-Range", res.Header.Get("ETag"))
	res, err = http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	rest, _ := io.ReadAll(res.Body)
	res.Body.Close()
	if res.StatusCode != http.StatusPartialContent || string(rest) != apk[4000:] {
		t.Fatalf("resume: got %d, %d bytes", res.StatusCode, len(rest))
	}

	res, _ = http.Get(srv.URL + "/app/download/x86")
	res.Body.Close()
	if res.StatusCode != http.StatusNotFound {
		t.Fatalf("unknown phone type: want 404, got %d", res.StatusCode)
	}
}

func TestPage(t *testing.T) {
	dir := t.TempDir()
	srv, _ := server(t, dir)

	res, _ := http.Get(srv.URL + "/app")
	page, _ := io.ReadAll(res.Body)
	res.Body.Close()
	if res.StatusCode != http.StatusServiceUnavailable || !strings.Contains(string(page), "No version is available") {
		t.Fatalf("nothing published: got %d %.200s", res.StatusCode, page)
	}

	publish(t, dir, 10, 9, map[string]string{"arm64": "a", "armv7": "b"})
	res, _ = http.Get(srv.URL + "/app")
	page, _ = io.ReadAll(res.Body)
	res.Body.Close()
	html := string(page)
	for _, want := range []string{
		`href="/app/download/arm64"`, `href="/app/download/armv7"`, "Version 1.4.0",
		"&lt;script&gt;", // release notes are escaped
	} {
		if !strings.Contains(html, want) {
			t.Errorf("page lacks %q", want)
		}
	}
	if strings.Contains(html, "<script>") {
		t.Error("release notes must not run as script")
	}
	if csp := res.Header.Get("Content-Security-Policy"); !strings.Contains(csp, "script-src 'self'") {
		t.Errorf("CSP %q", csp)
	}

	res, _ = http.Get(srv.URL + "/app/app.css")
	res.Body.Close()
	if res.StatusCode != http.StatusOK || !strings.HasPrefix(res.Header.Get("Content-Type"), "text/css") {
		t.Fatalf("stylesheet: %d %s", res.StatusCode, res.Header.Get("Content-Type"))
	}
}

// Apps 1.4.0 and 1.4.1 compare Android's versionCode (2000 + build on arm64)
// with the published build and send no scheme; they are answered in that
// scale so they see updates and required updates.
func TestVersionForAppsThatCompareVersionCode(t *testing.T) {
	dir := t.TempDir()
	srv, _ := server(t, dir)
	publish(t, dir, 12, 11, map[string]string{"arm64": "a", "armv7": "b"})

	get := func(query string) ReleaseInfo {
		t.Helper()
		res, err := http.Get(srv.URL + "/api/v1/app/version" + query)
		if err != nil {
			t.Fatal(err)
		}
		defer res.Body.Close()
		var body response.Data[ReleaseInfo]
		if err := json.NewDecoder(res.Body).Decode(&body); err != nil {
			t.Fatal(err)
		}
		return body.Data
	}

	if got := get(""); got.Build != 2012 || got.MinBuild != 2011 {
		t.Errorf("old app: got build %d, min %d; want 2012, 2011", got.Build, got.MinBuild)
	}
	if got := get("?scheme=2"); got.Build != 12 || got.MinBuild != 11 {
		t.Errorf("current app: got build %d, min %d; want 12, 11", got.Build, got.MinBuild)
	}
}

func TestBuildFor(t *testing.T) {
	if got := buildFor(0, 0); got != 0 {
		t.Errorf("no required build must stay 0 for old apps, got %d", got)
	}
	if got := buildFor(2, 0); got != 0 {
		t.Errorf("got %d", got)
	}
}
