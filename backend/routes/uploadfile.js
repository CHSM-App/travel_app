var express = require('express');
var router = express.Router();
var path = require('path');
var db = require('./db'); // DB connection

const {
  acceptImages,
  makeUploadHandler,
  safeJoin,
} = require('./middleware/secureUpload');

// Public base for the served file URLs (stored in the DB). Routes are mounted
// under /upload (see app.js), so a file ends up at:
//   {PUBLIC_BASE}/upload/<Type>/<agencyId>/<id>/<filename>
const PUBLIC_BASE = 'https://travels.vengurlatech.com';

// Each upload type's served folder lives next to this file (routes/<Type>/...).
function typeDir(type) {
  return path.join(__dirname, type);
}

// Path-traversal-safe sender for the GET routes. The folder/file segments come
// straight from the URL, so we resolve under the type's base dir and refuse
// anything that escapes it.
function sendProtectedFile(res, type, segments) {
  let filePath;
  try {
    filePath = safeJoin(typeDir(type), ...segments);
  } catch (err) {
    return res.status(400).json({ error: 'Invalid path' });
  }
  res.sendFile(filePath, (err) => {
    if (err) res.status(404).json({ error: 'File not found' });
  });
}

/* ============================== Admin Image ============================== */
router.post(
  '/AdminImage',
  acceptImages('image'),
  makeUploadHandler({
    requiredFields: ['agency_id', 'admin_id'],
    successMessage: 'Images uploaded successfully',
    destDir: (req) =>
      safeJoin(typeDir('AdminImage'), req.body.agency_id, req.body.admin_id),
    buildUrl: (req, f) =>
      `${PUBLIC_BASE}/upload/AdminImage/${req.body.agency_id}/${req.body.admin_id}/${f}`,
    save: (req, url) =>
      db.request()
        .input('operation', 'UpdateProfile')
        .input('image_url', url)
        .input('agency_id', req.body.agency_id)
        .input('admin_id', parseInt(req.body.admin_id))
        .execute('sp_admin'),
  })
);

router.get('/AdminImage/:agencyId/:adminId/:file', (req, res) => {
  sendProtectedFile(res, 'AdminImage', [
    req.params.agencyId,
    req.params.adminId,
    req.params.file,
  ]);
});

/* ========================== Vehicle Documents =========================== */
router.post(
  '/VehicleDocuments',
  acceptImages('document'),
  makeUploadHandler({
    requiredFields: ['agency_id', 'vehicleId'],
    successMessage: 'Vehicle documents uploaded successfully',
    destDir: (req) =>
      safeJoin(typeDir('VehicleDocuments'), req.body.agency_id, req.body.vehicleId),
    buildUrl: (req, f) =>
      `${PUBLIC_BASE}/upload/VehicleDocuments/${req.body.agency_id}/${req.body.vehicleId}/${f}`,
    save: (req, url) =>
      db.request()
        .input('operation', 'UpdateVehicleDocument')
        .input('rcdocument', url)
        .input('agency_id', req.body.agency_id)
        .input('vehicleId', parseInt(req.body.vehicleId))
        .execute('sp_Vehicle'),
  })
);

router.get('/VehicleDocuments/:agencyId/:vehicleId/:file', (req, res) => {
  sendProtectedFile(res, 'VehicleDocuments', [
    req.params.agencyId,
    req.params.vehicleId,
    req.params.file,
  ]);
});

/* =========================== Driver Documents =========================== */
router.post(
  '/DriverDocuments',
  acceptImages('document'),
  makeUploadHandler({
    requiredFields: ['agency_id', 'driverId'],
    successMessage: 'Driver documents uploaded successfully',
    destDir: (req) =>
      safeJoin(typeDir('DriverDocuments'), req.body.agency_id, req.body.driverId),
    buildUrl: (req, f) =>
      `${PUBLIC_BASE}/upload/DriverDocuments/${req.body.agency_id}/${req.body.driverId}/${f}`,
    save: (req, url) =>
      db.request()
        .input('operation', 'UpdateDriverDocument')
        .input('documents', url)
        .input('agency_id', req.body.agency_id)
        .input('driverId', parseInt(req.body.driverId))
        .execute('sp_driver'),
  })
);

router.get('/DriverDocuments/:agencyId/:driverId/:file', (req, res) => {
  sendProtectedFile(res, 'DriverDocuments', [
    req.params.agencyId,
    req.params.driverId,
    req.params.file,
  ]);
});

/* ========================== Customer Documents ========================== */
router.post(
  '/CustomerDocuments',
  acceptImages('document'),
  makeUploadHandler({
    requiredFields: ['agency_id', 'CustomerId'],
    successMessage: 'Customer documents uploaded successfully',
    destDir: (req) =>
      safeJoin(typeDir('CustomerDocuments'), req.body.agency_id, req.body.CustomerId),
    buildUrl: (req, f) =>
      `${PUBLIC_BASE}/upload/CustomerDocuments/${req.body.agency_id}/${req.body.CustomerId}/${f}`,
    save: (req, url) =>
      db.request()
        .input('operation', 'UpdateCustomerDocument')
        .input('id_proof', url)
        .input('agency_id', req.body.agency_id)
        .input('customer_id', parseInt(req.body.CustomerId))
        .execute('sp_Customer'),
  })
);

router.get('/CustomerDocuments/:agencyId/:CustomerId/:file', (req, res) => {
  sendProtectedFile(res, 'CustomerDocuments', [
    req.params.agencyId,
    req.params.CustomerId,
    req.params.file,
  ]);
});

module.exports = router;
