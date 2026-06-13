 var express = require('express');
var db = require("./db");
var router = express.Router();
var http=require('http');
const jwt = require('jsonwebtoken');
require('dotenv').config();
const reminders = require('./reminders');

let refreshTokens = [];

//-----------TRAVELS APP GET API--------------------------------//
	
  router.get('/driverList/:agency_id', async (req, res) => {
	  const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'DriverList')
	  .input('agency_id', agency_id)
      .execute('sp_trip');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err });
  }
});

  router.get('/deletedDriverList/:agency_id', async (req, res) => {
	  const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'fetchDeletedDrivers')
	  .input('agency_id', agency_id)
      .execute('sp_driver');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/VehicleList/:agency_id', async (req, res) => {
	  const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'VehicleList')
	  .input('agency_id', agency_id)
      .execute('sp_trip');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/deletedVehicleList/:agency_id', async (req, res) => {
	  const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'fetchDeletedVehicles')
	  .input('agency_id', agency_id)
      .execute('sp_vehicle');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/CustomerList/:agency_id', async (req, res) => {
	 const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'CustomerList')
	  .input('agency_id', agency_id)
      .execute('sp_trip');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});



// ---- Google Distance Matrix proxy (API key stays on the server) ----
router.get('/distance', async (req, res) => {
  const { origins, destinations } = req.query;
  if (!origins || !destinations) {
    return res
      .status(400)
      .json({ error: 'origins and destinations are required' });
  }

  try {
    const url = new URL('https://maps.googleapis.com/maps/api/distancematrix/json');
    url.searchParams.set('origins', origins);
    url.searchParams.set('destinations', destinations);
    url.searchParams.set('units', 'metric');
    url.searchParams.set('key', process.env.GOOGLE_MAPS_API_KEY);

    const googleRes = await fetch(url); // Node 18+ has fetch built in
    const data = await googleRes.json();

    const element = data?.rows?.[0]?.elements?.[0];
    if (!element || element.status !== 'OK') {
      return res.status(404).json({
        error: 'Route not found',
        googleStatus: element?.status || data.status,
      });
    }

    res.json({
      distanceKm: element.distance.value / 1000, // metres → km
      distanceText: element.distance.text,         // e.g. "118 km"
      durationText: element.duration?.text || null, // e.g. "2 hours 30 mins"
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});



// ---- Google Places Autocomplete proxy (API key stays on the server) ----
// The app's PlacesService hits this for Google-Maps-style location suggestions
// in the trip booking form. Returns a flat list of place descriptions; the
// client falls back to its own recent-locations on any empty/error response.
router.get('/placeAutocomplete', async (req, res) => {
  const input = (req.query.input || '').trim();
  // Mirror the client's own guard (it won't call below 3 chars) and avoid
  // billing Google for trivially short queries.
  if (input.length < 3) return res.json([]);

  try {
    const url = new URL('https://maps.googleapis.com/maps/api/place/autocomplete/json');
    url.searchParams.set('input', input);
    // Bias results to India — this is an Indian travel agency app.
    url.searchParams.set('components', 'country:in');
    url.searchParams.set('key', process.env.GOOGLE_MAPS_API_KEY);

    const googleRes = await fetch(url); // Node 18+ has fetch built in
    const data = await googleRes.json();

    // ZERO_RESULTS is a normal "nothing matched" — return an empty list, not an
    // error, so the field quietly falls back to recent locations.
    if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
      return res.status(502).json({
        error: 'Places lookup failed',
        googleStatus: data.status,
        googleMessage: data.error_message || null,
      });
    }

    const suggestions = (data.predictions || [])
      .map((p) => p.description)
      .filter((d) => typeof d === 'string' && d.trim().length > 0);

    res.json(suggestions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});



router.get('/fetchAvailableVehicles/:agency_id/:start_datetime/:end_datetime/:trip_id?', async (req, res) => {

  const { agency_id, start_datetime, end_datetime, trip_id} = req.params;

  try {

    const result = await db.request()
      .input('operation', 'FetchAvailableVehicles')
      .input('agency_id', agency_id)
      .input('start_datetime', start_datetime) 
      .input('end_datetime', end_datetime)
	  .input('trip_id', trip_id ? parseInt(trip_id) : null) 
      .execute('sp_trip');

    res.json(result.recordset);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/fetchAvailableDrivers/:agency_id/:start_datetime/:end_datetime/:trip_id?', async (req, res) => {

  const { agency_id, start_datetime, end_datetime, trip_id} = req.params;

  try {

    const result = await db.request()
      .input('operation', 'FetchAvailableDrivers')
      .input('agency_id', agency_id)
      .input('start_datetime', start_datetime) 
      .input('end_datetime', end_datetime)
	  .input('trip_id', trip_id ? parseInt(trip_id) : null) 
      .execute('sp_trip');

    res.json(result.recordset);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
	
  router.get('/Customerhistory/:customer_id', async (req, res) => {
	  const {customer_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'Customerhistory')
	  .input('customer_id', customer_id)
      .execute('sp_Customer');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

  router.get('/vehicleHistory/:vehicle_id', async (req, res) => {
	  const {vehicle_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'vehicleHistoryList')
	  .input('vehicleId', vehicle_id)
      .execute('sp_Vehicle');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

  router.get('/driverHistory/:driver_id', async (req, res) => {
	  const {driver_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'driverHistoryList')
	  .input('driverId', driver_id)
      .execute('sp_driver');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/VehicleTypeList', async (req, res) => {
  try {
     const result = await db.request()
      .input('operation', 'VehicleTypeList')
      .execute('sp_Vehicle');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


router.get('/StatusList', async (req, res) => {
  try {
     const result = await db.request()
      .input('operation', 'StatusList')
      .execute('sp_Vehicle');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/FuelTypeList', async (req, res) => {
  try {
     const result = await db.request()
      .input('operation', 'FuelTypeList')
      .execute('sp_Vehicle');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/UpcomingTrip/:agency_id', async (req, res) => {
		 const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'UpcomingTrip')
	 	  .input('agency_id', agency_id)
      .execute('sp_trip');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/HistoryTrip/:agency_id', async (req, res) => {
		 const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'HistoryTrip')
	 	  .input('agency_id', agency_id)
      .execute('sp_trip');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/Unpaidtrip/:agency_id', async (req, res) => {
		 const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'Unpaidtrip')
	 	  .input('agency_id', agency_id)
      .execute('sp_trip');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/activeTrip/:agency_id', async (req, res) => {
		 const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'activeTrip')
	 	  .input('agency_id', agency_id)
      .execute('sp_trip');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/cancelledTrip/:agency_id', async (req, res) => {
		 const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'cancelledTrip')
	 	  .input('agency_id', agency_id)
      .execute('sp_trip');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/getDriverList', async (req, res) => {
  try {
     const result = await db.request()
      .input('operation', 'getDriverList')
      .execute('sp_driver');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

	
  router.get('/Adminprofile/:admin_id', async (req, res) => {
	  const {admin_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'ProfileFetch')
	  .input('admin_id', admin_id)
      .execute('sp_admin');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

  router.get('/serviceRecord/:agency_id/:vehicle_id', async (req, res) => {
	  const {agency_id, vehicle_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'getServiceRecords')
	  .input('agency_id', agency_id)
	  .input('vehicleid', vehicle_id)
      .execute('sp_Vehicle');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// REPORT API
router.get('/report/:agency_id/:report_type', async (req, res) => {

    const { agency_id, report_type } = req.params;

    try {

        const result = await db.request()
            .input('operation', 'trip_report')
            .input('report_type', report_type)
            .input('agency_id', agency_id)
            .execute('sp_reports');

        res.status(200).json(result.recordset);

    } catch (err) {

        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });

    }

});

router.get('/paymentHistory/:trip_id', async (req, res) => {
	const {trip_id} = req.params;
  try {
    const result = await db.request()
      .input("operation", "GetPaymentHistory")
      .input("trip_id", trip_id)
      .execute("sp_trip");
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});


  router.get('/VehicleReport/:agency_id', async (req, res) => {
	  const {agency_id} = req.params;
  try {
     const result = await db.request()
      .input('operation', 'getVehicleReport')
	  .input('agency_id', agency_id)
      .execute('sp_Vehicle');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// =====================================================
// PUSH NOTIFICATIONS — device token registration
// (protected routes; called after login when a token exists)
// =====================================================

// Body: { admin_id, agency_id, fcm_token, platform }
router.post('/registerDeviceToken', async (req, res) => {
  try {
    const { admin_id, agency_id, fcm_token, platform } = req.body;
    if (!fcm_token) {
      return res.status(400).json({ success: false, message: 'fcm_token is required' });
    }
    await db.request()
      .input('operation', 'register')
      .input('admin_id', admin_id || null)
      .input('agency_id', agency_id || null)
      .input('fcm_token', fcm_token)
      .input('platform', platform || null)
      .execute('sp_device_token');
    return res.json({ success: true });
  } catch (err) {
    console.error('[registerDeviceToken]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
});

// Body: { fcm_token }
router.post('/removeDeviceToken', async (req, res) => {
  try {
    const { fcm_token } = req.body;
    if (!fcm_token) {
      return res.status(400).json({ success: false, message: 'fcm_token is required' });
    }
    await db.request()
      .input('operation', 'remove')
      .input('fcm_token', fcm_token)
      .execute('sp_device_token');
    return res.json({ success: true });
  } catch (err) {
    console.error('[removeDeviceToken]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
});

// Test trigger: immediately push the reminder summary to the caller's agency.
// Body: { agency_id }
router.post('/sendTestReminder', async (req, res) => {
  try {
    const { agency_id } = req.body;
    if (!agency_id) {
      return res.status(400).json({ success: false, message: 'agency_id is required' });
    }
    const result = await reminders.sendReminderForAgency(agency_id);
    return res.json({ success: true, ...result });
  } catch (err) {
    console.error('[sendTestReminder]', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;