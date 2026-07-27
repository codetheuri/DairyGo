package auth

import (
	"context"
	"time"

	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/pkg/logger"
	"github.com/codetheuri/tusk/pkg/query"
	"gorm.io/gorm"
)

type Repository struct {
	db  *gorm.DB
	log logger.Logger
}

func NewRepository(db *gorm.DB, log logger.Logger) *Repository {
	return &Repository{
		db:  db,
		log: log,
	}
}

// CreateUserWithProfile inserts a new user and user profile inside a transaction.
func (r *Repository) CreateUserWithProfile(ctx context.Context, user *User, profile *UserProfile) error {
	return r.CreateUserWithProfileAndRole(ctx, user, profile, nil)
}

// CreateUserWithProfileAndRole inserts a new user, user profile, and attaches an optional role ID inside a transaction.
func (r *Repository) CreateUserWithProfileAndRole(ctx context.Context, user *User, profile *UserProfile, roleID *uint) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(user).Error; err != nil {
			return err
		}
		profile.UserID = user.ID
		if err := tx.Create(profile).Error; err != nil {
			return err
		}
		if roleID != nil && *roleID > 0 {
			userRole := UserRole{
				UserID: user.ID,
				RoleID: *roleID,
			}
			if err := tx.FirstOrCreate(&userRole, UserRole{UserID: user.ID, RoleID: *roleID}).Error; err != nil {
				return err
			}
		}
		user.Profile = profile
		return nil
	})
}

func (r *Repository) attachRoleName(ctx context.Context, user *User) {
	if user == nil {
		return
	}
	if user.IsSuperUser {
		user.RoleName = "Sacco Administrator"
		return
	}
	var roleName string
	r.db.WithContext(ctx).
		Table("roles").
		Select("roles.name").
		Joins("JOIN user_roles ON user_roles.role_id = roles.id").
		Where("user_roles.user_id = ?", user.ID).
		Scan(&roleName)
	if roleName != "" {
		user.RoleName = roleName
	} else {
		user.RoleName = "Milk Collector"
	}
}

// FindByLogin searches for a user by username, email, or phone number.
func (r *Repository) FindByLogin(ctx context.Context, login string) (*User, error) {
	var user User
	err := r.db.WithContext(ctx).
		Preload("Profile").
		Where("username = ? OR email = ? OR phone = ?", login, login, login).
		First(&user).Error
	if err != nil {
		return nil, err
	}
	r.attachRoleName(ctx, &user)
	return &user, nil
}

// FindByID fetches a user account by primary key ID.
func (r *Repository) FindByID(ctx context.Context, id uint) (*User, error) {
	var user User
	err := r.db.WithContext(ctx).Preload("Profile").First(&user, id).Error
	if err != nil {
		return nil, err
	}
	r.attachRoleName(ctx, &user)
	return &user, nil
}

// ListUsers fetches all registered users with optional search/pagination.
func (r *Repository) ListUsers(ctx context.Context, q query.Query) ([]User, query.Meta, error) {
	cfg := query.Config{
		DefaultSort:    "-created_at",
		DefaultPerPage: 20,
		MaxPerPage:     100,
		AllowedSorts: map[string]string{
			"id":         "users.id",
			"username":   "users.username",
			"email":      "users.email",
			"created_at": "users.created_at",
		},
		AllowedSearches: []string{"users.username", "users.email", "users.phone"},
	}

	db := r.db.Preload("Profile")
	if saccoID, ok := middleware.GetSaccoID(ctx); ok && saccoID != "" {
		db = db.Where("sacco_id = ?", saccoID)
	} else if authUser, ok := ctx.Value("user").(*User); ok && authUser != nil && authUser.SaccoID != nil {
		db = db.Where("sacco_id = ?", *authUser.SaccoID)
	}

	users, meta, err := query.Paginate[User](ctx, db, q, cfg)
	if err != nil {
		return nil, meta, err
	}
	for i := range users {
		r.attachRoleName(ctx, &users[i])
	}
	return users, meta, nil
}

// UpdateUser updates user status or profile details.
func (r *Repository) UpdateUser(ctx context.Context, user *User) error {
	return r.db.WithContext(ctx).Save(user).Error
}

// UpdateProfile updates user profile details.
func (r *Repository) UpdateProfile(ctx context.Context, profile *UserProfile) error {
	return r.db.WithContext(ctx).Save(profile).Error
}

// SaveRefreshToken persists a new hashed refresh token.
func (r *Repository) SaveRefreshToken(ctx context.Context, token *RefreshToken) error {
	return r.db.WithContext(ctx).Create(token).Error
}

// FindRefreshToken finds a active refresh token by hash.
func (r *Repository) FindRefreshToken(ctx context.Context, tokenHash string) (*RefreshToken, error) {
	var token RefreshToken
	err := r.db.WithContext(ctx).
		Where("token_hash = ? AND revoked_at IS NULL AND expires_at > ?", tokenHash, time.Now()).
		First(&token).Error
	if err != nil {
		return nil, err
	}
	return &token, nil
}

// RevokeRefreshToken marks a token as revoked.
func (r *Repository) RevokeRefreshToken(ctx context.Context, tokenHash string) error {
	return r.db.WithContext(ctx).
		Model(&RefreshToken{}).
		Where("token_hash = ?", tokenHash).
		Update("revoked_at", time.Now()).Error
}
