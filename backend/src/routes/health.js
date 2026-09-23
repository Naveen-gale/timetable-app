'use strict';

const express = require('express');

const router = express.Router();

/**
 * GET /health
 *
 * Public liveness check. Always returns 200 so Render's health check passes
 * even during a brief DB reconnect. The `db` field in the response body shows
 * whether MongoDB is currently connected.
 */
router.get('/', (req, res) => {
  const dbConnected =
    typeof req.app.locals.isDbConnected === 'function'
      ? req.app.locals.isDbConnected()
      : false;

  res.status(200).json({
    success: true,
    message: 'Backend is running',
    db: dbConnected ? 'connected' : 'disconnected',
  });
});

module.exports = router;
