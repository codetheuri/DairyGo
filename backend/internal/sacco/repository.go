package sacco

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/codetheuri/tusk/internal/auth"
	"github.com/codetheuri/tusk/pkg/query"
	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// Create provisions a new Sacco, default settings, and initial Sacco Admin user atomically within a database transaction.
func (r *Repository) Create(ctx context.Context, s *Sacco, adminUser *auth.User, adminProfile *auth.UserProfile, settings *SaccoSettings) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(s).Error; err != nil {
			return fmt.Errorf("failed to create sacco: %w", err)
		}

		settings.SaccoID = s.ID
		if err := tx.Create(settings).Error; err != nil {
			return fmt.Errorf("failed to create sacco settings: %w", err)
		}

		adminUser.SaccoID = &s.ID
		if err := tx.Create(adminUser).Error; err != nil {
			return fmt.Errorf("failed to create sacco admin user: %w", err)
		}

		if adminProfile != nil {
			adminProfile.UserID = adminUser.ID
			if err := tx.Create(adminProfile).Error; err != nil {
				return fmt.Errorf("failed to create admin profile: %w", err)
			}
		}

		// Look up or assign "admin" role to the initial admin user if roles exist
		var role auth.Role
		if err := tx.Where("name = ?", "admin").First(&role).Error; err == nil {
			userRole := auth.UserRole{
				UserID: adminUser.ID,
				RoleID: role.ID,
			}
			_ = tx.Create(&userRole).Error
		}

		return nil
	})
}

func (r *Repository) FindByID(ctx context.Context, id string) (*Sacco, error) {
	var s Sacco
	if err := r.db.WithContext(ctx).Preload("Settings").Where("id = ?", id).First(&s).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("sacco not found")
		}
		return nil, err
	}
	return &s, nil
}

func (r *Repository) FindByCode(ctx context.Context, code string) (*Sacco, error) {
	var s Sacco
	if err := r.db.WithContext(ctx).Where("code = ?", strings.ToUpper(code)).First(&s).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("sacco not found")
		}
		return nil, err
	}
	return &s, nil
}

func (r *Repository) List(ctx context.Context, q query.Query) ([]Sacco, query.Meta, error) {
	cfg := query.Config{
		DefaultSort:    "-created_at",
		DefaultPerPage: 20,
		MaxPerPage:     100,
		AllowedSorts: map[string]string{
			"id":         "saccos.id",
			"code":       "saccos.code",
			"name":       "saccos.name",
			"status":     "saccos.status",
			"created_at": "saccos.created_at",
		},
		AllowedSearches: []string{"saccos.code", "saccos.name", "saccos.email", "saccos.phone"},
		AllowedFilters: map[string]string{
			"status": "saccos.status",
		},
	}

	return query.Paginate[Sacco](ctx, r.db.Preload("Settings"), q, cfg)
}

func (r *Repository) Update(ctx context.Context, s *Sacco) error {
	return r.db.WithContext(ctx).Save(s).Error
}

func (r *Repository) UpdateStatus(ctx context.Context, id string, status Status) error {
	return r.db.WithContext(ctx).Model(&Sacco{}).Where("id = ?", id).Update("status", status).Error
}

func (r *Repository) GetSettings(ctx context.Context, saccoID string) (*SaccoSettings, error) {
	var settings SaccoSettings
	if err := r.db.WithContext(ctx).Where("sacco_id = ?", saccoID).First(&settings).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("sacco settings not found")
		}
		return nil, err
	}
	return &settings, nil
}

func (r *Repository) UpdateSettings(ctx context.Context, settings *SaccoSettings) error {
	return r.db.WithContext(ctx).Save(settings).Error
}
