package sacco

import (
	"bytes"
	"encoding/base64"
	"image"
	"image/png"
	"strings"
	"testing"
)

func pngOf(w, h int) []byte {
	var buf bytes.Buffer
	_ = png.Encode(&buf, image.NewRGBA(image.Rect(0, 0, w, h)))
	return buf.Bytes()
}

func TestDecodeLogo(t *testing.T) {
	good := base64.StdEncoding.EncodeToString(pngOf(256, 255))
	data, kind, err := decodeLogo(good)
	if err != nil || kind != "image/png" || len(data) == 0 {
		t.Fatalf("good logo: %v %q", err, kind)
	}
	if _, _, err := decodeLogo("data:image/png;base64," + good); err != nil {
		t.Errorf("data URL: %v", err)
	}
	for name, in := range map[string]string{
		"not base64": "%%%",
		"not image":  base64.StdEncoding.EncodeToString([]byte("hello, this is text")),
		"too small":  base64.StdEncoding.EncodeToString(pngOf(10, 10)),
		"damaged":    base64.StdEncoding.EncodeToString(pngOf(64, 64)[:60]),
		"too large":  base64.StdEncoding.EncodeToString(append(pngOf(64, 64), make([]byte, MaxLogoBytes)...)),
	} {
		if _, _, err := decodeLogo(in); err == nil {
			t.Errorf("%s: accepted", name)
		} else if !strings.Contains(err.Error(), "logo") {
			t.Errorf("%s: unhelpful error %q", name, err)
		}
	}
}
