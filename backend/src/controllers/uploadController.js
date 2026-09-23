'use strict';

const { getImageKitAuthParams } = require('../config/imagekit');

/**
 * POST /api/uploads/auth
 *
 * Returns ImageKit upload authentication parameters so the Flutter client
 * can upload files directly to ImageKit without ever seeing the private key.
 *
 * The response contains:
 *   - token     — random UUID
 *   - expire    — Unix timestamp (30 min from now)
 *   - signature — HMAC-SHA1 of (token + expire) signed with the private key
 *   - publicKey — ImageKit public key (safe to share)
 *   - urlEndpoint — ImageKit URL endpoint (safe to share)
 *
 * IMPORTANT: IMAGEKIT_PRIVATE_KEY is used server-side to compute the signature
 * and is NEVER included in the response.
 */
function getUploadAuth(req, res) {
  try {
    const authParams = getImageKitAuthParams(); // 30-minute expiry by default

    return res.status(200).json({
      success: true,
      message: 'Upload auth parameters generated.',
      data: authParams, // already excludes the private key
    });
  } catch (err) {
    console.error('[uploadController.getUploadAuth]', err.message);

    if (err.message.includes('environment variables')) {
      return res.status(503).json({
        success: false,
        message: 'Upload service is not configured. Contact the administrator.',
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Failed to generate upload authentication.',
    });
  }
}

module.exports = { getUploadAuth };
