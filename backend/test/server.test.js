const http = require('http');
const assert = require('assert');
const server = require('../server.js');

console.log('Testing Emergixx Cloud Gateway API Server...');

// Verify server instance
assert(server instanceof http.Server, 'Server must be an instance of http.Server');
assert(typeof server.listen === 'function', 'Server must have listen method');

console.log('✓ Cloud Gateway API server exported and validated successfully.');
process.exit(0);
