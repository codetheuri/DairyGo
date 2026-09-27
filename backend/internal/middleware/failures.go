package middleware

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// FailedRequest describes an API request that ended with status 400 or above.
// Request bodies are never captured (they may contain passwords); Message is
// the error message the API returned.
type FailedRequest struct {
	Level      string // WARN for 4xx, ERROR for 5xx
	Method     string
	Path       string
	Query      string
	Status     int
	Message    string
	RequestID  string
	UserID     *uint
	SaccoID    *string
	DurationMS int64
	IP         string
	UserAgent  string
}

// FailureStore persists failed requests so platform operators can review them.
type FailureStore interface {
	SaveFailedRequest(ctx context.Context, f FailedRequest) error
}

// maxCapturedBody bounds how much of an error response is kept in memory.
const maxCapturedBody = 4096

// RecordFailures stores every API request that fails (status >= 400) in store.
// The caller is identified from the bearer token, since the authentication
// context is created further down the handler chain. Saving happens in the
// background so it never slows the response.
func RecordFailures(store FailureStore, jwtSecret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if !strings.HasPrefix(r.URL.Path, "/api/") {
				next.ServeHTTP(w, r)
				return
			}

			start := time.Now()
			cw := &capturingWriter{ResponseWriter: w, status: http.StatusOK}
			next.ServeHTTP(cw, r)
			if cw.status < http.StatusBadRequest {
				return
			}

			f := FailedRequest{
				Level:      "WARN",
				Method:     r.Method,
				Path:       r.URL.Path,
				Query:      r.URL.RawQuery,
				Status:     cw.status,
				Message:    errorMessage(cw.body.Bytes()),
				RequestID:  GetRequestID(r.Context()),
				DurationMS: time.Since(start).Milliseconds(),
				IP:         clientIP(r),
				UserAgent:  r.UserAgent(),
			}
			if cw.status >= http.StatusInternalServerError {
				f.Level = "ERROR"
			}
			f.UserID, f.SaccoID = callerFromToken(r.Header.Get("Authorization"), jwtSecret)

			go func() {
				ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
				defer cancel()
				_ = store.SaveFailedRequest(ctx, f)
			}()
		})
	}
}

// capturingWriter records the status code and, for error responses, the start of the body.
type capturingWriter struct {
	http.ResponseWriter
	status int
	body   bytes.Buffer
}

func (c *capturingWriter) WriteHeader(code int) {
	c.status = code
	c.ResponseWriter.WriteHeader(code)
}

func (c *capturingWriter) Write(b []byte) (int, error) {
	if c.status >= http.StatusBadRequest && c.body.Len() < maxCapturedBody {
		remaining := maxCapturedBody - c.body.Len()
		if len(b) < remaining {
			remaining = len(b)
		}
		c.body.Write(b[:remaining])
	}
	return c.ResponseWriter.Write(b)
}

// errorMessage extracts "message: field error; ..." from the standard error
// envelope, falling back to the raw body.
func errorMessage(body []byte) string {
	var envelope struct {
		Message string            `json:"message"`
		Errors  map[string]string `json:"errors"`
	}
	if err := json.Unmarshal(body, &envelope); err != nil || envelope.Message == "" {
		return strings.TrimSpace(string(body))
	}
	if len(envelope.Errors) == 0 {
		return envelope.Message
	}
	fields := make([]string, 0, len(envelope.Errors))
	for field, msg := range envelope.Errors {
		if msg == envelope.Message {
			continue // the API often repeats the message as a "server" detail
		}
		fields = append(fields, field+": "+msg)
	}
	if len(fields) == 0 {
		return envelope.Message
	}
	sort.Strings(fields)
	return envelope.Message + " (" + strings.Join(fields, "; ") + ")"
}

// callerFromToken reads the user and Sacco from a valid bearer token, if any.
func callerFromToken(header, jwtSecret string) (*uint, *string) {
	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
		return nil, nil
	}
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(parts[1], claims, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return []byte(jwtSecret), nil
	})
	if err != nil || !token.Valid {
		return nil, nil
	}
	userID := claims.UserID
	return &userID, claims.SaccoID
}

func clientIP(r *http.Request) string {
	if fwd := r.Header.Get("X-Forwarded-For"); fwd != "" {
		return strings.TrimSpace(strings.Split(fwd, ",")[0])
	}
	return r.RemoteAddr
}
