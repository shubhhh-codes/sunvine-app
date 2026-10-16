/**
 * WebCrypto cryptographic utilities for Cloudflare Workers & Vitest
 */

export const APP_JWT_ISSUER = 'sunvine-epc-app';

export function base64UrlEncode(str: string): string {
  const bytes = new TextEncoder().encode(str);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

export function base64UrlDecode(str: string): string {
  let base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4) base64 += '=';
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return new TextDecoder().decode(bytes);
}

export async function sha256(input: string): Promise<string> {
  const msgUint8 = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

export function generateRandomToken(bytesCount = 32): string {
  const bytes = new Uint8Array(bytesCount);
  crypto.getRandomValues(bytes);
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

export function normalizeMobile(raw: string): string {
  if (!raw || typeof raw !== 'string') return '';
  const digitsOnly = raw.replace(/\D/g, '');
  return digitsOnly.slice(-10);
}

export async function signCompactJwt(
  payload: { id: string; dealer_id: string; role: 'dealer' },
  secret: string,
  expiresInSeconds = 3600
): Promise<string> {
  if (!secret || secret.trim().length < 32) {
    throw new Error('APP_JWT_SECRET is missing or too short (min 32 chars).');
  }

  const header = { alg: 'HS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const fullPayload = {
    ...payload,
    jti: crypto.randomUUID(),
    iss: APP_JWT_ISSUER,
    iat: now,
    exp: now + expiresInSeconds,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(fullPayload));
  const data = `${encodedHeader}.${encodedPayload}`;

  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    enc.encode(secret.trim()),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sigBuf = await crypto.subtle.sign('HMAC', key, enc.encode(data));
  const bytes = new Uint8Array(sigBuf);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  const signature = btoa(binary)
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  const token = `${data}.${signature}`;
  if (token.length > 4096) {
    throw new Error('Minted JWT exceeds maximum size limit of 4096 bytes.');
  }

  return token;
}

export async function verifyCompactJwt(
  token: string,
  secret: string
): Promise<{ valid: boolean; payload?: any; error?: string }> {
  if (!token || typeof token !== 'string') return { valid: false, error: 'Token missing' };
  if (token.length > 4096) return { valid: false, error: 'Token exceeds 4096 characters' };

  const parts = token.split('.');
  if (parts.length !== 3) return { valid: false, error: 'Malformed token structure' };

  const [encodedHeader, encodedPayload, signature] = parts;

  let header: any;
  try {
    header = JSON.parse(base64UrlDecode(encodedHeader));
  } catch {
    return { valid: false, error: 'Invalid header encoding' };
  }

  if (header?.alg !== 'HS256') {
    return { valid: false, error: 'Invalid algorithm. Expected HS256' };
  }

  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    enc.encode(secret.trim()),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['verify']
  );

  let sigBase64 = signature.replace(/-/g, '+').replace(/_/g, '/');
  while (sigBase64.length % 4) sigBase64 += '=';
  const sigBinary = atob(sigBase64);
  const sigBytes = new Uint8Array(sigBinary.length);
  for (let i = 0; i < sigBinary.length; i++) {
    sigBytes[i] = sigBinary.charCodeAt(i);
  }

  const dataBytes = enc.encode(`${encodedHeader}.${encodedPayload}`);
  const validSig = await crypto.subtle.verify('HMAC', key, sigBytes, dataBytes);
  if (!validSig) {
    return { valid: false, error: 'Invalid signature' };
  }

  try {
    const payload = JSON.parse(base64UrlDecode(encodedPayload));
    if (!payload || payload.iss !== APP_JWT_ISSUER) {
      return { valid: false, error: `Invalid issuer. Expected ${APP_JWT_ISSUER}` };
    }
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < now) {
      return { valid: false, error: 'Token has expired' };
    }
    return { valid: true, payload };
  } catch {
    return { valid: false, error: 'Invalid payload encoding' };
  }
}
