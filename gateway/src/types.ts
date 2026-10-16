export interface Env {
  DB: D1Database;
  APP_ENV: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  APP_JWT_SECRET: string;
}

export type ErrorCode =
  | 'INVALID_CREDENTIALS'
  | 'ACCOUNT_SUSPENDED'
  | 'RATE_LIMITED'
  | 'REAUTH_REQUIRED'
  | 'ORIGIN_ERROR'
  | 'CONFIG_ERROR'
  | 'ROLE_NOT_ALLOWED'
  | 'VALIDATION_ERROR';

export interface AppErrorResponse {
  success: false;
  code: ErrorCode;
  message: string;
  retryAfter?: number;
}

export interface CompactJwtPayload {
  id: string;
  dealer_id: string;
  role: 'dealer';
  jti: string;
  iss: string;
  iat: number;
  exp: number;
}

export interface DealerProfile {
  id: string;
  dealerCode: string;
  role: 'dealer';
  mobile: string;
  firmName: string;
  contactPerson: string;
  city: string;
  state: string;
  discom: string;
  tier: string;
  maxMarginCapPerKw: number;
  assignedStaffId: string;
  assignedStaffName: string;
  category: string;
  pricingConfig: Record<string, any>;
}

export interface RefreshTokenRecord {
  id: string;
  family_id: string;
  token_hash: string;
  dealer_id: string;
  device_id: string;
  device_name: string | null;
  issued_at: number;
  expires_at: number;
  rotated_at: number | null;
  revoked_at: number | null;
  user_agent: string | null;
}

export interface AppReleaseRecord {
  id: string;
  platform: string;
  latest_version: string;
  min_supported_version: string;
  apk_url: string;
  release_notes: string | null;
  created_at: number;
}
