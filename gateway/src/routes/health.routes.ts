import { Hono } from 'hono';
import { Env } from '../types.js';
import { getSupabase } from '../utils/supabase.js';

export const healthRoutes = new Hono<{ Bindings: Env }>();

healthRoutes.get('/', (c) => {
  return c.json({ service: 'sunvine-app-backend', status: 'ok', version: '1.0.0' });
});

healthRoutes.get('/v1/health', async (c) => {
  let supabaseReachable = false;
  let d1Reachable = false;

  const secretsConfigured = Boolean(
    c.env.SUPABASE_SERVICE_ROLE_KEY &&
    c.env.SUPABASE_SERVICE_ROLE_KEY.length > 20 &&
    c.env.APP_JWT_SECRET &&
    c.env.APP_JWT_SECRET.length >= 32
  );

  try {
    const testRow = await c.env.DB.prepare('SELECT 1 as alive').first<{ alive: number }>();
    d1Reachable = testRow?.alive === 1;
  } catch {
    d1Reachable = false;
  }

  let supabaseErrorMsg: string | null = null;
  try {
    if (secretsConfigured) {
      const supabase = getSupabase(c.env);
      const { error } = await supabase.from('system_settings').select('id').limit(1);
      if (error) {
        supabaseErrorMsg = error.message;
        supabaseReachable = false;
      } else {
        supabaseReachable = true;
      }
    }
  } catch (err: any) {
    supabaseErrorMsg = err?.message || 'Exception during Supabase query';
    supabaseReachable = false;
  }

  const ok = supabaseReachable && d1Reachable && secretsConfigured;

  return c.json({
    ok,
    supabaseReachable,
    supabaseError: supabaseErrorMsg,
    d1: d1Reachable,
    secretsConfigured,
    env: c.env.APP_ENV || 'staging',
    version: '1.0.0',
  });
});

healthRoutes.get('/v1/app/version', (c) => {
  return c.json({
    currentVersion: '1.0.0',
    minSupportedVersion: '1.0.0',
    upgradeRequired: false,
    downloadUrl: 'https://sunvine.in/app',
  });
});
