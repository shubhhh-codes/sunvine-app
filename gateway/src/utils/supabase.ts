import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { Env } from '../types.js';
import { validateEnvironment } from '../config/env.js';

export function getSupabase(env: Env): SupabaseClient {
  const envCheck = validateEnvironment(env);
  if (!envCheck.ok) {
    throw new Error(envCheck.error);
  }
  return createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
