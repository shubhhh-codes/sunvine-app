import { describe, it, expect } from 'vitest';
import { signCompactJwt, verifyCompactJwt, normalizeMobile, APP_JWT_ISSUER } from '../src/crypto.js';

describe('Compact JWT and Mobile Normalization', () => {
  const TEST_SECRET = 'a_very_secure_test_secret_with_more_than_32_characters_for_hmac';

  it('normalizes 10-digit mobile numbers with various prefixes and symbols', () => {
    expect(normalizeMobile('+91 98765-43210')).toBe('9876543210');
    expect(normalizeMobile('919876543210')).toBe('9876543210');
    expect(normalizeMobile('9876543210')).toBe('9876543210');
    expect(normalizeMobile('  98765 43210  ')).toBe('9876543210');
    expect(normalizeMobile('12345')).toBe('12345');
  });

  it('signs and verifies compact app JWT with 1 hour expiration', async () => {
    const payload = {
      id: 'd-test-uuid-001',
      dealer_id: 'd-test-uuid-001',
      role: 'dealer' as const,
    };

    const token = await signCompactJwt(payload, TEST_SECRET, 3600);
    expect(typeof token).toBe('string');
    expect(token.length).toBeLessThan(500); // Compact token < 500 chars

    const verification = await verifyCompactJwt(token, TEST_SECRET);
    expect(verification.valid).toBe(true);
    expect(verification.payload).toBeDefined();
    expect(verification.payload.iss).toBe(APP_JWT_ISSUER);
    expect(verification.payload.role).toBe('dealer');
    expect(verification.payload.dealer_id).toBe('d-test-uuid-001');
    expect(verification.payload.jti).toBeDefined();
    expect(verification.payload.exp).toBeGreaterThan(Math.floor(Date.now() / 1000));
  });

  it('rejects tampered or forged JWT signature', async () => {
    const token = await signCompactJwt({ id: 'u1', dealer_id: 'u1', role: 'dealer' }, TEST_SECRET, 3600);
    const tampered = token.slice(0, -5) + 'AAAAA';

    const verification = await verifyCompactJwt(tampered, TEST_SECRET);
    expect(verification.valid).toBe(false);
    expect(verification.error).toBe('Invalid signature');
  });

  it('rejects expired JWT token', async () => {
    // Expired 10 seconds ago
    const token = await signCompactJwt({ id: 'u1', dealer_id: 'u1', role: 'dealer' }, TEST_SECRET, -10);
    const verification = await verifyCompactJwt(token, TEST_SECRET);
    expect(verification.valid).toBe(false);
    expect(verification.error).toBe('Token has expired');
  });
});
