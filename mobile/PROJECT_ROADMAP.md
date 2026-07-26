# Dairy Sacco Mobile Application Roadmap (Flutter)

## Phase 1 — Mobile Foundation & Design System
- [x] Flutter project initialization & dependency configuration (`pubspec.yaml`)
- [x] Feature-First & Clean Architecture directory structure (`core/`, `app/`, `features/`)
- [x] Material 3 Design System (Colors, Typography, Themes)
- [x] Reusable Core UI Components (`PrimaryButton`, `AppTextField`, `StatCard`, `StatusPill`, `LoadingOverlay`, `EmptyStateWidget`, `ErrorView`)
- [x] Dio Network Client setup (JWT Auth Interceptor, Error Handling, Debug Logging)
- [x] Secure Storage Service for Auth Tokens (`flutter_secure_storage`)
- [x] GoRouter Configuration with Auth Guard & Path constants

## Phase 2 — Authentication & Session Management
- [x] Freezed Auth Models & DTOs (`LoginRequest`, `LoginResponse`, `UserEntity`)
- [x] Auth Data Source & Auth Repository Implementation
- [x] Riverpod Auth State Controller (`AsyncNotifier`)
- [x] Modern Mobile Login Screen (Email/Phone + Password with validation & error toasts)
- [x] Session Persistence & Auto-login on App Launch
- [x] Logout & Token Invalidation

## Phase 3 — Collector Shift & Executive Mobile Dashboards
- [x] Dashboard Models (`ExecutiveSummary`, `CollectorShiftData`)
- [x] Dashboard Repository & Riverpod Providers
- [x] Collector Mobile Field Shift Dashboard (Today's Intake, Sales, Spoilage, Net Coolant Station Delivery)
- [x] Executive Summary Dashboard (Real-time Sacco intake cards, 7-day collection trend chart)

## Phase 4 — Farmer Member Management & Fast Search
- [x] Member Models & DTOs (`MemberEntity`, `RegisterMemberRequest`)
- [x] Member Repository & Riverpod Search Provider
- [x] Farmer Directory Screen with Instant Search (`M-0001` or Name)
- [x] Farmer Registration Screen (Register new member with phone & national ID)
- [x] Detailed Farmer Profile Screen (Historical intake & payout summary)

## Phase 5 — Daily Milk Collection & Intake Module
- [x] Milk Collection Models (`MilkCollectionEntity`, `RecordCollectionRequest`)
- [x] Active Buying Price Provider (`GET /api/v1/sacco/milk-prices/active`)
- [x] Collector Milk Intake Screen (Farmer Selection, Litres Input, Shift Selector, Real-time Price Calculation)
- [x] Intake Duplicate Prevention Handling & User Feedback
- [x] Edit Collection Quantity Dialog (`PUT /api/v1/sacco/milk-collections/{id}`)
- [x] Daily Collection History Screen (Filterable by Date & Shift)

## Phase 6 — Direct Field Sales & Spoilage Module
- [x] Field Sales Models & Screen (Record sales to buyers/hotels, buyer name, litres, price)
- [x] Spoilage / Loss Logging Screen (Transit loss volume & reason)
- [x] Live Reconciliation Status Pill on Collector Dashboard

## Phase 7 — Reports & Audit Views
- [x] Farmer Payout Statements Screen
- [x] Sacco Mathematical Balancing Ledger Screen
- [x] Collector Audit Summary Screen

## Phase 8 — Polishing, Performance & UX Excellence
- [x] Smooth transitions, micro-animations, and haptic feedback
- [x] Pull-to-refresh on all list views
- [x] Global Error Snackbar & Network Error Toast handling
