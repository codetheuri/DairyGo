package idempotency

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/codetheuri/tusk/internal/middleware"
)

// Header is the request header carrying the client's key for one save.
const Header = "Idempotency-Key"

// ReplayedHeader is set on a response that was stored, not freshly produced.
const ReplayedHeader = "Idempotent-Replayed"

const (
	// maxBody bounds the request and response bodies handled here.
	maxBody = 1 << 20
	// staleAfter: a request still "running" after this long crashed; its
	// key may be claimed again.
	staleAfter = 2 * time.Minute
)

var validKey = regexp.MustCompile(`^[A-Za-z0-9_-]{8,64}$`)

// Keeper is the storage the middleware needs; *Store implements it.
type Keeper interface {
	Begin(ctx context.Context, rec *Record) (*Record, error)
	Complete(ctx context.Context, userID uint, key string, status int, contentType string, body []byte) error
	Release(ctx context.Context, userID uint, key string) error
}

// Middleware performs a keyed write once per user and key. It applies to
// POST, PUT, PATCH and DELETE requests under /api/ that carry the
// Idempotency-Key header and a valid bearer token; everything else passes
// straight through.
//
//   - First request: runs normally; the response is stored.
//   - Same key again, same request: the stored response is returned with
//     Idempotent-Replayed: true, and nothing is saved twice.
//   - Same key while the first is still running: 409, retry shortly.
//   - Same key with a different request: 422, the client has a bug.
//
// Server errors (5xx) and auth failures are not stored, so a retry runs again.
func Middleware(keeper Keeper, jwtSecret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			key := r.Header.Get(Header)
			if key == "" || !isWrite(r.Method) || !strings.HasPrefix(r.URL.Path, "/api/") {
				next.ServeHTTP(w, r)
				return
			}
			if !validKey.MatchString(key) {
				writeError(w, http.StatusBadRequest, "Idempotency-Key must be 8 to 64 letters, digits, '-' or '_'")
				return
			}
			userID, _ := middleware.CallerFromToken(r.Header.Get("Authorization"), jwtSecret)
			if userID == nil {
				next.ServeHTTP(w, r) // not signed in: the handler answers 401
				return
			}

			body, err := io.ReadAll(io.LimitReader(r.Body, maxBody+1))
			if err != nil || len(body) > maxBody {
				writeError(w, http.StatusRequestEntityTooLarge, "Request body too large")
				return
			}
			r.Body = io.NopCloser(bytes.NewReader(body))

			rec := &Record{
				UserID:      *userID,
				Key:         key,
				Method:      r.Method,
				Path:        r.URL.Path,
				RequestHash: requestHash(r.Method, r.URL.Path, body),
				CreatedAt:   time.Now(),
			}
			existing, err := keeper.Begin(r.Context(), rec)
			if err != nil {
				// Storage unavailable: serve the request rather than fail it.
				next.ServeHTTP(w, r)
				return
			}
			if existing != nil {
				if !replay(w, existing, rec) {
					return
				}
				// A crashed earlier attempt: take the key over.
				_ = keeper.Release(r.Context(), rec.UserID, key)
				if again, err := keeper.Begin(r.Context(), rec); err != nil || again != nil {
					writeError(w, http.StatusConflict, "This request is still being processed. Try again in a moment.")
					return
				}
			}

			cw := &captureWriter{ResponseWriter: w, status: http.StatusOK}
			next.ServeHTTP(cw, r)

			// The client may have given up waiting; store the outcome anyway so
			// its retry gets this answer instead of saving again.
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()
			if storable(cw.status) && !cw.truncated {
				_ = keeper.Complete(ctx, rec.UserID, key, cw.status, cw.Header().Get("Content-Type"), cw.body.Bytes())
			} else {
				_ = keeper.Release(ctx, rec.UserID, key)
			}
		})
	}
}

// replay answers from an existing record. It returns true when the record
// belongs to a crashed request and the caller should take the key over.
func replay(w http.ResponseWriter, existing, rec *Record) bool {
	switch {
	case existing.RequestHash != rec.RequestHash || existing.Method != rec.Method || existing.Path != rec.Path:
		writeError(w, http.StatusUnprocessableEntity, "This Idempotency-Key was already used for a different request")
		return false
	case existing.InProgress() && time.Since(existing.CreatedAt) > staleAfter:
		return true
	case existing.InProgress():
		w.Header().Set("Retry-After", "2")
		writeError(w, http.StatusConflict, "This request is still being processed. Try again in a moment.")
		return false
	}
	if existing.ContentType != "" {
		w.Header().Set("Content-Type", existing.ContentType)
	}
	w.Header().Set(ReplayedHeader, "true")
	w.WriteHeader(existing.StatusCode)
	_, _ = io.WriteString(w, existing.ResponseBody)
	return false
}

func isWrite(method string) bool {
	switch method {
	case http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete:
		return true
	}
	return false
}

// storable: results worth replaying. Successes and validation errors are
// final; auth errors, conflicts, rate limits and server errors may change, so
// a retry should run again.
func storable(status int) bool {
	switch {
	case status >= 200 && status < 300:
		return true
	case status == http.StatusUnauthorized, status == http.StatusForbidden,
		status == http.StatusRequestTimeout, status == http.StatusConflict,
		status == http.StatusTooManyRequests:
		return false
	case status >= 400 && status < 500:
		return true
	}
	return false
}

func requestHash(method, path string, body []byte) string {
	h := sha256.New()
	h.Write([]byte(method + " " + path + "\n"))
	h.Write(body)
	return hex.EncodeToString(h.Sum(nil))
}

func writeError(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]any{"success": false, "message": message})
}

// captureWriter passes the response through and keeps a copy of it.
type captureWriter struct {
	http.ResponseWriter
	status    int
	body      bytes.Buffer
	truncated bool
	wrote     bool
}

func (c *captureWriter) WriteHeader(code int) {
	if !c.wrote {
		c.status = code
		c.wrote = true
	}
	c.ResponseWriter.WriteHeader(code)
}

func (c *captureWriter) Write(b []byte) (int, error) {
	c.wrote = true
	if c.body.Len()+len(b) > maxBody {
		c.truncated = true
	} else {
		c.body.Write(b)
	}
	return c.ResponseWriter.Write(b)
}
