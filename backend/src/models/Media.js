'use strict';

const mongoose = require('mongoose');

/**
 * Supported media types the Flutter client can upload.
 * Files are uploaded to ImageKit; only metadata is stored here.
 */
const MEDIA_TYPES = ['photo', 'video', 'file'];

const mediaSchema = new mongoose.Schema(
  {
    deviceId: {
      type: String,
      required: [true, 'deviceId is required'],
      trim: true,
      index: true,
    },

    type: {
      type: String,
      required: [true, 'type is required'],
      enum: { values: MEDIA_TYPES, message: 'type must be photo, video, or file' },
    },

    fileName: {
      type: String,
      required: [true, 'fileName is required'],
      trim: true,
      maxlength: [512, 'fileName must be ≤ 512 characters'],
    },

    mimeType: {
      type: String,
      trim: true,
      maxlength: 128,
    },

    // File size in bytes
    size: {
      type: Number,
      min: 0,
    },

    // Public URL returned by ImageKit after upload
    imageKitUrl: {
      type: String,
      required: [true, 'imageKitUrl is required'],
      trim: true,
    },

    // ImageKit's internal file ID (useful for deletion/management)
    imageKitFileId: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

mediaSchema.index({ deviceId: 1, createdAt: -1 });

module.exports = mongoose.model('Media', mediaSchema);
