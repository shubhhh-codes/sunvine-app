import { verifyCompactJwt } from '../crypto.js';
import { errorResponse } from '../utils/error.js';

export const requireDealer = async (c: any, next: () => Promise<void>) => {
  const authHeader = c.req.header('authorization') || '';
  if (!authHeader.toLowerCase().startsWith('bearer ')) {
    const err = errorResponse('REAUTH_REQUIRED', 'Authentication required.', 401);
    return c.json(err.body, err.status);
  }

  const token = authHeader.slice(7).trim();
  const verifyResult = await verifyCompactJwt(token, c.env.APP_JWT_SECRET);
  if (!verifyResult.valid || !verifyResult.payload) {
    const err = errorResponse('REAUTH_REQUIRED', 'Invalid or expired token.', 401);
    return c.json(err.body, err.status);
  }

  const payload = verifyResult.payload;
  if (payload.role !== 'dealer') {
    const err = errorResponse('ROLE_NOT_ALLOWED', 'Access restricted to dealers.', 403);
    return c.json(err.body, err.status);
  }

  c.set('dealerId', payload.dealer_id);
  await next();
};
