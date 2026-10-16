import { Hono } from 'hono';
import { Env } from './types.js';
import { validateEnvironment } from './config/env.js';
import { errorResponse } from './utils/error.js';
import { healthRoutes } from './routes/health.routes.js';
import { authRoutes } from './routes/auth.routes.js';
import { dealerRoutes } from './routes/dealer.routes.js';

// Re-export utilities and configuration guards for testing and external consumers
export { validateEnvironment } from './config/env.js';
export { getSupabase } from './utils/supabase.js';
export {
  checkRateLimit,
  recordFailedAttempt,
  resetRateLimit,
} from './utils/rate-limiter.js';
export { errorResponse } from './utils/error.js';

export const app = new Hono<{ Bindings: Env; Variables: { dealerId: string } }>();

// ── CORS & Global Pre-Flight Middleware ──────────────────────────────────────
app.use('*', async (c, next) => {
  if (c.req.method === 'OPTIONS') {
    c.header('Access-Control-Allow-Origin', '*');
    c.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    c.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    return c.text('', 204);
  }

  c.header('Access-Control-Allow-Origin', '*');
  c.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  c.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Verify environment safety guard
  const envCheck = validateEnvironment(c.env);
  if (!envCheck.ok) {
    const err = errorResponse('CONFIG_ERROR', envCheck.error!, 500);
    return c.json(err.body, err.status);
  }

  await next();
});

// ── Mount Modular Route Handlers ─────────────────────────────────────────────
app.route('', healthRoutes);
app.route('', authRoutes);
app.route('', dealerRoutes);

export default app;
