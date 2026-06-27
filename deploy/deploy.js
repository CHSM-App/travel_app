#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { google } = require('googleapis');

// ─── Paths ────────────────────────────────────────────────────────────────────
const AAB_PATH = path.resolve(__dirname, '../frontend/build/app/outputs/bundle/release/app-release.aab');
const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, 'service-account.json');
const PUBSPEC_PATH = path.resolve(__dirname, '../frontend/pubspec.yaml');

// ─── CLI argument parsing ──────────────────────────────────────────────────────
function parseArgs() {
  const args = process.argv.slice(2);
  const opts = {
    priority: 3,
    track: 'production',
    force: false,
    dryRun: false,
    fraction: null,
  };

  for (const arg of args) {
    if (arg.startsWith('--priority=')) {
      const val = parseInt(arg.split('=')[1], 10);
      if (isNaN(val) || val < 0 || val > 5) {
        console.error('ERROR: --priority must be 0–5');
        process.exit(1);
      }
      opts.priority = val;
    } else if (arg.startsWith('--track=')) {
      const val = arg.split('=')[1];
      if (!['internal', 'alpha', 'beta', 'production'].includes(val)) {
        console.error('ERROR: --track must be one of internal, alpha, beta, production');
        process.exit(1);
      }
      opts.track = val;
    } else if (arg === '--force') {
      opts.force = true;
    } else if (arg === '--dry-run') {
      opts.dryRun = true;
    } else if (arg.startsWith('--fraction=')) {
      const val = parseFloat(arg.split('=')[1]);
      if (isNaN(val) || val <= 0 || val > 1) {
        console.error('ERROR: --fraction must be between 0.01 and 1.0');
        process.exit(1);
      }
      opts.fraction = val;
    } else {
      console.error(`ERROR: Unknown argument: ${arg}`);
      process.exit(1);
    }
  }

  // --force implies 100% rollout
  if (opts.force) opts.fraction = 1.0;

  return opts;
}

// ─── Read version from pubspec.yaml ───────────────────────────────────────────
function readPubspecVersion() {
  const content = fs.readFileSync(PUBSPEC_PATH, 'utf8');
  const match = content.match(/^version:\s*(.+)$/m);
  if (!match) throw new Error('Could not find version in pubspec.yaml');
  return match[1].trim();
}

// ─── Read package name from pubspec.yaml ──────────────────────────────────────
function readPackageName() {
  const content = fs.readFileSync(PUBSPEC_PATH, 'utf8');
  const match = content.match(/^name:\s*(.+)$/m);
  return match ? match[1].trim() : 'com.vengurlatech.vego';
}

// ─── Human-readable file size ─────────────────────────────────────────────────
function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

// ─── Prompt helper ────────────────────────────────────────────────────────────
function prompt(question) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim().toLowerCase());
    });
  });
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  const opts = parseArgs();

  // Validate required files
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`ERROR: Service account file not found at:\n  ${SERVICE_ACCOUNT_PATH}`);
    console.error('Place your Google Play service account JSON at deploy/service-account.json');
    process.exit(1);
  }
  if (!fs.existsSync(AAB_PATH)) {
    console.error(`ERROR: AAB not found at:\n  ${AAB_PATH}`);
    console.error('Build it first with: flutter build appbundle --release');
    process.exit(1);
  }

  const version = readPubspecVersion();
  const aabSize = fs.statSync(AAB_PATH).size;
  const rolloutPct = opts.fraction != null ? `${(opts.fraction * 100).toFixed(0)}%` : 'staged (default)';

  // ─── Release summary ──────────────────────────────────────────────────────
  console.log('\n╔══════════════════════════════════════════════════╗');
  console.log('║           Vego — Play Store Upload               ║');
  console.log('╚══════════════════════════════════════════════════╝');
  console.log(`  Package     : com.vengurlatech.vego`);
  console.log(`  Version     : ${version}`);
  console.log(`  Track       : ${opts.track}`);
  console.log(`  Priority    : ${opts.priority}`);
  console.log(`  AAB size    : ${formatBytes(aabSize)}`);
  console.log(`  Rollout     : ${rolloutPct}`);
  console.log(`  Dry run     : ${opts.dryRun ? 'YES — no upload will happen' : 'no'}`);
  console.log('');

  if (opts.dryRun) {
    console.log('Dry run complete. All files validated. Exiting without upload.');
    return;
  }

  // ─── Double confirmation for high-risk deploys ─────────────────────────────
  if (opts.priority === 5 && opts.force) {
    console.log('⚠️  WARNING: You are about to push a FORCED update (priority=5) at 100% rollout.');
    console.log('   All users will see a mandatory update dialog they cannot dismiss.');
    const first = await prompt('   Type "yes" to continue: ');
    if (first !== 'yes') { console.log('Aborted.'); process.exit(0); }
    const second = await prompt('   Type "confirm" to proceed with forced full rollout: ');
    if (second !== 'confirm') { console.log('Aborted.'); process.exit(0); }
  } else {
    const answer = await prompt('Proceed with upload? (yes/no): ');
    if (answer !== 'yes') { console.log('Aborted.'); process.exit(0); }
  }

  // ─── Google Play API ──────────────────────────────────────────────────────
  const serviceAccount = JSON.parse(fs.readFileSync(SERVICE_ACCOUNT_PATH, 'utf8'));
  const auth = new google.auth.GoogleAuth({
    credentials: serviceAccount,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  const publisher = google.androidpublisher({ version: 'v3', auth });
  const packageName = 'com.vengurlatech.vego';
  let editId = null;

  try {
    // 1. Open edit session
    console.log('\nOpening edit session...');
    const editResponse = await publisher.edits.insert({ packageName });
    editId = editResponse.data.id;
    console.log(`  Edit ID: ${editId}`);

    // 2. Upload AAB
    console.log('Uploading AAB...');
    const aabResponse = await publisher.edits.bundles.upload({
      packageName,
      editId,
      media: {
        mimeType: 'application/octet-stream',
        body: fs.createReadStream(AAB_PATH),
      },
    });
    const versionCode = aabResponse.data.versionCode;
    console.log(`  Uploaded version code: ${versionCode}`);

    // 3. Assign to track with priority and rollout
    console.log(`Assigning to track '${opts.track}' with priority ${opts.priority}...`);
    const release = {
      versionCodes: [String(versionCode)],
      status: opts.fraction != null && opts.fraction < 1 ? 'inProgress' : 'completed',
      inAppUpdatePriority: opts.priority,
    };
    if (opts.fraction != null && opts.fraction < 1) {
      release.userFraction = opts.fraction;
    }

    await publisher.edits.tracks.update({
      packageName,
      editId,
      track: opts.track,
      requestBody: { releases: [release] },
    });

    // 4. Commit edit
    console.log('Committing edit...');
    await publisher.edits.commit({ packageName, editId });
    editId = null; // prevent cleanup from running on success

    console.log('\n✓ Upload successful!');
    console.log(`  Version ${version} is now on the '${opts.track}' track.`);
    console.log(`  In-app update priority: ${opts.priority}`);
  } catch (err) {
    // Clean up the edit session so it doesn't block future uploads
    if (editId) {
      try {
        console.log('\nUpload failed — cleaning up edit session...');
        await publisher.edits.delete({ packageName, editId });
        console.log('  Edit session cleaned up.');
      } catch (cleanupErr) {
        console.error(`  WARNING: Could not clean up edit session ${editId}: ${cleanupErr.message}`);
      }
    }
    console.error(`\nERROR: Upload failed — ${err.message}`);
    process.exit(1);
  }
}

main();
