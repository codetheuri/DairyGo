package appupdate

import (
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"github.com/go-chi/chi/v5"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/logger"
)

// RegisterRoutes adds, all public (the app needs them before login, and an
// outdated app may be unable to log in):
//   - GET /api/v1/app/version: the latest release, for the in-app updater;
//   - GET /app: the download page to share;
//   - GET /app/download/{abi}: the APK.
func RegisterRoutes(api huma.API, r chi.Router, store *Store, log logger.Logger) {
	h := NewHandler(store, log)

	huma.Register(api, huma.Operation{
		OperationID: "get-app-version",
		Method:      http.MethodGet,
		Path:        "/api/v1/app/version",
		Summary:     "Latest mobile app release",
		Description: "The latest Android release: version, minimum version still allowed, notes and APK downloads with SHA-256. Public. 404 when nothing is published.",
		Tags:        []string{"Mobile App"},
	}, h.Version)

	r.Group(func(r chi.Router) {
		r.Use(middleware.ConsoleSecurityHeaders)
		r.Get("/app", h.Page)
		r.Get("/app/app.css", h.Stylesheet)
		r.Get("/app/download/{abi}", h.Download)
		r.Head("/app/download/{abi}", h.Download)
	})
}
