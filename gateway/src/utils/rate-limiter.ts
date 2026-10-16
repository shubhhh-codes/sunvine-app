export async function checkRateLimit(
  db: D1Database,
  key: string,
  maxAttempts: number
): Promise<{ allowed: boolean; remaining: number; resetSeconds: number }> {
  const now = Math.floor(Date.now() / 1000);
  try {
    const row = await db
      .prepare('SELECT attempts, reset_at FROM auth_rate_limits WHERE key = ?')
      .bind(key)
      .first<{ attempts: number; reset_at: number }>();

    if (!row || now >= row.reset_at) {
      return { allowed: true, remaining: maxAttempts, resetSeconds: 0 };
    }

    const remaining = Math.max(0, maxAttempts - row.attempts);
    const resetSeconds = Math.max(1, row.reset_at - now);
    return { allowed: row.attempts < maxAttempts, remaining, resetSeconds };
  } catch {
    return { allowed: true, remaining: maxAttempts, resetSeconds: 0 };
  }
}

export async function recordFailedAttempt(
  db: D1Database,
  key: string,
  windowSeconds: number
): Promise<void> {
  const now = Math.floor(Date.now() / 1000);
  const resetAt = now + windowSeconds;
  try {
    const row = await db
      .prepare('SELECT attempts, reset_at FROM auth_rate_limits WHERE key = ?')
      .bind(key)
      .first<{ attempts: number; reset_at: number }>();

    if (!row || now >= row.reset_at) {
      await db
        .prepare('INSERT OR REPLACE INTO auth_rate_limits (key, attempts, reset_at) VALUES (?, 1, ?)')
        .bind(key, resetAt)
        .run();
    } else {
      await db
        .prepare('UPDATE auth_rate_limits SET attempts = attempts + 1 WHERE key = ?')
        .bind(key)
        .run();
    }
  } catch {}
}

export async function resetRateLimit(db: D1Database, key: string): Promise<void> {
  try {
    await db.prepare('DELETE FROM auth_rate_limits WHERE key = ?').bind(key).run();
  } catch {}
}
