'use strict';

const express = require('express');
const { saveMetadata, saveMetadataValidators } = require('../controllers/mediaController');
const { requireAuth } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

/**
 * POST /api/media/metadata
 *
 * Stores ImageKit URL + file metadata after the client has completed a direct upload.
 * Requires a valid device JWT.
 */
router.post('/metadata', requireAuth, saveMetadataValidators, validate, saveMetadata);

module.exports = router;
