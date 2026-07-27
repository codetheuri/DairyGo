package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/danielgtaylor/huma/v2"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

type contextKey string

const (
	ContextKeyUserID  contextKey = "user_id"
	ContextKeySaccoID contextKey = "sacco_id"
	ContextKeyRole    contextKey = "role"
	ContextKeyJTI     contextKey = "jti"
)

type Claims struct {
	UserID  uint    `json:"user_id"`
	SaccoID *string `json:"sacco_id,omitempty"`
	Role    string  `json:"role"`
	jwt.RegisteredClaims
}

func Authenticate(jwtSecret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusUnauthorized)
				w.Write([]byte(`{"success":false,"error":{"code":"UNAUTHORIZED","message":"Authorization header is required"}}`))
				return
			}

			parts := strings.SplitN(authHeader, " ", 2)
			if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusUnauthorized)
				w.Write([]byte(`{"success":false,"error":{"code":"UNAUTHORIZED","message":"Invalid authorization format. Expected: Bearer <token>"}}`))
				return
			}

			tokenString := parts[1]
			claims := &Claims{}

			token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, jwt.ErrSignatureInvalid
				}
				return []byte(jwtSecret), nil
			})

			if err != nil || !token.Valid {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusUnauthorized)
				w.Write([]byte(`{"success":false,"error":{"code":"UNAUTHORIZED","message":"Invalid or expired token"}}`))
				return
			}

			ctx := context.WithValue(r.Context(), ContextKeyUserID, claims.UserID)
			ctx = context.WithValue(ctx, "user_id", claims.UserID)
			if claims.SaccoID != nil && *claims.SaccoID != "" {
				ctx = context.WithValue(ctx, ContextKeySaccoID, *claims.SaccoID)
				ctx = context.WithValue(ctx, "sacco_id", *claims.SaccoID)
			}
			ctx = context.WithValue(ctx, ContextKeyRole, claims.Role)
			ctx = context.WithValue(ctx, "role", claims.Role)
			ctx = context.WithValue(ctx, ContextKeyJTI, claims.ID)
			ctx = context.WithValue(ctx, "jti", claims.ID)

			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func RequireRole(allowedRoles ...string) func(http.Handler) http.Handler {
	allowedSet := make(map[string]bool, len(allowedRoles))
	for _, r := range allowedRoles {
		allowedSet[r] = true
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			role, ok := r.Context().Value(ContextKeyRole).(string)
			if !ok || !allowedSet[role] {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusForbidden)
				w.Write([]byte(`{"success":false,"error":{"code":"FORBIDDEN","message":"You do not have permission to perform this action"}}`))
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func GetUserID(ctx context.Context) uint {
	if ctx == nil {
		return 0
	}
	id, _ := ctx.Value(ContextKeyUserID).(uint)
	return id
}

func GetSaccoID(ctx context.Context) (string, bool) {
	if ctx == nil {
		return "", false
	}
	if saccoID, ok := ctx.Value(ContextKeySaccoID).(string); ok && saccoID != "" {
		return saccoID, true
	}
	if saccoID, ok := ctx.Value("sacco_id").(string); ok && saccoID != "" {
		return saccoID, true
	}
	return "", false
}

func IsSuperUser(ctx context.Context) bool {
	if ctx == nil {
		return false
	}
	if isSuper, ok := ctx.Value("is_super_user").(bool); ok {
		return isSuper
	}
	return false
}

func GetUserRole(ctx context.Context) string {
	if ctx == nil {
		return ""
	}
	if role, ok := ctx.Value(ContextKeyRole).(string); ok && role != "" {
		return role
	}
	if role, ok := ctx.Value("role").(string); ok && role != "" {
		return role
	}
	return ""
}

func IsExecutiveOrAdmin(ctx context.Context) bool {
	if IsSuperUser(ctx) {
		return true
	}
	role := strings.ToLower(GetUserRole(ctx))
	return strings.Contains(role, "admin") || strings.Contains(role, "board") || strings.Contains(role, "executive")
}

// HumaAuthenticate decodes the JWT Authorization header into the Huma request context.
func HumaAuthenticate(api huma.API, jwtSecret string, db *gorm.DB) func(huma.Context, func(huma.Context)) {
	return func(ctx huma.Context, next func(huma.Context)) {
		authHeader := ctx.Header("Authorization")
		if authHeader == "" {
			next(ctx)
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) == 2 && strings.ToLower(parts[0]) == "bearer" {
			tokenString := parts[1]
			claims := &Claims{}
			token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, jwt.ErrSignatureInvalid
				}
				return []byte(jwtSecret), nil
			})

			if err == nil && token.Valid {
				reqCtx := ctx.Context()
				reqCtx = context.WithValue(reqCtx, ContextKeyUserID, claims.UserID)
				reqCtx = context.WithValue(reqCtx, "user_id", claims.UserID)
				if claims.SaccoID != nil && *claims.SaccoID != "" {
					reqCtx = context.WithValue(reqCtx, ContextKeySaccoID, *claims.SaccoID)
					reqCtx = context.WithValue(reqCtx, "sacco_id", *claims.SaccoID)
				}
				reqCtx = context.WithValue(reqCtx, ContextKeyRole, claims.Role)
				reqCtx = context.WithValue(reqCtx, "role", claims.Role)

				var userStruct struct {
					IsSuperUser bool    `gorm:"is_super_user"`
					SaccoID     *string `gorm:"sacco_id"`
				}
				if db != nil {
					if err := db.WithContext(reqCtx).Table("users").Where("id = ?", claims.UserID).Select("is_super_user", "sacco_id").Take(&userStruct).Error; err == nil {
						reqCtx = context.WithValue(reqCtx, "is_super_user", userStruct.IsSuperUser)
						if userStruct.SaccoID != nil && *userStruct.SaccoID != "" {
							reqCtx = context.WithValue(reqCtx, ContextKeySaccoID, *userStruct.SaccoID)
							reqCtx = context.WithValue(reqCtx, "sacco_id", *userStruct.SaccoID)
						}
					}
				}

				ctx = huma.WithContext(ctx, reqCtx)
			}
		}

		next(ctx)
	}
}
