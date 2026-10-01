// Package letterhead reads what is printed at the top of a Sacco's
// documents (name, contacts, logo) and staff names, for every module that
// makes PDF or Excel files.
package letterhead

import (
	"context"
	"fmt"

	"gorm.io/gorm"

	"github.com/codetheuri/tusk/pkg/document"
)

// StaffNameSQL is a user's full name, or their username without one, for a
// query joining users u and user_profiles p.
const StaffNameSQL = "COALESCE(NULLIF(TRIM(COALESCE(p.first_name, '') || ' ' || COALESCE(p.last_name, '')), ''), u.username)"

// Source reads letterheads and staff names.
type Source struct {
	db *gorm.DB
}

// New creates a letterhead source.
func New(db *gorm.DB) *Source {
	return &Source{db: db}
}

// Letterhead is the Sacco's name, contacts and logo.
func (s *Source) Letterhead(ctx context.Context, saccoID string) (document.Letterhead, error) {
	var row struct {
		Name    string
		Phone   *string
		Email   *string
		Address *string
		Logo    []byte
	}
	err := s.db.WithContext(ctx).Table("saccos").Select("name, phone, email, address, logo").
		Where("id = ?", saccoID).Take(&row).Error
	if err != nil {
		return document.Letterhead{}, fmt.Errorf("sacco: %w", err)
	}
	return document.Letterhead{Name: row.Name, Phone: deref(row.Phone), Email: deref(row.Email), Address: deref(row.Address), Logo: row.Logo}, nil
}

// StaffName is a user's name as shown on documents.
func (s *Source) StaffName(ctx context.Context, userID uint) string {
	var name string
	s.db.WithContext(ctx).Table("users u").Select(StaffNameSQL).
		Joins("LEFT JOIN user_profiles p ON p.user_id = u.id").Where("u.id = ?", userID).Scan(&name)
	return name
}

func deref(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
