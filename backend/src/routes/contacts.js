'use strict';

const express = require('express');
const { saveContacts, saveContactsValidators } = require('../controllers/contactController');
const { requireAuth } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

/**
 * POST /api/contacts
 *
 * Stores user-authorised contacts sent by the Flutter client.
 * Requires a valid device JWT.
 */
router.post('/', requireAuth, saveContactsValidators, validate, saveContacts);

module.exports = router;
