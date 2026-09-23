'use strict';

const mongoose = require('mongoose');

/**
 * Allowed permission status values across the app.
 * Mirrors the values Flutter will send.
 */
const PERMISSION_STATUSES = [
  'granted',
  'denied',
  'permanently_denied',
  'limited',
  'unavailable',
  'unknown',
];

const permissionsSchema = new mongoose.Schema(
  {
    photos:    { type: String, enum: PERMISSION_STATUSES, default: 'unknown' },
    videos:    { type: String, enum: PERMISSION_STATUSES, default: 'unknown' },
    files:     { type: String, enum: PERMISSION_STATUSES, default: 'unknown' },
    contacts:  { type: String, enum: PERMISSION_STATUSES, default: 'unknown' },
    biometric: { type: String, enum: ['available', 'unavailable', 'unknown'], default: 'unknown' },
  },
  { _id: false }
);

const deviceSchema = new mongoose.Schema(
  {
    // App-generated UUID — used as the primary identifier instead of IMEI
    deviceId: {
      type: String,
      required: [true, 'deviceId is required'],
      unique: true,
      trim: true,
      maxlength: [128, 'deviceId must be ≤ 128 characters'],
    },

    manufacturer: { type: String, trim: true, maxlength: 128, default: 'Unknown' },
    model:        { type: String, trim: true, maxlength: 128, default: 'Unknown' },

    androidVersion: { type: String, trim: true, maxlength: 32 },
    androidSdk:     { type: Number, min: 0, max: 99 },

    appVersion:  { type: String, trim: true, maxlength: 32 },
    buildNumber: { type: String, trim: true, maxlength: 32 },

    permissions: { type: permissionsSchema, default: () => ({}) },
  },
  {
    timestamps: true, // adds createdAt + updatedAt automatically
  }
);

// Index on deviceId is already unique; add one more for time-based queries
deviceSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Device', deviceSchema);
