// Package appupdate publishes the Android app outside an app store: the
// latest version for the in-app updater, the APK downloads, and a download
// page to share instead of sending APK files over WhatsApp.
//
// A release is a folder (APP_RELEASES_DIR) holding the APKs and latest.json,
// written by mobile/scripts/release.sh and copied to the server. Nothing is
// uploaded through the API, so a stolen password cannot replace the app.
package appupdate

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sync"
	"time"
)

// ManifestName is the file describing the latest release.
const ManifestName = "latest.json"

// ErrNoRelease means no release has been published yet.
var ErrNoRelease = errors.New("no app release has been published")

// ErrUnknownABI means the release has no APK for that phone type.
var ErrUnknownABI = errors.New("no APK for this phone type")

// ABIs lists the phone types an APK is built for, most common first.
var ABIs = []string{"arm64", "armv7"}

var (
	apkName   = regexp.MustCompile(`^[A-Za-z0-9._-]+\.apk$`)
	sha256Hex = regexp.MustCompile(`^[0-9a-f]{64}$`)
)

// Manifest is latest.json.
type Manifest struct {
	Version     string          `json:"version"`
	Build       int             `json:"build"`
	MinBuild    int             `json:"min_build"`
	Notes       string          `json:"notes"`
	PublishedAt time.Time       `json:"published_at"`
	Files       map[string]File `json:"files"`
}

// File is one APK of a release.
type File struct {
	Name   string `json:"name"`
	SHA256 string `json:"sha256"`
	Size   int64  `json:"size"`
}

// Store reads the published release from a folder.
type Store struct {
	dir string

	mu       sync.Mutex
	modTime  time.Time
	manifest *Manifest
}

// NewStore returns a Store for dir.
func NewStore(dir string) *Store { return &Store{dir: dir} }

// Latest returns the published release. It re-reads latest.json only when
// the file changes, so publishing needs no restart.
func (s *Store) Latest() (*Manifest, error) {
	path := filepath.Join(s.dir, ManifestName)
	info, err := os.Stat(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, ErrNoRelease
	}
	if err != nil {
		return nil, err
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	if s.manifest != nil && info.ModTime().Equal(s.modTime) {
		return s.manifest, nil
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var m Manifest
	if err := json.Unmarshal(raw, &m); err != nil {
		return nil, fmt.Errorf("%s: %w", ManifestName, err)
	}
	if err := s.validate(&m); err != nil {
		return nil, fmt.Errorf("%s: %w", ManifestName, err)
	}
	s.manifest, s.modTime = &m, info.ModTime()
	return &m, nil
}

// validate rejects a manifest the app must not act on, including one whose
// APKs are missing or only partly copied, so phones never download a broken
// file or are forced to update to a release that is not there.
func (s *Store) validate(m *Manifest) error {
	switch {
	case m.Version == "":
		return errors.New("version is empty")
	case m.Build <= 0:
		return errors.New("build must be positive")
	case m.MinBuild < 0 || m.MinBuild > m.Build:
		return errors.New("min_build must be between 0 and build")
	case len(m.Files) == 0:
		return errors.New("no files")
	}
	for abi, f := range m.Files {
		if !knownABI(abi) {
			return fmt.Errorf("unknown phone type %q", abi)
		}
		if !apkName.MatchString(f.Name) {
			return fmt.Errorf("%s: invalid file name %q", abi, f.Name)
		}
		if !sha256Hex.MatchString(f.SHA256) {
			return fmt.Errorf("%s: sha256 must be 64 lowercase hex digits", abi)
		}
		info, err := os.Stat(filepath.Join(s.dir, f.Name))
		if err != nil {
			return fmt.Errorf("%s: %w", abi, err)
		}
		if info.Size() != f.Size {
			return fmt.Errorf("%s: %s is %d bytes, expected %d", abi, f.Name, info.Size(), f.Size)
		}
	}
	return nil
}

// Open opens the APK for abi. The caller closes it.
func (s *Store) Open(abi string) (*os.File, File, *Manifest, error) {
	m, err := s.Latest()
	if err != nil {
		return nil, File{}, nil, err
	}
	f, ok := m.Files[abi]
	if !ok {
		return nil, File{}, nil, ErrUnknownABI
	}
	// The name was validated as a plain file name, so it cannot leave dir.
	file, err := os.Open(filepath.Join(s.dir, f.Name))
	if err != nil {
		return nil, File{}, nil, err
	}
	return file, f, m, nil
}

func knownABI(abi string) bool {
	for _, a := range ABIs {
		if a == abi {
			return true
		}
	}
	return false
}
