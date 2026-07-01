/*
 * Daily reminder builder + sender (FCM push).
 *
 * Per agency, gathers:
 *   - count of trips scheduled to START tomorrow (excluding Complete=4, Cancelled=5)
 *   - count of active vehicles whose PUC expires within 7 days
 *   - count of active vehicles whose Insurance expires within 7 days
 *   - count of active drivers whose Licence expires within 7 days
 * and pushes a summary notification to that agency's registered devices.
 *
 * Trip/expiry dates are user-entered local (IST) values compared against the
 * SQL server clock (IST) via GETDATE() — correct here. (UTC-vs-GETDATE only
 * matters for Node-written timestamps like OTP expiry; see sql/ notes.)
 */

const db = require('./db');
const fcm = require('./fcm');

const EXPIRY_DAYS = 7;

async function buildAgencyReminders() {
  // Trips starting tomorrow (IST calendar day), not complete/cancelled.
  const trips = await db.request().query(`
    SELECT agency_id, COUNT(*) AS cnt
    FROM   dbo.trips
    WHERE  CAST(start_datetime AS DATE) = CAST(DATEADD(DAY, 1, GETDATE()) AS DATE)
      AND  status NOT IN (4, 5)
      AND  agency_id IS NOT NULL
    GROUP BY agency_id
  `);

  // Active vehicles with PUC / insurance expiring today..+7 days.
  const veh = await db.request().query(`
    SELECT agency_id,
      SUM(CASE WHEN puc_expiry IS NOT NULL
               AND puc_expiry BETWEEN CAST(GETDATE() AS DATE)
                                  AND DATEADD(DAY, ${EXPIRY_DAYS}, CAST(GETDATE() AS DATE))
               THEN 1 ELSE 0 END) AS puc_cnt,
      SUM(CASE WHEN insurance_expiry IS NOT NULL
               AND insurance_expiry BETWEEN CAST(GETDATE() AS DATE)
                                        AND DATEADD(DAY, ${EXPIRY_DAYS}, CAST(GETDATE() AS DATE))
               THEN 1 ELSE 0 END) AS ins_cnt
    FROM   dbo.vehicles
    WHERE  active_status = 0
      AND  agency_id IS NOT NULL
    GROUP BY agency_id
  `);

  // Active drivers whose licence expires today..+7 days.
  const drv = await db.request().query(`
    SELECT agency_id, COUNT(*) AS lic_cnt
    FROM   dbo.drivers
    WHERE  active_status = 0
      AND  agency_id IS NOT NULL
      AND  LicenceExpiry IS NOT NULL
      AND  LicenceExpiry BETWEEN CAST(GETDATE() AS DATE)
                             AND DATEADD(DAY, ${EXPIRY_DAYS}, CAST(GETDATE() AS DATE))
    GROUP BY agency_id
  `);

  const map = {};
  const ensure = (id) => (map[id] = map[id] || { agency_id: id, trips: 0, puc: 0, ins: 0, lic: 0 });
  for (const r of trips.recordset) ensure(r.agency_id).trips = r.cnt;
  for (const r of veh.recordset) {
    ensure(r.agency_id).puc = r.puc_cnt;
    ensure(r.agency_id).ins = r.ins_cnt;
  }
  for (const r of drv.recordset) ensure(r.agency_id).lic = r.lic_cnt;

  return Object.values(map).filter((a) => a.trips > 0 || a.puc > 0 || a.ins > 0 || a.lic > 0);
}

function composeMessage(a) {
  const parts = [];
  if (a.trips > 0) parts.push(`${a.trips} trip${a.trips > 1 ? 's' : ''} scheduled tomorrow`);
  if (a.puc > 0) parts.push(`${a.puc} PUC${a.puc > 1 ? 's' : ''} expiring within ${EXPIRY_DAYS} days`);
  if (a.ins > 0) parts.push(`${a.ins} insurance ${a.ins > 1 ? 'policies' : 'policy'} expiring within ${EXPIRY_DAYS} days`);
  if (a.lic > 0) parts.push(`${a.lic} driver licence${a.lic > 1 ? 's' : ''} expiring within ${EXPIRY_DAYS} days`);
  return { title: 'Daily Reminder', body: parts.join('  •  ') };
}

async function tokensForAgency(agencyId) {
  const r = await db.request()
    .input('operation', 'listByAgency')
    .input('agency_id', agencyId)
    .execute('sp_device_token');
  return r.recordset.map((x) => x.fcm_token).filter(Boolean);
}

async function removeInvalidTokens(tokens) {
  for (const t of tokens) {
    try {
      await db.request().input('operation', 'remove').input('fcm_token', t).execute('sp_device_token');
    } catch (e) {
      console.warn('[reminders] failed to purge token:', e.message);
    }
  }
}

// Sends the daily summary to every agency that has something to report.
async function sendDailyReminders() {
  const agencies = await buildAgencyReminders();
  let notifications = 0;

  for (const a of agencies) {
    const tokens = await tokensForAgency(a.agency_id);
    if (!tokens.length) continue;

    const { title, body } = composeMessage(a);
    const res = await fcm.sendToTokens(tokens, title, body, {
      type: 'daily_reminder',
      agency_id: a.agency_id,
    });
    if (res.invalidTokens.length) await removeInvalidTokens(res.invalidTokens);
    notifications += res.successCount;
  }

  console.log(`[reminders] agencies=${agencies.length} notifications_sent=${notifications}`);
  return { agencies: agencies.length, notifications };
}

// On-demand send for one agency (used by the test endpoint). Always sends
// something so the user can verify delivery even on a quiet day.
async function sendReminderForAgency(agencyId) {
  const tokens = await tokensForAgency(agencyId);
  if (!tokens.length) return { sent: 0, reason: 'no registered devices for this agency' };

  const agencies = await buildAgencyReminders();
  const a = agencies.find((x) => x.agency_id === agencyId);

  const msg = a
    ? composeMessage(a)
    : { title: 'Daily Reminder', body: 'No trips tomorrow and no documents expiring in the next 7 days. (Test message)' };

  const res = await fcm.sendToTokens(tokens, msg.title, msg.body, {
    type: 'daily_reminder',
    agency_id: agencyId,
  });
  if (res.invalidTokens.length) await removeInvalidTokens(res.invalidTokens);

  return { sent: res.successCount, failed: res.failureCount, body: msg.body };
}

module.exports = { sendDailyReminders, sendReminderForAgency };
