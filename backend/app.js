const express = require('express');
const createError = require('http-errors');
const path = require('path');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
require('dotenv').config({ path: __dirname + '/.env' });


// Routers
const insertRouter = require('./routes/insert');
const usersRouter = require('./routes/users');
const fileAccess = require('./routes/fileAccess');
const loginRouter = require('./routes/login');
const uploadRouter = require('./routes/uploadfile');
const indexRouter = require('./routes/index');
const healthRouter = require('./routes/health');
// Auth middleware
const protect = require('./routes/middleware/protect');
// DB
const db = require('./routes/db');
// Daily reminders (FCM push)
const cron = require('node-cron');
const reminders = require('./routes/reminders');

const app = express();

/* =========================
   APP CONFIG
========================= */
app.set('trust proxy', true);
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

app.use(cors());
app.use(logger('dev'));
//app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

/* =========================
   ROUTES
========================= */

// Public routes — no token required
app.use('/health', healthRouter);
app.use('/login', loginRouter);

// Public self-registration: AddAdmin must be reachable before the user has a
// token (gated client-side by WhatsApp OTP). Every other /insert/* route stays
// protected.
const PUBLIC_INSERT_PATHS = ['/AddAdmin'];
app.use('/insert', (req, res, next) => {
  if (PUBLIC_INSERT_PATHS.includes(req.path)) return next();
  return protect(req, res, next);
}, insertRouter);

// Protected routes — valid JWT access token required
app.use('/users',   protect, usersRouter);
app.use('/file',    protect, fileAccess);

// Uploads: POSTs (creating files) require a valid token. GET (serving files)
// is public so Image.network can render them without an auth header — safe
// because filenames carry a 128-bit random token, making URLs unguessable.
app.use('/upload', (req, res, next) => {
  if (req.method === 'GET') return next();
  return protect(req, res, next);
}, uploadRouter);

app.use('/index',   protect, indexRouter);

/* =========================
   BACKGROUND TASKS
========================= */
async function cleanupRefreshTokens() {
  try {
    await db.request()
      .input('operation', 'AutoTask')
      .execute('ManageRefreshToken');
    console.log('✔ Refresh tokens cleaned');
  } catch (err) {
    console.error('❌ Cleanup Error:', err);
  }
}

async function generateBill() {
  try {
    await db.request().execute('gen_bill');
    console.log('✔ Bills generated');
  } catch (err) {
    console.error('❌ Bill Error:', err);
  }
}

// Run once on startup
cleanupRefreshTokens();
generateBill();

// Run every 24 hours
setInterval(cleanupRefreshTokens, 24 * 60 * 60 * 1000);
setInterval(generateBill, 24 * 60 * 60 * 1000);

// Daily reminder push at 23:00 IST (11 PM, night before) — tomorrow's trips +
// PUC/insurance expiring within 7 days, sent to each agency's registered devices.
cron.schedule('0 23 * * *', () => {
  reminders.sendDailyReminders().catch((err) =>
    console.error('❌ Daily reminder error:', err.message)
  );
}, { timezone: 'Asia/Kolkata' });

/* =========================
   SPA CATCH-ALL (landing page / React Router)
========================= */
// Serve the built landing page (public/index.html) for any unmatched GET so
// client-side routes like /privacy, /help, /delete-account work on direct load
// and refresh. API routes are mounted above and known API prefixes are excluded
// here, so genuine API misses still fall through to the JSON 404 below.
const SPA_API_PREFIXES = ['/health', '/login', '/insert', '/users', '/file', '/upload', '/index'];
app.get('*', (req, res, next) => {
  if (SPA_API_PREFIXES.some((p) => req.path === p || req.path.startsWith(p + '/'))) {
    return next();
  }
  res.set('Cache-Control', 'no-store, no-cache, must-revalidate');
  res.sendFile(path.join(__dirname, 'public', 'index.html'), (err) => {
    if (err) next();
  });
});

/* =========================
   404 HANDLER
========================= */
app.use((req, res, next) => {
  next(createError(404, 'Route not found'));
});

/* =========================
   ERROR HANDLER
========================= */
app.use((err, req, res, next) => {
  console.error('🔥 Error:', err);

  if (res.headersSent) return next(err);

  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
  });
});

/* =========================
   SERVER START
========================= */
const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

module.exports = app;
