import { describe, it, expect, beforeEach, vi } from 'vitest';
import { app, validateEnvironment } from '../src/index.js';
import { MockD1Database } from './mockD1.js';
import { sha256, signCompactJwt } from '../src/crypto.js';

describe('Standalone Worker Backend Endpoints & Security Policy', () => {
  const TEST_JWT_SECRET = 'a_very_secure_test_secret_with_more_than_32_characters_for_hmac';
  const TEST_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock_service_role_key_long_enough_for_test';
  let mockDb: MockD1Database;
  let env: any;

  beforeEach(() => {
    mockDb = new MockD1Database();
    env = {
      DB: mockDb,
      APP_ENV: 'staging',
      SUPABASE_URL: 'https://voyargkmlkrlidyxjcbk.supabase.co',
      SUPABASE_SERVICE_ROLE_KEY: TEST_SERVICE_ROLE_KEY,
      APP_JWT_SECRET: TEST_JWT_SECRET,
    };
  });

  describe('Environment Configuration Guard', () => {
    it('refuses execution if Staging environment is configured with Production Supabase URL', () => {
      const invalidEnv = {
        ...env,
        APP_ENV: 'staging',
        SUPABASE_URL: 'https://wyberzvcyrjipjqpotwe.supabase.co',
      };
      const check = validateEnvironment(invalidEnv);
      expect(check.ok).toBe(false);
      expect(check.error).toContain('Staging environment cannot use Production Supabase URL');
    });

    it('refuses execution if Production environment is configured with Staging Supabase URL', () => {
      const invalidEnv = {
        ...env,
        APP_ENV: 'production',
        SUPABASE_URL: 'https://voyargkmlkrlidyxjcbk.supabase.co',
      };
      const check = validateEnvironment(invalidEnv);
      expect(check.ok).toBe(false);
      expect(check.error).toContain('Production environment cannot use Staging Supabase URL');
    });

    it('accepts matching Staging environment and Supabase URL', () => {
      const check = validateEnvironment(env);
      expect(check.ok).toBe(true);
    });
  });

  describe('Health Endpoint (/v1/health)', () => {
    it('returns booleans only and never leaks secret strings or keys', async () => {
      const res = await app.request('/v1/health', { method: 'GET' }, env);
      expect(res.status).toBe(200);
      const data = await res.json();

      expect(typeof data.ok).toBe('boolean');
      expect(typeof data.supabaseReachable).toBe('boolean');
      expect(typeof data.d1).toBe('boolean');
      expect(typeof data.secretsConfigured).toBe('boolean');
      expect(data.env).toBe('staging');
      expect(data.version).toBe('1.0.0');

      // Zero secret leakage check
      const rawString = JSON.stringify(data);
      expect(rawString).not.toContain(TEST_SERVICE_ROLE_KEY);
      expect(rawString).not.toContain(TEST_JWT_SECRET);
      expect(rawString).not.toContain('eyJ');
    });
  });

  describe('Authentication (/v1/auth/login)', () => {
    it('rejects invalid mobile numbers with 401 INVALID_CREDENTIALS', async () => {
      const res = await app.request('/v1/auth/login', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          mobile: '12345', // Short number
          password: 'Password123',
        }),
      }, env);

      expect(res.status).toBe(401);
      const data = await res.json();
      expect(data.success).toBe(false);
      expect(data.code).toBe('INVALID_CREDENTIALS');
    });

    it('throttles login requests when rate limit is exceeded', async () => {
      const testMobile = '9876543210';
      const acctKey = `ratelimit:acct:${testMobile}`;
      // Simulate 5 prior failed attempts
      mockDb.rateLimits.set(acctKey, { attempts: 5, reset_at: Math.floor(Date.now() / 1000) + 300 });

      const res = await app.request('/v1/auth/login', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          mobile: testMobile,
          password: 'Password123',
        }),
      }, env);

      expect(res.status).toBe(429);
      const data = await res.json();
      expect(data.code).toBe('RATE_LIMITED');
      expect(data.retryAfter).toBeGreaterThan(0);
    });
  });

  describe('Refresh Token Rotation, Reuse Detection, and Revocation (/v1/auth/refresh)', () => {
    const rawToken = 'test-refresh-token-uuid-1.abc123xyz';
    const familyId = 'fam-001';
    const dealerId = 'c1f77d61-3eb2-43bb-a5a4-09f191f69201';

    beforeEach(async () => {
      const tokenHash = await sha256(rawToken);
      const nowSec = Math.floor(Date.now() / 1000);
      mockDb.refreshTokens.push({
        id: 'token-rec-1',
        family_id: familyId,
        token_hash: tokenHash,
        dealer_id: dealerId,
        device_id: 'device-test-1',
        device_name: 'Samsung SM-S921E',
        issued_at: nowSec,
        expires_at: nowSec + 86400 * 30,
        rotated_at: null,
        revoked_at: null,
        user_agent: 'Sunvine-Mobile/1.0',
      });
    });

    it('detects token reuse and immediately revokes entire family', async () => {
      // First, mark the token as rotated
      const oldRecord = mockDb.refreshTokens.find((r) => r.id === 'token-rec-1')!;
      oldRecord.rotated_at = Math.floor(Date.now() / 1000) - 10;

      // Add a second unrotated active token in the same family
      mockDb.refreshTokens.push({
        id: 'token-rec-2',
        family_id: familyId,
        token_hash: 'some-hash-2',
        dealer_id: dealerId,
        device_id: 'device-test-1',
        device_name: 'Samsung SM-S921E',
        issued_at: Math.floor(Date.now() / 1000),
        expires_at: Math.floor(Date.now() / 1000) + 86400,
        rotated_at: null,
        revoked_at: null,
        user_agent: 'Sunvine-Mobile/1.0',
      });

      // Attacker attempts to use the already-rotated rawToken
      const res = await app.request('/v1/auth/refresh', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          refreshToken: rawToken,
          deviceId: 'device-test-1',
        }),
      }, env);

      expect(res.status).toBe(401);
      const data = await res.json();
      expect(data.code).toBe('REAUTH_REQUIRED');
      expect(data.message).toContain('Token reuse detected');

      // Verify ALL tokens in this family are now revoked
      for (const rec of mockDb.refreshTokens.filter((r) => r.family_id === familyId)) {
        expect(rec.revoked_at).not.toBeNull();
      }
    });

    it('rejects expired refresh tokens with 401 REAUTH_REQUIRED', async () => {
      const oldRecord = mockDb.refreshTokens.find((r) => r.id === 'token-rec-1')!;
      oldRecord.expires_at = Math.floor(Date.now() / 1000) - 100; // Expired

      const res = await app.request('/v1/auth/refresh', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          refreshToken: rawToken,
        }),
      }, env);

      expect(res.status).toBe(401);
      const data = await res.json();
      expect(data.code).toBe('REAUTH_REQUIRED');
    });
  });

  describe('Protected Endpoints Security Guard', () => {
    it('rejects unauthenticated requests to /v1/me with 401 REAUTH_REQUIRED', async () => {
      const res = await app.request('/v1/me', { method: 'GET' }, env);
      expect(res.status).toBe(401);
      const data = await res.json();
      expect(data.code).toBe('REAUTH_REQUIRED');
    });

    it('rejects unauthenticated requests to /v1/quotations with 401 REAUTH_REQUIRED', async () => {
      const res = await app.request('/v1/quotations', { method: 'GET' }, env);
      expect(res.status).toBe(401);
      const data = await res.json();
      expect(data.code).toBe('REAUTH_REQUIRED');
    });

    it('rejects unauthenticated requests to /v1/customer-files with 401 REAUTH_REQUIRED', async () => {
      const res = await app.request('/v1/customer-files', { method: 'GET' }, env);
      expect(res.status).toBe(401);
      const data = await res.json();
      expect(data.code).toBe('REAUTH_REQUIRED');
    });

    it('rejects unauthenticated requests to /v1/ledger with 401 REAUTH_REQUIRED', async () => {
      const res = await app.request('/v1/ledger', { method: 'GET' }, env);
      expect(res.status).toBe(401);
      const data = await res.json();
      expect(data.code).toBe('REAUTH_REQUIRED');
    });

    it('rejects tokens with non-dealer role with 403 ROLE_NOT_ALLOWED', async () => {
      const adminToken = await signCompactJwt(
        { id: 'admin-1', dealer_id: 'admin-1', role: 'admin' as any },
        TEST_JWT_SECRET,
        3600
      );

      const res = await app.request('/v1/me', {
        method: 'GET',
        headers: { authorization: `Bearer ${adminToken}` },
      }, env);

      expect(res.status).toBe(403);
      const data = await res.json();
      expect(data.code).toBe('ROLE_NOT_ALLOWED');
    });
  });
});
