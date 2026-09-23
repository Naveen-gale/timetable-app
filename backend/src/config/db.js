'use strict';

const mongoose = require('mongoose');

/**
 * Opens the Mongoose connection to MongoDB Atlas.
 * Uses MONGODB_URI from environment variables — never hardcoded.
 */
async function connectDB() {
  const uri = process.env.MONGODB_URI;

  if (!uri) {
    throw new Error(
      'MONGODB_URI is not set. Add it to your .env file or Render environment variables.'
    );
  }

  try {
    await mongoose.connect(uri, {
      // Mongoose 8+ sets these by default, but explicit is clearer
      serverSelectionTimeoutMS: 10000, // 10 s — fail fast on misconfiguration
    });

    console.log('[DB] MongoDB connected:', mongoose.connection.host);
  } catch (err) {
    console.error('[DB] Connection failed:', err.message);
    // Rethrow so server.js can decide whether to exit or retry
    throw err;
  }
}

module.exports = connectDB;
