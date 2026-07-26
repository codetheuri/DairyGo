package member

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/query"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) CreateMember(ctx context.Context, req *CreateMemberRequest) (*Member, error) {
	saccoID, ok := middleware.GetSaccoID(ctx)
	if !ok || saccoID == "" {
		return nil, fmt.Errorf("sacco context is required to register members")
	}

	var membershipNo string
	if req.MembershipNumber != nil && strings.TrimSpace(*req.MembershipNumber) != "" {
		membershipNo = strings.ToUpper(strings.TrimSpace(*req.MembershipNumber))
		existing, err := s.repo.FindByMembershipNumber(ctx, saccoID, membershipNo)
		if err == nil && existing != nil {
			return nil, fmt.Errorf("membership number '%s' already exists in this Sacco", membershipNo)
		}
	} else {
		seq, err := s.repo.GetNextMembershipSequence(ctx, saccoID)
		if err != nil {
			return nil, fmt.Errorf("failed to generate membership sequence: %w", err)
		}
		membershipNo = fmt.Sprintf("MEM-%04d", seq)
	}

	userID := middleware.GetUserID(ctx)
	var registeredByID *uint
	if userID > 0 {
		registeredByID = &userID
	}

	gender := "OTHER"
	if req.Gender != nil && *req.Gender != "" {
		gender = strings.ToUpper(*req.Gender)
	}

	member := &Member{
		ID:               uuid.New().String(),
		SaccoID:          saccoID,
		MembershipNumber: membershipNo,
		FirstName:        strings.TrimSpace(req.FirstName),
		LastName:         strings.TrimSpace(req.LastName),
		NationalID:       req.NationalID,
		Phone:            strings.TrimSpace(req.Phone),
		Email:            req.Email,
		Gender:           &gender,
		Location:         req.Location,
		Status:           StatusActive,
		MpesaNumber:      req.MpesaNumber,
		MpesaName:        req.MpesaName,
		BankName:         req.BankName,
		BankAccountNumber: req.BankAccountNumber,
		BankBranch:       req.BankBranch,
		RegisteredByID:   registeredByID,
	}

	if err := s.repo.Create(ctx, member); err != nil {
		return nil, fmt.Errorf("failed to create member: %w", err)
	}

	return member, nil
}

func (s *Service) GetMemberByID(ctx context.Context, id string) (*Member, error) {
	if strings.TrimSpace(id) == "" {
		return nil, fmt.Errorf("member id is required")
	}
	return s.repo.FindByID(ctx, id)
}

func (s *Service) ListMembers(ctx context.Context, q query.Query) ([]Member, query.Meta, error) {
	return s.repo.List(ctx, q)
}

func (s *Service) UpdateMember(ctx context.Context, id string, req *UpdateMemberRequest) (*Member, error) {
	member, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	if req.FirstName != nil {
		member.FirstName = strings.TrimSpace(*req.FirstName)
	}
	if req.LastName != nil {
		member.LastName = strings.TrimSpace(*req.LastName)
	}
	if req.NationalID != nil {
		member.NationalID = req.NationalID
	}
	if req.Phone != nil {
		member.Phone = strings.TrimSpace(*req.Phone)
	}
	if req.Email != nil {
		member.Email = req.Email
	}
	if req.Gender != nil {
		gender := strings.ToUpper(*req.Gender)
		member.Gender = &gender
	}
	if req.Location != nil {
		member.Location = req.Location
	}
	if req.MpesaNumber != nil {
		member.MpesaNumber = req.MpesaNumber
	}
	if req.MpesaName != nil {
		member.MpesaName = req.MpesaName
	}
	if req.BankName != nil {
		member.BankName = req.BankName
	}
	if req.BankAccountNumber != nil {
		member.BankAccountNumber = req.BankAccountNumber
	}
	if req.BankBranch != nil {
		member.BankBranch = req.BankBranch
	}

	if err := s.repo.Update(ctx, member); err != nil {
		return nil, fmt.Errorf("failed to update member: %w", err)
	}

	return member, nil
}

func (s *Service) UpdateStatus(ctx context.Context, id string, status Status) error {
	if status != StatusActive && status != StatusInactive && status != StatusSuspended {
		return fmt.Errorf("invalid member status: %s", status)
	}
	return s.repo.UpdateStatus(ctx, id, status)
}
