
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
require('dotenv').config();

const sql = require('mssql');   // ✅ ADD THIS LINE
const db = require('./db'); // your mssql pool wrapper
const crypto = require('crypto');
var bodyParser = require('body-parser');
const path = require('path');

const axios = require("axios");

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
        success: false,
        message: "Mobile No and Password required"
      });
    }

    const result = await db.request()
      .input("operation", sql.NVarChar, "Login")
      .input("mobile", sql.NVarChar(20), mobile)
      .input("password", sql.NVarChar(50), password)
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


// =====================================================
// FORGOT PASSWORD
// =====================================================
router.post("/forgotPassword", async (req, res) => {

  try {

    const { mobile, password } = req.body;

    if (!mobile || !password) {
      return res.status(400).json({
        success: false,
        message: "mobile no and new password required"
      });
    }

    const result = await db.request()
      .input("operation", sql.NVarChar, "ForgotPassword")
      .input("admin_id", sql.Int, 0)
      .input("name", sql.NVarChar(50), "")
      .input("email", sql.NVarChar(50), "")
      .input("mobile", sql.NVarChar(20), mobile)
      .input("password", sql.NVarChar(50), password)
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




module.exports = router; 