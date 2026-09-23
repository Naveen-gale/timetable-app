'use strict';

const express = require('express');
const {
  registerDevice,
  updatePermissions,
  getDevice,
  registerValidators,
  updatePermissionsValidators,
} = require('../controllers/deviceController');
const { requireAuth } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

/**
 * POST /api/devices/register
 * Public — no auth required (device registers itself on first run).
 */
router.post('/register', registerValidators, validate, registerDevice);

/**
 * PATCH /api/devices/:deviceId/permissions
 * Requires a valid device JWT (received after registration).
 */
router.patch(
  '/:deviceId/permissions',
  requireAuth,
  updatePermissionsValidators,
  validate,
  updatePermissions
);

/**
 * GET /api/devices/:deviceId
 * Requires a valid device JWT.
 */
router.get('/:deviceId', requireAuth, getDevice);

module.exports = router;
