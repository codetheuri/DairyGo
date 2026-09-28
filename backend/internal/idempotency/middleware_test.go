package idempotency

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/codetheuri/tusk/internal/middleware"
)

const secret = "test-secret"

// memKeeper is an in-memory Keeper with the same claim semantics as Store.
type memKeeper struct {
	mu   sync.Mutex
	recs map[string]*Record
}

func newMem() *memKeeper { return &memKeeper{recs: map[string]*Record{}} }

func id(userID uint, key string) string { return fmt.Sprintf("%d|%s", userID, key) }

func (m *memKeeper) Begin(_ context.Context, rec *Record) (*Record, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if existing, ok := m.recs[id(rec.UserID, rec.Key)]; ok {
		cp := *existing
		return &cp, nil
	}
	cp := *rec
	m.recs[id(rec.UserID, rec.Key)] = &cp
	return nil, nil
}

func (m *memKeeper) Complete(_ context.Context, userID uint, key string, status int, ct string, body []byte) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	r := m.recs[id(userID, key)]
	r.StatusCode, r.ContentType, r.ResponseBody = status, ct, string(body)
	return nil
}

func (m *memKeeper) Release(_ context.Context, userID uint, key string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.recs, id(userID, key))
	return nil
}

func token(t *testing.T, userID uint) string {
	t.Helper()
	claims := middleware.Claims{UserID: userID, RegisteredClaims: jwt.RegisteredClaims{
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
	}}
	s, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(secret))
	if err != nil {
		t.Fatal(err)
	}
	return "Bearer " + s
}

// server counts how many times the handler really ran ("sales saved").
func server(keeper Keeper, status int) (http.Handler, *int32) {
	var saved int32
	h := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		n := atomic.AddInt32(&saved, 1)
		body, _ := io.ReadAll(r.Body)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		_, _ = w.Write([]byte(`{"sale":` + string(rune('0'+n)) + `,"echo":` + string(body) + `}`))
	})
	return Middleware(keeper, secret)(h), &saved
}

func do(h http.Handler, auth, key, body string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(http.MethodPost, "/api/v1/sacco/milk-sales", strings.NewReader(body))
	if auth != "" {
		req.Header.Set("Authorization", auth)
	}
	if key != "" {
		req.Header.Set(Header, key)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestRetryIsSavedOnce(t *testing.T) {
	h, saved := server(newMem(), http.StatusOK)
	auth := token(t, 7)
	first := do(h, auth, "sale-key-0001", `{"litres":20}`)
	again := do(h, auth, "sale-key-0001", `{"litres":20}`)

	if *saved != 1 {
		t.Fatalf("handler ran %d times, want 1", *saved)
	}
	if again.Body.String() != first.Body.String() || again.Code != first.Code {
		t.Fatalf("replay differs: %d %q vs %d %q", again.Code, again.Body, first.Code, first.Body)
	}
	if again.Header().Get(ReplayedHeader) != "true" {
		t.Fatal("replayed response not marked")
	}
}

func TestKeysAreScopedPerUser(t *testing.T) {
	h, saved := server(newMem(), http.StatusOK)
	do(h, token(t, 1), "shared-key-01", `{}`)
	do(h, token(t, 2), "shared-key-01", `{}`)
	if *saved != 2 {
		t.Fatalf("handler ran %d times, want 2 (different users)", *saved)
	}
}

func TestSameKeyDifferentRequestIsRejected(t *testing.T) {
	h, saved := server(newMem(), http.StatusOK)
	auth := token(t, 7)
	do(h, auth, "sale-key-0002", `{"litres":20}`)
	res := do(h, auth, "sale-key-0002", `{"litres":99}`)
	if res.Code != http.StatusUnprocessableEntity || *saved != 1 {
		t.Fatalf("got %d, saved %d; want 422 and 1", res.Code, *saved)
	}
}

func TestInProgressKeyAsksToRetry(t *testing.T) {
	keeper := newMem()
	auth := token(t, 7)
	// A first request is still running.
	_, _ = keeper.Begin(context.Background(), &Record{
		UserID: 7, Key: "sale-key-0003", Method: http.MethodPost, Path: "/api/v1/sacco/milk-sales",
		RequestHash: requestHash(http.MethodPost, "/api/v1/sacco/milk-sales", []byte(`{}`)),
		CreatedAt:   time.Now(),
	})
	h, saved := server(keeper, http.StatusOK)
	res := do(h, auth, "sale-key-0003", `{}`)
	if res.Code != http.StatusConflict || *saved != 0 {
		t.Fatalf("got %d, saved %d; want 409 and 0", res.Code, *saved)
	}
}

func TestCrashedRequestCanBeRetried(t *testing.T) {
	keeper := newMem()
	_, _ = keeper.Begin(context.Background(), &Record{
		UserID: 7, Key: "sale-key-0004", Method: http.MethodPost, Path: "/api/v1/sacco/milk-sales",
		RequestHash: requestHash(http.MethodPost, "/api/v1/sacco/milk-sales", []byte(`{}`)),
		CreatedAt:   time.Now().Add(-staleAfter - time.Second),
	})
	h, saved := server(keeper, http.StatusOK)
	if res := do(h, token(t, 7), "sale-key-0004", `{}`); res.Code != http.StatusOK || *saved != 1 {
		t.Fatalf("got %d, saved %d; want 200 and 1", res.Code, *saved)
	}
}

func TestServerErrorIsNotStored(t *testing.T) {
	h, saved := server(newMem(), http.StatusInternalServerError)
	auth := token(t, 7)
	do(h, auth, "sale-key-0005", `{}`)
	do(h, auth, "sale-key-0005", `{}`)
	if *saved != 2 {
		t.Fatalf("handler ran %d times, want 2 (5xx must be retryable)", *saved)
	}
}

func TestValidationErrorIsStored(t *testing.T) {
	h, saved := server(newMem(), http.StatusBadRequest)
	auth := token(t, 7)
	do(h, auth, "sale-key-0006", `{}`)
	do(h, auth, "sale-key-0006", `{}`)
	if *saved != 1 {
		t.Fatalf("handler ran %d times, want 1", *saved)
	}
}

func TestPassThrough(t *testing.T) {
	h, saved := server(newMem(), http.StatusOK)
	do(h, token(t, 7), "", `{}`)     // no key
	do(h, "", "sale-key-0007", `{}`) // not signed in: handler decides (401)
	do(h, "Bearer junk", "sale-key-0007", `{}`)
	if *saved != 3 {
		t.Fatalf("handler ran %d times, want 3", *saved)
	}
	get := httptest.NewRequest(http.MethodGet, "/api/v1/sacco/milk-sales", nil)
	get.Header.Set(Header, "sale-key-0008")
	get.Header.Set("Authorization", token(t, 7))
	h.ServeHTTP(httptest.NewRecorder(), get)
	if *saved != 4 {
		t.Fatal("GET must not be keyed")
	}
}

func TestInvalidKeyRejected(t *testing.T) {
	h, saved := server(newMem(), http.StatusOK)
	for _, key := range []string{"short", strings.Repeat("a", 65), "has space here!"} {
		if res := do(h, token(t, 7), key, `{}`); res.Code != http.StatusBadRequest {
			t.Errorf("key %q: got %d, want 400", key, res.Code)
		}
	}
	if *saved != 0 {
		t.Fatal("handler must not run for an invalid key")
	}
}

func TestConcurrentDuplicatesRunOnce(t *testing.T) {
	keeper := newMem()
	var saved int32
	release := make(chan struct{})
	slow := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		atomic.AddInt32(&saved, 1)
		<-release
		w.WriteHeader(http.StatusOK)
	})
	h := Middleware(keeper, secret)(slow)
	auth := token(t, 7)

	var wg sync.WaitGroup
	codes := make(chan int, 5)
	for i := 0; i < 5; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			codes <- do(h, auth, "double-tap-01", `{}`).Code
		}()
	}
	time.Sleep(100 * time.Millisecond)
	close(release)
	wg.Wait()
	close(codes)
	if saved != 1 {
		t.Fatalf("handler ran %d times for 5 simultaneous taps, want 1", saved)
	}
	ok, busy := 0, 0
	for c := range codes {
		switch c {
		case http.StatusOK:
			ok++
		case http.StatusConflict:
			busy++
		}
	}
	if ok != 1 || busy != 4 {
		t.Fatalf("got %d OK and %d 409, want 1 and 4", ok, busy)
	}
}
