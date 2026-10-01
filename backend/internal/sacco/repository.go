package sacco

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/codetheuri/tusk/internal/auth"
	"github.com/codetheuri/tusk/internal/payout"
	"github.com/codetheuri/tusk/pkg/audit"
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
func (r *Repository) Create(ctx context.Context, s *Sacco, adminUser *auth.User, adminProfile *auth.UserProfile, settings *SaccoSettings, createdBy uint) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(s).Error; err != nil {
			return fmt.Errorf("failed to create sacco: %w", err)
		}

		settings.SaccoID = s.ID
		if err := tx.Create(settings).Error; err != nil {
			return fmt.Errorf("failed to create sacco settings: %w", err)
		}

		// Example deductions (switched off) for the admin to complete.
		if err := tx.Create(payout.Examples(s.ID)).Error; err != nil {
			return fmt.Errorf("failed to add example deductions: %w", err)
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

		if err := audit.Record(tx, audit.Entry{
			SaccoID: s.ID, EntityType: "sacco", EntityID: s.ID, Action: audit.ActionCreate,
			ActorID: createdBy, NewValues: map[string]any{"code": s.Code, "name": s.Name, "admin_username": adminUser.Username},
		}); err != nil {
			return err
		}

		// The initial admin is a regular Sacco Administrator, not a platform super
		// user, so their access stays inside this Sacco.
		userRole := auth.UserRole{UserID: adminUser.ID, RoleID: auth.RoleSaccoAdmin}
		if err := tx.Create(&userRole).Error; err != nil {
			return fmt.Errorf("failed to assign sacco admin role: %w", err)
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

// UpdateStatus changes a Sacco's status and saves the audit entry atomically.
func (r *Repository) UpdateStatus(ctx context.Context, id string, status Status, entry audit.Entry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		res := tx.Model(&Sacco{}).Where("id = ?", id).Update("status", status)
		if res.Error != nil {
			return res.Error
		}
		if res.RowsAffected == 0 {
			return fmt.Errorf("sacco not found")
		}
		return audit.Record(tx, entry)
	})
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
