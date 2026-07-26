package app

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/danielgtaylor/huma/v2"
	"github.com/danielgtaylor/huma/v2/adapters/humachi"
	"github.com/go-chi/chi/v5"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/internal/auth"
	"github.com/codetheuri/tusk/internal/collection"
	"github.com/codetheuri/tusk/internal/dashboard"
	"github.com/codetheuri/tusk/internal/member"
	"github.com/codetheuri/tusk/internal/middleware"
	"github.com/codetheuri/tusk/internal/notification"
	"github.com/codetheuri/tusk/internal/report"
	"github.com/codetheuri/tusk/internal/sacco"

	appDatabase "github.com/codetheuri/tusk/internal/platform/database"

	"github.com/codetheuri/tusk/pkg/logger"
	"github.com/codetheuri/tusk/pkg/response"
)

type App struct {
	cfg    *config.Config
	router *chi.Mux
	log    logger.Logger
}

func New(cfg *config.Config, log logger.Logger) (*App, error) {
	db, err := appDatabase.NewGoRMDB(cfg, log)
	if err != nil {
		return nil, fmt.Errorf("database connection failed: %w", err)
	}

	r := chi.NewRouter()

	// Middlewares
	r.Use(middleware.RequestID())
	r.Use(middleware.Logger(log))
	r.Use(middleware.Recovery(log))
	r.Use(middleware.CORS(cfg.CORSOrigins, log))
	r.Use(middleware.SecurityHeaders)

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(fmt.Sprintf(`{"status":"ok","app_name":"%s","version":"%s","time":"%s"}`, cfg.AppName, cfg.AppVersion, time.Now().Format(time.RFC3339))))
	})

	r.Get("/ready", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		sqlDB, err := db.DB()
		if err != nil || sqlDB.PingContext(r.Context()) != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			w.Write([]byte(`{"status":"unavailable","database":"disconnected"}`))
			return
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ready","database":"connected"}`))
	})

	// Initialize Huma custom formatting
	response.SetupHuma()

	humaConfig := huma.DefaultConfig("Dairy Cooperative Platform API", "1.0.0")
	humaConfig.Info.Description = "## Official Dairy Cooperative (Sacco) Platform API\n\nDeveloper documentation for Sacco Management, Multi-Tenancy, Member Management, Milk Collections, Sales, Spoilage, and Reconciliation."

	humaConfig.Tags = []*huma.Tag{
		{Name: "Authentication", Description: "User registration, login, token refresh, logout, and self profile operations"},
		{Name: "Users", Description: "User account management and listing"},
		{Name: "Roles", Description: "Security role management (CRUD)"},
		{Name: "Role Permissions", Description: "Attaching and detaching permission strings to/from roles"},
		{Name: "User Roles", Description: "Assigning and revoking security roles to/from users"},
		{Name: "Permissions", Description: "System permission catalog listing"},
		{Name: "Sacco Management (Admin)", Description: "Platform Super User operations for provisioning and managing Dairy Saccos"},
		{Name: "Sacco Tenant Profile", Description: "Tenant Sacco profile and operational settings"},
		{Name: "Member Management", Description: "Farmer registration, profile management, and payout details"},
		{Name: "Milk Pricing", Description: "Sacco buying price rate configuration"},
		{Name: "Milk Collections", Description: "Farmer milk intake recording and status verification"},
		{Name: "Milk Sales", Description: "Direct field sales to hotels, processors, or local buyers"},
		{Name: "Milk Spoilage", Description: "Milk loss, acidity testing failure, and transport damage logging"},
		{Name: "Collector Reconciliation", Description: "Collector daily intake, sales, spoilage, and net delivery overview"},
		{Name: "Reports & Reconciliation", Description: "Farmer payroll statements, Sacco balancing ledgers, and collector audit reports"},
		{Name: "Executive & Mobile Dashboards", Description: "Sacco summary cards, trend time series charts, and collector field shift metrics"},
		{Name: "SMS Notifications", Description: "Pluggable SMS dispatching (httpSMS Android SIM Gateway, Africa's Talking) and audit logs"},
	}

	humaConfig.Info.Contact = &huma.Contact{
		Name:  "API Support",
		Email: "theurij113@gmail.com",
	}

	// Add Bearer JWT Security Scheme to OpenAPI docs
	humaConfig.Components = &huma.Components{
		SecuritySchemes: map[string]*huma.SecurityScheme{
			"bearerAuth": {
				Type:         "http",
				Scheme:       "bearer",
				BearerFormat: "JWT",
				Description:  "Enter token as: Bearer <your_jwt_token>",
			},
		},
	}

	// Disable $schema from showing up in OpenAPI docs/responses
	humaConfig.CreateHooks = []func(huma.Config) huma.Config{
		func(c huma.Config) huma.Config {
			c.SchemasPath = ""
			return c
		},
	}
	api := humachi.New(r, humaConfig)

	// Configure OpenAPI x-tagGroups extension for Scalar / Redoc UI sidebar grouping
	openAPI := api.OpenAPI()
	if openAPI.Extensions == nil {
		openAPI.Extensions = map[string]any{}
	}
	openAPI.Extensions["x-tagGroups"] = []map[string]any{
		{
			"name": "IAM",
			"tags": []string{
				"Authentication",
				"Users",
				"Roles",
				"Role Permissions",
				"User Roles",
				"Permissions",
			},
		},
		{
			"name": "Sacco Platform",
			"tags": []string{
				"Sacco Management (Admin)",
				"Sacco Tenant Profile",
				"Member Management",
			},
		},
		{
			"name": "Milk Operations & Ledger",
			"tags": []string{
				"Milk Pricing",
				"Milk Collections",
				"Milk Sales",
				"Milk Spoilage",
				"Collector Reconciliation",
				"Reports & Reconciliation",
			},
		},
		{
			"name": "Dashboards & Analytics",
			"tags": []string{
				"Executive & Mobile Dashboards",
			},
		},
		{
			"name": "Communications",
			"tags": []string{
				"SMS Notifications",
			},
		},
	}

	// Global Huma JWT Authentication Middleware
	api.UseMiddleware(middleware.HumaAuthenticate(api, cfg.JWTSecret, db))

	// Register Domain Module Routes
	auth.RegisterRoutes(api, db, cfg, log)
	sacco.RegisterRoutes(api, db, cfg, log)
	member.RegisterRoutes(api, db, cfg, log)
	collection.RegisterRoutes(api, db, cfg, log)
	report.RegisterRoutes(api, db, cfg, log)
	dashboard.RegisterRoutes(api, db, cfg, log)
	notification.RegisterRoutes(api, db, cfg, log)

	return &App{
		cfg:    cfg,
		router: r,
		log:    log,
	}, nil
}

func (a *App) Run() error {
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", a.cfg.ServerPort),
		Handler:      a.router,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	ln, err := net.Listen("tcp", srv.Addr)
	if err != nil {
		return fmt.Errorf("failed to start listener: %w", err)
	}

	actualAddr := ln.Addr().(*net.TCPAddr)
	a.log.Info(fmt.Sprintf("Server is listening on port %d. Docs at http://localhost:%d/docs", actualAddr.Port, actualAddr.Port))

	go func() {
		if err := srv.Serve(ln); err != nil && err != http.ErrServerClosed {
			a.log.Fatal("Server failed to listen or serve", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	sig := <-quit
	a.log.Warn("Received shutdown signal", "signal", sig.String())

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	a.log.Info("Attempting to shut down gracefully...")
	if err := srv.Shutdown(ctx); err != nil {
		return fmt.Errorf("server shutdown failed: %w", err)
	}

	a.log.Info("Server shut down gracefully.")
	return nil
}
