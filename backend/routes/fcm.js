/*
 * Firebase Cloud Messaging helper for the travel_app.
 *
 * Initializes firebase-admin once from serviceAccountKey.json and exposes a
 * single multicast sender. Initialization is guarded: if the key is missing or
 * invalid the server still boots — sends become no-ops and are logged, so the
 * rest of the API keeps working until a valid key is dropped in.
 *
 * IMPORTANT: serviceAccountKey.json must belong to THIS app's Firebase project
 * (vego-6b986). A key for any other project (e.g. society-management-32053 or
 * travelapp-d1a9c) will init fine but every send fails because the device
 * tokens belong to a different project.
 */

const admin = require('firebase-admin');
const path = require('path');

let initialized = false;
try {
  const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));
  if (!admin.apps.length) {
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  }
  initialized = true;
  console.log('[FCM] initialized for project:', serviceAccount.project_id);
} catch (e) {
  console.warn('[FCM] NOT initialized — push sends disabled:', e.message);
}

/**
 * Send one notification to many device tokens.
 * @returns {Promise<{successCount:number, failureCount:number, invalidTokens:string[]}>}
 */
async function sendToTokens(tokens, title, body, data = {}) {
  const empty = { successCount: 0, failureCount: 0, invalidTokens: [] };
  if (!initialized) {
    console.warn('[FCM] skip send — not initialized');
    return empty;
  }
  if (!Array.isArray(tokens) || tokens.length === 0) return empty;

  // FCM data values must all be strings.
  const stringData = {};
  for (const [k, v] of Object.entries(data)) stringData[k] = String(v);

  const message = {
    notification: { title, body },
    data: stringData,
    tokens,
    android: {
      priority: 'high',
      notification: { channelId: 'daily_reminders' },
    },
  };

  const resp = await admin.messaging().sendEachForMulticast(message);

  // Collect tokens FCM says are dead so the caller can purge them.
  const invalidTokens = [];
  resp.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error && r.error.code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/invalid-argument'
      ) {
        invalidTokens.push(tokens[i]);
      }
    }
  });

  return { successCount: resp.successCount, failureCount: resp.failureCount, invalidTokens };
}

module.exports = { sendToTokens, isReady: () => initialized };
