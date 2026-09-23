'use strict';

const express = require('express');
const { getUploadAuth } = require('../controllers/uploadController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/uploads/auth
 *
 * Returns ImageKit upload authentication parameters.
 * Requires a valid device JWT — only registered devices can upload.
 * The ImageKit private key is NEVER included in the response.
 */
router.post('/auth', requireAuth, getUploadAuth);

module.exports = router;
