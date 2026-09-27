package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"
)

type memoryStore struct {
	mu   sync.Mutex
	logs []FailedRequest
	done chan struct{}
}

func (m *memoryStore) SaveFailedRequest(_ context.Context, f FailedRequest) error {
	m.mu.Lock()
	m.logs = append(m.logs, f)
	m.mu.Unlock()
	m.done <- struct{}{}
	return nil
}

func TestRecordFailures(t *testing.T) {
	store := &memoryStore{done: make(chan struct{}, 4)}
	handler := RecordFailures(store, "secret")(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/api/v1/fail":
			w.WriteHeader(http.StatusBadRequest)
			_, _ = w.Write([]byte(`{"success":false,"message":"Validation failed","errors":{"phone":"required"}}`))
		case "/api/v1/boom":
			w.WriteHeader(http.StatusInternalServerError)
			_, _ = w.Write([]byte(`{"message":"database unavailable"}`))
		default:
			_, _ = w.Write([]byte(`{"success":true}`))
		}
	}))

	for _, path := range []string{"/api/v1/ok", "/api/v1/fail", "/api/v1/boom", "/health"} {
		handler.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, path+"?x=1", nil))
	}

	for i := 0; i < 2; i++ {
		select {
		case <-store.done:
		case <-time.After(time.Second):
			t.Fatal("failed requests were not saved")
		}
	}

	store.mu.Lock()
	defer store.mu.Unlock()
	if len(store.logs) != 2 {
		t.Fatalf("expected 2 failures recorded, got %d", len(store.logs))
	}
	byPath := map[string]FailedRequest{}
	for _, f := range store.logs {
		byPath[f.Path] = f
	}
	if f := byPath["/api/v1/fail"]; f.Level != "WARN" || f.Status != 400 || f.Message != "Validation failed (phone: required)" || f.Query != "x=1" {
		t.Errorf("unexpected 4xx record: %+v", f)
	}
	if f := byPath["/api/v1/boom"]; f.Level != "ERROR" || f.Message != "database unavailable" {
		t.Errorf("unexpected 5xx record: %+v", f)
	}
}

func TestErrorMessageSkipsRepeatedDetail(t *testing.T) {
	got := errorMessage([]byte(`{"message":"invalid credentials","errors":{"server":"invalid credentials"}}`))
	if got != "invalid credentials" {
		t.Fatalf("got %q", got)
	}
}
