import { RefreshTokenRecord, AppReleaseRecord } from '../src/types.js';

export class MockD1Database {
  public refreshTokens: RefreshTokenRecord[] = [];
  public appReleases: AppReleaseRecord[] = [];
  public rateLimits = new Map<string, { attempts: number; reset_at: number }>();

  prepare(sql: string) {
    return new MockD1PreparedStatement(sql, [], this);
  }

  async executeFirst<T>(sql: string, params: any[]): Promise<T | null> {
    const norm = sql.trim().toLowerCase();
    if (norm.includes('select 1 as alive')) {
      return ({ alive: 1 } as any) as T;
    }
    if (norm.includes('from auth_rate_limits where key = ?')) {
      const key = params[0];
      const entry = this.rateLimits.get(key);
      return (entry as any) || null;
    }
    if (norm.includes('from refresh_tokens where token_hash = ?')) {
      const hash = params[0];
      const found = this.refreshTokens.find((r) => r.token_hash === hash);
      return (found as any) || null;
    }
    if (norm.includes('from refresh_tokens where id = ?')) {
      const id = params[0];
      const found = this.refreshTokens.find((r) => r.id === id);
      return (found as any) || null;
    }
    if (norm.includes('from app_releases where platform = ?')) {
      const platform = params[0];
      const matches = this.appReleases.filter((r) => r.platform === platform);
      matches.sort((a, b) => b.created_at - a.created_at);
      return (matches[0] as any) || null;
    }
    return null;
  }

  async executeAll<T>(sql: string, params: any[]): Promise<{ results: T[] }> {
    const norm = sql.trim().toLowerCase();
    if (norm.includes('from refresh_tokens') && norm.includes('group by family_id')) {
      const families = new Map<string, number>();
      for (const t of this.refreshTokens) {
        if (t.revoked_at === null) {
          const current = families.get(t.family_id) || t.issued_at;
          families.set(t.family_id, Math.min(current, t.issued_at));
        }
      }
      const results: any[] = Array.from(families.entries()).map(([family_id, earliest_issued]) => ({
        family_id,
        earliest_issued,
      }));
      return { results };
    }
    return { results: [] };
  }

  async executeRun(sql: string, params: any[]): Promise<{ success: boolean }> {
    const norm = sql.trim().toLowerCase();
    if (norm.includes('insert or replace into auth_rate_limits') || norm.includes('insert into auth_rate_limits')) {
      const [key, attempts, reset_at] = params;
      this.rateLimits.set(key, { attempts, reset_at });
      return { success: true };
    }

    if (norm.includes('update auth_rate_limits set attempts = attempts + 1 where key = ?')) {
      const key = params[0];
      const entry = this.rateLimits.get(key);
      if (entry) {
        entry.attempts += 1;
      }
      return { success: true };
    }

    if (norm.includes('delete from auth_rate_limits where key = ?')) {
      const key = params[0];
      this.rateLimits.delete(key);
      return { success: true };
    }

    if (norm.startsWith('insert into refresh_tokens')) {
      const [
        id,
        family_id,
        token_hash,
        dealer_id,
        device_id,
        device_name,
        issued_at,
        expires_at,
        user_agent,
      ] = params;
      this.refreshTokens.push({
        id,
        family_id,
        token_hash,
        dealer_id,
        device_id,
        device_name,
        issued_at,
        expires_at,
        rotated_at: null,
        revoked_at: null,
        user_agent,
      });
      return { success: true };
    }

    if (norm.includes('update refresh_tokens set revoked_at = ? where family_id = ?')) {
      const [revoked_at, family_id] = params;
      for (const row of this.refreshTokens) {
        if (row.family_id === family_id && row.revoked_at === null) {
          row.revoked_at = revoked_at;
        }
      }
      return { success: true };
    }

    if (norm.includes('update refresh_tokens set rotated_at = ? where id = ?')) {
      const [rotated_at, id] = params;
      const found = this.refreshTokens.find((r) => r.id === id);
      if (found) {
        found.rotated_at = rotated_at;
      }
      return { success: true };
    }

    return { success: true };
  }
}

export class MockD1PreparedStatement {
  constructor(
    private sql: string,
    private params: any[] = [],
    private db: MockD1Database
  ) {}

  bind(...args: any[]) {
    return new MockD1PreparedStatement(this.sql, args, this.db);
  }

  async first<T = any>(): Promise<T | null> {
    return this.db.executeFirst<T>(this.sql, this.params);
  }

  async all<T = any>(): Promise<{ results: T[] }> {
    return this.db.executeAll<T>(this.sql, this.params);
  }

  async run(): Promise<{ success: boolean }> {
    return this.db.executeRun(this.sql, this.params);
  }
}
