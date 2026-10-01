package sacco

import (
	"bytes"
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"image"
	_ "image/jpeg" // decode JPEG logos
	_ "image/png"  // decode PNG logos
	"net/http"
	"strings"
)

// MaxLogoBytes bounds a logo: plenty for a sharp letterhead, small enough to
// keep every report quick to make.
const MaxLogoBytes = 512 << 10

// ErrNoLogo means the Sacco has no logo.
var ErrNoLogo = errors.New("this Sacco has no logo")

// decodeLogo checks an uploaded logo (base64, optionally a data: URL) and
// returns its bytes and type: a PNG or JPEG of at most MaxLogoBytes that
// really is an image of a sensible size.
func decodeLogo(encoded string) ([]byte, string, error) {
	encoded = strings.TrimSpace(encoded)
	if i := strings.Index(encoded, ","); strings.HasPrefix(encoded, "data:") && i > 0 {
		encoded = encoded[i+1:]
	}
	data, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return nil, "", fmt.Errorf("the logo could not be read; send a PNG or JPEG image")
	}
	if len(data) > MaxLogoBytes {
		return nil, "", fmt.Errorf("the logo is too large (%d KB); use one under %d KB", len(data)>>10, MaxLogoBytes>>10)
	}
	kind := http.DetectContentType(data)
	if kind != "image/png" && kind != "image/jpeg" {
		return nil, "", fmt.Errorf("the logo must be a PNG or JPEG image")
	}
	// Decode it all, not just the header, so a damaged file is refused now
	// rather than breaking every report later.
	img, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, "", fmt.Errorf("the logo image is damaged")
	}
	if b := img.Bounds(); b.Dx() < 32 || b.Dy() < 32 || b.Dx() > 4000 || b.Dy() > 4000 {
		return nil, "", fmt.Errorf("the logo must be between 32 and 4000 pixels wide and high")
	}
	return data, kind, nil
}

// SetLogo stores a Sacco's logo, printed on its reports.
func (s *Service) SetLogo(ctx context.Context, saccoID, encoded string) error {
	data, kind, err := decodeLogo(encoded)
	if err != nil {
		return err
	}
	return s.repo.SetLogo(ctx, saccoID, data, kind)
}

// RemoveLogo removes a Sacco's logo.
func (s *Service) RemoveLogo(ctx context.Context, saccoID string) error {
	return s.repo.SetLogo(ctx, saccoID, nil, "")
}

// Logo returns a Sacco's logo and its type.
func (s *Service) Logo(ctx context.Context, saccoID string) ([]byte, string, error) {
	return s.repo.Logo(ctx, saccoID)
}

// SetLogo stores (or with nil, removes) a Sacco's logo.
func (r *Repository) SetLogo(ctx context.Context, saccoID string, data []byte, kind string) error {
	var typ any = kind
	if data == nil {
		typ = nil
	}
	res := r.db.WithContext(ctx).Table("saccos").Where("id = ? AND deleted_at IS NULL", saccoID).
		Updates(map[string]any{"logo": data, "logo_type": typ})
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return fmt.Errorf("sacco not found")
	}
	return nil
}

// Logo loads a Sacco's logo.
func (r *Repository) Logo(ctx context.Context, saccoID string) ([]byte, string, error) {
	var row struct {
		Logo     []byte
		LogoType *string
	}
	err := r.db.WithContext(ctx).Table("saccos").Select("logo, logo_type").
		Where("id = ? AND deleted_at IS NULL", saccoID).Take(&row).Error
	if err != nil {
		return nil, "", fmt.Errorf("sacco not found")
	}
	if len(row.Logo) == 0 || row.LogoType == nil {
		return nil, "", ErrNoLogo
	}
	return row.Logo, *row.LogoType, nil
}
