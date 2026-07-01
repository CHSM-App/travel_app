const mssql = require('mssql');

const sqlConfig = {
    user: 'travel_admin',      // Replace with your username
    password: 'Travel@admin_123',//'@x8#H8$?hEQJU',   // Replace with your password
    server: 'winsome.grabweb.in',        // Replace with your server
    database: 'travel_agency',
    port: 5691,
    options: {
        encrypt: true, // Use this if you're on Windows Azure
        trustServerCertificate: true // Change to true for local dev / self-signed certs
    },
    // The DB host (shared Plesk/IIS) closes idle connections. Let tarn drop idle
    // ones (min:0) and recreate on demand; cap the rest so we fail fast instead
    // of hanging when the server is unreachable.
    pool: { max: 10, min: 0, idleTimeoutMillis: 30000 },
    connectionTimeout: 15000,
    requestTimeout: 30000,
};

// ---------------------------------------------------------------------------
// Self-healing connection pool.
//
// The previous version used mssql's GLOBAL connection (`mssql.connect(config, cb)`)
// with no error handler and no reconnection. When the host dropped an idle
// connection the pool moved to a closed state and stayed there, so every later
// `db.request()` failed with "Connection is closed." (HTTP 500).
//
// Here we own a dedicated ConnectionPool, attach an `error` listener (an
// unhandled pool 'error' can otherwise crash the process), and rebuild +
// reconnect transparently whenever the pool is missing or has been torn down.
// ---------------------------------------------------------------------------

let pool;
let connectPromise;

function buildPool() {
    const p = new mssql.ConnectionPool(sqlConfig);
    p.on('error', (err) => {
        console.error('[db] pool error:', err && err.message);
        // Drop the broken pool so the next call rebuilds a fresh, connected one.
        if (pool === p) {
            pool = undefined;
            connectPromise = undefined;
        }
    });
    return p;
}

// Resolves to a live, connected pool. Rebuilds + reconnects when the pool is
// missing or was torn down. Safe to call concurrently (shares one connect()).
function connect() {
    if (pool && pool.connected) return Promise.resolve(pool);
    if (connectPromise) return connectPromise;
    if (!pool) pool = buildPool();

    const p = pool;
    connectPromise = p.connect()
        .then(() => {
            connectPromise = undefined;
            console.log('Connection Successful');
            return p;
        })
        .catch((err) => {
            connectPromise = undefined;
            if (pool === p) pool = undefined; // failed pool is unusable; rebuild next time
            console.error('[db] connect failed:', err && err.message);
            throw err;
        });
    return connectPromise;
}

// Open the pool at boot and keep it warm. If the SQL server drops the
// connection later, the next request transparently reconnects.
connect().catch(() => { /* logged above; retried lazily on the next call */ });

function live() {
    if (!pool || !pool.connected) {
        connect().catch(() => {}); // kick off a background reconnect
        throw new mssql.ConnectionError('Database connection not ready, reconnecting — please retry.');
    }
    return pool;
}

// Backwards-compatible facade. Existing call sites use one of:
//   db.request()           -> mssql Request on the live pool
//   db.query(sql[, cb])    -> mssql query (callback, promise, or tagged template)
//   await db.connect()     -> connected pool
// We forward to the current live pool and (re)connect in the background so a
// dropped connection self-heals instead of failing forever.
module.exports = {
    connect,
    get pool() { return pool; },
    request() {
        return live().request();
    },
    query(...args) {
        const cb = typeof args[args.length - 1] === 'function' ? args[args.length - 1] : null;
        if (!pool || !pool.connected) {
            connect().catch(() => {});
            const err = new mssql.ConnectionError('Database connection not ready, reconnecting — please retry.');
            if (cb) return cb(err);
            return Promise.reject(err);
        }
        return pool.query(...args);
    },
};