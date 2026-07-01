/**
 * One-shot seed script: inserts a dummy admin for mobile 8262878298.
 * Run from the backend directory: node seed_dummy_admin.js
 * Delete this file after use.
 */

require('dotenv').config();
const mssql = require('mssql');
const bcrypt = require('bcryptjs');

const sqlConfig = {
  user: 'travel_admin',
  password: 'Travel@admin_123',
  server: 'winsome.grabweb.in',
  database: 'travel_agency',
  port: 5691,
  options: { encrypt: true, trustServerCertificate: true },
  connectionTimeout: 15000,
  requestTimeout: 30000,
};

const DUMMY = {
  name:         'Test Admin',
  email:        'testadmin@vengurlatech.com',
  mobile:       '8262878298',
  pin:          '1234',          // 4-digit PIN — change if needed
  address:      'Test Address, Vengurla',
  agency_name:  'Test Agency',
  city:         'Vengurla',
  per_km_charge: 12.00,
};

(async () => {
  let pool;
  try {
    pool = await mssql.connect(sqlConfig);
    console.log('DB connected');

    const hashedPin = await bcrypt.hash(DUMMY.pin, 10);

    const result = await pool.request()
      .input('operation',      mssql.NVarChar(50),  'Insert')
      .input('admin_id',       mssql.Int,           0)
      .input('name',           mssql.NVarChar(50),  DUMMY.name)
      .input('email',          mssql.NVarChar(50),  DUMMY.email)
      .input('mobile',         mssql.NVarChar(50),  DUMMY.mobile)
      .input('password',       mssql.NVarChar(100), hashedPin)
      .input('address',        mssql.NVarChar(100), DUMMY.address)
      .input('agency_name',    mssql.NVarChar(50),  DUMMY.agency_name)
      .input('city',           mssql.NVarChar(50),  DUMMY.city)
      .input('per_km_charge',  mssql.Decimal(10,2), DUMMY.per_km_charge)
      .execute('sp_admin');

    console.log('Result:', result.recordset);
    console.log('\nDone. Login with mobile=8262878298 PIN=1234');
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  } finally {
    if (pool) await pool.close();
  }
})();
