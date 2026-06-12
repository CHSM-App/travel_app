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
// DB
const db = require('./routes/db');

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
   ROUTES (NO PROTECT)
========================= */


app.use('/insert', insertRouter);
app.use('/users', usersRouter);
app.use('/file', fileAccess);
app.use('/login', loginRouter);
app.use('/upload', uploadRouter);
app.use('/index', indexRouter);

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
const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

module.exports = app;
