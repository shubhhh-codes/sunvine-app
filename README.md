# Sunvine EPC Monorepo

> **Sunvine EPC Gujarat Dealer Network** — Monorepo containing the Flutter Android Dealer Mobile Application and the Cloudflare Workers Serverless Gateway.

---

## 📁 Monorepo Folder Structure

```
sunvine-apk/
├── app/                              # Flutter Android Mobile Application
│   ├── env/                          # Environment configuration files
│   │   ├── dev.json                  # Local development config (127.0.0.1:8787)
│   │   ├── staging.json              # Staging gateway config
│   │   └── prod.json                 # Production gateway config
│   ├── lib/
│   │   ├── core/                     # Cross-cutting foundational modules
│   │   │   ├── config/               # AppConfig and environment profile parsers
│   │   │   ├── constants/            # ApiEndpoints, StorageKeys
│   │   │   ├── errors/               # AppException & Failure hierarchies
│   │   │   ├── network/              # Dio ApiClient, interceptors, Result monad, TokenStorage
│   │   │   ├── services/             # DeviceInfoService, system services
│   │   │   ├── state/                # Lightweight ServiceLocator dependency injection
│   │   │   ├── theme/                # AppColors, AppTypography, AppTheme
│   │   │   └── widgets/              # Reusable design system UI components
│   │   ├── features/                 # Modular domain features (Clean Architecture)
│   │   │   ├── auth/                 # Authentication, biometrics gate & token rotation
│   │   │   │   ├── data/             # AuthRepository implementation
│   │   │   │   ├── domain/           # Models, IAuthRepository contract, AuthService
│   │   │   │   └── presentation/     # AuthController, LoginScreen, BiometricGateScreen
│   │   │   ├── dashboard/            # Business overview, KPIs, recent quotes feed
│   │   │   │   ├── data/             # DashboardRepository
│   │   │   │   ├── domain/           # DashboardModels
│   │   │   │   └── presentation/     # DashboardController, DashboardScreen, subwidgets
│   │   │   ├── quotations/           # Solar proposal generator and search
│   │   │   │   ├── data/             # QuotationsRepository
│   │   │   │   ├── domain/           # QuotationModel
│   │   │   │   └── presentation/     # QuotationsController, QuotationsScreen
│   │   │   ├── applications/         # Active installation tracking pipeline
│   │   │   │   ├── data/             # ApplicationsRepository
│   │   │   │   ├── domain/           # CustomerFileModel
│   │   │   │   └── presentation/     # ApplicationsController, ApplicationsScreen
│   │   │   ├── ledger/               # Dealer commissions, payouts and ledger
│   │   │   │   ├── data/             # LedgerRepository
│   │   │   │   ├── domain/           # LedgerEntryModel, LedgerSummaryModel
│   │   │   │   └── presentation/     # LedgerController, LedgerScreen
│   │   │   └── settings/             # Environment info & gateway diagnostics
│   │   │       ├── data/             # SystemRepository
│   │   │       └── presentation/     # DiagnosticsController, DiagnosticsScreen
│   │   └── main.dart                 # App bootstrap, DI wiring, reactive root widget
│   └── test/                         # Flutter unit and widget tests
│
├── gateway/                          # Cloudflare Workers Serverless Backend
│   ├── src/
│   │   ├── config/                   # Environment validation guards and TTL constants
│   │   ├── middleware/               # CORS preflight, dealer JWT authentication guard
│   │   ├── routes/                   # Modular Hono route sub-apps
│   │   │   ├── auth.routes.ts        # Login, single-flight refresh rotation, logout
│   │   │   ├── health.routes.ts      # Zero-leak health telemetry and app versioning
│   │   │   └── dealer.routes.ts      # Profile, catalog bootstrap, quotes, files, ledger
│   │   ├── utils/                    # Crypto (HS256, SHA256), D1 rate limiting, Supabase
│   │   ├── types.ts                  # Shared TypeScript interfaces and error codes
│   │   └── index.ts                  # Application entry point mounting route modules
│   ├── migrations/                   # Cloudflare D1 SQL schema migrations
│   └── test/                         # Vitest automated test suite
│
├── docs/                             # Engineering specifications & flow maps
│   ├── ARCHITECTURE.md               # Clean architecture blueprint & API contracts
│   └── FLOW_MAP.md                   # Visual data and authentication flows
└── scripts/                          # Developer automation scripts
    ├── dev.js                        # Hot-reload development orchestrator
    ├── dev-phone.ps1                 # Samsung phone ADB test runner
    ├── check-no-secrets.ps1          # Pre-commit secret scanning guard
    └── e2e-login.ps1                 # End-to-end dealer smoke test
```

---

## 🏛️ Clean Architecture & Separation of Concerns

Each feature adheres strictly to the **Data -> Domain -> Presentation** layers:

1. **Domain Layer**:
   - Entities (`QuotationModel`, `CustomerFileModel`, `LedgerEntryModel`, `DealerUser`).
   - Abstract repository contracts (`IAuthRepository`, `IQuotationsRepository`, etc.).
   - Pure business rules with zero Flutter/UI dependencies.

2. **Data Layer**:
   - Repository implementations calling the gateway via `ApiClient`.
   - Data transfer object parsing with resilient fallbacks.
   - Secure token storage with encrypted Android shared preferences.

3. **Presentation Layer**:
   - **Controllers**: Extend `ChangeNotifier` to hold reactive state (`isLoading`, `errorMessage`, `data`).
   - **Screens & Widgets**: Pure view layer. Observes controllers via `ListenableBuilder`, dispatches user actions, and displays user-friendly error views or loading indicators.

---

## ⚡ State Management

- **Zero Third-Party Dependency Lock-In**: Utilizes Flutter's built-in `ChangeNotifier` paired with `ListenableBuilder` for fine-grained reactive rebuilds.
- **Service Locator Pattern**: `ServiceLocator` provides type-safe dependency injection, decoupling services from presentation widgets and making tests trivial to mock.

---

## 🛡️ Robust Error Handling & API Result Monad

All repository methods return a functional `Result<T>` type:
- `Result.success(data)` holds valid domain entities.
- `Result.failure(failure)` holds strongly-typed `Failure` objects (`NetworkFailure`, `AuthFailure`, `ForbiddenFailure`, `RateLimitFailure`, `ServerFailure`).
- `ErrorInterceptor` translates low-level `DioException` instances into user-safe `AppException` exceptions.
- UI renders `SunErrorView` with retry triggers when failures occur.

---

## 🌐 Scalable API Structure & Interceptors

The HTTP layer is powered by `ApiClient` wrapped around `Dio`:
- **AuthInterceptor**: Injects `Authorization: Bearer <token>` automatically, skipping public auth routes.
- **RefreshInterceptor**: Thread-safe single-flight mutex (`Completer<String?>`) guaranteeing only **one** refresh network request runs at any time, immediately queuing and retrying concurrent failing requests.
- **ErrorInterceptor**: Intercepts HTTP 400/401/403/429/500 and translates them to uniform application exceptions.

---

## ⚙️ Environment Configuration

Environment settings are isolated from source code into JSON definition files:
- **`app/env/dev.json`**: Points to local Cloudflare Worker (`http://127.0.0.1:8787`).
- **`app/env/staging.json`**: Points to staging environment.
- **`app/env/prod.json`**: Points to production gateway (`https://gateway.sunvine.in`).

Run Flutter with your desired environment:
```bash
flutter run --dart-define-from-file=env/dev.json
```

---

## 🚀 Quick Start & Commands

```bash
# Start dev watcher with auto hot-reload
npm run dev

# Run Flutter analyzer
npm run app:analyze

# Run Flutter tests
npm run app:test

# Run Gateway tests (Vitest)
npm run gateway:test

# Run all test suites
npm test

# Verify no secrets are committed
npm run check:secrets
```
