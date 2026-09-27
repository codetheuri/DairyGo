// Package superadmin powers the platform console: the DairyGo operator's view
// across every Sacco (overview, onboarding, suspension, staff, farmers) and
// the platform logs (audit trail, failed requests, SMS).
//
// Every endpoint requires a platform super user (is_super_user with no Sacco).
// Sacco-level work reuses the member and auth services by running them in the
// chosen Sacco's context, so business rules are not duplicated here.
package superadmin

import "time"

// Overview is the platform-wide summary shown on the console home page.
type Overview struct {
	SaccosTotal          int64        `json:"saccos_total"`
	SaccosActive         int64        `json:"saccos_active"`
	SaccosSuspended      int64        `json:"saccos_suspended"`
	SaccosInactive       int64        `json:"saccos_inactive"`
	ActiveFarmers        int64        `json:"active_farmers"`
	StaffUsers           int64        `json:"staff_users"`
	TodayCollectedLitres float64      `json:"today_collected_litres"`
	MonthCollectedLitres float64      `json:"month_collected_litres"`
	MonthSalesRevenueKES float64      `json:"month_sales_revenue_kes"`
	MonthPayoutKES       float64      `json:"month_payout_liability_kes"`
	ReceivablesKES       float64      `json:"receivables_kes"`
	FailedRequests24h    int64        `json:"failed_requests_24h"`
	ServerErrors24h      int64        `json:"server_errors_24h"`
	Saccos               []SaccoStats `json:"saccos"`
}

// SaccoStats is one Sacco's row in the overview.
type SaccoStats struct {
	ID              string     `json:"id"`
	Code            string     `json:"code"`
	Name            string     `json:"name"`
	Status          string     `json:"status"`
	CreatedAt       time.Time  `json:"created_at"`
	ActiveFarmers   int64      `json:"active_farmers"`
	StaffCount      int64      `json:"staff_count"`
	MonthLitres     float64    `json:"month_litres"`
	MonthRevenueKES float64    `json:"month_revenue_kes"`
	ReceivablesKES  float64    `json:"receivables_kes"`
	LastCollection  *time.Time `json:"last_collection,omitempty"`
}

// StaffUser is a Sacco staff account as seen by the platform operator.
type StaffUser struct {
	ID                  uint       `json:"id"`
	Username            string     `json:"username"`
	Email               string     `json:"email"`
	Phone               *string    `json:"phone,omitempty"`
	FirstName           string     `json:"first_name"`
	LastName            string     `json:"last_name"`
	RoleName            string     `json:"role_name"`
	IsActive            bool       `json:"is_active"`
	FailedLoginAttempts int        `json:"failed_login_attempts"`
	LockedUntil         *time.Time `json:"locked_until,omitempty"`
	LastLoginAt         *time.Time `json:"last_login_at,omitempty"`
	CreatedAt           time.Time  `json:"created_at"`
}

// AuditEntry is an audit log row with the actor and Sacco names filled in.
type AuditEntry struct {
	ID         string    `json:"id"`
	SaccoID    *string   `json:"sacco_id,omitempty"`
	SaccoName  *string   `json:"sacco_name,omitempty"`
	EntityType string    `json:"entity_type"`
	EntityID   string    `json:"entity_id"`
	Action     string    `json:"action"`
	ActorID    *uint     `json:"actor_id,omitempty"`
	ActorName  *string   `json:"actor_name,omitempty"`
	Reason     *string   `json:"reason,omitempty"`
	OldValues  *string   `json:"old_values,omitempty"`
	NewValues  *string   `json:"new_values,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
}

// SystemLog is a failed API request (see middleware.RecordFailures).
type SystemLog struct {
	ID         string    `json:"id" gorm:"primaryKey"`
	Level      string    `json:"level"`
	Method     string    `json:"method"`
	Path       string    `json:"path"`
	Query      *string   `json:"query,omitempty"`
	Status     int       `json:"status"`
	Message    *string   `json:"message,omitempty"`
	RequestID  *string   `json:"request_id,omitempty"`
	UserID     *uint     `json:"user_id,omitempty"`
	Username   *string   `json:"username,omitempty" gorm:"->;-:migration"`
	SaccoID    *string   `json:"sacco_id,omitempty"`
	SaccoName  *string   `json:"sacco_name,omitempty" gorm:"->;-:migration"`
	DurationMS int64     `json:"duration_ms"`
	IP         *string   `json:"ip,omitempty"`
	UserAgent  *string   `json:"user_agent,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
}

// TableName sets the database table name.
func (SystemLog) TableName() string {
	return "system_logs"
}

// SMSEntry is an SMS log row with the Sacco name filled in.
type SMSEntry struct {
	ID             string    `json:"id"`
	SaccoID        *string   `json:"sacco_id,omitempty"`
	SaccoName      *string   `json:"sacco_name,omitempty"`
	RecipientPhone string    `json:"recipient_phone"`
	Message        string    `json:"message"`
	Provider       string    `json:"provider"`
	Status         string    `json:"status"`
	ErrorMessage   *string   `json:"error_message,omitempty"`
	CreatedAt      time.Time `json:"created_at"`
}
