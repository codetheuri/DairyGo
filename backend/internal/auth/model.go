package auth

import (
	"time"

	"gorm.io/gorm"
)

// Seeded Sacco role IDs (see migration 00007). They are fixed so that
// onboarding and staff registration can assign them without a name lookup.
const (
	RoleSaccoAdmin uint = 1
	RoleCollector  uint = 2
	RoleExecutive  uint = 3
)

// SaccoRoleName returns the display name of a seeded Sacco role.
func SaccoRoleName(roleID uint) string {
	switch roleID {
	case RoleSaccoAdmin:
		return "Sacco Administrator"
	case RoleCollector:
		return "Milk Collector"
	case RoleExecutive:
		return "Board Member / Executive"
	default:
		return ""
	}
}

// IsSaccoRole reports whether roleID is one of the roles a Sacco may assign to its own staff.
func IsSaccoRole(roleID uint) bool {
	return roleID == RoleSaccoAdmin || roleID == RoleCollector || roleID == RoleExecutive
}

// User handles core authentication data, credentials, and security state.
//
// IsSuperUser marks a platform operator. It is only honoured for accounts
// with no SaccoID; see middleware.HumaAuthenticate.
type User struct {
	ID                  uint       `json:"id" gorm:"primaryKey"`
	SaccoID             *string    `json:"sacco_id,omitempty" gorm:"index"`
	Username            string     `json:"username" gorm:"uniqueIndex;not null"`
	Email               string     `json:"email" gorm:"uniqueIndex;not null"`
	Phone               *string    `json:"phone,omitempty" gorm:"uniqueIndex"`
	Password            string     `json:"-" gorm:"not null"`
	IsSuperUser         bool       `json:"is_super_user" gorm:"default:false"`
	IsActive            bool       `json:"is_active" gorm:"default:true"`
	IsVerified          bool       `json:"is_verified" gorm:"default:false"`
	FailedLoginAttempts int        `json:"failed_login_attempts" gorm:"default:0"`
	LockedUntil         *time.Time `json:"locked_until,omitempty"`
	LastLoginAt         *time.Time `json:"last_login_at,omitempty"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`

	// DeletedAt marks a removed account (see Service.RemoveStaff). GORM leaves
	// removed accounts out of every query on User; the row stays so records
	// they made keep their name.
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`
	DeletedByID *uint          `json:"-"`

	RoleName string `json:"role_name,omitempty" gorm:"-"`
	// Permissions the user holds through their role, sent with the profile
	// (login, refresh, /auth/me) so the app shows only what they may use.
	Permissions []string `json:"permissions,omitempty" gorm:"-"`

	// 1-to-1 Profile relationship
	Profile *UserProfile `json:"profile,omitempty" gorm:"foreignKey:UserID"`
}

// UserProfile stores personal identity information.
type UserProfile struct {
	UserID    uint      `json:"user_id" gorm:"primaryKey"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Avatar    string    `json:"avatar"`
	Bio       string    `json:"bio"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// RefreshToken stores hashed refresh tokens for session management and revocation.
type RefreshToken struct {
	ID        uint       `json:"id" gorm:"primaryKey"`
	UserID    uint       `json:"user_id" gorm:"not null;index"`
	TokenHash string     `json:"-" gorm:"uniqueIndex;not null"`
	ExpiresAt time.Time  `json:"expires_at" gorm:"not null"`
	RevokedAt *time.Time `json:"revoked_at,omitempty"`
	// ReplacedAt is set when the token is rotated; it stays usable for a
	// short grace period (see refreshDecision).
	ReplacedAt *time.Time `json:"replaced_at,omitempty"`
	CreatedAt  time.Time  `json:"created_at"`
}

// Role represents a security role containing permissions.
type Role struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	Name        string    `json:"name" gorm:"uniqueIndex;not null"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	Permissions []string  `json:"permissions,omitempty" gorm:"-"`
}

// RolePermission defines the join table linking roles to permissions.
type RolePermission struct {
	RoleID         uint   `gorm:"primaryKey"`
	PermissionName string `gorm:"primaryKey"`
	CreatedAt      time.Time
}

// UserRole defines the join table linking users to roles.
type UserRole struct {
	UserID    uint `gorm:"primaryKey"`
	RoleID    uint `gorm:"primaryKey"`
	CreatedAt time.Time
}
