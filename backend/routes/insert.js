var express = require('express');
var db = require("./db");
const sql = require('mssql');
const bcrypt = require('bcryptjs');
var router = express.Router();
var bodyParser = require('body-parser');
router.use(bodyParser.json());
/*const auth = require('./middleware/auth');*/
router.use(bodyParser.urlencoded({ extended: true }));

//-----------TRAVELS APP POST API----------------------//
router.post('/Addtripbooking', async (req, res) => {
  try {
    console.log("REQ BODY ===>", req.body);

    const {
      vehicleid,
      driverid,
      pickuplocation,
      droplocation,
      distance,
      fuelrequired,
      tollcharges,
      repairingcharges,
      drivercharges,
      fuelcharges,
      startdatetime,
      enddatetime,
      status,
      Customerid,
      tripcharges,
      bookingdate,
		agency_id,
      is_return_trip
    } = req.body;

    if (!vehicleid)  {
      return res.status(400).json({
        success: false,
        message: "vehicleid is required"
      });
    }
	  if (!Customerid) {
      return res.status(400).json({
        success: false,
        message: "Customerid is required"
      });
    }

  await db.request()
  .input("operation", sql.NVarChar, "Update")
  .input("trip_id", sql.Int, 0)
  .input("vehicle_id", sql.Int, vehicleid)
  .input("driver_id", sql.Int, driverid)
  .input("pickup_location", sql.NVarChar(50), pickuplocation)
  .input("drop_location", sql.NVarChar(50), droplocation)
  .input("distance", sql.Decimal(7,2), distance)
  .input("fuel_required", sql.Decimal(7,2), fuelrequired)
  .input("toll_charges", sql.Decimal(10,2), tollcharges)
  .input("repairing_charges", sql.Decimal(10,2), repairingcharges)
  .input("driver_charges", sql.Decimal(10,2), drivercharges)
  .input("fuel_charges", sql.Decimal(10,2), fuelcharges || 0)
  .input("start_datetime", sql.NVarChar(50), startdatetime)
.input("end_datetime", sql.NVarChar(50), enddatetime)
.input("booking_date", sql.NVarChar(50), bookingdate)
	 // .input("start_datetime", sql.DateTime, startdatetime ? new Date(startdatetime) : null)
//.input("end_datetime", sql.DateTime, enddatetime ? new Date(enddatetime) : null)
//.input("booking_date", sql.DateTime, bookingdate ? new Date(bookingdate) : null)
  .input("status", sql.Int, status)
  .input("Customer_id", sql.Int, Customerid)
  .input("amount_approve", sql.Decimal(10,2), tripcharges)
	  .input("agency_id", sql.NVarChar(20), agency_id)
  .input("is_return_trip", sql.Int, is_return_trip ? 1 : 0)
 // .input("booking_date", sql.DateTime, bookingdate)
  .execute("sp_trip");


    res.json({
      success: true,
      message: "Trip inserted successfully"
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});


router.post('/updateTripbooking/:trip_id', async (req, res) => {
  try {
    const { trip_id } = req.params;

  const {
  vehicleid,
  driverid,
  Customerid,
  pickuplocation,
  droplocation,
  distance,
  fuelrequired,
  fuelcharges,
  tripcharges,
  startdatetime,
  enddatetime,
  bookingdate,
  agency_id,
  is_return_trip
} = req.body;

    const result = await db.request()
      .input('operation', 'Update')
      .input('trip_id', trip_id)
      .input('vehicle_id', vehicleid)
      .input('driver_id', driverid)
      .input('Customer_id', Customerid)
      .input('pickup_location', pickuplocation)
      .input('drop_location', droplocation)
      .input('distance', distance)
      .input('fuel_required', fuelrequired)
      .input('fuel_charges', fuelcharges || 0)
      .input('amount_approve', tripcharges)
      .input('start_datetime', startdatetime)
      .input('end_datetime', enddatetime)
      .input('booking_date', bookingdate)
      .input('agency_id', agency_id)
      .input('is_return_trip', sql.Int, is_return_trip ? 1 : 0)
      .execute('sp_trip');

    res.json({
      success: true,
      message: "Trip updated successfully",
      data: result.recordset
    });

  } catch (err) {
    console.log(err);
    res.status(500).json({
      success: false,
      error: err.message
    });
  }
});


router.post('/updatePaymentStatus', async (req, res) => {
  try {

    const {
      trip_id,
      toll_charges,
      repairing_charges,
      driver_charges,
      fuel_charges,
      amount_received,
	  payment_mode
    } = req.body;

    // validation
    if (!trip_id) {
      return res.status(400).json({
        success: false,
        message: "trip_id is required"
      });
    }

    await db.request()
      .input("operation", "unpaidToPaid")
      .input("trip_id", sql.Int, trip_id)
      .input("toll_charges", sql.Decimal(10,2), toll_charges || 0)
      .input("repairing_charges", sql.Decimal(10,2), repairing_charges || 0)
      .input("driver_charges", sql.Decimal(10,2), driver_charges || 0)
      .input("fuel_charges", sql.Decimal(10,2), fuel_charges || 0)
      .input("amount_received", sql.Decimal(10,2), amount_received || 0)
	  .input("payment_mode", sql.NVarChar(100), payment_mode)
      .execute("sp_trip");

    res.json({
      success: true,
      message: `Trip moved to the history successfully ${trip_id}`
    });

  } catch (err) {

    res.status(500).json({
      success: false,
      message: err.message
    });

  }
});

// Ends an ACTIVE trip. End datetime is optional on a booking, so it gets
// stamped here (defaults to "now" when the client doesn't send one). The SP
// (operation 'endTrip') sets end_datetime, saves final charges, and moves the
// trip to unpaid / paid based on amount_received vs the approved amount.
router.post('/endTrip', async (req, res) => {
  try {
    const {
      trip_id,
      end_datetime,
      toll_charges,
      repairing_charges,
      driver_charges,
      fuel_charges,
      amount_received,
	  payment_mode
    } = req.body;

    if (!trip_id) {
      return res.status(400).json({
        success: false,
        message: "trip_id is required"
      });
    }

    await db.request()
      .input("operation", "endTrip")
      .input("trip_id", sql.Int, trip_id)
      // Store the IST wall-clock the client sent as a literal string (same as
      // start_datetime in Addtripbooking). Passing it through `new Date()` would
      // re-interpret it via the server timezone and shift the stored time.
      .input("end_datetime", sql.NVarChar(50), end_datetime || null)
      .input("toll_charges", sql.Decimal(10, 2), toll_charges || 0)
      .input("repairing_charges", sql.Decimal(10, 2), repairing_charges || 0)
      .input("driver_charges", sql.Decimal(10, 2), driver_charges || 0)
      .input("fuel_charges", sql.Decimal(10, 2), fuel_charges || 0)
      .input("amount_received", sql.Decimal(10, 2), amount_received || 0)
	   .input("payment_mode", sql.NVarChar(50), payment_mode)
      .execute("sp_trip");

    res.json({
      success: true,
      message: `Trip ${trip_id} ended successfully`
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});



router.post('/cancelTrip/:trip_id', async (req, res) => {
  try {

    const { trip_id } = req.params;

    // validation
    if (!trip_id) {
      return res.status(400).json({
        success: false,
        message: "trip_id is required"
      });
    }

    await db.request()
      .input("operation", "cancelTrip")
      .input("trip_id", trip_id)
      .execute("sp_trip");

    res.json({
      success: true,
      message: `Trip cancelled successfully ${trip_id}`
    });

  } catch (err) {

    res.status(500).json({
      success: false,
      message: err.message
    });

  }
});

router.post('/Addvehicle', async (req, res) => {
  try {

    console.log("REQ BODY ===>", req.body);

    const {
      name,
      number,
      TypeId,
      capacity,
      FuelTypeId,
      mileage,
      StatusId,
      rcdocument,
      agency_id,
      per_km_charge,
      puc_expiry,
      insurance_expiry
    } = req.body;

    if (!number) {
      return res.status(400).json({
        success: false,
        message: "Vehicle Number is required"
      });
    }

    // ✅ STORE RESULT IN VARIABLE
    const result = await db.request()
      .input("operation", sql.NVarChar, "Update")
      .input("vehicleid", sql.Int, 0)
      .input("name", sql.VarChar, name)
      .input("number", sql.VarChar, number)
      .input("TypeId", sql.Int, TypeId)
      .input("capacity", sql.Int, capacity)
      .input("FuelTypeId", sql.Int, FuelTypeId)
      .input("mileage", sql.VarChar, mileage)
      .input("StatusId", sql.Int, StatusId)
      .input("rcdocument", sql.VarChar, rcdocument)
      .input("agency_id", sql.VarChar, agency_id)
      .input("per_km_charge", sql.Decimal(10, 2), per_km_charge || 0)
      .input("puc_expiry", sql.Date, puc_expiry || null)
      .input("insurance_expiry", sql.Date, insurance_expiry || null)
      .execute("sp_Vehicle");

    console.log("SP RESULT ===>", result.recordset);

    // ✅ RETURN VEHICLE ID TO FLUTTER
    res.json(result.recordset[0]);

  } catch (err) {

    console.error(err);

    res.status(500).json({
      success: false,
      message: err.message
    });

  }
});

router.post('/Updatevehicle', async (req, res) => {
  try {
    console.log("REQ BODY ===>", req.body);

    const {
      vehicleId,
      name,
      number,
      TypeId,
      capacity,
      FuelTypeId,
      mileage,
      StatusId,
      rcdocument,
		agency_id,
      per_km_charge,
      puc_expiry,
      insurance_expiry
    } = req.body;

    if (!number) {
      return res.status(400).json({
        success: false,
        message: "Vehicle Number is required"
      });
    }

    const operation = vehicleId ? "Update" : "Insert";

    await db.request()
      .input("operation", sql.NVarChar, operation)
      .input("vehicleid", sql.Int, vehicleId || 0)
      .input("name", sql.VarChar, name)
      .input("number", sql.VarChar, number)
      .input("TypeId", sql.Int, TypeId)
      .input("capacity", sql.Int, capacity)
      .input("FuelTypeId", sql.Int, FuelTypeId)
      .input("mileage", sql.VarChar, mileage)
      .input("StatusId", sql.Int, StatusId)
      .input("rcdocument", sql.VarChar, rcdocument)
	       .input("agency_id", sql.VarChar, agency_id)
      .input("per_km_charge", sql.Decimal(10, 2), per_km_charge || 0)
      .input("puc_expiry", sql.Date, puc_expiry || null)
      .input("insurance_expiry", sql.Date, insurance_expiry || null)
      .execute("sp_Vehicle");

    res.json({
      success: true,
      message: operation === "Update"
          ? "Vehicle updated successfully"
          : "Vehicle inserted successfully"
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});



router.post('/AddDriver', async (req, res) => {
  try {

    console.log("REQ BODY ===>", req.body);

    const {
      name,
      phone,
      address,
      licenceNo,
      licenceExpiry,
      vehicle_id,
      documents,   
      agency_id
    } = req.body;

    if (!name || !phone) {
      return res.status(400).json({
        success: false,
        message: "Name and phone are required"
      });
    }

    const result = await db.request()
      .input("operation", sql.NVarChar, "Update")
      .input("driverId", sql.Int, 0)
      .input("name", sql.NVarChar, name)
      .input("phone", sql.NVarChar, phone)
      .input("address", sql.NVarChar, address)
      .input("licenceNo", sql.NVarChar, licenceNo)
      .input("licenceExpiry", sql.Date, licenceExpiry)
      .input("vehicle_id", sql.Int, vehicle_id)
      .input("documents", sql.NVarChar, documents)  // ✅ correct
      .input("agency_id", sql.NVarChar, agency_id)
      .execute("sp_driver");

    console.log("SP RESULT:", result.recordset);

    res.json({
      success: true,
      message: "Driver inserted successfully",
      data: result.recordset[0]   // ✅ returns driverId
    });

  } catch (err) {

    console.error(err);

    res.status(500).json({
      success: false,
      message: err.message
    });

  }
});
router.post('/Updatedriver', async (req, res) => {
  try {
    console.log("REQ BODY ===>", req.body);

    const {
      driverId,
      name,
      phone,
      address,
      licenceNo,
		
      licenceExpiry,
		agency_id
    } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: "Phone number is required"
      });
    }

    const operation = driverId ? "Update" : "Insert";

    await db.request()
      .input("operation", sql.NVarChar, operation)
      .input("driverid", sql.Int, driverId || 0)
      .input("name", sql.VarChar, name)
      .input("phone", sql.VarChar, phone)
      .input("address", sql.VarChar, address)
      .input("licenceNo", sql.VarChar, licenceNo)
	   .input("agency_id", sql.VarChar, agency_id)
      .input("licenceExpiry", sql.DateTime, licenceExpiry)
      .execute("sp_Driver"); 

    res.json({
      success: true,
      message: operation === "Update"
        ? "Driver updated successfully"
        : "Driver inserted successfully"
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

router.post('/AddAdmin', async (req, res) => {
  try {
    const {
      admin_id,
      name,
      email,
      mobile,
      password,
      address,
      agency_name,
      city,
      per_km_charge
    } = req.body;

    // decide operation automatically
    const operation = admin_id && admin_id > 0 ? "Update" : "Insert";

    // Hash the 4-digit PIN before storing. bcrypt produces a salted ~60-char
    // hash, so the DB `password` column must be NVARCHAR(100) (see sp_admin).
    // Only hash when a PIN is actually provided so profile updates that don't
    // change the PIN don't overwrite it with a hash of an empty string.
    const hashedPassword = password
      ? await bcrypt.hash(String(password), 10)
      : password;

    const result = await db.request()

      .input("operation", sql.NVarChar(50), operation)

      .input("admin_id", sql.Int, admin_id || 0)

      .input("name", sql.NVarChar(50), name)

      .input("email", sql.NVarChar(50), email)

      .input("mobile", sql.NVarChar(50), mobile)

      .input("password", sql.NVarChar(100), hashedPassword)

      .input("address", sql.NVarChar(100), address)

      .input("agency_name", sql.NVarChar(50), agency_name)

      .input("city", sql.NVarChar(50), city)

      .input("per_km_charge", sql.Decimal(10, 2), per_km_charge || 0)

      .execute("sp_admin");


    res.json(result.recordset[0]);

  }
  catch (err) {

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


router.post('/AddCustomer', async (req, res) => {
  try {
    console.log("REQ BODY ===>", req.body);

    const {
      name,
      phone,
      address,
      LicenceNo,
      LicenceExpiry,
      agency_id,
      id_proof
    } = req.body;

    if (!name || !phone) {
      return res.status(400).json({
        success: false,
        message: "Name and phone are required"
      });
    }

    const result = await db.request()
      .input("operation", sql.NVarChar, "Update")
      .input("customer_id", sql.Int, 0)
      .input("name", sql.NVarChar, name)
      .input("phone", sql.NVarChar, phone)
      .input("address", sql.NVarChar, address)
      .input("LicenceNo", sql.NVarChar, LicenceNo)
      .input("LicenceExpiry", sql.Date, LicenceExpiry)
      .input("agency_id", sql.NVarChar, agency_id)
      .input("id_proof", sql.NVarChar, id_proof)
      .execute("sp_Customer");

    console.log("SP RESULT:", result.recordset);

    const row = result.recordset[0] || {};
    // Forward the SP's verdict so SP-level failures (e.g. duplicate phone)
    // surface as HTTP 409 → Dio badResponse → friendlyErrorMessage shows
    // the SP's message in the snackbar.
    //
    // Be lenient: only reject when the SP *explicitly* says it failed.
    // If the SP doesn't return a `success` column at all, treat it as
    // success (backward-compatible with older procs).
    const isFailure =
      row.success === 0 || row.success === "0" || row.success === false;

    if (isFailure) {
      return res.status(409).json({
        success: false,
        message: row.message || "Could not save customer"
      });
    }

    res.json({
      success: true,
      message: row.message || "Customer inserted successfully",
      data: row
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});


router.post('/UpdateCustomer', async (req, res) => {
  try {
    console.log("REQ BODY ===>", req.body);

    const {
      customer_id,
      name,
      phone,
      address,
      LicenceNo,
      LicenceExpiry,
      agency_id,
      id_proof
    } = req.body;

    if (!customer_id) {
      return res.status(400).json({
        success: false,
        message: "customer_id is required"
      });
    }

    // Decide operation automatically (Update or Insert)
    const operation = customer_id ? "Update" : "Insert";

    const result = await db.request()
      .input("operation", sql.NVarChar, operation)
      .input("customer_id", sql.Int, customer_id || 0)
      .input("name", sql.NVarChar, name)
      .input("phone", sql.NVarChar, phone)
      .input("address", sql.NVarChar, address)
      .input("LicenceNo", sql.NVarChar, LicenceNo)
      .input("LicenceExpiry", sql.Date, LicenceExpiry)
      .input("agency_id", sql.NVarChar, agency_id)
      .input("id_proof", sql.NVarChar, id_proof)
      .execute("sp_Customer");

    res.json({
      success: true,
      message: operation === "Update"
        ? "Customer updated successfully"
        : "Customer inserted successfully",
      data: result.recordset[0] || { customer_id }
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});

router.post('/addService', async (req, res) => {
  try {

    const {
      vehicle_id,
      service_name,
      service_cost,
      service_date,
      description,
	  agency_id
    } = req.body;

    const result = await db.request()
      .input('operation', 'AddService')
      .input('vehicleid', vehicle_id)
      .input('service_name', service_name)
      .input('service_cost', service_cost)
      .input('service_date', service_date)
      .input('description', description)
	  .input('agency_id', agency_id)
      .execute('sp_Vehicle');

    res.json(result.recordset[0]);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/updateService/:service_id', async (req, res) => {
  try {
    const { service_id } = req.params;

    const result = await db.request()
      .input('operation', 'UpdateService')
      .input('service_id', service_id)
      .input('vehicleid', req.body.vehicle_id)
      .input('service_name', req.body.service_name)
      .input('service_cost', req.body.service_cost)
      .input('service_date', req.body.service_date)
      .input('description', req.body.description)
      .input('agency_id', req.body.agency_id)
      .execute('sp_Vehicle');

    res.json(result.recordset?.[0] ?? { success: true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.post("/DeleteAdminProfile", async (req, res) => {
  try {
    const { admin_id, agency_id } = req.body;

    if (!admin_id || !agency_id) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields: admin_id or agency_id",
      });
    }

    const pool = await sql.connect();
    const result = await pool.request()
      .input("operation", "DeleteProfile")             // always use DeleteProfile
      .input("admin_id", sql.Int, parseInt(admin_id))
      .input("agency_id", sql.NVarChar(20), agency_id)
      .execute("sp_admin");

    const dbMessage = result.recordset?.[0]?.message || "Profile image deleted successfully";

    res.status(200).json({
      success: true,
      message: dbMessage,
    });

  } catch (err) {
    console.error("❌ Error deleting admin profile image:", err);
    res.status(500).json({
      success: false,
      message: "Error deleting admin profile image",
      error: err.message,
    });
  }
});


module.exports = router; 