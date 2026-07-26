package sacco

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/codetheuri/tusk/internal/auth"
	"github.com/codetheuri/tusk/pkg/query"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

// CreateSacco provisions a new Sacco tenant, default settings, and initial Administrator account.
func (s *Service) CreateSacco(ctx context.Context, req *CreateSaccoRequest) (*Sacco, *auth.User, error) {
	code := strings.ToUpper(strings.TrimSpace(req.Code))
	if code == "" {
		return nil, nil, fmt.Errorf("sacco code is required")
	}

	existing, err := s.repo.FindByCode(ctx, code)
	if err == nil && existing != nil {
		return nil, nil, fmt.Errorf("sacco code '%s' already exists", code)
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.AdminUser.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to process admin password: %w", err)
	}

	saccoID := uuid.New().String()

	sacco := &Sacco{
		ID:      saccoID,
		Code:    code,
		Name:    strings.TrimSpace(req.Name),
		Email:   req.Email,
		Phone:   req.Phone,
		Address: req.Address,
		Status:  StatusActive,
	}

	settings := &SaccoSettings{
		SaccoID:  saccoID,
		Currency: "KES",
		MilkUnit: "LITRES",
	}

	adminUser := &auth.User{
		SaccoID:     &saccoID,
		Username:    strings.TrimSpace(req.AdminUser.Username),
		Email:       strings.TrimSpace(req.AdminUser.Email),
		Phone:       req.AdminUser.Phone,
		Password:    string(hash),
		IsSuperUser: true,
		IsActive:    true,
		IsVerified:  true,
	}

	adminProfile := &auth.UserProfile{
		FirstName: "Admin",
		LastName:  req.Name,
	}

	if err := s.repo.Create(ctx, sacco, adminUser, adminProfile, settings); err != nil {
		return nil, nil, err
	}

	sacco.Settings = settings
	return sacco, adminUser, nil
}

func (s *Service) GetSaccoByID(ctx context.Context, id string) (*Sacco, error) {
	if strings.TrimSpace(id) == "" {
		return nil, fmt.Errorf("sacco id is required")
	}
	return s.repo.FindByID(ctx, id)
}

func (s *Service) ListSaccos(ctx context.Context, q query.Query) ([]Sacco, query.Meta, error) {
	return s.repo.List(ctx, q)
}

func (s *Service) UpdateSacco(ctx context.Context, id string, req *UpdateSaccoRequest) (*Sacco, error) {
	sacco, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	if req.Name != nil {
		sacco.Name = strings.TrimSpace(*req.Name)
	}
	if req.Email != nil {
		sacco.Email = req.Email
	}
	if req.Phone != nil {
		sacco.Phone = req.Phone
	}
	if req.Address != nil {
		sacco.Address = req.Address
	}

	if err := s.repo.Update(ctx, sacco); err != nil {
		return nil, fmt.Errorf("failed to update sacco: %w", err)
	}

	return sacco, nil
}

func (s *Service) UpdateStatus(ctx context.Context, id string, status Status) error {
	if status != StatusActive && status != StatusInactive && status != StatusSuspended {
		return fmt.Errorf("invalid status: %s", status)
	}
	return s.repo.UpdateStatus(ctx, id, status)
}

func (s *Service) GetSettings(ctx context.Context, saccoID string) (*SaccoSettings, error) {
	if strings.TrimSpace(saccoID) == "" {
		return nil, fmt.Errorf("sacco id is required")
	}
	return s.repo.GetSettings(ctx, saccoID)
}

func (s *Service) UpdateSettings(ctx context.Context, saccoID string, req *UpdateSettingsRequest) (*SaccoSettings, error) {
	settings, err := s.repo.GetSettings(ctx, saccoID)
	if err != nil {
		return nil, err
	}

	if req.Currency != nil {
		settings.Currency = strings.ToUpper(strings.TrimSpace(*req.Currency))
	}
	if req.MilkUnit != nil {
		settings.MilkUnit = strings.ToUpper(strings.TrimSpace(*req.MilkUnit))
	}
	if req.MorningCutoffTime != nil {
		settings.MorningCutoffTime = req.MorningCutoffTime
	}
	if req.EveningCutoffTime != nil {
		settings.EveningCutoffTime = req.EveningCutoffTime
	}

	if err := s.repo.UpdateSettings(ctx, settings); err != nil {
		return nil, fmt.Errorf("failed to update settings: %w", err)
	}

	return settings, nil
}
