'use strict';

const { body } = require('express-validator');
const Device = require('../models/Device');
const { signDeviceToken } = require('../middleware/auth');
const { isValidDeviceId } = require('../utils/deviceId');

// ─── Validators ────────────────────────────────────────────────────────────

const PERMISSION_STATUSES = [
  'granted',
  'denied',
  'permanently_denied',
  'limited',
  'unavailable',
  'unknown',
];

const BIOMETRIC_STATUSES = ['available', 'unavailable', 'unknown'];

/** Shared validators for the permissions sub-object */
function permissionValidators() {
  return [
    body('permissions.photos')
      .optional()
      .isIn(PERMISSION_STATUSES)
      .withMessage(`permissions.photos must be one of: ${PERMISSION_STATUSES.join(', ')}`),
    body('permissions.videos')
      .optional()
      .isIn(PERMISSION_STATUSES)
      .withMessage(`permissions.videos must be one of: ${PERMISSION_STATUSES.join(', ')}`),
    body('permissions.files')
      .optional()
      .isIn(PERMISSION_STATUSES)
      .withMessage(`permissions.files must be one of: ${PERMISSION_STATUSES.join(', ')}`),
    body('permissions.contacts')
      .optional()
      .isIn(PERMISSION_STATUSES)
      .withMessage(`permissions.contacts must be one of: ${PERMISSION_STATUSES.join(', ')}`),
    body('permissions.biometric')
      .optional()
      .isIn(BIOMETRIC_STATUSES)
      .withMessage(`permissions.biometric must be one of: ${BIOMETRIC_STATUSES.join(', ')}`),
  ];
}

const registerValidators = [
  body('deviceId')
    .trim()
    .notEmpty()
    .withMessage('deviceId is required')
    .isLength({ max: 128 })
    .withMessage('deviceId must be ≤ 128 characters')
    .custom((v) => {
      if (!isValidDeviceId(v)) throw new Error('deviceId contains invalid characters');
      return true;
    }),
  body('manufacturer').optional().trim().isLength({ max: 128 }),
  body('model').optional().trim().isLength({ max: 128 }),
  body('androidVersion').optional().trim().isLength({ max: 32 }),
  body('androidSdk').optional().isInt({ min: 0, max: 99 }).toInt(),
  body('appVersion').optional().trim().isLength({ max: 32 }),
  body('buildNumber').optional().trim().isLength({ max: 32 }),
  ...permissionValidators(),
];

const updatePermissionsValidators = [
  body('photos')
    .optional()
    .isIn(PERMISSION_STATUSES)
    .withMessage(`photos must be one of: ${PERMISSION_STATUSES.join(', ')}`),
  body('videos')
    .optional()
    .isIn(PERMISSION_STATUSES)
    .withMessage(`videos must be one of: ${PERMISSION_STATUSES.join(', ')}`),
  body('files')
    .optional()
    .isIn(PERMISSION_STATUSES)
    .withMessage(`files must be one of: ${PERMISSION_STATUSES.join(', ')}`),
  body('contacts')
    .optional()
    .isIn(PERMISSION_STATUSES)
    .withMessage(`contacts must be one of: ${PERMISSION_STATUSES.join(', ')}`),
  body('biometric')
    .optional()
    .isIn(BIOMETRIC_STATUSES)
    .withMessage(`biometric must be one of: ${BIOMETRIC_STATUSES.join(', ')}`),
];

// ─── Handlers ──────────────────────────────────────────────────────────────

/**
 * POST /api/devices/register
 * Creates or updates a device record. Returns a device JWT.
 */
async function registerDevice(req, res) {
  try {
    const {
      deviceId,
      manufacturer,
      model,
      androidVersion,
      androidSdk,
      appVersion,
      buildNumber,
      permissions,
    } = req.body;

    const device = await Device.findOneAndUpdate(
      { deviceId },
      {
        $set: {
          manufacturer,
          model,
          androidVersion,
          androidSdk,
          appVersion,
          buildNumber,
          ...(permissions && { permissions }),
        },
      },
      {
        new: true,        // return the updated document
        upsert: true,     // create if it doesn't exist
        runValidators: true,
        setDefaultsOnInsert: true,
      }
    );

    // Issue a long-lived device token for authenticated routes
    let token;
    try {
      token = signDeviceToken(deviceId);
    } catch (_) {
      // JWT is optional — if secret not configured, proceed without token
      token = null;
    }

    return res.status(200).json({
      success: true,
      message: 'Device registered successfully.',
      data: {
        deviceId: device.deviceId,
        ...(token && { token }),
        registeredAt: device.createdAt,
        updatedAt: device.updatedAt,
      },
    });
  } catch (err) {
    console.error('[deviceController.registerDevice]', err.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to register device.',
    });
  }
}

/**
 * PATCH /api/devices/:deviceId/permissions
 * Updates only the permissions sub-document of an existing device.
 */
async function updatePermissions(req, res) {
  try {
    const { deviceId } = req.params;

    if (!isValidDeviceId(deviceId)) {
      return res.status(400).json({ success: false, message: 'Invalid deviceId.' });
    }

    const { photos, videos, files, contacts, biometric } = req.body;

    // Build a partial $set — only update fields that were actually sent
    const permissionUpdates = {};
    if (photos !== undefined)    permissionUpdates['permissions.photos']    = photos;
    if (videos !== undefined)    permissionUpdates['permissions.videos']    = videos;
    if (files !== undefined)     permissionUpdates['permissions.files']     = files;
    if (contacts !== undefined)  permissionUpdates['permissions.contacts']  = contacts;
    if (biometric !== undefined) permissionUpdates['permissions.biometric'] = biometric;

    if (Object.keys(permissionUpdates).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No permission fields provided.',
      });
    }

    const device = await Device.findOneAndUpdate(
      { deviceId },
      { $set: permissionUpdates },
      { new: true, runValidators: true }
    );

    if (!device) {
      return res.status(404).json({
        success: false,
        message: 'Device not found. Register the device first.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Permissions updated.',
      data: { permissions: device.permissions },
    });
  } catch (err) {
    console.error('[deviceController.updatePermissions]', err.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to update permissions.',
    });
  }
}

/**
 * GET /api/devices/:deviceId
 * Returns device record. Requires a valid device JWT.
 */
async function getDevice(req, res) {
  try {
    const { deviceId } = req.params;

    if (!isValidDeviceId(deviceId)) {
      return res.status(400).json({ success: false, message: 'Invalid deviceId.' });
    }

    const device = await Device.findOne({ deviceId }).lean();

    if (!device) {
      return res.status(404).json({
        success: false,
        message: 'Device not found.',
      });
    }

    // Strip internal Mongoose fields before returning
    const { __v, _id, ...safe } = device;

    return res.status(200).json({
      success: true,
      message: 'Device retrieved.',
      data: safe,
    });
  } catch (err) {
    console.error('[deviceController.getDevice]', err.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve device.',
    });
  }
}

module.exports = {
  registerDevice,
  updatePermissions,
  getDevice,
  registerValidators,
  updatePermissionsValidators,
};
