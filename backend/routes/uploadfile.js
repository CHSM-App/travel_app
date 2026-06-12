var express = require('express');
var router = express.Router();
var fs = require('fs-extra');
var multer = require('multer');
var path = require('path');
var db = require('./db'); // Your DB connection

// Absolute paths — under iisnode the process CWD is NOT reliably the Backend
// folder, so any relative path like 'uploads/' will land somewhere the move
// step can't find. Anchoring everything to __dirname avoids that whole class
// of bug (and explains the orphaned files in Backend/uploads/).
const UPLOAD_DIR = path.join(__dirname, '..', 'uploads');
fs.ensureDirSync(UPLOAD_DIR);

// Multer setup
const storage = multer.diskStorage({
    destination: function(req, file, cb){
        cb(null, UPLOAD_DIR);
    },
    filename: function(req, file, cb){
        cb(null, `${Date.now()}-${file.originalname}`);
    }
});
const upload = multer({ storage: storage });

// Robust replacement for `fs.move` — `move` can fail under iisnode when
// source/dest cross volumes or when locks linger. Explicit copy+remove is
// the same outcome but much more reliable, and we log every step so the
// real reason any failure ends up in iisnode/*.txt.
async function relocateUpload(src, dest) {
    try {
        await fs.copy(src, dest, { overwrite: true });
        await fs.remove(src);
    } catch (err) {
        console.error(`[upload] relocate failed src=${src} dest=${dest}:`, err);
        throw err;
    }
}

///------------------------Admin Upload Image---------------------------------------------
// --- Serve AdminImage folder as static for browser access ---
router.use('/upload/AdminImage', express.static(path.join(__dirname, 'AdminImage')));
// POST upload images
router.post('/AdminImage', upload.array('image', 10), async function(req, res){
    if(!req.files || req.files.length === 0){
        return res.status(400).json({ error: 'No file uploaded' });
    }
    try{
        const agencyId = req.body.agency_id;
        const adminId = req.body.admin_id;
        if(!agencyId || !adminId){
            return res.status(400).json({ error: 'agency_id and admin_id are required' });
        }
        // Create folder: AdminImage/<agencyId>/<adminId>
        const adminDir = path.join(__dirname, "AdminImage", agencyId.toString(), adminId.toString());
        await fs.ensureDir(adminDir);

        const movedFiles = [];
        for(const file of req.files){
            const src = path.join(UPLOAD_DIR, file.filename);
            const dest = path.join(adminDir, file.filename);
            await relocateUpload(src, dest);
            movedFiles.push(file.filename);
        }

        // Build public URLs
        const fileUrls = movedFiles.map(f => 
            `https://travels.vengurlatech.com/upload/AdminImage/${agencyId}/${adminId}/${f}`
        );

        // Save URLs to database
        for(const url of fileUrls){
            await db.request()
                .input('operation', 'UpdateProfile')
                .input('image_url', url)
                .input('agency_id', agencyId)
                .input('admin_id', parseInt(adminId))
                .execute('sp_admin'); // adjust SP name if needed
        }

        res.status(200).json({ 
            success: true,
            message: 'Images uploaded successfully',
            files: movedFiles,
            urls: fileUrls
        });

    } catch(err){
        console.error('Upload error:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET images by agency_id and admin_id
router.get('/AdminImage/:agencyId/:adminId/:file', async function(req, res){
    const filePath = path.join(__dirname, "AdminImage", req.params.agencyId, req.params.adminId, req.params.file);
    res.sendFile(filePath, (err) => {
        if(err){
            res.status(404).json({ error: "File not found" });
        }
    });
});



//---------------Vehicle Documents Upload------------------------------
// --- Serve VehicleDocuments folder as static for browser access ---
router.use('/upload/VehicleDocuments', express.static(path.join(__dirname, 'VehicleDocuments')));

// POST upload vehicle documents
router.post('/VehicleDocuments', upload.array('document', 10), async function(req, res){
    if(!req.files || req.files.length === 0){
        return res.status(400).json({ error: 'No file uploaded' });
    }
    try{
        const agencyId = req.body.agency_id;
        const vehicleId = req.body.vehicleId;
        if(!agencyId || !vehicleId){
            return res.status(400).json({ error: 'agency_id and vehicle_id are required' });
        }

        // Create folder: VehicleDocuments/<agencyId>/<vehicleId>
        const vehicleDir = path.join(__dirname, "VehicleDocuments", agencyId.toString(), vehicleId.toString());
        await fs.ensureDir(vehicleDir);

        const movedFiles = [];
        for(const file of req.files){
            const src = path.join(UPLOAD_DIR, file.filename);
            const dest = path.join(vehicleDir, file.filename);
            await relocateUpload(src, dest);
            movedFiles.push(file.filename);
        }

        // Build public URLs
        const fileUrls = movedFiles.map(f => 
            `https://travels.vengurlatech.com/upload/VehicleDocuments/${agencyId}/${vehicleId}/${f}`
        );

        // Save URLs to database
        for(const url of fileUrls){
            await db.request()
                .input('operation', 'UpdateVehicleDocument')
                .input('rcdocument', url)
                .input('agency_id', agencyId)
                .input('vehicleId', parseInt(vehicleId))
                .execute('sp_Vehicle'); // adjust SP name if needed
		
        }

        res.status(200).json({ 
            success: true,
            message: 'Vehicle documents uploaded successfully',
            files: movedFiles,
            urls: fileUrls
        });

    } catch(err){
        console.error('Upload error:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET vehicle document by agency_id, vehicle_id, and filename
router.get('/VehicleDocuments/:agencyId/:vehicleId/:file', async function(req, res){
    const filePath = path.join(__dirname, "VehicleDocuments", req.params.agencyId, req.params.vehicleId, req.params.file);
    res.sendFile(filePath, (err) => {
        if(err){
            res.status(404).json({ error: "File not found" });
        }
    });
});


//Drivers Douments 



//---------------Driver Documents Upload------------------------------
// --- Serve DriverDocuments folder as static for browser access ---
router.use('/upload/DriverDocuments', express.static(path.join(__dirname, 'DriverDocuments')));

// POST upload driver documents
router.post('/DriverDocuments', upload.array('document', 10), async function(req, res){
    if(!req.files || req.files.length === 0){
        return res.status(400).json({ error: 'No file uploaded' });
    }
    try{
        const agencyId = req.body.agency_id;
        const driverId = req.body.driverId;
        if(!agencyId || !driverId){
            return res.status(400).json({ error: 'agency_id and driverId are required' });
        }

        // Create folder: VehicleDocuments/<agencyId>/<driverId>
        const driverDir = path.join(__dirname, "DriverDocuments", agencyId.toString(), driverId.toString());
        await fs.ensureDir(driverDir);

        const movedFiles = [];
        for(const file of req.files){
            const src = path.join(UPLOAD_DIR, file.filename);
            const dest = path.join(driverDir, file.filename);
            await relocateUpload(src, dest);
            movedFiles.push(file.filename);
        }

        // Build public URLs
        const fileUrls = movedFiles.map(f => 
            `https://travels.vengurlatech.com/upload/DriverDocuments/${agencyId}/${driverId}/${f}`
        );

        // Save URLs to database
        for(const url of fileUrls){
            await db.request()
                .input('operation', 'UpdateDriverDocument')
                .input('documents', url)
                .input('agency_id', agencyId)
                .input('driverId', parseInt(driverId))
                .execute('sp_driver'); // adjust SP name if needed
		
        }

        res.status(200).json({ 
            success: true,
            message: 'Driver documents uploaded successfully',
            files: movedFiles,
            urls: fileUrls
        });

    } catch(err){
        console.error('Upload error:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET vehicle document by agency_id, driverId, and filename
router.get('/DriverDocuments/:agencyId/:driverId/:file', async function(req, res){
    const filePath = path.join(__dirname, "DriverDocuments", req.params.agencyId, req.params.driverId, req.params.file);
    res.sendFile(filePath, (err) => {
        if(err){
            res.status(404).json({ error: "File not found" });
        }
    });
});



//---------------Customer Documents Upload------------------------------
// --- Serve CustomerDocuments folder as static for browser access ---
router.use('/upload/CustomerDocuments', express.static(path.join(__dirname, 'CustomerDocuments')));
router.post('/CustomerDocuments', upload.array('document', 10), async function(req, res){
    if(!req.files || req.files.length === 0){
        return res.status(400).json({ error: 'No file uploaded' });
    }
    try{
        const agencyId = req.body.agency_id;
        const CustomerId = req.body.CustomerId;
        if(!agencyId || !CustomerId){
            return res.status(400).json({ error: 'agency_id and CustomerId are required' });
        }

        // Correct folder path
        const customerDir = path.join(__dirname, "CustomerDocuments", agencyId.toString(), CustomerId.toString());
        await fs.ensureDir(customerDir);

        const movedFiles = [];
        for(const file of req.files){
            const src = path.join(UPLOAD_DIR, file.filename);
            const dest = path.join(customerDir, file.filename);
            await relocateUpload(src, dest);
            movedFiles.push(file.filename);
        }

        // Build public URLs
        const fileUrls = movedFiles.map(f => 
            `https://travels.vengurlatech.com/upload/CustomerDocuments/${agencyId}/${CustomerId}/${f}`
        );

        // Save URLs to database
        for(const url of fileUrls){
            await db.request()
                .input('operation', 'UpdateCustomerDocument')
                .input('id_proof', url)
                .input('agency_id', agencyId)
                .input('customer_id', parseInt(CustomerId))
                .execute('sp_Customer');
        }

        res.status(200).json({ 
            success: true,
            message: 'Customer documents uploaded successfully',
            files: movedFiles,
            urls: fileUrls
        });

    } catch(err){
        console.error('Upload error:', err);
        res.status(500).json({ error: err.message });
    }
});

// GET vehicle document by agency_id, CustomerId, and filename
router.get('/CustomerDocuments/:agencyId/:CustomerId/:file', async function(req, res){
    const filePath = path.join(__dirname, "CustomerDocuments", req.params.agencyId, req.params.CustomerId, req.params.file);
    res.sendFile(filePath, (err) => {
        if(err){
            res.status(404).json({ error: "File not found" });
        }
    });
});

module.exports = router;
