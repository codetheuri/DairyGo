package member

import (
	"fmt"
	"strings"
)

// DefaultInactiveAfterDays is how long an active farmer may go without
// bringing milk before being marked inactive, when the Sacco has not chosen.
const DefaultInactiveAfterDays = 60

// What each status allows:
//
//   - ACTIVE: brings milk as usual.
//   - INACTIVE: has not brought milk for a while (or was marked so). Milk is
//     still taken, and taking it makes the farmer active again.
//   - SUSPENDED: stopped by the Sacco (for example a dispute or adulterated
//     milk). No milk is taken until staff make the farmer active again.

// maxReasonLength bounds the reason kept in the audit trail.
const maxReasonLength = 500

// checkStatusChange validates a status change made by staff and returns the
// reason to record (trimmed; empty when none was given). A suspension needs
// a reason, so that everyone can see why the farmer is refused.
func checkStatusChange(from, to Status, reason string) (string, error) {
	switch to {
	case StatusActive, StatusInactive, StatusSuspended:
	default:
		return "", fmt.Errorf("invalid member status: %s", to)
	}
	if from == to {
		return "", fmt.Errorf("the farmer is already %s", strings.ToLower(string(to)))
	}
	reason = strings.TrimSpace(reason)
	if to == StatusSuspended && reason == "" {
		return "", fmt.Errorf("give a reason for suspending the farmer")
	}
	if len(reason) > maxReasonLength {
		return "", fmt.Errorf("the reason is too long (at most %d characters)", maxReasonLength)
	}
	return reason, nil
}
