'use strict';

const mongoose = require('mongoose');

/**
 * Stores contacts that the user explicitly authorised the Flutter app to sync.
 * Only name + phone numbers are stored — minimal PII.
 */
const contactSchema = new mongoose.Schema(
  {
    deviceId: {
      type: String,
      required: [true, 'deviceId is required'],
      trim: true,
      index: true,
    },

    name: {
      type: String,
      required: [true, 'name is required'],
      trim: true,
      maxlength: [256, 'name must be ≤ 256 characters'],
    },

    // Array of phone number strings — E.164 or local format as provided
    phones: {
      type: [String],
      default: [],
      validate: {
        validator: (arr) => arr.every((p) => typeof p === 'string' && p.length <= 32),
        message: 'Each phone number must be a string of ≤ 32 characters',
      },
    },
  },
  {
    timestamps: true,
  }
);

contactSchema.index({ deviceId: 1, name: 1 });

module.exports = mongoose.model('Contact', contactSchema);
