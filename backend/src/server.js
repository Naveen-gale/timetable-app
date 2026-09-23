'use strict';

// ─── Load environment variables FIRST ─────────────────────────────────────
require('dotenv').config();

const express = require('express');
const helmet  = require('helmet');
const cors    = require('cors');
const morgan  = require('morgan');

const connectDB  = require('./config/db');
const healthRoute  = require('./routes/health');
const devicesRoute = require('./routes/devices');
const uploadsRoute = require('./routes/uploads');
const mediaRoute   = require('./routes/media');
const contactsRoute = require('./routes/contacts');

// ─── App ──────────────────────────────────────────────────────────────────

const app = express();

// ─── Security headers ─────────────────────────────────────────────────────
app.use(helmet());

// ─── CORS ─────────────────────────────────────────────────────────────────
//
// Flutter on Android communicates over HTTPS to Render.
// In development, also allow local traffic.
//
// For a production private app (not a public API), you can lock this down
// further by specifying the Render domain. For now we allow all origins
// because the Flutter HTTP client does not send an Origin header on Android.
app.use(
  cors({
    origin: '*',
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// ─── Body parsing ─────────────────────────────────────────────────────────
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));

// ─── Logging ──────────────────────────────────────────────────────────────
const logFormat = process.env.NODE_ENV === 'production' ? 'combined' : 'dev';
app.use(morgan(logFormat));

// ─── Routes ───────────────────────────────────────────────────────────────

app.use('/health',       healthRoute);
app.use('/api/devices',  devicesRoute);
app.use('/api/uploads',  uploadsRoute);
app.use('/api/media',    mediaRoute);
app.use('/api/contacts', contactsRoute);

// ─── 404 handler ──────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ success: false, message: 'Route not found.' });
});

// ─── Global error handler ─────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error('[Unhandled error]', err);
  // Never leak stack traces or internal messages in production
  const message =
    process.env.NODE_ENV === 'production'
      ? 'An unexpected error occurred.'
      : err.message || 'An unexpected error occurred.';
  res.status(500).json({ success: false, message });
});

// ─── Start ────────────────────────────────────────────────────────────────

const PORT = parseInt(process.env.PORT || '10000', 10);

// Track DB connection state for readiness probes
let dbConnected = false;

// Expose DB state so routes can check it if needed
app.locals.isDbConnected = () => dbConnected;

async function start() {
  // Attempt MongoDB connection — non-fatal so /health still works
  try {
    await connectDB();
    dbConnected = true;
  } catch (err) {
    console.warn(
      '[Server] MongoDB unavailable — starting without DB. ' +
        'API routes requiring the database will return 503.\n  Reason:',
      err.message
    );
  }

  // Render requires binding to 0.0.0.0
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`[Server] TTAPP backend running on port ${PORT}`);
    console.log(`[Server] Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`[Server] DB connected: ${dbConnected}`);
    console.log(`[Server] Health check: http://localhost:${PORT}/health`);
  });
}

start();
