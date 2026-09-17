const http = require('http');
const assert = require('assert');
const server = require('../server.js');

console.log('Testing Emergixx Command Center Server...');

// Verify server instance
assert(server instanceof http.Server, 'Server must be an instance of http.Server');
assert(typeof server.listen === 'function', 'Server must have listen method');

console.log('✓ Command Center server exported and validated successfully.');
process.exit(0);
