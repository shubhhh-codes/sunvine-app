# Phase 0 Step B — Execution Report: Cloudflare Gateway & Native Flutter App Skeleton

**Status:** Completed & Verified  
**Date:** October 16, 2026  
**Target Roles:** Authorized Solar EPC Dealer (Gujarat Network)  
**Target Device:** Samsung Galaxy S24 (`Samsung SM-S921E`, device ID `RZGYA0LA25E`)  
**Quality Gates:**
- `gateway`: `npm test` passed 13/13 tests (100% green).
- `app`: `dart analyze .` / `flutter analyze` passed with 0 issues.

---

## 1. Summary of Proposed Vercel Additive Changes (DIFF ONLY)

The diff has been saved to [`docs/PROPOSED_VERCEL_CHANGES.diff`](file:///e:/sunvine-apk/docs/PROPOSED_VERCEL_CHANGES.diff). Per project rules, the `reference/` backend was left strictly unmodified.

### Key Additive Endpoints & Enhancements:
1. **`POST /api/auth/gateway-session` (`api/_lib/authGatewaySession.js` & `api/auth/[action].js`):**
   - Protected strictly via HMAC-SHA256 signature verification over `x-gateway-timestamp` with a maximum 60s clock skew (`GATEWAY_HMAC_SECRET`).
   - Revalidates dealer session against PostgreSQL `dealer_accounts`.
   - Enforces `max_margin_cap_per_kw` existence (no hardcoded fallbacks per rule HC-03).
   - Returns fresh dealer profile mirroring `authLogin.js` lines 250–268 and account status (`active`, `suspended`, `inactive`, `not_found`).
   - Includes full vitest parity test specification: [`test/parity/gateway-session-parity.test.js`](file:///e:/sunvine-apk/docs/PROPOSED_VERCEL_CHANGES.diff).

2. **Signed Client IP Forwarding (`api/_lib/rateLimiter.js`):**
   - Updates `getClientIp(req)` to inspect `x-sunvine-client-ip`.
   - Honors this header only when verified against `x-sunvine-ip-timestamp` and `x-sunvine-ip-signature` using `GATEWAY_HMAC_SECRET` (timing-safe HMAC comparison with $\le 60\text{s}$ clock skew).
   - Seamlessly falls back to `x-forwarded-for`, `x-real-ip`, or socket IP if unsigned or invalid.

3. **Master Document Registry (`api/catalog.js?type=document_master`):**
   - Authenticated read-only endpoint (`requireUser`, any role).
   - Reads catalog document rules directly from PostgreSQL `document_master` with Supabase fallback, cached via Redis (`catalog:documents`, 12-hour TTL).
   - Eliminates client-side direct Supabase SDK access.

---

## 2. Cloudflare Gateway Architecture (`gateway/`)

The production-ready Cloudflare Worker gateway is built in TypeScript with Hono and WebCrypto.

### 2.1 D1 Schema & Migrations (`gateway/migrations/`)

#### 1. `0001_create_refresh_tokens.sql`:
```sql
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id TEXT PRIMARY KEY,
  family_id TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  dealer_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  device_name TEXT,
  issued_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  rotated_at INTEGER,
  revoked_at INTEGER,
  user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash ON refresh_tokens (token_hash);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_family_id ON refresh_tokens (family_id);
```

#### 2. `0002_create_app_releases.sql`:
```sql
CREATE TABLE IF NOT EXISTS app_releases (
  id TEXT PRIMARY KEY,
  platform TEXT NOT NULL,
  latest_version TEXT NOT NULL,
  min_supported_version TEXT NOT NULL,
  apk_url TEXT NOT NULL,
  release_notes TEXT,
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_app_releases_platform_created ON app_releases (platform, created_at DESC);
```

### 2.2 D1 Setup & Deployment Commands
```bash
# 1. Login to Cloudflare Wrangler
cd gateway
npx wrangler login

# 2. Create D1 database
npx wrangler d1 create sunvine-gateway-d1

# 3. Apply local migrations (for local development & testing)
npx wrangler d1 migrations apply sunvine-gateway-d1 --local

# 4. Apply remote migrations (for production)
npx wrangler d1 migrations apply sunvine-gateway-d1 --remote

# 5. Deploy Worker Gateway
npm run deploy
```

### 2.3 Wired Endpoints & Test Verification
All endpoints are covered by automated unit & integration tests (`npm test` $\rightarrow$ 13/13 passing):
- `POST /v1/auth/login`: Strictly enforces `role: 'dealer'`, proxies to origin with signed IP headers, validates token locally, re-mints short-lived (1 hr) JWT with identical dealer claims, generates rotating D1 refresh token, returns session payload. Throws fatal error if JWT > 4096 bytes.
- `POST /v1/auth/refresh`: Hashes token using SHA-256; detects reuse of rotated/revoked tokens and revokes the entire `family_id`; checks origin account status via `gateway-session`; revokes family on suspension/deletion; issues rotated refresh token + fresh 1-hour access JWT.
- `POST /v1/auth/logout`: Revokes token family in D1 and proxies Bearer token to origin `/api/auth/logout` so origin blacklists `jti` in Redis.
- `ALL /v1/api/*`: Strict allowlisted reverse proxy for `catalog`, `quotations`, `customer-files`, `ledger`, `storage-presign`, `storage-download`, `storage-delete`. Blocks admin and unallowlisted routes with 403 Forbidden. Strips cookies, enforces 15s timeout, and enforces 1MB body limit (413).
- `GET /v1/app/version?platform=android`: Queries D1 `app_releases` for APK distribution metadata.
- `GET /v1/health`: Returns service health status and timestamp.

---

## 3. Native Flutter App Skeleton (`app/`)

### 3.1 Project Specification
- **Framework:** Flutter 3.47.7 (Dart 3.13.5).
- **Package ID:** `com.sunvine.epc`.
- **Application Name:** "Sunvine EPC".
- **Android `minSdkVersion`:** 26 (Android 8.0 Oreo and above).
- **Android Activity:** `FlutterFragmentActivity` in `MainActivity.kt` for hardware biometric unlock.
- **Flavor Configuration:** Configurable via `--dart-define=GATEWAY_BASE_URL=...` (defaults to `https://gateway.sunvine.in`).

### 3.2 Design System & Component Kit (`lib/core/theme/`)
- **Palette:** Canvas `#070D18`, Surface `#0D1527`, Energy Gradient (`#059669` $\rightarrow$ `#14B8A6`), Border `#1E293B`.
- **Typography:** Headlines (`Space Grotesk`), Body & UI (`Inter`), Numbers/kW/Currency (`Roboto Mono`).
- **Components:** `SunButton` (primary/secondary/danger, touch target $\ge 48\text{dp}$), `SunInput` (touch target $\ge 48\text{dp}$, focus highlight), `SunCard`, `SunBadge` (emerald, amber, rose, cyan, slate), `SunShimmer`.

### 3.3 Session Architecture & Biometric Lifecycle
- **Encrypted Storage:** `TokenStorage` backed by Android `EncryptedSharedPreferences` via `flutter_secure_storage`.
- **Single-Flight Refresh:** `RefreshInterceptor` locks concurrent requests, rotates session via `/v1/auth/refresh`, retries original request with new access token, and auto-clears storage if revoked.
- **Biometric Unlock (`local_auth`):**
  - **Cold Start:** If refresh token exists, prompts biometric unlock before displaying console.
  - **5-Minute Background Gate:** Tracks pause/resume timestamps via `WidgetsBindingObserver`. If app backgrounded $> 5$ minutes, prompts biometric re-authentication before restoring access.
- **In-App Update Check Stub:** Background check querying `GET /v1/app/version?platform=android` on launch, presenting non-blocking modal bottom sheet if update is available.

---

## 4. Step-by-Step Instructions to Run on Connected Android Device (`Samsung SM-S921E`)

Your device is already connected and recognized:
```
Found 4 connected devices:
  SM S921E (mobile) • RZGYA0LA25E • android-arm64 • Android 17 (API 37)
```

### Steps to Run:

1. **Open PowerShell in `e:\sunvine-apk\app`:**
   ```powershell
   cd e:\sunvine-apk\app
   ```

2. **Verify Device Connection:**
   ```powershell
   flutter devices
   ```
   You should see `SM S921E (mobile) • RZGYA0LA25E`.

3. **Run the App in Debug Mode:**
   ```powershell
   flutter run -d RZGYA0LA25E
   ```
   *To run pointing to a custom staging or local gateway:*
   ```powershell
   flutter run -d RZGYA0LA25E --dart-define=GATEWAY_BASE_URL=http://<YOUR_LAN_IP>:8787
   ```

4. **Verify Tests and Static Analysis:**
   ```powershell
   # Gateway tests (Vitest)
   cd e:\sunvine-apk\gateway
   npm test

   # Flutter static analysis
   cd e:\sunvine-apk\app
   dart analyze .
   ```
