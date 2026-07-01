var express = require('express');
var router = express.Router();
var db = require('./db');
var sql = require('mssql');  // <--- add this line

// ================= DELETE VEHICLE =================
router.delete('/deleteVehicles/:vehicleid', async (req, res) => {
  try {

    const vehicleid = req.params.vehicleid;

    // validation
    if (!vehicleid) {
      return res.status(400).json({
        status: 0,
        message: "vehicleid is required"
      });
    }

    const pool = await db.connect();

    const result = await pool.request()
      .input('operation', sql.NVarChar, 'DELETE')
      .input('vehicleid', sql.Int, vehicleid)
      .execute('sp_vehicle');

    const response = result.recordset[0];

    return res.status(200).json({
      status: response.status,
      message: response.message
    });

  } catch (error) {

    console.error("Delete Vehicle Error:", error);

    return res.status(500).json({
      status: 0,
      message: "Server error",
      error: error.message
    });

  }
});

// ================= DELETE DRIVER =================
router.delete('/deleteDrivers/:driverId', async (req, res) => {
  try {

    const driverId = req.params.driverId;

    if (!driverId) {
      return res.status(400).json({
        status: 0,
        message: "driverId is required"
      });
    }

    const pool = await db.connect();

    const result = await pool.request()
      .input('operation', sql.NVarChar, 'DELETE')
      .input('driverId', sql.Int, driverId)
      .execute('sp_driver');

    const response = result.recordset[0];

    return res.status(200).json({
      status: response.status,
      message: response.message
    });

  } catch (error) {

    console.error("Delete Driver Error:", error);

    return res.status(500).json({
      status: 0,
      message: "Server error",
      error: error.message
    });

  }
});

// ================= DELETE CUSTOMER =================
router.delete('/deleteCustomers/:customer_id', async (req, res) => {
  try {

    const customer_id = req.params.customer_id;

    if (!customer_id) {
      return res.status(400).json({
        status: 0,
        message: "customer_id is required"
      });
    }

    const pool = await db.connect();

    const result = await pool.request()
      .input('operation', sql.NVarChar, 'DELETE')
      .input('customer_id', sql.Int, customer_id)
      .execute('sp_Customer');

    const response = result.recordset[0];

    return res.status(200).json({
      status: response.status,
      message: response.message
    });

  } catch (error) {

    console.error("Delete Customer Error:", error);

    return res.status(500).json({
      status: 0,
      message: "Server error",
      error: error.message
    });

  }
});

router.delete('/deleteService/:service_id', async (req, res) => {
  try {
    const { service_id } = req.params;
    const result = await db.request()
      .input('operation', 'DeleteService')
      .input('service_id', service_id)
      .execute('sp_Vehicle');
    res.json(result.recordset?.[0] ?? { success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router; 