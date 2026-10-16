import { Env } from '../types.js';

export const ACCESS_TOKEN_TTL_SECONDS = 3600; // 1 hour
export const REFRESH_TOKEN_TTL_SECONDS = 30 * 24 * 3600; // 30 days
export const STAGING_SUPABASE_HOST = 'voyargkmlkrlidyxjcbk.supabase.co';
export const PRODUCTION_SUPABASE_HOST = 'wyberzvcyrjipjqpotwe.supabase.co';

export function validateEnvironment(env: Env): { ok: boolean; error?: string } {
  const currentEnv = (env.APP_ENV || 'staging').toLowerCase();
  const supabaseUrl = env.SUPABASE_URL || '';

  if (currentEnv === 'staging' && supabaseUrl.includes(PRODUCTION_SUPABASE_HOST)) {
    return {
      ok: false,
      error: 'CONFIG_GUARD: Refusing to start. Staging environment cannot use Production Supabase URL.',
    };
  }

  if (currentEnv === 'production' && supabaseUrl.includes(STAGING_SUPABASE_HOST)) {
    return {
      ok: false,
      error: 'CONFIG_GUARD: Refusing to start. Production environment cannot use Staging Supabase URL.',
    };
  }

  return { ok: true };
}
