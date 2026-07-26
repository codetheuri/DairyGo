package member

import (
	"context"
	"errors"
	"fmt"

	"github.com/codetheuri/tusk/pkg/query"
	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(ctx context.Context, m *Member) error {
	return r.db.WithContext(ctx).Create(m).Error
}

func (r *Repository) FindByID(ctx context.Context, id string) (*Member, error) {
	var m Member
	err := r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Where("id = ?", id).First(&m).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("member not found")
		}
		return nil, err
	}
	return &m, nil
}

func (r *Repository) FindByMembershipNumber(ctx context.Context, saccoID, membershipNo string) (*Member, error) {
	var m Member
	err := r.db.WithContext(ctx).Where("sacco_id = ? AND membership_number = ?", saccoID, membershipNo).First(&m).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("member not found")
		}
		return nil, err
	}
	return &m, nil
}

func (r *Repository) GetNextMembershipSequence(ctx context.Context, saccoID string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&Member{}).Where("sacco_id = ?", saccoID).Unscoped().Count(&count).Error
	return count + 1, err
}

func (r *Repository) List(ctx context.Context, q query.Query) ([]Member, query.Meta, error) {
	cfg := query.Config{
		DefaultSort:    "-created_at",
		DefaultPerPage: 20,
		MaxPerPage:     100,
		AllowedSorts: map[string]string{
			"id":                "members.id",
			"membership_number": "members.membership_number",
			"first_name":        "members.first_name",
			"last_name":         "members.last_name",
			"status":            "members.status",
			"created_at":        "members.created_at",
		},
		AllowedSearches: []string{"members.membership_number", "members.first_name", "members.last_name", "members.phone", "members.national_id"},
		AllowedFilters: map[string]string{
			"status": "members.status",
		},
	}

	session := r.db.Model(&Member{}).Scopes(query.TenantScope(ctx))
	return query.Paginate[Member](ctx, session, q, cfg)
}

func (r *Repository) Update(ctx context.Context, m *Member) error {
	return r.db.WithContext(ctx).Scopes(query.TenantScope(ctx)).Save(m).Error
}

func (r *Repository) UpdateStatus(ctx context.Context, id string, status Status) error {
	return r.db.WithContext(ctx).Model(&Member{}).Scopes(query.TenantScope(ctx)).Where("id = ?", id).Update("status", status).Error
}
