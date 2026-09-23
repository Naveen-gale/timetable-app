'use strict';

const { body } = require('express-validator');
const Media = require('../models/Media');
const { isValidDeviceId } = require('../utils/deviceId');

// ─── Validators ────────────────────────────────────────────────────────────

const MEDIA_TYPES = ['photo', 'video', 'file'];

const saveMetadataValidators = [
  body('deviceId')
    .trim()
    .notEmpty()
    .withMessage('deviceId is required')
    .custom((v) => {
      if (!isValidDeviceId(v)) throw new Error('deviceId contains invalid characters');
      return true;
    }),
  body('type')
    .trim()
    .notEmpty()
    .withMessage('type is required')
    .isIn(MEDIA_TYPES)
    .withMessage(`type must be one of: ${MEDIA_TYPES.join(', ')}`),
  body('fileName')
    .trim()
    .notEmpty()
    .withMessage('fileName is required')
    .isLength({ max: 512 })
    .withMessage('fileName must be ≤ 512 characters'),
  body('imageKitUrl')
    .trim()
    .notEmpty()
    .withMessage('imageKitUrl is required')
    .isURL({ require_tld: false })
    .withMessage('imageKitUrl must be a valid URL'),
  body('mimeType').optional().trim().isLength({ max: 128 }),
  body('size').optional().isInt({ min: 0 }).toInt(),
  body('imageKitFileId').optional().trim().isLength({ max: 256 }),
];

// ─── Handler ───────────────────────────────────────────────────────────────

/**
 * POST /api/media/metadata
 *
 * Called by the Flutter client after it has successfully uploaded a file to
 * ImageKit. Stores the returned URL and metadata in MongoDB.
 */
async function saveMetadata(req, res) {
  try {
    const {
      deviceId,
      type,
      fileName,
      mimeType,
      size,
      imageKitUrl,
      imageKitFileId,
    } = req.body;

    const media = await Media.create({
      deviceId,
      type,
      fileName,
      mimeType,
      size,
      imageKitUrl,
      imageKitFileId,
    });

    return res.status(201).json({
      success: true,
      message: 'Media metadata saved.',
      data: {
        id: media._id,
        deviceId: media.deviceId,
        type: media.type,
        fileName: media.fileName,
        imageKitUrl: media.imageKitUrl,
        createdAt: media.createdAt,
      },
    });
  } catch (err) {
    console.error('[mediaController.saveMetadata]', err.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to save media metadata.',
    });
  }
}

module.exports = { saveMetadata, saveMetadataValidators };
