import { Hono } from 'hono';
import { SupabaseClient } from '@supabase/supabase-js';
import { Env, DealerProfile, RefreshTokenRecord } from '../types.js';
import { errorResponse } from '../utils/error.js';
import { getSupabase } from '../utils/supabase.js';
import {
  checkRateLimit,
  recordFailedAttempt,
  resetRateLimit,
} from '../utils/rate-limiter.js';
import {
  ACCESS_TOKEN_TTL_SECONDS,
  REFRESH_TOKEN_TTL_SECONDS,
} from '../config/env.js';
import {
  sha256,
  signCompactJwt,
  generateRandomToken,
  normalizeMobile,
} from '../crypto.js';

export const authRoutes = new Hono<{ Bindings: Env }>();

authRoutes.post('/v1/auth/login', async (c) => {
  let body: any;
  try {
    body = await c.req.json();
  } catch {
    const err = errorResponse('VALIDATION_ERROR', 'Invalid JSON body.', 400);
    return c.json(err.body, err.status);
  }

  const { mobile, identifier, password, deviceId, deviceName } = body || {};
  const rawMobile = String(mobile || identifier || '').trim();

  if (!rawMobile || !password || typeof password !== 'string') {
    const err = errorResponse('VALIDATION_ERROR', 'mobile and password are required.', 400);
    return c.json(err.body, err.status);
  }

  const cleanMobile = normalizeMobile(rawMobile);
  if (cleanMobile.length !== 10) {
    const err = errorResponse('INVALID_CREDENTIALS', 'Mobile number or password is incorrect.', 401);
    return c.json(err.body, err.status);
  }

  const clientIp =
    c.req.header('cf-connecting-ip') ||
    c.req.header('x-real-ip') ||
    c.req.header('x-forwarded-for')?.split(',')[0].trim() ||
    '127.0.0.1';

  const ipKey = `ratelimit:ip:${clientIp}`;
  const acctKey = `ratelimit:acct:${cleanMobile}`;

  // Check rate limits
  const ipCheck = await checkRateLimit(c.env.DB, ipKey, 10);
  if (!ipCheck.allowed) {
    const err = errorResponse('RATE_LIMITED', `Too many attempts. Try again in ${ipCheck.resetSeconds} seconds.`, 429, ipCheck.resetSeconds);
    return c.json(err.body, err.status);
  }

  const acctCheck = await checkRateLimit(c.env.DB, acctKey, 5);
  if (!acctCheck.allowed) {
    const err = errorResponse('RATE_LIMITED', `Too many failed login attempts for this account. Try again in ${acctCheck.resetSeconds} seconds.`, 429, acctCheck.resetSeconds);
    return c.json(err.body, err.status);
  }

  let supabase: SupabaseClient;
  try {
    supabase = getSupabase(c.env);
  } catch (err: any) {
    const resp = errorResponse('ORIGIN_ERROR', 'Database service configuration error: ' + err.message, 500);
    return c.json(resp.body, resp.status);
  }

  // 1. Password check via Supabase RPC (pgcrypto crypt in C)
  let verifiedDealerId: string | null = null;
  try {
    const { data, error } = await supabase.rpc('verify_dealer_password', {
      p_mobile: cleanMobile,
      p_password: password,
    });

    if (error) {
      console.error('[auth/login] RPC error:', error.message);
      const resp = errorResponse('ORIGIN_ERROR', 'Database authentication service unavailable.', 503);
      return c.json(resp.body, resp.status);
    }

    verifiedDealerId = data;
  } catch (err: any) {
    console.error('[auth/login] Supabase RPC exception:', err.message);
    const resp = errorResponse('ORIGIN_ERROR', 'Origin service unavailable.', 503);
    return c.json(resp.body, resp.status);
  }

  if (!verifiedDealerId) {
    // Record failure in D1
    await recordFailedAttempt(c.env.DB, ipKey, 5 * 60);
    await recordFailedAttempt(c.env.DB, acctKey, 15 * 60);
    const err = errorResponse('INVALID_CREDENTIALS', 'Mobile number or password is incorrect.', 401);
    return c.json(err.body, err.status);
  }

  // 2. Fetch dealer account details
  const { data: dealer, error: fetchErr } = await supabase
    .from('dealer_accounts')
    .select('id, dealer_code, firm_name, contact_person, mobile_number, email, status, city, state, discom, tier, max_margin_cap_per_kw, assigned_staff_id, assigned_staff_name, pricing_config')
    .eq('id', verifiedDealerId)
    .maybeSingle();

  if (fetchErr || !dealer) {
    const err = errorResponse('INVALID_CREDENTIALS', 'Dealer account record not found.', 401);
    return c.json(err.body, err.status);
  }

  // 3. Status checks
  if (dealer.status === 'suspended' || dealer.status === 'inactive') {
    const err = errorResponse('ACCOUNT_SUSPENDED', 'Account suspended, contact Sunvine support.', 403);
    return c.json(err.body, err.status);
  }

  // 4. Governance margin cap check
  if (
    dealer.max_margin_cap_per_kw === null ||
    dealer.max_margin_cap_per_kw === undefined ||
    isNaN(Number(dealer.max_margin_cap_per_kw))
  ) {
    const err = errorResponse('CONFIG_ERROR', `Dealer ${dealer.dealer_code || dealer.id} is missing margin cap configuration in database.`, 500);
    return c.json(err.body, err.status);
  }

  // Reset rate limits on successful authentication
  await resetRateLimit(c.env.DB, ipKey);
  await resetRateLimit(c.env.DB, acctKey);

  // Mint compact access token
  const accessToken = await signCompactJwt(
    { id: dealer.id, dealer_id: dealer.id, role: 'dealer' },
    c.env.APP_JWT_SECRET,
    ACCESS_TOKEN_TTL_SECONDS
  );

  // Mint 30-day random refresh token
  const nowSec = Math.floor(Date.now() / 1000);
  const rawRefreshToken = `${crypto.randomUUID()}.${generateRandomToken(32)}`;
  const tokenHash = await sha256(rawRefreshToken);
  const familyId = crypto.randomUUID();
  const tokenId = crypto.randomUUID();
  const userAgent = c.req.header('user-agent') || null;

  await c.env.DB.prepare(`
    INSERT INTO refresh_tokens (
      id, family_id, token_hash, dealer_id, device_id, device_name,
      issued_at, expires_at, rotated_at, revoked_at, user_agent
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL, NULL, ?)
  `).bind(
    tokenId,
    familyId,
    tokenHash,
    dealer.id,
    deviceId || 'unknown',
    deviceName || null,
    nowSec,
    nowSec + REFRESH_TOKEN_TTL_SECONDS,
    userAgent
  ).run();

  // Cap active families per dealer at 20
  try {
    const activeFamilies = await c.env.DB.prepare(`
      SELECT family_id, MIN(issued_at) as earliest_issued
      FROM refresh_tokens
      WHERE dealer_id = ? AND revoked_at IS NULL
      GROUP BY family_id
      ORDER BY earliest_issued DESC
    `).bind(dealer.id).all<{ family_id: string }>();

    if (activeFamilies.results && activeFamilies.results.length > 20) {
      const excess = activeFamilies.results.slice(20);
      for (const f of excess) {
        await c.env.DB.prepare('UPDATE refresh_tokens SET revoked_at = ? WHERE family_id = ? AND revoked_at IS NULL')
          .bind(nowSec, f.family_id)
          .run();
      }
    }
  } catch {}

  const isDirect = dealer.assigned_staff_id === 'STF-DIRECT';
  const userProfile: DealerProfile = {
    id: dealer.id,
    dealerCode: dealer.dealer_code,
    role: 'dealer',
    mobile: dealer.mobile_number,
    firmName: dealer.firm_name,
    contactPerson: dealer.contact_person,
    city: dealer.city,
    state: dealer.state,
    discom: dealer.discom,
    tier: dealer.tier,
    maxMarginCapPerKw: Number(dealer.max_margin_cap_per_kw),
    assignedStaffId: dealer.assigned_staff_id || 'STF-DIRECT',
    assignedStaffName: dealer.assigned_staff_name || (isDirect ? 'Direct to Company (HQ Desk)' : 'Sunvine Sales Staff'),
    category: dealer.pricing_config?.category || 'Margin Based',
    pricingConfig: dealer.pricing_config || {},
  };

  const accessExpiresAt = nowSec + ACCESS_TOKEN_TTL_SECONDS;

  return c.json({
    success: true,
    accessToken,
    refreshToken: rawRefreshToken,
    expiresIn: ACCESS_TOKEN_TTL_SECONDS,
    accessExpiresAt,
    user: userProfile,
  });
});

authRoutes.post('/v1/auth/refresh', async (c) => {
  let body: any;
  try {
    body = await c.req.json();
  } catch {
    const err = errorResponse('VALIDATION_ERROR', 'Invalid JSON body.', 400);
    return c.json(err.body, err.status);
  }

  const { refreshToken, deviceId } = body || {};
  if (!refreshToken || typeof refreshToken !== 'string') {
    const err = errorResponse('VALIDATION_ERROR', 'refreshToken is required.', 400);
    return c.json(err.body, err.status);
  }

  const tokenHash = await sha256(refreshToken);
  const nowSec = Math.floor(Date.now() / 1000);

  const tokenRecord = await c.env.DB.prepare(
    'SELECT * FROM refresh_tokens WHERE token_hash = ?'
  )
    .bind(tokenHash)
    .first<RefreshTokenRecord>();

  if (!tokenRecord) {
    const err = errorResponse('REAUTH_REQUIRED', 'Invalid or expired refresh token. Please sign in again.', 401);
    return c.json(err.body, err.status);
  }

  // Token reuse detection: if token is already rotated or revoked, immediately revoke family
  if (tokenRecord.revoked_at !== null || tokenRecord.rotated_at !== null) {
    await c.env.DB.prepare(
      'UPDATE refresh_tokens SET revoked_at = ? WHERE family_id = ? AND revoked_at IS NULL'
    )
      .bind(nowSec, tokenRecord.family_id)
      .run();

    const err = errorResponse('REAUTH_REQUIRED', 'Token reuse detected. Refresh session revoked.', 401);
    return c.json(err.body, err.status);
  }

  // Check token expiration
  if (tokenRecord.expires_at < nowSec) {
    const err = errorResponse('REAUTH_REQUIRED', 'Refresh token expired. Please sign in again.', 401);
    return c.json(err.body, err.status);
  }

  // Re-read dealer from Supabase
  const supabase = getSupabase(c.env);
  const { data: dealer, error: dealerErr } = await supabase
    .from('dealer_accounts')
    .select('id, status')
    .eq('id', tokenRecord.dealer_id)
    .maybeSingle();

  if (dealerErr || !dealer) {
    await c.env.DB.prepare('UPDATE refresh_tokens SET revoked_at = ? WHERE family_id = ? AND revoked_at IS NULL')
      .bind(nowSec, tokenRecord.family_id)
      .run();
    const err = errorResponse('REAUTH_REQUIRED', 'Account no longer exists.', 401);
    return c.json(err.body, err.status);
  }

  if (dealer.status === 'suspended' || dealer.status === 'inactive') {
    await c.env.DB.prepare('UPDATE refresh_tokens SET revoked_at = ? WHERE family_id = ? AND revoked_at IS NULL')
      .bind(nowSec, tokenRecord.family_id)
      .run();
    const err = errorResponse('ACCOUNT_SUSPENDED', 'Account suspended, contact Sunvine support.', 403);
    return c.json(err.body, err.status);
  }

  // Mark current token rotated
  await c.env.DB.prepare('UPDATE refresh_tokens SET rotated_at = ? WHERE id = ?')
    .bind(nowSec, tokenRecord.id)
    .run();

  // Mint new rotated refresh token in the same family
  const newRawRefreshToken = `${crypto.randomUUID()}.${generateRandomToken(32)}`;
  const newTokenHash = await sha256(newRawRefreshToken);
  const newTokenId = crypto.randomUUID();
  const userAgent = c.req.header('user-agent') || tokenRecord.user_agent;

  await c.env.DB.prepare(`
    INSERT INTO refresh_tokens (
      id, family_id, token_hash, dealer_id, device_id, device_name,
      issued_at, expires_at, rotated_at, revoked_at, user_agent
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL, NULL, ?)
  `).bind(
    newTokenId,
    tokenRecord.family_id,
    newTokenHash,
    tokenRecord.dealer_id,
    deviceId || tokenRecord.device_id,
    tokenRecord.device_name,
    nowSec,
    nowSec + REFRESH_TOKEN_TTL_SECONDS,
    userAgent
  ).run();

  // Mint new 1-hour access token
  const accessToken = await signCompactJwt(
    { id: dealer.id, dealer_id: dealer.id, role: 'dealer' },
    c.env.APP_JWT_SECRET,
    ACCESS_TOKEN_TTL_SECONDS
  );

  const accessExpiresAt = nowSec + ACCESS_TOKEN_TTL_SECONDS;

  return c.json({
    success: true,
    accessToken,
    refreshToken: newRawRefreshToken,
    expiresIn: ACCESS_TOKEN_TTL_SECONDS,
    accessExpiresAt,
  });
});

authRoutes.post('/v1/auth/logout', async (c) => {
  let body: any = {};
  try {
    body = await c.req.json();
  } catch {}

  const refreshToken = body?.refreshToken;
  const nowSec = Math.floor(Date.now() / 1000);

  if (refreshToken) {
    const tokenHash = await sha256(refreshToken);
    const rec = await c.env.DB.prepare(
      'SELECT family_id FROM refresh_tokens WHERE token_hash = ?'
    )
      .bind(tokenHash)
      .first<{ family_id: string }>();

    if (rec?.family_id) {
      await c.env.DB.prepare(
        'UPDATE refresh_tokens SET revoked_at = ? WHERE family_id = ? AND revoked_at IS NULL'
      )
        .bind(nowSec, rec.family_id)
        .run();
    }
  }

  return c.json({ success: true, message: 'Logged out successfully.' });
});
