import { ErrorCode, AppErrorResponse } from '../types.js';

export function errorResponse(
  code: ErrorCode,
  message: string,
  status: 400 | 401 | 403 | 429 | 500 | 502 | 503,
  retryAfter?: number
) {
  const body: AppErrorResponse = { success: false, code, message };
  if (retryAfter !== undefined) {
    body.retryAfter = retryAfter;
  }
  return { body, status };
}
