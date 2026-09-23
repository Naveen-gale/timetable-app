'use strict';

const { body } = require('express-validator');
const Contact = require('../models/Contact');
const { isValidDeviceId } = require('../utils/deviceId');

// ─── Validators ────────────────────────────────────────────────────────────

const saveContactsValidators = [
  body('deviceId')
    .trim()
    .notEmpty()
    .withMessage('deviceId is required')
    .custom((v) => {
      if (!isValidDeviceId(v)) throw new Error('deviceId contains invalid characters');
      return true;
    }),
  body('contacts')
    .isArray({ min: 1, max: 500 })
    .withMessage('contacts must be a non-empty array of up to 500 items'),
  body('contacts.*.name')
    .trim()
    .notEmpty()
    .withMessage('Each contact must have a name')
    .isLength({ max: 256 })
    .withMessage('Contact name must be ≤ 256 characters'),
  body('contacts.*.phones')
    .optional()
    .isArray()
    .withMessage('phones must be an array'),
  body('contacts.*.phones.*')
    .optional()
    .isString()
    .isLength({ max: 32 })
    .withMessage('Each phone number must be a string of ≤ 32 characters'),
];

// ─── Handler ───────────────────────────────────────────────────────────────

/**
 * POST /api/contacts
 *
 * Stores contacts that the user explicitly authorised the Flutter app to sync.
 * Accepts a batch of contacts for a given deviceId.
 *
 * Uses bulkWrite with upsert to avoid duplicating records across multiple syncs.
 */
async function saveContacts(req, res) {
  try {
    const { deviceId, contacts } = req.body;

    if (!Array.isArray(contacts) || contacts.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'contacts array is required and must not be empty.',
      });
    }

    // Upsert each contact by (deviceId + name) — simple deduplication
    const ops = contacts.map((c) => ({
      updateOne: {
        filter: { deviceId, name: c.name.trim() },
        update: {
          $set: {
            phones: Array.isArray(c.phones)
              ? c.phones.map(String).slice(0, 20) // cap per-contact phone count
              : [],
          },
        },
        upsert: true,
      },
    }));

    const result = await Contact.bulkWrite(ops, { ordered: false });

    return res.status(200).json({
      success: true,
      message: 'Contacts saved.',
      data: {
        inserted: result.upsertedCount,
        updated:  result.modifiedCount,
        total:    contacts.length,
      },
    });
  } catch (err) {
    console.error('[contactController.saveContacts]', err.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to save contacts.',
    });
  }
}

module.exports = { saveContacts, saveContactsValidators };
