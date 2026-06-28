/*
 * WhatsApp OTP Service — travel_app
 * Adapted from billing_software/backend/src/whatsapp.js (OTP section only)
 *
 * Uses SMSala WhatsApp API to send OTP for:
 *   - 'register' : new user registration verification
 *   - 'forgot_pin': admin PIN reset
 *
 * Set WHATSAPP_ENABLED=true in .env to deliver real messages.
 * When disabled, OTP is generated + saved to DB but not sent (dev mode).
 *
 * OTP is stored as SHA-256 hash — plain text never touches the DB.
 */

const https  = require('https');
const crypto = require('crypto');
const sql    = require('mssql');
const db     = require('./db');   // travel_app pool (already connected promise)

require('dotenv').config();

const API_TOKEN    = process.env.WHATSAPP_API_TOKEN || '';
const ENABLED      = process.env.WHATSAPP_ENABLED === 'true';
const OTP_TEMPLATE = process.env.WHATSAPP_TPL_OTP  || '';

const OTP_EXPIRY_MINUTES = 10;
const OTP_LENGTH         = 6;
const IST_OFFSET_MS      = 5.5 * 60 * 60 * 1000; // SQL Server GETDATE() returns IST

function nowIst() {
  return new Date(Date.now() + IST_OFFSET_MS);
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone normaliser — returns "91XXXXXXXXXX" or null
// ─────────────────────────────────────────────────────────────────────────────

function normalisePhone(raw) {
  if (!raw) return null;
  const digits = String(raw).replace(/\D/g, '');
  if (digits.length === 10)                             return `91${digits}`;
  if (digits.length === 12 && digits.startsWith('91')) return digits;
  if (digits.length === 11 && digits.startsWith('0'))  return `91${digits.slice(1)}`;
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP generator — cryptographically random 6-digit string
// ─────────────────────────────────────────────────────────────────────────────

function generateOtp() {
  const buf = crypto.randomBytes(4);
  const num = buf.readUInt32BE(0) % 1_000_000;
  return String(num).padStart(OTP_LENGTH, '0');
}

// ─────────────────────────────────────────────────────────────────────────────
// HTTP helper — JSON POST to api2.smsala.com
// ─────────────────────────────────────────────────────────────────────────────

function postJson(path, body) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(body);
    const options = {
      hostname: 'api2.smsala.com',
      path,
      method: 'POST',
      headers: {
        'Content-Type':   'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    };
    const req = https.request(options, res => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch { resolve({ raw: data }); }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DB helpers — use sp_otp stored procedure
// ─────────────────────────────────────────────────────────────────────────────

async function saveOtp(phone, otpCode, purpose) {
  const otpHash  = crypto.createHash('sha256').update(otpCode).digest('hex');
  const expiresAt = new Date(nowIst().getTime() + OTP_EXPIRY_MINUTES * 60 * 1000);

  // Invalidate previous unused OTPs for this phone+purpose, then insert new one
  await (await db).request()
    .input('operation',  sql.NVarChar(20), 'invalidate')
    .input('phone',      sql.NVarChar(20), phone)
    .input('purpose',    sql.NVarChar(20), purpose)
    .input('otp_hash',   sql.NVarChar(64), null)
    .input('expires_at', sql.DateTime,     null)
    .execute('sp_otp');

  await (await db).request()
    .input('operation',  sql.NVarChar(20), 'save')
    .input('phone',      sql.NVarChar(20), phone)
    .input('purpose',    sql.NVarChar(20), purpose)
    .input('otp_hash',   sql.NVarChar(64), otpHash)
    .input('expires_at', sql.DateTime,     expiresAt)
    .execute('sp_otp');
}

async function updateSendStatus(phone, purpose, status, campaignId, errorDetail) {
  try {
    await (await db).request()
      .input('operation',    sql.NVarChar(20),  'updateStatus')
      .input('phone',        sql.NVarChar(20),  phone       || null)
      .input('purpose',      sql.NVarChar(20),  purpose     || null)
      .input('otp_hash',     sql.NVarChar(64),  null)
      .input('expires_at',   sql.DateTime,      null)
      .input('status',       sql.NVarChar(20),  status      || 'sent')
      .input('campaign_id',  sql.NVarChar(100), campaignId  ? String(campaignId) : null)
      .input('error_detail', sql.NVarChar(500), errorDetail || null)
      .execute('sp_otp');
  } catch (e) {
    console.warn('[OTP] DB status update failed:', e.message);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// sendOtp — generates, stores hash, and delivers OTP via WhatsApp
//
// purpose: 'register' | 'forgot_pin'
// ─────────────────────────────────────────────────────────────────────────────

async function sendOtp(phone, purpose) {
  const normPhone = normalisePhone(phone);
  if (!normPhone) throw new Error('Invalid phone number.');

  const otpCode = generateOtp();
  await saveOtp(normPhone, otpCode, purpose);

  if (!ENABLED) {
    // Dev mode: skip delivery, log plain OTP so developer can test without a real phone
    console.info(`[OTP] WhatsApp disabled — OTP for ${normPhone} (${purpose}): ${otpCode}`);
    return {
      sent: false,
      dev_otp: process.env.NODE_ENV !== 'production' ? otpCode : undefined,
    };
  }

  if (!API_TOKEN) throw new Error('WhatsApp API token not configured.');

  let result;
  try {
    result = await postJson('/whatsapp/SendOtp', {
      PhoneNumber: normPhone,
      OtpCode:     otpCode,
      ApiToken:    API_TOKEN,
      TemplateId:  OTP_TEMPLATE || undefined,
    });
  } catch (err) {
    await updateSendStatus(normPhone, purpose, 'failed', null, err.message);
    throw new Error('Failed to send OTP. Please try again.');
  }

  const success = result.IsSuccess === true || result.ErrorCode === 0;
  await updateSendStatus(
    normPhone, purpose,
    success ? 'sent' : 'failed',
    result.ReturnData,
    success ? null : (result.ErrorDescription || JSON.stringify(result)),
  );

  if (!success) throw new Error(result.ErrorDescription || 'OTP delivery failed.');

  console.info(`[OTP] Sent to ${normPhone} (${purpose}) — CampaignId: ${result.ReturnData}`);
  return { sent: true };
}

// ─────────────────────────────────────────────────────────────────────────────
// verifyOtp — validates OTP hash, marks it used on success
//
// Returns true if valid, false if wrong/expired/already-used
// ─────────────────────────────────────────────────────────────────────────────

async function verifyOtp(phone, otpCode, purpose) {
  const normPhone = normalisePhone(phone);
  if (!normPhone) return false;

  const otpHash = crypto.createHash('sha256').update(String(otpCode)).digest('hex');

  const result = await (await db).request()
    .input('operation',  sql.NVarChar(20), 'verify')
    .input('phone',      sql.NVarChar(20), normPhone)
    .input('purpose',    sql.NVarChar(20), purpose)
    .input('otp_hash',   sql.NVarChar(64), otpHash)
    .input('expires_at', sql.DateTime,     nowIst())
    .execute('sp_otp');

  const rows = result.recordset || [];
  if (rows.length === 0) return false;

  // Mark as used
  await (await db).request()
    .input('operation',  sql.NVarChar(20), 'markUsed')
    .input('phone',      sql.NVarChar(20), normPhone)
    .input('purpose',    sql.NVarChar(20), purpose)
    .input('otp_hash',   sql.NVarChar(64), otpHash)
    .input('expires_at', sql.DateTime,     null)
    .execute('sp_otp');

  return true;
}

module.exports = { sendOtp, verifyOtp, normalisePhone };
