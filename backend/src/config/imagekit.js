'use strict';

const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

/**
 * Validates that all required ImageKit environment variables are set.
 * Throws a clear error if any are missing so the developer gets an obvious message.
 */
function assertImageKitConfig() {
  const { IMAGEKIT_PRIVATE_KEY, IMAGEKIT_PUBLIC_KEY, IMAGEKIT_URL_ENDPOINT } =
    process.env;

  if (!IMAGEKIT_PRIVATE_KEY || !IMAGEKIT_PUBLIC_KEY || !IMAGEKIT_URL_ENDPOINT) {
    throw new Error(
      'ImageKit environment variables are not fully configured. ' +
        'Set IMAGEKIT_PRIVATE_KEY, IMAGEKIT_PUBLIC_KEY, and IMAGEKIT_URL_ENDPOINT.'
    );
  }
}

/**
 * Generates ImageKit client-side upload authentication parameters.
 *
 * Algorithm documented at:
 * https://imagekit.io/docs/api-reference/upload-file-api/client-side-file-upload
 *
 *   token     — random UUID (used as the message to sign)
 *   expire    — Unix timestamp (seconds) when this auth expires (default: 30 min)
 *   signature — HMAC-SHA1(privateKey, token + expire)
 *
 * IMPORTANT: The private key is used only to compute the signature and is
 * NEVER included in the return value sent to the Flutter client.
 *
 * @param {number} [expirySeconds=1800]  How long (in seconds) until the token expires.
 * @returns {{ token: string, expire: number, signature: string, publicKey: string, urlEndpoint: string }}
 */
function getImageKitAuthParams(expirySeconds = 1800) {
  assertImageKitConfig();

  const { IMAGEKIT_PRIVATE_KEY, IMAGEKIT_PUBLIC_KEY, IMAGEKIT_URL_ENDPOINT } =
    process.env;

  const token  = uuidv4();
  const expire = Math.floor(Date.now() / 1000) + expirySeconds;

  // HMAC-SHA1 with the private key over (token + expire)
  const signature = crypto
    .createHmac('sha1', IMAGEKIT_PRIVATE_KEY)
    .update(token + expire)
    .digest('hex');

  return {
    token,
    expire,
    signature,
    // Return the public key and endpoint so the Flutter client doesn't
    // need to hardcode them — but the private key is intentionally excluded.
    publicKey:   IMAGEKIT_PUBLIC_KEY,
    urlEndpoint: IMAGEKIT_URL_ENDPOINT,
  };
}

module.exports = { getImageKitAuthParams, assertImageKitConfig };
