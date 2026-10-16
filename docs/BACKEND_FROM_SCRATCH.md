# Backend from Scratch: Standalone Worker Architecture & Specification

## Overview
This specification details the architecture for the standalone Sunvine EPC mobile backend running as a Cloudflare Worker (`gateway/` or `backend/`). The Worker communicates directly with Supabase via PostgREST/service-role API without traversing Vercel or the legacy web app.

---

## 1. Reference Analysis (Web Implementation)

All line references point to `reference/` (tracking branch `devlopment` of `E:\repos\dealer-portal-quotation`).

### 1.1 `dealer_accounts` & Login Flow
- **Columns selected during login**:
  `id, dealer_code, firm_name, contact_person, mobile_number, email, password_hash, status, city, state, discom, tier, max_margin_cap_per_kw, assigned_staff_id, assigned_staff_name, pricing_config`
  - Reference: [`reference/api/_lib/authLogin.js:201`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L201), [`reference/api/_lib/authLogin.js:210-211`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L210-L211)
- **Mobile Number Matching**:
  - Normalized: stripped of non-digits and sliced to the last 10 digits:
    `const cleanMobile = cleanIdentifier.replace(/\D/g, '').slice(-10);` ([`reference/api/_lib/authLogin.js:193`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L193))
  - Validated: `if (cleanMobile.length !== 10) return 401;` ([`reference/api/_lib/authLogin.js:194-197`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L194-L197))
  - Database Query: `WHERE mobile_number = $1` / `.eq('mobile_number', cleanMobile)` ([`reference/api/_lib/authLogin.js:201`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L201), [`reference/api/_lib/authLogin.js:211`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L211)).
  - *Parity Note*: In the web codebase, while staff/admin lookups check both `cleanMobile` and `+91${cleanMobile}` or `RIGHT(mobile_number, 10)`, the dealer query relies strictly on `.eq('mobile_number', cleanMobile)`. In Supabase, dealer mobile numbers are stored as exact 10 digits.
- **Status Values That Block Login**:
  - `status === 'suspended' || status === 'inactive'` returns HTTP 403:
    `{ error: 'Account suspended. Contact Sunvine support.' }` ([`reference/api/_lib/authLogin.js:237-239`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L237-L239))
  - `requireUser` also checks that status is `'active'`; anything else (`'pending'`, `'inactive'`, `'suspended'`) returns 403 Forbidden ([`reference/api/_lib/requireAuth.js:227-242`](file:///E:/sunvine-apk/reference/api/_lib/requireAuth.js#L227-L242)).
- **Password Hash Algorithms & Cost**:
  - Standard bcrypt (`$2a$`, `$2b$`, `$2y$`, `$2x$`) with cost factor 10 ([`reference/api/_lib/authLogin.js:15-21`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L15-L21), [`reference/api/_lib/security.js:28-33`](file:///E:/sunvine-apk/reference/api/_lib/security.js#L28-L33)).
  - PBKDF2 format (`pbkdf2$iterations$salt$hash` using SHA-512, 100,000 iterations, 64-byte key) ([`reference/api/_lib/authLogin.js:24-40`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L24-L40), [`reference/api/_lib/security.js:13-20`](file:///E:/sunvine-apk/reference/api/_lib/security.js#L13-L20)).
- **Failed-Attempt & Lockout Columns and Rules**:
  - **Database schema**: The `dealer_accounts` table in PostgreSQL has **NO** columns for failed attempts, lockout timestamps, or `last_login` ([`reference/supabase/schema_current.sql:24-45`](file:///E:/sunvine-apk/reference/supabase/schema_current.sql#L24-L45)).
  - **Web Rate Limiting**: Managed entirely through Upstash Redis (or in-memory fallback):
    * IP-level: 10 attempts per 5-minute window (`ratelimit:${clientIp}`) ([`reference/api/_lib/authLogin.js:75`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L75)).
    * Account-level: 5 failures per 15-minute window (`ratelimit:acct:${cleanIdentifier}`) ([`reference/api/_lib/authLogin.js:102-109`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L102-L109)).
    * Block response: HTTP 429 `{ error: 'Too many failed login attempts for this account. Try again in ${resetSeconds} seconds.', retryAfter: resetSeconds }`.
    * On successful login, rate limits are explicitly cleared ([`reference/api/_lib/authLogin.js:373-374`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L373-L374)).
  - *Worker Implementation*: Cloudflare D1 will track failed attempts and lockout per IP and per identifier (e.g. 5 attempts / 15 min window), without altering `dealer_accounts`.
- **What is Updated on Success**:
  - The web application updates **nothing** in PostgreSQL upon successful login. `last_login` is only defined on `admin_accounts`, not `dealer_accounts`.
- **What Happens When `max_margin_cap_per_kw` is Missing**:
  - In `authLogin.js`: if `max_margin_cap_per_kw` is `null`, `undefined`, or `NaN`, it immediately throws:
    `throw new Error('Dealer ... is missing max_margin_cap_per_kw configuration in database.');`
    which is caught and returns HTTP 500 `{ error: 'Internal authentication error. Please try again.' }` ([`reference/api/_lib/authLogin.js:242-248`](file:///E:/sunvine-apk/reference/api/_lib/authLogin.js#L242-L248)).

---

### 1.2 JWT Token Claims: Web vs. Mobile App

#### Web Claims (Bloated)
In `authLogin.js:251-268` and `jwt.js:40-46`, the web signs:
- `id` (dealer UUID)
- `dealer_id` (dealer UUID)
- `dealerCode` (e.g. `DL-801`)
- `role` (`'dealer'`)
- `mobile` (10-digit mobile)
- `firmName` (Firm business name)
- `contactPerson` (Owner name)
- `city`
- `state`
- `discom`
- `tier` (e.g. `Gold EPC`)
- `maxMarginCapPerKw` (numeric)
- `assignedStaffId`
- `assignedStaffName`
- `category`
- `pricingConfig` (JSON object)
- `jti` (UUID)
- `iss` (`'sunvine-solar-epc'`)
- `iat` (timestamp)
- `exp` (timestamp, 24 hours)

#### Mobile App Access Token (Compact)
Issued with HS256, 1-hour expiration (`expiresIn: 3600`):
```json
{
  "id": "uuid-v4",
  "dealer_id": "uuid-v4",
  "role": "dealer",
  "jti": "uuid-v4",
  "iss": "sunvine-epc-app",
  "iat": 1729000000,
  "exp": 1729003600
}
```
All dealer profile fields (`dealerCode`, `firmName`, `contactPerson`, `city`, `state`, `discom`, `tier`, `maxMarginCapPerKw`, `assignedStaffId`, `assignedStaffName`, `category`, `pricingConfig`) are delivered strictly in the HTTP response `user` payload, keeping JWT payload under 200 bytes.

---

### 1.3 Tables & Exact Read Queries

#### A. Catalog Bootstrap
- **Tables**: `system_settings`, `solar_modules`, `solar_inverters`, `pricing_presets`, `dealer_custom_pricing`, `inverter_benchmark_matrix`, `bos_pricing_matrix`, `solar_banks`.
- **Reference**: [`reference/api/catalog.js:31-193`](file:///E:/sunvine-apk/reference/api/catalog.js#L31-L193)
- **Queries**:
  1. `system_settings`: `.from('system_settings').select('id, governance_settings, statutory_taxes, company_profile, bank_details').eq('id', 'global_settings').maybeSingle()`
  2. `solar_modules`: `.from('solar_modules').select('id, brand, model, wattage, cell_tech, efficiency, rate_per_wp_inr, warranty, dimensions').order('created_at', { ascending: false })`
  3. `solar_inverters`: `.from('solar_inverters').select('id, brand, model, capacity_kw, phase, base_price_inr, warranty').order('created_at', { ascending: false })`
  4. `pricing_presets`: `.from('pricing_presets').select('id, base_rate_per_kw, subsidy_cap, min_margin_per_kw, enforce_min_margin').eq('id', 'global_default').maybeSingle()`
  5. `dealer_custom_pricing`: `.from('dealer_custom_pricing').select('id, tier, tier_id, max_margin_cap_per_kw, min_margin_per_kw, discount_on_bom_pct').order('tier', { ascending: true })`
  6. `inverter_benchmark_matrix`: `.from('inverter_benchmark_matrix').select('id, capacity_kw, phase, brand, benchmark_price_inr').order('capacity_kw', { ascending: true })`
  7. `bos_pricing_matrix`: `.from('bos_pricing_matrix').select('capacity_slab, panel_brand, bos_price_per_wp, gst_rate').order('capacity_slab', { ascending: true })`
  8. `solar_banks`: `.from('solar_banks').select('id, bank_name, interest_rate, max_tenure_years, processing_fee').order('bank_name', { ascending: true })`

#### B. Quotations List
- **Table**: `quotations`
- **Reference**: [`reference/api/quotations.js:1190-1226`](file:///E:/sunvine-apk/reference/api/quotations.js#L1190-L1226)
- **Scoping & Projection**:
  - Filter: `.eq('dealer_id', dealer_id)`
  - Explicit Column Selection (No `*`, No internal margins/costs):
    `id, dealer_id, dealer_code, dealer_name, customer_name, customer_phone, customer_city, customer_state, system_capacity_kw, panel_type, inverter_type, structure_type, total_amount, subsidy_amount, net_payable, annual_generation_kwh, status, share_token, request_id, share_expires_at, quote_payload, created_at, updated_at`
  - Sorting: `.order('created_at', { ascending: false })`
  - Pagination: `.range(offset, offset + limit - 1)` (clamped between 1 and 100).

#### C. Customer Files List
- **Table**: `customer_files`
- **Reference**: [`reference/api/customer-files.js:287-325`](file:///E:/sunvine-apk/reference/api/customer-files.js#L287-L325)
- **Scoping & Projection**:
  - Filter: `.eq('dealer_id', dealer_id).not('is_deleted', 'is', true)`
  - Explicit Column Selection:
    `id, customer_name, phone, address, city, discom, consumer_no, sanctioned_load_kw, solar_system_kw, roof_type, source_type, dealer_id, dealer_name, staff_id, staff_name, finance_type, loan_bank, loan_account_no, quotation_id, stage, status, documents, timeline, cancellation_reason, cancelled_at, cancelled_by, is_verified, verified_at, verified_by, is_deleted, created_at, updated_at`
  - Sorting: `.order('created_at', { ascending: false })`
  - Pagination: `.range(offset, offset + limit - 1)`

#### D. Financial Ledger
- **Table**: `dealer_ledger_entries`
- **Reference**: [`reference/api/ledger.js:42-97`](file:///E:/sunvine-apk/reference/api/ledger.js#L42-L97)
- **Scoping & Projection**:
  - Filter: `.eq('dealer_id', dealer_id)`
  - Explicit Column Selection:
    `id, voucher_no, dealer_id, dealer_code, dealer_name, customer_file_id, customer_name, entry_date, entry_type, category, amount, payment_mode, reference_no, narration, proof_url, created_by, created_at`
  - Sorting: `.order('entry_date', { ascending: true }).order('created_at', { ascending: true })`
  - Calculation: Compute cumulative running balance:
    * `DEBIT`: dealer owes Sunvine (`+amount`)
    * `CREDIT`: Sunvine owes dealer (`-amount`)
    * Returned in reverse chronological order (newest first) with `summary: { totalDebit, totalCredit, netBalance, totalEntries }`.

---

## 2. Proposed Worker API (`/v1`)

### Standard Error Response Shape
All errors conform to:
```json
{
  "success": false,
  "code": "INVALID_CREDENTIALS | ACCOUNT_SUSPENDED | RATE_LIMITED | REAUTH_REQUIRED | ORIGIN_ERROR | CONFIG_ERROR | ROLE_NOT_ALLOWED | VALIDATION_ERROR",
  "message": "Human-readable error description",
  "retryAfter": 60
}
```

---

### Endpoints

#### 1. `POST /v1/auth/login`
- **Description**: Authenticate dealer with 10-digit mobile and password.
- **Request**:
  ```json
  {
    "mobile": "9876543210",
    "password": "DealerPassword123"
  }
  ```
- **Processing**:
  1. Rate-limit check in D1: 5 attempts / 15 min window per identifier + IP.
  2. Normalize mobile: strip spaces, dashes, `+91`, `91`, verify length is 10.
  3. Fetch dealer from `dealer_accounts` where `mobile_number = normalizedMobile`.
  4. If dealer not found: increment failure count in D1, return 401 `INVALID_CREDENTIALS`.
  5. Check `status`: if `suspended` or `inactive`, return 403 `ACCOUNT_SUSPENDED`.
  6. Check `max_margin_cap_per_kw`: if missing/invalid, return 500 `CONFIG_ERROR`.
  7. Verify password (bcrypt/pgcrypto). If mismatch: increment failure count in D1, return 401 `INVALID_CREDENTIALS`.
  8. Reset rate limits in D1.
  9. Generate:
     - Access JWT (HS256, 1 hour).
     - Refresh Token: 256-bit cryptographically secure random string (30 days).
     - Store SHA-256 hash of refresh token in D1 (`refresh_tokens` table) with family ID, dealer ID, device label, expiry, revoked flag.
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "accessToken": "eyJ...",
    "refreshToken": "64_hex_chars_or_uuid",
    "expiresIn": 3600,
    "user": {
      "id": "c1f77d61-3eb2-43bb-a5a4-09f191f69201",
      "dealerCode": "DL-801",
      "role": "dealer",
      "mobile": "9876543210",
      "firmName": "Sunvine Saur Urja",
      "contactPerson": "Ramesh Patel",
      "city": "Rajkot",
      "state": "Gujarat",
      "discom": "PGVCL",
      "tier": "Gold EPC",
      "maxMarginCapPerKw": 6000,
      "assignedStaffId": "STF-DIRECT",
      "assignedStaffName": "Direct to Company (HQ Desk)",
      "category": "Margin Based",
      "pricingConfig": {}
    }
  }
  ```

#### 2. `POST /v1/auth/refresh`
- **Description**: Rotate refresh token and issue new 1-hour access token.
- **Request**:
  ```json
  {
    "refreshToken": "existing_refresh_token"
  }
  ```
- **Processing**:
  1. Hash token with SHA-256 and query D1 `refresh_tokens`.
  2. If not found or expired: return 401 `REAUTH_REQUIRED`.
  3. If token was already revoked / rotated: **Token Reuse Detected**. Immediately revoke all tokens in the family (`family_id`), return 401 `REAUTH_REQUIRED`.
  4. Re-query `dealer_accounts` from Supabase: ensure dealer still exists and `status == 'active'`. If suspended/deleted, return 403 `ACCOUNT_SUSPENDED`.
  5. Mark current token as revoked/used.
  6. Issue new refresh token in the same family and store its hash in D1.
  7. Issue new access JWT.
  8. Cap active families per dealer at 20 (evict oldest).
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "accessToken": "eyJ...",
    "refreshToken": "new_refresh_token",
    "expiresIn": 3600
  }
  ```

#### 3. `POST /v1/auth/logout`
- **Description**: Revoke current refresh token family.
- **Headers**: `Authorization: Bearer <accessToken>`
- **Request**:
  ```json
  {
    "refreshToken": "existing_refresh_token"
  }
  ```
- **Processing**: Revoke family in D1.
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Logged out successfully"
  }
  ```

#### 4. `GET /v1/me`
- **Headers**: `Authorization: Bearer <accessToken>`
- **Description**: Fetch live dealer profile details directly from Supabase.
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "user": {
      "id": "c1f77d61-3eb2-43bb-a5a4-09f191f69201",
      "dealerCode": "DL-801",
      "role": "dealer",
      "mobile": "9876543210",
      "firmName": "Sunvine Saur Urja",
      "contactPerson": "Ramesh Patel",
      "city": "Rajkot",
      "state": "Gujarat",
      "discom": "PGVCL",
      "tier": "Gold EPC",
      "maxMarginCapPerKw": 6000,
      "assignedStaffId": "STF-DIRECT",
      "assignedStaffName": "Direct to Company (HQ Desk)",
      "category": "Margin Based",
      "pricingConfig": {}
    }
  }
  ```

#### 5. `GET /v1/catalog/bootstrap`
- **Headers**: `Authorization: Bearer <accessToken>`
- **Description**: Retrieve hardware, presets, matrices, and settings.
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "settings": {
      "governance_settings": { ... },
      "statutory_taxes": { ... },
      "company_profile": { ... }
    },
    "catalog": {
      "hardware": { "modules": [...], "inverters": [...] },
      "presets": { ... },
      "tierMargins": [...],
      "inverterBenchmarks": [...],
      "bosMatrix": [...],
      "solarBanks": [...]
    }
  }
  ```

#### 6. `GET /v1/quotations?limit=50&offset=0`
- **Headers**: `Authorization: Bearer <accessToken>`
- **Description**: List quotations belonging strictly to the authenticated dealer.
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "quotations": [
      {
        "id": "SV-2026-Q1001",
        "dealer_id": "c1f77d61-3eb2-43bb-a5a4-09f191f69201",
        "dealer_code": "DL-801",
        "dealer_name": "Sunvine Saur Urja",
        "customer_name": "Bhavin Shah",
        "customer_phone": "9898012345",
        "customer_city": "Rajkot",
        "customer_state": "Gujarat",
        "system_capacity_kw": 5.26,
        "panel_type": "Goldi Solar 550W TOPCon",
        "inverter_type": "Deye 5kW String",
        "structure_type": "standard_hdgi",
        "total_amount": 265000,
        "subsidy_amount": 78000,
        "net_payable": 187000,
        "annual_generation_kwh": 7574,
        "status": "Active / Sent",
        "share_token": "a1b2c3d4...",
        "created_at": "2026-10-16T10:00:00Z",
        "updated_at": "2026-10-16T10:00:00Z"
      }
    ],
    "total": 1,
    "limit": 50,
    "offset": 0
  }
  ```

#### 7. `GET /v1/customer-files?limit=50&offset=0`
- **Headers**: `Authorization: Bearer <accessToken>`
- **Description**: List non-deleted customer files scoped strictly to authenticated dealer.
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "files": [
      {
        "id": "FIL-SV-2026-Q1001",
        "customerName": "Bhavin Shah",
        "phone": "9898012345",
        "address": "15, Tagore Road",
        "city": "Rajkot",
        "discom": "PGVCL",
        "consumerNo": "PG-88912",
        "sanctionedLoadKw": 6.0,
        "solarSystemKw": 5.26,
        "roofType": "Flat RCC",
        "sourceType": "DEALER",
        "dealerId": "c1f77d61-3eb2-43bb-a5a4-09f191f69201",
        "stage": "LEAD_SOURCED",
        "status": "Sourced",
        "isVerified": false,
        "createdAt": "2026-10-16T10:00:00Z"
      }
    ],
    "total": 1,
    "limit": 50,
    "offset": 0
  }
  ```

#### 8. `GET /v1/ledger`
- **Headers**: `Authorization: Bearer <accessToken>`
- **Description**: Financial ledger entries and summary for authenticated dealer.
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "entries": [
      {
        "id": "vch-uuid",
        "voucher_no": "VCH-2026-ABCD-1234",
        "dealer_id": "c1f77d61-3eb2-43bb-a5a4-09f191f69201",
        "entry_date": "2026-10-15",
        "entry_type": "DEBIT",
        "category": "EQUIPMENT_DISPATCH",
        "amount": 150000,
        "payment_mode": "BANK_TRANSFER",
        "reference_no": "RTGS9988112",
        "narration": "Dispatch for FIL-SV-2026-Q1001",
        "running_balance": 150000,
        "created_at": "2026-10-15T12:00:00Z"
      }
    ],
    "summary": {
      "totalDebit": 150000,
      "totalCredit": 0,
      "netBalance": 150000,
      "totalEntries": 1
    }
  }
  ```

#### 9. `GET /v1/health`
- **Description**: Unauthenticated health check returning booleans only.
- **Success Response (200 OK)**:
  ```json
  {
    "ok": true,
    "supabaseReachable": true,
    "d1": true,
    "secretsConfigured": true,
    "env": "staging",
    "version": "1.0.0"
  }
  ```

#### 10. `GET /v1/app/version`
- **Description**: Minimum supported version and current version for app upgrade checks.
- **Success Response (200 OK)**:
  ```json
  {
    "currentVersion": "1.0.0",
    "minSupportedVersion": "1.0.0",
    "upgradeRequired": false,
    "downloadUrl": "https://sunvine.in/app"
  }
  ```

---

## 3. D1 Database Schema (`gateway/migrations/0001_auth_tables.sql`)

```sql
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id TEXT PRIMARY KEY,
    family_id TEXT NOT NULL,
    dealer_id TEXT NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    device_label TEXT,
    expires_at INTEGER NOT NULL,
    revoked INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_family ON refresh_tokens (family_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_dealer ON refresh_tokens (dealer_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens (token_hash);

CREATE TABLE IF NOT EXISTS auth_rate_limits (
    key TEXT PRIMARY KEY,
    attempts INTEGER NOT NULL DEFAULT 1,
    reset_at INTEGER NOT NULL
);
```
