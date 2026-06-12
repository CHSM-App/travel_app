const express = require('express');
const cors = require('cors');
const axios = require("axios");
const path = require('path');
const fs = require('fs');
var db = require("./db");
const app = express();
// Enable CORS so other domains can access the API
app.use(cors({
  origin: '*', // or specify "https://your-other-domain.com"
  methods: ['GET']
}));


/*app.get("/fileshow/:owner_id", async (req, res) => {
    try {
        const ownerId = req.params.owner_id;

        // 1. Get id_proof path from DB
        db.query(
            "SELECT id_proof FROM owner_master WHERE owner_id='" + ownerId + "'",
            async function (err, rows) {

                if (err) {
                    return res.status(500).json({ error: err.message });
                }

                if (!rows.recordset || rows.recordset.length === 0) {
                    return res.status(404).json({ error: "No record found for this owner_id" });
                }

                let filePath = rows.recordset[0].id_proof;

                if (!filePath) {
                    return res.status(400).json({ error: "id_proof path is empty" });
                }

                console.log("DB FILE PATH:", filePath);

                // Convert forward slashes to backslashes
                filePath = filePath.replace(/\//g, "\\");

                // Encode spaces only
                const safePath = filePath.replace(/ /g, "%20");

                const handlerUrl = `https://chshub.co.in/getFiles.ashx?path=${safePath}`;

                try {
                    // 2. Fetch file from Server B
                    const response = await axios.get(handlerUrl, {
                        responseType: "arraybuffer"
                    });

                    // 3. Forward headers
                    res.set("Content-Type", response.headers["content-type"] || "application/pdf");
                    res.set("Content-Disposition", response.headers["content-disposition"] || "inline");

                    // 4. Send file to frontend
                    res.send(response.data);

                } catch (fileErr) {
                    console.error("File fetch error:", fileErr.message);
                    return res.status(500).json({ error: "Unable to fetch file" });
                }
            }
        );

    } catch (err) {
        console.error("API error:", err.message);
        return res.status(500).json({ error: "Unexpected server error" });
    }
});
*/


app.get("/fileshow/:owner_id", async (req, res) => {
    try {
        const ownerId = req.params.owner_id;

        db.query(
            "SELECT id_proof,agreement_path FROM owner_master WHERE owner_id=@id",
            { id: ownerId },
            async (err, result) => {

                if (err) return res.status(500).json({ error: err.message });

                if (!result.recordset || result.recordset.length === 0)
                    return res.status(404).json({ error: "Owner not found" });

                let filePath = result.recordset[0].id_proof;

                if (!filePath)
                    return res.status(400).json({ error: "File path empty" });

                console.log("Original DB Path:", filePath);

                // Convert DB format → safe URL format
                // 1. Replace backslashes
                filePath = filePath.replace(/\\/g, "/");

                // 2. Encode entire path (spaces, special chars)
                const encodedPath = encodeURIComponent(filePath);

                const fileURL = `https://chshub.co.in/getFiles.ashx?path=${encodedPath}`;

                try {
                    const response = await axios.get(fileURL, {
                        responseType: "arraybuffer"
                    });

                    res.set("Content-Type", response.headers["content-type"]);
                    res.set("Content-Disposition", response.headers["content-disposition"] || "inline");

                    res.send(response.data);

                } catch (fetchErr) {
                    console.error("Fetching Error:", fetchErr.message);
                    res.status(500).json({ error: "Unable to load file" });
                }
            }
        );

    } catch (err) {
        res.status(500).json({ error: "Unexpected server error" });
    }
});



const FILES_DIR = __dirname;
// GET /file?name=filename.pdf
app.get('/*', (req, res) => {
  const fileName =  req.params[0];
  if (!fileName) {
    return res.status(400).json({ error: 'File name is required' });
  }

  const filePath = path.join(FILES_DIR, fileName);

  // Security check – prevent directory traversal attacks
  if (!filePath.startsWith(FILES_DIR)) {
    return res.status(403).json({ error: 'Invalid file path' });
  }

  // Check if file exists
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }

  // Send file for download or inline viewing
  res.sendFile(filePath);
});

// Optional: List all files




module.exports = app;
