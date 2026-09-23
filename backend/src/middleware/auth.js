'use strict';

const jwt = require('jsonwebtoken');

/**
 * Optional JWT authentication middleware.
 *
 * Routes that require a valid device token should use this middleware.
 * Routes that must be public (e.g. /health, /api/devices/register) should NOT use it.
 *
 * Expects: Authorization: Bearer <token>
 *
 * On success:  attaches req.device = { deviceId } and calls next()
 * On failure:  returns 401 with a safe error message
 */
function requireAuth(req, res, next) {
  const authHeader = req.headers['authorization'] || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Authentication token is required.',
    });
  }

  const secret = process.env.JWT_SECRET;
  if (!secret) {
    // Server misconfiguration — do not reveal internals to the client
    console.error('[Auth] JWT_SECRET is not configured.');
    return res.status(500).json({
      success: false,
      message: 'Server configuration error.',
    });
  }

  try {
    const payload = jwt.verify(token, secret);
    req.device = { deviceId: payload.deviceId };
    return next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token.',
    });
  }
}

/**
 * Generates a signed JWT for a registered device.
 * @param {string} deviceId
 * @returns {string} signed JWT
 */
function signDeviceToken(deviceId) {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('JWT_SECRET is not configured.');

  return jwt.sign({ deviceId }, secret, {
    expiresIn: '365d', // long-lived device token; revocation handled by re-registration
    issuer: 'timetable-backend',
  });
}

module.exports = { requireAuth, signDeviceToken };
