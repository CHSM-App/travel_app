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

  // Active vehicles with PUC expiring today..+7 days (per-vehicle rows).
  const pucVeh = await db.request().query(`
    SELECT agency_id, name, number, puc_expiry
    FROM   dbo.vehicles
    WHERE  active_status = 0
      AND  agency_id IS NOT NULL
      AND  puc_expiry IS NOT NULL
      AND  puc_expiry BETWEEN CAST(GETDATE() AS DATE)
                          AND DATEADD(DAY, ${EXPIRY_DAYS}, CAST(GETDATE() AS DATE))
  `);

  // Active vehicles with Insurance expiring today..+7 days (per-vehicle rows).
  const insVeh = await db.request().query(`
    SELECT agency_id, name, number, insurance_expiry
    FROM   dbo.vehicles
    WHERE  active_status = 0
      AND  agency_id IS NOT NULL
      AND  insurance_expiry IS NOT NULL
      AND  insurance_expiry BETWEEN CAST(GETDATE() AS DATE)
                                AND DATEADD(DAY, ${EXPIRY_DAYS}, CAST(GETDATE() AS DATE))
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
  const ensure = (id) =>
    (map[id] = map[id] || { agency_id: id, trips: 0, puc: [], ins: [], lic: 0 });
  for (const r of trips.recordset) ensure(r.agency_id).trips = r.cnt;
  for (const r of pucVeh.recordset) {
    ensure(r.agency_id).puc.push({ name: r.name, number: r.number, expiry: r.puc_expiry });
  }
  for (const r of insVeh.recordset) {
    ensure(r.agency_id).ins.push({ name: r.name, number: r.number, expiry: r.insurance_expiry });
  }
  for (const r of drv.recordset) ensure(r.agency_id).lic = r.lic_cnt;

  return Object.values(map).filter(
    (a) => a.trips > 0 || a.puc.length > 0 || a.ins.length > 0 || a.lic > 0
  );
}

function vehicleLabel(v) {
  return v.name ? `${v.name} (${v.number})` : v.number;
}

// Builds one notification per concern (trips / PUC / insurance) instead of a
// single combined summary, so each shows up as a separate push notification.
function composeMessages(a) {
  const messages = [];

  if (a.trips > 0) {
    messages.push({
      title: 'Trips Tomorrow',
      body: `${a.trips} trip${a.trips > 1 ? 's' : ''} scheduled tomorrow`,
      type: 'trip_reminder',
    });
  }

  if (a.puc.length > 0) {
    messages.push({
      title: 'PUC Expiry Reminder',
      body: `PUC expiring within ${EXPIRY_DAYS} days: ${a.puc.map(vehicleLabel).join(', ')}`,
      type: 'puc_reminder',
    });
  }

  if (a.ins.length > 0) {
    messages.push({
      title: 'Insurance Expiry Reminder',
      body: `Insurance expiring within ${EXPIRY_DAYS} days: ${a.ins.map(vehicleLabel).join(', ')}`,
      type: 'insurance_reminder',
    });
  }

  if (a.lic > 0) {
    messages.push({
      title: 'Licence Expiry Reminder',
      body: `${a.lic} driver licence${a.lic > 1 ? 's' : ''} expiring within ${EXPIRY_DAYS} days`,
      type: 'licence_reminder',
    });
  }

  return messages;
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

// Sends one push notification per concern (trips / PUC / insurance / licence)
// to every agency that has something to report.
async function sendDailyReminders() {
  const agencies = await buildAgencyReminders();
  let notifications = 0;

  for (const a of agencies) {
    const tokens = await tokensForAgency(a.agency_id);
    if (!tokens.length) continue;

    for (const { title, body, type } of composeMessages(a)) {
      const res = await fcm.sendToTokens(tokens, title, body, {
        type,
        agency_id: a.agency_id,
      });
      if (res.invalidTokens.length) await removeInvalidTokens(res.invalidTokens);
      notifications += res.successCount;
    }
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

  const messages = a
    ? composeMessages(a)
    : [{
        title: 'Daily Reminder',
        body: 'No trips tomorrow and no documents expiring in the next 7 days. (Test message)',
        type: 'daily_reminder',
      }];

  let sent = 0;
  let failed = 0;
  const bodies = [];
  for (const { title, body, type } of messages) {
    const res = await fcm.sendToTokens(tokens, title, body, { type, agency_id: agencyId });
    if (res.invalidTokens.length) await removeInvalidTokens(res.invalidTokens);
    sent += res.successCount;
    failed += res.failureCount;
    bodies.push(body);
  }

  return { sent, failed, body: bodies.join(' | ') };
}

module.exports = { sendDailyReminders, sendReminderForAgency };
