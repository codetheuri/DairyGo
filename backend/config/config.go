package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql" // MySQL driver
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"     // PostgreSQL driver
	_ "gorm.io/driver/sqlite" // SQLite driver
)

type Config struct {
	DBUser         string
	DBPass         string
	DBHost         string
	DBPort         string
	DBName         string
	DBDriver       string
	ServerPort     int
	LOG_LEVEL      string
	JWTSecret      string
	AccessTokenTTL time.Duration
	// SessionIdleTimeout signs a user out after this long without using the
	// app: each token refresh extends the session by this much.
	SessionIdleTimeout time.Duration
	AppName            string
	AppVersion         string
	AppMode            string
	AppTimezone        string
	DbURL              string
	DBMaxIdleConns     int
	DBMaxOpenConns     int
	DBConnMaxLifetime  int
	CORSOrigins        []string
	// AutoMigrate applies pending database migrations before the API starts
	// serving (AUTO_MIGRATE=true), so a deploy needs no separate step.
	AutoMigrate bool
	// AppReleasesDir holds the published Android app (APKs and
	// latest.json), served for download and the in-app updater.
	AppReleasesDir string

	//mailer config
	MailerHost     string
	MailerPort     int
	MailerUsername string
	MailerPassword string
	MailerSender   string

	// SMS Config
	SMSProvider      string
	HttpSMSAPIKey    string
	HttpSMSFromPhone string
	ATUsername       string
	ATAPIKey         string
	ATSenderID       string
	ATIsSandbox      bool
}

// placeholderJWTSecret is the example value committed in docker-compose.yml.
// Anyone who has seen the repository knows it, so it must never sign tokens.
const placeholderJWTSecret = "generate_a_secure_random_string_for_production"

// validateJWTSecret refuses secrets that would let anyone forge a login.
func validateJWTSecret(secret, appMode string) error {
	switch {
	case secret == "":
		return fmt.Errorf("JWT_SECRET not set in .env")
	case secret == placeholderJWTSecret:
		return fmt.Errorf("JWT_SECRET is the public placeholder from docker-compose.yml; set a random secret (openssl rand -hex 32)")
	case appMode == "prod" && len(secret) < 32:
		return fmt.Errorf("JWT_SECRET must be at least 32 characters in production (openssl rand -hex 32)")
	}
	return nil
}

// durationEnv reads a duration such as "1h" or "720h", or returns def.
func durationEnv(name string, def time.Duration) (time.Duration, error) {
	raw := os.Getenv(name)
	if raw == "" {
		return def, nil
	}
	d, err := time.ParseDuration(raw)
	if err != nil || d <= 0 {
		return 0, fmt.Errorf("invalid %s value %q: use a duration such as 1h or 720h", name, raw)
	}
	return d, nil
}

func LoadConfig() (*Config, error) {
	err := godotenv.Load(".env")
	if err != nil && !os.IsNotExist(err) {
		return nil, fmt.Errorf("error loading .env file: %w", err)
	}
	cfg := &Config{
		DBUser: os.Getenv("DB_USER"),
		DBPass: os.Getenv("DB_PASS"),
		DBHost: os.Getenv("DB_HOST"),
		// DBPort: os.Getenv("DB_PORT"),
		DBName:    os.Getenv("DB_NAME"),
		DBDriver:  os.Getenv("DB_DRIVER"),
		LOG_LEVEL: os.Getenv("LOG_LEVEL"),
		JWTSecret: os.Getenv("JWT_SECRET"),
		// AccessTokenTTL:    os.Getenv("ACCESS_TOKEN_TTL"),
		AppName:           os.Getenv("APP_NAME"),
		AppVersion:        os.Getenv("APP_VERSION"),
		AppMode:           os.Getenv("APP_MODE"),
		AppTimezone:       os.Getenv("APP_TIMEZONE"),
		AppReleasesDir:    os.Getenv("APP_RELEASES_DIR"),
		AutoMigrate:       os.Getenv("AUTO_MIGRATE") == "true",
		DBMaxIdleConns:    10,
		DBMaxOpenConns:    100,
		DBConnMaxLifetime: 60, // default value in seconds
		// SMS configuration
		SMSProvider:      os.Getenv("SMS_PROVIDER"),
		HttpSMSAPIKey:    os.Getenv("HTTPSMS_API_KEY"),
		HttpSMSFromPhone: os.Getenv("HTTPSMS_FROM_PHONE"),
		ATUsername:       os.Getenv("AT_USERNAME"),
		ATAPIKey:         os.Getenv("AT_API_KEY"),
		ATSenderID:       os.Getenv("AT_SENDER_ID"),
		ATIsSandbox:      os.Getenv("AT_IS_SANDBOX") == "true",
	}
	if err := validateJWTSecret(cfg.JWTSecret, cfg.AppMode); err != nil {
		return nil, err
	}
	// Access tokens are short-lived; the app refreshes them silently.
	if cfg.AccessTokenTTL, err = durationEnv("ACCESS_TOKEN_TTL", time.Hour); err != nil {
		return nil, err
	}
	if cfg.SessionIdleTimeout, err = durationEnv("SESSION_IDLE_TIMEOUT", 30*24*time.Hour); err != nil {
		return nil, err
	}

	if cfg.AppReleasesDir == "" {
		cfg.AppReleasesDir = "releases"
	}
	if cfg.AppTimezone == "" {
		cfg.AppTimezone = "Africa/Nairobi"
	}
	if loc, err := time.LoadLocation(cfg.AppTimezone); err == nil {
		time.Local = loc
	}

	if cfg.DBDriver == "" {
		return nil, fmt.Errorf("DB_DRIVER not set in .env")
	}
	dbPortStr := os.Getenv("DB_PORT")
	if dbPortStr == "" && cfg.DBDriver != "sqlite" {
		return nil, fmt.Errorf("DB_PORT not set in .env for non-sqlite driver")
	}
	if cfg.DBDriver != "sqlite" {
		dbPort, err := strconv.Atoi(dbPortStr)
		if err != nil {
			return nil, fmt.Errorf("invalid DB_PORT value in .env: %w", err)
		}
		cfg.DBPort = strconv.Itoa(dbPort)
	}
	// app mode

	//server port
	serverPortStr := os.Getenv("SERVER_PORT")
	if serverPortStr == "" {
		serverPortStr = "8080" // default port
	}
	serverPort, err := strconv.Atoi(serverPortStr)
	if err != nil {
		return nil, fmt.Errorf("invalid SERVER_PORT value %s: %w", serverPortStr, err)
	}
	cfg.ServerPort = serverPort
	//mail port
	mailerPortStr := os.Getenv("MAIL_PORT")
	if mailerPortStr != "" {
		mailPort, err := strconv.Atoi(mailerPortStr)
		if err != nil {
			return nil, fmt.Errorf("invalid MAIL_PORT value %s: %w", mailerPortStr, err)
		}
		cfg.MailerPort = mailPort
	}

	//basic validation
	if cfg.DBDriver != "sqlite" && (cfg.DBUser == "" || cfg.DBPass == "" || cfg.DBHost == "" || cfg.DBName == "") {
		return nil, fmt.Errorf("missing required database configuration")
	}
	//sqlite
	if cfg.DBDriver == "sqlite" && cfg.DBName == "" {
		return nil, fmt.Errorf("DB_NAME not set for sqlite driver (should be file path)")
	}
	if val := os.Getenv("DB_MAX_IDLE_CONNS"); val != "" {
		if i, err := strconv.Atoi(val); err == nil {
			cfg.DBMaxIdleConns = i
		}
	}
	if val := os.Getenv("DB_MAX_OPEN_CONNS"); val != "" {
		if i, err := strconv.Atoi(val); err == nil {
			cfg.DBMaxOpenConns = i
		}
	}
	if val := os.Getenv("DB_CONN_MAX_LIFETIME"); val != "" {
		if i, err := strconv.Atoi(val); err == nil {
			cfg.DBConnMaxLifetime = i
		}
	}

	corsOriginStr := os.Getenv("ALLOWED_ORIGINS")
	if corsOriginStr != "" {
		cfg.CORSOrigins = strings.Split(corsOriginStr, ",")
	} else {
		cfg.CORSOrigins = []string{}
	}
	//dsn based on DB driver
	switch cfg.DBDriver {
	case "mysql":
		cfg.DbURL = fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
			cfg.DBUser,
			cfg.DBPass,
			cfg.DBHost,
			cfg.DBPort,
			cfg.DBName,
		)
	case "postgres", "pgsql":
		cfg.DbURL = fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=%s",
			cfg.DBHost,
			cfg.DBUser,
			cfg.DBPass,
			cfg.DBName,
			cfg.DBPort,
			cfg.AppTimezone,
		)
	case "sqlite":
		cfg.DbURL = cfg.DBName

	default:
		return nil, fmt.Errorf("unsupported DB_DRIVER: %s", cfg.DBDriver)
	}
	return cfg, nil

}
