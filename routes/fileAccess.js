const express = require('express');
const app = express();

// This router previously exposed a catch-all `GET /*` that served any file
// under this directory by name (including db.js, which holds DB credentials)
// to any authenticated user, plus a dead `/fileshow/:owner_id` endpoint left
// over from an unrelated project (referenced a non-existent `owner_master`
// table). Nothing in this app calls `/file/*`, so both were removed rather
// than hardened.

module.exports = app;
