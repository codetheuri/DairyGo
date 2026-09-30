package member

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/audit"
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

	kin, err := cleanNextOfKin(req.NextOfKinName, req.NextOfKinRelationship, req.NextOfKinPhone)
	if err != nil {
		return nil, err
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
		ID:                uuid.New().String(),
		SaccoID:           saccoID,
		MembershipNumber:  membershipNo,
		FirstName:         strings.TrimSpace(req.FirstName),
		LastName:          strings.TrimSpace(req.LastName),
		NationalID:        req.NationalID,
		Phone:             strings.TrimSpace(req.Phone),
		Email:             req.Email,
		Gender:            &gender,
		Location:          req.Location,
		Status:            StatusActive,
		MpesaNumber:       req.MpesaNumber,
		MpesaName:         req.MpesaName,
		BankName:          req.BankName,
		BankAccountNumber: req.BankAccountNumber,
		BankBranch:        req.BankBranch,
		RegisteredByID:    registeredByID,

		NextOfKinName:         &kin.Name,
		NextOfKinRelationship: &kin.Relationship,
		NextOfKinPhone:        &kin.Phone,
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

// UpdateMember changes a farmer's details. Only the fields sent change; an
// optional field sent empty is cleared. The change is audited with the old
// and new values, since payout details decide where the farmer's money goes.
func (s *Service) UpdateMember(ctx context.Context, id string, req *UpdateMemberRequest) (*Member, error) {
	member, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	before := auditFields(member)

	if req.FirstName != nil {
		member.FirstName = strings.TrimSpace(*req.FirstName)
	}
	if req.LastName != nil {
		member.LastName = strings.TrimSpace(*req.LastName)
	}
	if req.Phone != nil {
		member.Phone = strings.TrimSpace(*req.Phone)
	}
	if req.Gender != nil {
		gender := strings.ToUpper(strings.TrimSpace(*req.Gender))
		if gender != "MALE" && gender != "FEMALE" && gender != "OTHER" {
			return nil, fmt.Errorf("gender must be MALE, FEMALE or OTHER")
		}
		member.Gender = &gender
	}
	setOptional(&member.NationalID, req.NationalID)
	setOptional(&member.Email, req.Email)
	setOptional(&member.Location, req.Location)
	setOptional(&member.MpesaNumber, req.MpesaNumber)
	setOptional(&member.MpesaName, req.MpesaName)
	setOptional(&member.BankName, req.BankName)
	setOptional(&member.BankAccountNumber, req.BankAccountNumber)
	setOptional(&member.BankBranch, req.BankBranch)

	switch {
	case len(member.FirstName) < 2 || len(member.LastName) < 2:
		return nil, fmt.Errorf("first and last name are required")
	case countDigits(member.Phone) < 10:
		return nil, fmt.Errorf("phone number must have at least 10 digits")
	case member.MpesaNumber != nil && countDigits(*member.MpesaNumber) < 10:
		return nil, fmt.Errorf("M-Pesa number must have at least 10 digits")
	}

	// Editing any next of kin detail must leave all three complete.
	if req.NextOfKinName != nil || req.NextOfKinRelationship != nil || req.NextOfKinPhone != nil {
		kin, err := cleanNextOfKin(
			firstSet(req.NextOfKinName, member.NextOfKinName),
			firstSet(req.NextOfKinRelationship, member.NextOfKinRelationship),
			firstSet(req.NextOfKinPhone, member.NextOfKinPhone),
		)
		if err != nil {
			return nil, err
		}
		member.NextOfKinName, member.NextOfKinRelationship, member.NextOfKinPhone = &kin.Name, &kin.Relationship, &kin.Phone
	}

	old, changed := diffFields(before, auditFields(member))
	if len(changed) == 0 {
		return member, nil
	}
	entry := audit.Entry{
		SaccoID: member.SaccoID, EntityType: auditEntityMember, EntityID: member.ID,
		Action: audit.ActionUpdate, ActorID: middleware.GetUserID(ctx),
		OldValues: old, NewValues: changed,
	}
	if err := s.repo.UpdateWithAudit(ctx, member, entry); err != nil {
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

// History returns the changes made to a farmer of the caller's Sacco.
func (s *Service) History(ctx context.Context, id string) ([]audit.Log, error) {
	m, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("member not found")
	}
	return s.repo.History(ctx, m)
}
