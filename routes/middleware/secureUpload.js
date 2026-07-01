// ============================================================================
// secureUpload.js — hardened multipart image upload helpers
// ----------------------------------------------------------------------------
// Every upload is staged in uploads/temp/ first, validated (MIME whitelist,
// size/count limits, *magic-byte* signature), then relocated into its final
// served folder. Anything that fails validation never leaves the temp area and
// is deleted, so a half-written or spoofed file is never reachable through the
// static GET routes.
//
// Final folders stay where they already live (routes/<Type>/<agency>/<id>) so
// existing on-disk files and the absolute URLs already stored in the DB keep
// resolving. Only the *staging* + *validation* layers are new.
// ============================================================================
const path = require('path');
const crypto = require('crypto');
const fs = require('fs-extra');
const multer = require('multer');

// Absolute paths only — under iisnode the process CWD is not reliably the
// backend folder, so relative paths land somewhere the move step can't find.
const TEMP_DIR = path.join(__dirname, '..', '..', 'uploads', 'temp');
fs.ensureDirSync(TEMP_DIR);

const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB per file
const MAX_FILES = 6;                    // per request

// Only the raster image types the app actually displays. The MIME a client
// puts on a multipart part is attacker-controlled, so this is just the first
// (cheap) gate — the magic-byte check below is the real one.
const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);

/** Error that carries an HTTP status so the route can answer cleanly. */
class UploadError extends Error {
  constructor(message, status = 400) {
    super(message);
    this.name = 'UploadError';
    this.status = status;
  }
}

// ---------------------------------------------------------------------------
// Filename sanitization
// ---------------------------------------------------------------------------
// Strip any directory component, allow only [A-Za-z0-9._-] in the base name,
// drop leading dots (no ".htaccess"-style names), cap the length, and keep a
// known-good extension. Defeats path traversal and shell/HTML-special chars in
// the stored name. The byte-level content is verified separately.
function sanitizeFilename(original) {
  const rawExt = path.extname(String(original || ''));
  const ext = rawExt.toLowerCase().replace(/[^a-z0-9.]/g, '').slice(0, 8);

  let base = path.basename(String(original || ''), rawExt);
  base = base
    .replace(/[^A-Za-z0-9_-]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^[._-]+/, '')
    .slice(0, 80);

  if (!base) base = 'file';
  return `${base}${ext}`;
}

// ---------------------------------------------------------------------------
// Magic-byte (file signature) detection
// ---------------------------------------------------------------------------
// JPEG  -> FF D8 FF
// PNG   -> 89 50 4E 47 0D 0A 1A 0A
// WebP  -> "RIFF" (52 49 46 46) .... "WEBP" (57 45 42 50) at offset 8
// Returns the detected MIME or null. Rejecting on null kills polyglots and
// renamed files (e.g. a .php with a fake image/jpeg part).
function detectImageType(buf) {
  if (buf.length >= 3 && buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) {
    return 'image/jpeg';
  }
  if (
    buf.length >= 8 &&
    buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47 &&
    buf[4] === 0x0d && buf[5] === 0x0a && buf[6] === 0x1a && buf[7] === 0x0a
  ) {
    return 'image/png';
  }
  if (
    buf.length >= 12 &&
    buf[0] === 0x52 && buf[1] === 0x49 && buf[2] === 0x46 && buf[3] === 0x46 &&
    buf[8] === 0x57 && buf[9] === 0x45 && buf[10] === 0x42 && buf[11] === 0x50
  ) {
    return 'image/webp';
  }
  return null;
}

/** Read the first `n` bytes of a file without slurping the whole thing. */
async function readHead(filePath, n = 12) {
  const fd = await fs.open(filePath, 'r');
  try {
    const buffer = Buffer.alloc(n);
    const { bytesRead } = await fs.read(fd, buffer, 0, n, 0);
    return buffer.subarray(0, bytesRead);
  } finally {
    await fs.close(fd);
  }
}

// ---------------------------------------------------------------------------
// Path-traversal-safe join
// ---------------------------------------------------------------------------
// Used for both the destination folder (built from body values) and the served
// file path (built from URL params). Guarantees the resolved path stays inside
// `base` so "..", absolute paths, and encoded traversal can't escape.
function safeJoin(base, ...parts) {
  const resolvedBase = path.resolve(base);
  const target = path.resolve(resolvedBase, ...parts.map((p) => String(p)));
  if (target !== resolvedBase && !target.startsWith(resolvedBase + path.sep)) {
    throw new UploadError('Invalid path', 400);
  }
  return target;
}

// ---------------------------------------------------------------------------
// Reliable temp -> final relocation
// ---------------------------------------------------------------------------
// Explicit copy+remove instead of fs.move — move can fail under iisnode when
// source/dest cross volumes or when locks linger.
async function relocate(src, dest) {
  await fs.copy(src, dest, { overwrite: true });
  await fs.remove(src);
}

/** Best-effort cleanup of every temp file multer wrote for this request. */
async function cleanupTemp(files) {
  await Promise.all(
    (files || []).map((f) => fs.remove(path.join(TEMP_DIR, f.filename)).catch(() => {}))
  );
}

// ---------------------------------------------------------------------------
// Multer instance — disk storage into the temp area, with limits + MIME gate
// ---------------------------------------------------------------------------
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, TEMP_DIR),
  filename: (req, file, cb) => {
    // Unguessable name: 128-bit random token + a sanitized, known-good
    // extension. GET serving is public (so Image.network can load files), so
    // the random token is what keeps another agency's URLs from being guessed.
    // The original base name is dropped so it can't leak (e.g. "aadhaar.jpg").
    const ext = path.extname(sanitizeFilename(file.originalname));
    const token = crypto.randomBytes(16).toString('hex');
    cb(null, `${Date.now()}-${token}${ext}`);
  },
});

function fileFilter(req, file, cb) {
  if (!ALLOWED_MIME.has(file.mimetype)) {
    return cb(new UploadError(`Unsupported file type: ${file.mimetype}`, 415));
  }
  cb(null, true);
}

const multerInstance = multer({
  storage,
  fileFilter,
  limits: { fileSize: MAX_FILE_SIZE, files: MAX_FILES },
});

/**
 * Express middleware: accept up to MAX_FILES files on `fieldName`, translating
 * multer/limit/MIME errors into clean JSON responses (and cleaning any temp
 * files multer already wrote before it bailed).
 */
function acceptImages(fieldName) {
  const mw = multerInstance.array(fieldName, MAX_FILES);
  return (req, res, next) => {
    mw(req, res, async (err) => {
      if (!err) return next();
      await cleanupTemp(req.files);

      if (err instanceof multer.MulterError) {
        const map = {
          LIMIT_FILE_SIZE: [413, 'Each file must be 5MB or smaller'],
          LIMIT_FILE_COUNT: [413, 'A maximum of 6 files may be uploaded per request'],
          LIMIT_UNEXPECTED_FILE: [400, `Unexpected file field (expected "${fieldName}")`],
        };
        const [status, message] = map[err.code] || [400, err.message];
        return res.status(status).json({ success: false, error: message });
      }
      const status = err.status || 400;
      return res.status(status).json({ success: false, error: err.message });
    });
  };
}

/**
 * Verify every staged file is a genuine JPEG/PNG/WebP by its magic bytes.
 * Throws UploadError on the first failure; caller is responsible for temp
 * cleanup (handler does it in `finally`).
 */
async function verifyImageSignatures(files) {
  for (const file of files) {
    const head = await readHead(path.join(TEMP_DIR, file.filename));
    const detected = detectImageType(head);
    if (!detected || !ALLOWED_MIME.has(detected)) {
      throw new UploadError(
        `"${file.originalname}" failed image signature verification (possible polyglot or spoofed file)`,
        415
      );
    }
  }
}

/**
 * Build a route handler that validates signatures, relocates temp -> final,
 * persists each URL, and always cleans up temp files.
 *
 * config:
 *   requiredFields : string[]  body keys that must be present
 *   destDir(req)   : -> absolute final folder (use safeJoin to stay inside base)
 *   buildUrl(req,f): -> public URL string for filename f
 *   save(req,url)  : async persist of one URL to the DB
 *   successMessage : string
 */
function makeUploadHandler({ requiredFields = [], destDir, buildUrl, save, successMessage }) {
  return async function handler(req, res) {
    try {
      if (!req.files || req.files.length === 0) {
        return res.status(400).json({ success: false, error: 'No file uploaded' });
      }

      const missing = requiredFields.filter((f) => !req.body[f]);
      if (missing.length) {
        return res
          .status(400)
          .json({ success: false, error: `Missing required field(s): ${missing.join(', ')}` });
      }

      // Real content check — defeats spoofed MIME / polyglot files.
      await verifyImageSignatures(req.files);

      const finalDir = destDir(req); // throws UploadError on traversal
      await fs.ensureDir(finalDir);

      const moved = [];
      for (const file of req.files) {
        const dest = safeJoin(finalDir, file.filename);
        await relocate(path.join(TEMP_DIR, file.filename), dest);
        moved.push(file.filename);
      }

      const urls = moved.map((f) => buildUrl(req, f));
      for (const url of urls) {
        await save(req, url);
      }

      return res.status(200).json({
        success: true,
        message: successMessage,
        files: moved,
        urls,
      });
    } catch (err) {
      console.error('[secureUpload] handler error:', err);
      const status = err.status || 500;
      return res.status(status).json({ success: false, error: err.message });
    } finally {
      // Remove anything still left in temp (validation failure, or a relocate
      // that threw partway through).
      await cleanupTemp(req.files);
    }
  };
}

module.exports = {
  acceptImages,
  makeUploadHandler,
  sanitizeFilename,
  detectImageType,
  safeJoin,
  UploadError,
  MAX_FILES,
  MAX_FILE_SIZE,
  ALLOWED_MIME,
};
