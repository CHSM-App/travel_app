const express = require('express');
const mssql = require('mssql');

const sqlConfig = {
    user: 'travel_admin',      // Replace with your username
    password:  'Travel@admin_123',//'@x8#H8$?hEQJU',   // Replace with your password
    server: 'winsome.grabweb.in' ,        // Replace with your server
    database: 'travel_agency',
   port:5691,
      // Replace with your database
    options: {
        encrypt: true, // Use this if you're on Windows Azure
        trustServerCertificate: true // Change to true for local dev / self-signed certs
    }
};
// Create a connection pool *once*, and reuse it everywhere
const db = mssql.connect(sqlConfig,function(err){
    if(err)
        console.log(err);
    else
    console.log("Connection Successful")


});
module.exports = db;