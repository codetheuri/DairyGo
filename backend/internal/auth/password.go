package auth

import (
	"fmt"
	"unicode/utf8"
)

// MinPasswordLength is the shortest password accepted anywhere: signing up
// staff, changing a password in the app, and the platform console (adding
// staff, resetting a password, a new Sacco's administrator).
//
// Struct tags cannot use a constant, so request types write it as
// minLength:"4"; TestPasswordRulesMatch (internal/app) checks every password
// field of the API, and web_test.go the console, against this value. The app
// mirrors it in lib/core/constants/password_rules.dart.
const MinPasswordLength = 4

// CheckPasswordLength refuses a password shorter than MinPasswordLength
// (counted in characters, not bytes).
func CheckPasswordLength(password string) error {
	if utf8.RuneCountInString(password) < MinPasswordLength {
		return fmt.Errorf("password must be at least %d characters", MinPasswordLength)
	}
	return nil
}
