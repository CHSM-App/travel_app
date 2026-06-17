
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
require('dotenv').config();

const sql = require('mssql');
const db = require('./db');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
var bodyParser = require('body-parser');
const path = require('path');

const axios = require("axios");
const { sendOtp, verifyOtp } = require('./otp');

router.use(bodyParser.json());
router.use(bodyParser.urlencoded({ extended: true }));


function generateRefreshToken() {
  // opaque random token for DB storage + never reveal secret structure
  return crypto.randomBytes(64).toString('hex');
}

// Create tokens helper
function createAccessToken(payload) {
  return jwt.sign(payload, process.env.JWT_SECRET_KEY, { expiresIn: '15m' }); // production: 15m
}
function createRefreshTokenPayload(mobile) {
  // we don't sign this with jwt secret; we'll store opaque token in db
  const token = generateRefreshToken();
  // You can optionally also sign metadata as a jwt for additional checks.
  return token;
}

/**
 * Login (creates access + refresh token)
 * Expect mobile in req.body
 */
router.post('/Createlogin', async (req, res) => {
  try {
    const { mobile, deviceDetails } = req.body;
	 
    //const ip = req.ip || req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress|| null;

    if (!mobile) return res.status(400).json({ error: 'Mobile number required' });

    // Create Access Token (short)
    const accessToken = createAccessToken({ mobile });

    // Create opaque refresh token (store in DB)
    const refreshToken = createRefreshTokenPayload(mobile);
    const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000); // 7 days

    // Insert into DB (using stored proc or parameterized query)
    await db.request()
	   .input('operation', 'insert')
      .input('user_mobile', mobile)
      .input('refresh_token', refreshToken)
      .input('device_info', deviceDetails)
     // .input('ip_address', ip)
      .input('expires_at', expiresAt)
      .execute('ManageRefreshToken'); // or .query(...) if you didn't create proc

    // Send tokens to client (client stores refresh token in secure storage)
    // Optionally set access token in response header
    return res.json({ accessToken, refreshToken, expiresAt });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
});

/**
 * Refresh access token
 * Expect { refresh_token } in req.body
 * Implements rotation: revoke old refresh token, issue new one
 */
router.post('/refreshAccessToken', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken)
      return res.status(400).json({ error: 'Refresh token required' });

    // check token
    const result = await db.request()
      .input('operation', 'get')
      .input('refresh_token', refreshToken)
      .execute('ManageRefreshToken');

    const rows = result.recordset || [];

    if (!rows.length)
      return res.status(403).json({ error: 'Invalid or expired refresh token' });

    const row = rows[0];
    const mobile = row.user_mobile;

    // ✅ revoke old refresh token
    await db.request()
      .input('operation', 'revoke')
      .input('refresh_token', refreshToken)
      .execute('ManageRefreshToken');

    // create new tokens
    const newAccessToken = createAccessToken({ mobile });
    const newRefreshToken = createRefreshTokenPayload(mobile);
    const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000);

    // insert new refresh token
    await db.request()
      .input('operation', 'insert')
      .input('user_mobile', mobile)
      .input('refresh_token', newRefreshToken)
      .input('device_info', row.device_info || null)
      .input('expires_at', expiresAt)
      .execute('ManageRefreshToken');

    res.json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresAt
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Refresh failed' });
  }
});


router.post('/logout', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ error: 'Refresh token required' });

    await db.request()
	  .input('operation', 'revoke')
		.input('refresh_token', refreshToken)
		.execute('ManageRefreshToken');
    return res.json({ success: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Logout failed' });
  }
});






// =====================================================
// LOGIN ADMIN API
// =====================================================
router.post("/Adminlogin", async (req, res) => {

  try {

    const { mobile, password } = req.body;

    if (!mobile || !password) {
      return res.status(400).json({
        success: 0,
        message: "Mobile No and PIN required"
      });
    }

    // PINs are stored as salted bcrypt hashes, which SQL cannot compare. Fetch
    // the admin record (including the stored hash) by mobile, then verify the
    // PIN here with bcrypt.compare.
    const result = await db.request()
      .input("operation", sql.NVarChar, "GetAdminByMobile")
      .input("mobile", sql.NVarChar(20), mobile)
      .execute("sp_admin");

    const admin = result.recordset[0];

    if (!admin) {
      return res.json({ success: 0, message: "Invalid mobile number or PIN" });
    }

    const match = await bcrypt.compare(String(password), admin.password || "");

    if (!match) {
      return res.json({ success: 0, message: "Invalid mobile number or PIN" });
    }

    res.json({
      success: 1,
      message: "Login successful",
      admin_id: admin.admin_id,
      name: admin.name,
      email: admin.email,
      mobile: admin.mobile,
      agency_id: admin.agency_id,
      image_url: admin.image_url,
  
    });

  } catch (err) {

    console.log(err);

    res.status(500).json({
      success: 0,
      message: err.message
    });

  }

});


// =====================================================
// FORGOT PASSWORD
// =====================================================
router.post("/forgotPassword", async (req, res) => {

  try {

    const { mobile, password } = req.body;

    if (!mobile || !password) {
      return res.status(400).json({
        success: false,
        message: "mobile no and new PIN required"
      });
    }

    // Hash the new PIN before storing (same scheme as signup).
    const hashedPassword = await bcrypt.hash(String(password), 10);

    const result = await db.request()
      .input("operation", sql.NVarChar, "ForgotPassword")
      .input("admin_id", sql.Int, 0)
      .input("name", sql.NVarChar(50), "")
      .input("email", sql.NVarChar(50), "")
      .input("mobile", sql.NVarChar(20), mobile)
      .input("password", sql.NVarChar(100), hashedPassword)
      .input("address", sql.NVarChar(100), "")
      .input("agency_name", sql.NVarChar(50), "")
      .input("city", sql.NVarChar(50), "")
      .execute("sp_admin");

    const response = result.recordset[0];

    res.json(response);

  } catch (err) {

    console.log(err);

    res.status(500).json({
      success: false,
      message: err.message
    });

  }

});












//Send OTP
const API_URL = "http://papi.messagebot.in/SendSmsV2";
const API_TOKEN = "L2Uj2dK9ARQrfUy2";
const SOURCE_ID = "SMSALA"; // your approved sender ID

router.post("/send-sms", async (req, res) => {
  const { phone, message, dltEntityId, dltTemplateId } = req.body;

  if (!phone || !message) {
    return res.status(400).json({ error: "phone and message are required" });
  }

  const payload = [
    {
      apiToken: API_TOKEN,
      messageType: "3",            // Transactional
      messageEncoding: "1",        // Text
      destinationAddress: phone,   // e.g. 91XXXXXXXXXX
      sourceAddress: SOURCE_ID,
      messageText: message,
      dltEntityId,
      dltEntityTemplateId: dltTemplateId
    }
  ];

  try {
    const response = await axios.post(API_URL, payload, {
      headers: { "Content-Type": "application/json" }
    });

    return res.json({
      success: true,
      providerResponse: response.data
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      error: err.message,
      details: err.response?.data
    });
  }
});

router.get('/privacy', (req, res) => {
	res.sendFile(path.join(__dirname, 'privacy.html'));
});


// =====================================================
// SEND OTP
// Body: { mobile, purpose }  purpose: 'register' | 'forgot_pin'
// =====================================================
router.post('/sendOtp', async (req, res) => {
  try {
    const { mobile, purpose } = req.body;

    if (!mobile || !purpose) {
      return res.status(400).json({ success: false, message: 'mobile and purpose are required' });
    }

    if (!['register', 'forgot_pin', 'delete_account', 'change_mobile'].includes(purpose)) {
      return res.status(400).json({ success: false, message: "purpose must be 'register', 'forgot_pin', 'delete_account' or 'change_mobile'" });
    }

    // For registration, reject up-front if the mobile already belongs to an
    // account — otherwise the user only finds out after verifying the OTP. This
    // lets the sign-up screen surface the error before navigating to the OTP page.
    if (purpose === 'register') {
      const adminRes = await db.request()
        .input('operation', sql.NVarChar, 'GetAdminByMobile')
        .input('mobile', sql.NVarChar(20), mobile)
        .execute('sp_admin');
      const admin = adminRes.recordset && adminRes.recordset[0];
      if (admin) {
        return res.status(409).json({
          success: false,
          message: 'An account with this mobile number already exists. Please sign in instead.',
        });
      }
    }

    // For account deletion, confirm the mobile belongs to a real account before
    // sending an OTP — otherwise the user gets a code for an account that does
    // not exist and only finds out at the final step.
    if (purpose === 'delete_account') {
      const adminRes = await db.request()
        .input('operation', sql.NVarChar, 'GetAdminByMobile')
        .input('mobile', sql.NVarChar(20), mobile)
        .execute('sp_admin');
      const admin = adminRes.recordset && adminRes.recordset[0];
      if (!admin) {
        return res.status(404).json({ success: false, message: 'No account found for this mobile number.' });
      }

      // If a deletion request is already pending for this number, reject here
      // (no OTP is sent) so the user stays on the phone-number step with an error.
      const pendingRes = await db.request()
        .input('mobile', sql.NVarChar(20), mobile)
        .query(`SELECT TOP 1 scheduled_for FROM dbo.account_deletion_requests
                WHERE mobile = @mobile AND status = 'pending'
                ORDER BY requested_at DESC`);
      const pending = pendingRes.recordset && pendingRes.recordset[0];
      if (pending) {
        // scheduled_for is stored as IST wall-clock; the driver hands it back
        // as a UTC-labelled Date, so render it as-is (timeZone UTC = no shift).
        const schedDate = pending.scheduled_for
          ? new Date(pending.scheduled_for).toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' })
          : null;
        return res.status(409).json({
          success: false,
          message: schedDate
            ? `An account deletion request for this number is already pending (scheduled for deletion by ${schedDate}).`
            : 'An account deletion request for this number is already pending.',
        });
      }
    }

    const result = await sendOtp(mobile, purpose);
    return res.json({ success: true, ...result });
  } catch (err) {
    console.error('[sendOtp]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
});


// =====================================================
// VERIFY OTP
// Body: { mobile, otp, purpose }
// =====================================================
router.post('/verifyOtp', async (req, res) => {
  try {
    const { mobile, otp, purpose } = req.body;

    if (!mobile || !otp || !purpose) {
      return res.status(400).json({ success: false, message: 'mobile, otp, and purpose are required' });
    }

    const valid = await verifyOtp(mobile, otp, purpose);

    if (!valid) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    return res.json({ success: true, message: 'OTP verified' });
  } catch (err) {
    console.error('[verifyOtp]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
});


// =====================================================
// DELETE ACCOUNT (request)
// Used by the website's Delete Account page (Google Play data-deletion
// compliance). Flow:
//   1. /sendOtp       { mobile, purpose: 'delete_account' }  → WhatsApp OTP
//   2. /deleteAccount { mobile, otp, reason? }               → verify + record
//
// We do NOT hard-delete here. The OTP is verified, the admin's details are
// copied into account_deletion_requests with an optional reason, and the user
// is told their account will be deleted within 30 days. The team reviews each
// request and removes the account manually. (Run sql/account_deletion_requests.sql once.)
// =====================================================
router.post('/deleteAccount', async (req, res) => {
  try {
    const { mobile, otp, reason } = req.body;

    if (!mobile || !otp) {
      return res.status(400).json({ success: false, message: 'mobile and otp are required' });
    }

    // 1. Verify the OTP (single-use; consumed on success)
    const valid = await verifyOtp(mobile, otp, 'delete_account');
    if (!valid) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    // 2. Resolve the admin so we can snapshot their details into the request
    const adminRes = await db.request()
      .input('operation', sql.NVarChar, 'GetAdminByMobile')
      .input('mobile', sql.NVarChar(20), mobile)
      .execute('sp_admin');

    const admin = adminRes.recordset && adminRes.recordset[0];
    if (!admin) {
      return res.status(404).json({ success: false, message: 'No account found for this mobile number.' });
    }

    const safeReason = (reason && String(reason).trim().slice(0, 500)) || null;

    // 3. Record the deletion request (reuse a pending one if it already exists)
    const result = await db.request()
      .input('admin_id',    sql.Int,           parseInt(admin.admin_id) || null)
      .input('agency_id',   sql.NVarChar(20),  admin.agency_id   || null)
      .input('name',        sql.NVarChar(100), admin.name        || null)
      .input('email',       sql.NVarChar(100), admin.email       || null)
      .input('mobile',      sql.NVarChar(20),  mobile)
      .input('agency_name', sql.NVarChar(100), admin.agency_name || null)
      .input('city',        sql.NVarChar(100), admin.city        || null)
      .input('reason',      sql.NVarChar(500), safeReason)
      .query(`
        IF EXISTS (SELECT 1 FROM dbo.account_deletion_requests WHERE mobile = @mobile AND status = 'pending')
        BEGIN
          UPDATE dbo.account_deletion_requests
            SET reason = COALESCE(@reason, reason)
          WHERE mobile = @mobile AND status = 'pending';
          SELECT TOP 1 scheduled_for FROM dbo.account_deletion_requests
          WHERE mobile = @mobile AND status = 'pending' ORDER BY requested_at DESC;
        END
        ELSE
        BEGIN
          -- Store IST wall-clock (server reviews these by hand). +330 min from
          -- UTC is IST regardless of the SQL server's own timezone setting.
          DECLARE @now DATETIME = DATEADD(MINUTE, 330, GETUTCDATE());
          INSERT INTO dbo.account_deletion_requests
            (admin_id, agency_id, name, email, mobile, agency_name, city, reason, status, requested_at, scheduled_for)
          OUTPUT INSERTED.scheduled_for
          VALUES
            (@admin_id, @agency_id, @name, @email, @mobile, @agency_name, @city, @reason, 'pending', @now, DATEADD(DAY, 30, @now));
        END
      `);

    const scheduled = result.recordset && result.recordset[0] && result.recordset[0].scheduled_for;

    return res.json({
      success: true,
      message: 'Your account deletion request has been received. Your account will be deleted within 30 days.',
      scheduled_for: scheduled || null,
    });
  } catch (err) {
    console.error('[deleteAccount]', err);
    return res.status(500).json({ success: false, message: err.message });
  }
});


module.exports = router;