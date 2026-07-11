const express = require('express');
const router = express.Router();
const db = require('./db');

// ================= HEALTH CHECK =================
// Public, unauthenticated. Reports API uptime and database connectivity.
router.get('/', async (req, res) => {
  const health = {
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    database: 'unknown',
  };

  try {
    const pool = await db;
    await pool.request().query('SELECT 1');
    health.database = 'connected';
    return res.status(200).json(health);
  } catch (error) {
    console.error('Health check DB error:', error);
    health.status = 'degraded';
    health.database = 'disconnected';
    return res.status(503).json(health);
  }
});

module.exports = router;
