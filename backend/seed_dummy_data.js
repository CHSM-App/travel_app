/**
 * Seed dummy data for agency AGY-005 (admin_id=7, mobile=8262878298).
 * Run: node seed_dummy_data.js
 * Delete after use.
 */

require('dotenv').config();
const mssql = require('mssql');
const sql   = mssql;

const sqlConfig = {
  user: 'travel_admin', password: 'Travel@admin_123',
  server: 'winsome.grabweb.in', database: 'travel_agency', port: 5691,
  options: { encrypt: true, trustServerCertificate: true },
  connectionTimeout: 15000, requestTimeout: 30000,
};

const AGENCY_ID = 'AGY-005';

// ── helpers ──────────────────────────────────────────────────────────────────
function dt(offsetDays, hour = 10) {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  const pad = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(hour)}:00:00`;
}

// ── seed data ─────────────────────────────────────────────────────────────────

const VEHICLES = [
  { name: 'Swift Dzire',   number: 'GA-01-AA-1234', TypeId: 1, capacity: 4, FuelTypeId: 1, mileage: '18',  StatusId: 1, per_km_charge: 12, puc_expiry: '2025-12-31', insurance_expiry: '2025-11-30' },
  { name: 'Toyota Innova', number: 'GA-02-BB-5678', TypeId: 2, capacity: 7, FuelTypeId: 2, mileage: '14',  StatusId: 1, per_km_charge: 18, puc_expiry: '2025-10-31', insurance_expiry: '2026-01-31' },
  { name: 'Maruti Ertiga', number: 'GA-03-CC-9012', TypeId: 3, capacity: 7, FuelTypeId: 1, mileage: '16',  StatusId: 1, per_km_charge: 15, puc_expiry: '2026-03-31', insurance_expiry: '2026-02-28' },
];

const DRIVERS = [
  { name: 'Ramesh Naik',   phone: '9876543210', address: 'Vengurla, Goa',    licenceNo: 'GA0120231234', licenceExpiry: '2027-06-30' },
  { name: 'Suresh Dessai', phone: '9823456781', address: 'Sindhudurg, MH',   licenceNo: 'MH0420225678', licenceExpiry: '2026-09-15' },
  { name: 'Vijay Gawas',   phone: '9765432109', address: 'Sawantwadi, MH',   licenceNo: 'MH0220249012', licenceExpiry: '2028-03-10' },
];

const CUSTOMERS = [
  { name: 'Anil Patil',   phone: '9000011111', address: 'Pune, MH',        LicenceNo: 'MH1220221111', LicenceExpiry: '2027-01-01' },
  { name: 'Priya Shetty', phone: '9000022222', address: 'Mumbai, MH',      LicenceNo: 'MH0120232222', LicenceExpiry: '2026-05-20' },
  { name: 'Rohit Kamat',  phone: '9000033333', address: 'Belgaum, KA',     LicenceNo: 'KA0420243333', LicenceExpiry: '2028-11-11' },
];

// Trip statuses (from sp_trip behaviour observed in routes):
//   3 = Upcoming, 2 = Active, 4 = Complete/History, 5 = Cancelled, 1 = Unpaid
const TRIP_TEMPLATES = [
  { label: 'Upcoming #1',   pickup: 'Vengurla',  drop: 'Panaji',       dist: 95,  start: dt(3),   end: dt(3,18),  status: 3, amount: 1140, charges: { toll: 50,  repair: 0,   driver: 200, fuel: 190  } },
  { label: 'Upcoming #2',   pickup: 'Sawantwadi',drop: 'Kolhapur',     dist: 110, start: dt(5),   end: dt(5,20),  status: 3, amount: 1650, charges: { toll: 80,  repair: 0,   driver: 300, fuel: 220  } },
  { label: 'Active',        pickup: 'Vengurla',  drop: 'Goa Airport',  dist: 80,  start: dt(0,8), end: dt(0,16),  status: 2, amount: 960,  charges: { toll: 40,  repair: 0,   driver: 150, fuel: 160  } },
  { label: 'Unpaid',        pickup: 'Kudal',     drop: 'Pune',         dist: 350, start: dt(-5),  end: dt(-4),    status: 1, amount: 5250, charges: { toll: 200, repair: 0,   driver: 500, fuel: 700  } },
  { label: 'History #1',    pickup: 'Vengurla',  drop: 'Mumbai',       dist: 520, start: dt(-10), end: dt(-9),    status: 4, amount: 7800, charges: { toll: 300, repair: 500, driver: 700, fuel: 1040 } },
  { label: 'History #2',    pickup: 'Panaji',    drop: 'Belgaum',      dist: 180, start: dt(-3),  end: dt(-3,20), status: 4, amount: 2700, charges: { toll: 100, repair: 0,   driver: 300, fuel: 360  } },
  { label: 'Cancelled',     pickup: 'Vengurla',  drop: 'Hubli',        dist: 200, start: dt(1),   end: dt(2),     status: 5, amount: 3000, charges: { toll: 0,   repair: 0,   driver: 0,   fuel: 0    } },
];

// ── main ──────────────────────────────────────────────────────────────────────
(async () => {
  let pool;
  try {
    pool = await mssql.connect(sqlConfig);
    console.log('✅ DB connected\n');

    // 1. Vehicles
    const vehicleIds = [];
    for (const v of VEHICLES) {
      const r = await pool.request()
        .input('operation',        sql.NVarChar,      'Update')
        .input('vehicleid',        sql.Int,            0)
        .input('name',             sql.VarChar,        v.name)
        .input('number',           sql.VarChar,        v.number)
        .input('TypeId',           sql.Int,            v.TypeId)
        .input('capacity',         sql.Int,            v.capacity)
        .input('FuelTypeId',       sql.Int,            v.FuelTypeId)
        .input('mileage',          sql.VarChar,        v.mileage)
        .input('StatusId',         sql.Int,            v.StatusId)
        .input('rcdocument',       sql.VarChar,        '')
        .input('agency_id',        sql.VarChar,        AGENCY_ID)
        .input('per_km_charge',    sql.Decimal(10,2),  v.per_km_charge)
        .input('puc_expiry',       sql.Date,           v.puc_expiry)
        .input('insurance_expiry', sql.Date,           v.insurance_expiry)
        .execute('sp_Vehicle');
      const row = r.recordset[0];
      vehicleIds.push(row.vehicleid || row.vehicle_id || row.id);
      console.log(`🚗 Vehicle inserted: ${v.name} (${v.number}) → id=${JSON.stringify(row)}`);
    }

    // 2. Drivers
    const driverIds = [];
    for (let i = 0; i < DRIVERS.length; i++) {
      const d = DRIVERS[i];
      const r = await pool.request()
        .input('operation',     sql.NVarChar, 'Update')
        .input('driverId',      sql.Int,       0)
        .input('name',          sql.NVarChar,  d.name)
        .input('phone',         sql.NVarChar,  d.phone)
        .input('address',       sql.NVarChar,  d.address)
        .input('licenceNo',     sql.NVarChar,  d.licenceNo)
        .input('licenceExpiry', sql.Date,      d.licenceExpiry)
        .input('vehicle_id',    sql.Int,       vehicleIds[i] || null)
        .input('documents',     sql.NVarChar,  '')
        .input('agency_id',     sql.NVarChar,  AGENCY_ID)
        .execute('sp_driver');
      const row = r.recordset[0];
      driverIds.push(row.driverId || row.driver_id || row.id);
      console.log(`👤 Driver inserted: ${d.name} → id=${JSON.stringify(row)}`);
    }

    // 3. Customers
    const customerIds = [];
    for (const c of CUSTOMERS) {
      const r = await pool.request()
        .input('operation',    sql.NVarChar, 'Update')
        .input('customer_id',  sql.Int,       0)
        .input('name',         sql.NVarChar,  c.name)
        .input('phone',        sql.NVarChar,  c.phone)
        .input('address',      sql.NVarChar,  c.address)
        .input('LicenceNo',    sql.NVarChar,  c.LicenceNo)
        .input('LicenceExpiry',sql.Date,      c.LicenceExpiry)
        .input('agency_id',    sql.NVarChar,  AGENCY_ID)
        .input('id_proof',     sql.NVarChar,  '')
        .execute('sp_Customer');
      const row = r.recordset[0];
      customerIds.push(row.customer_id || row.customerId || row.id);
      console.log(`🧑 Customer inserted: ${c.name} → id=${JSON.stringify(row)}`);
    }

    console.log('\nvehicleIds:', vehicleIds);
    console.log('driverIds:', driverIds);
    console.log('customerIds:', customerIds);

    // 4. Trips
    console.log('\nInserting trips...');
    for (let i = 0; i < TRIP_TEMPLATES.length; i++) {
      const t   = TRIP_TEMPLATES[i];
      const vid = vehicleIds[i % vehicleIds.length];
      const did = driverIds[i % driverIds.length];
      const cid = customerIds[i % customerIds.length];

      if (!vid || !cid) {
        console.warn(`⚠️  Skipping trip "${t.label}" — missing vehicleId or customerId`);
        continue;
      }

      await pool.request()
        .input('operation',          sql.NVarChar,      'Update')
        .input('trip_id',            sql.Int,            0)
        .input('vehicle_id',         sql.Int,            vid)
        .input('driver_id',          sql.Int,            did || null)
        .input('pickup_location',    sql.NVarChar(50),   t.pickup)
        .input('drop_location',      sql.NVarChar(50),   t.drop)
        .input('distance',           sql.Decimal(7,2),   t.dist)
        .input('fuel_required',      sql.Decimal(7,2),   +(t.dist / 15).toFixed(2))
        .input('toll_charges',       sql.Decimal(10,2),  t.charges.toll)
        .input('repairing_charges',  sql.Decimal(10,2),  t.charges.repair)
        .input('driver_charges',     sql.Decimal(10,2),  t.charges.driver)
        .input('fuel_charges',       sql.Decimal(10,2),  t.charges.fuel)
        .input('start_datetime',     sql.NVarChar(50),   t.start)
        .input('end_datetime',       sql.NVarChar(50),   t.end)
        .input('booking_date',       sql.NVarChar(50),   t.start.split(' ')[0])
        .input('status',             sql.Int,            t.status)
        .input('Customer_id',        sql.Int,            cid)
        .input('amount_approve',     sql.Decimal(10,2),  t.amount)
        .input('agency_id',          sql.NVarChar(20),   AGENCY_ID)
        .input('is_return_trip',     sql.Int,            0)
        .execute('sp_trip');
      console.log(`🗺️  Trip inserted: "${t.label}" (${t.pickup} → ${t.drop}, status=${t.status})`);
    }

    console.log('\n✅ All dummy data inserted successfully!');
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  } finally {
    if (pool) await pool.close();
  }
})();
