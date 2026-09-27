// Package web embeds the platform console, a static single-page app served at
// /platform. It talks to the same /api/v1 endpoints as the mobile app.
package web

import (
	"embed"
	"io/fs"
	"net/http"
)

//go:embed platform
var files embed.FS

// PlatformHandler serves the console's static files.
func PlatformHandler() http.Handler {
	sub, err := fs.Sub(files, "platform")
	if err != nil {
		panic(err) // the embedded directory is fixed at build time
	}
	return http.FileServer(http.FS(sub))
}
