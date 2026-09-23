'use strict';

const { v4: uuidv4 } = require('uuid');

/**
 * Validates that a deviceId string is a non-empty, safe identifier.
 * Accepts UUID v4 or any alphanumeric+hyphen+underscore string up to 128 chars.
 *
 * @param {string} id
 * @returns {boolean}
 */
function isValidDeviceId(id) {
  if (typeof id !== 'string') return false;
  if (id.length === 0 || id.length > 128) return false;
  // Allow UUID v4 and general safe identifiers
  return /^[a-zA-Z0-9\-_]+$/.test(id);
}

/**
 * Generates a new random UUID v4 to use as a device identifier.
 * Called by the Flutter client on first run; stored in SharedPreferences.
 *
 * @returns {string}
 */
function generateDeviceId() {
  return uuidv4();
}

module.exports = { isValidDeviceId, generateDeviceId };
