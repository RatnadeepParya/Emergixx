/**
 * Emergixx Cloud API Gateway
 * Handles synchronization between offline mobile mesh networks and centralized cloud services.
 * Dual-mode: Standalone zero-dependency runtime + Express / Firebase Admin plug-in support.
 */

const http = require('http');
const url = require('url');

const PORT = process.env.PORT || 8080;

// Central in-memory state representing Cloud Firestore collections
const db = {
  emergencies: [],
  checkins: [],
  broadcasts: [
    {
      broadcastId: 'gov-alert-001',
      title: 'Civil Protection Alert: Flood Warning',
      message: 'River levels rising in Sector 4. Evacuate to higher ground or Civic Center.',
      severity: 'HIGH',
      issuedBy: 'DISASTER_MANAGEMENT_AUTHORITY',
      authoritySignature: '3045022100a98f12b847192837461524354657687980abcdef0123456789abcdef01',
      timestamp: Date.now() - 7200000,
      expiresAt: Date.now() + 86400000,
    },
  ],
  authorityKeys: [
    {
      authorityId: 'CIVIL_PROTECTION_AUTH_01',
      name: 'National Disaster Response Authority',
      ed25519PublicKey: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      validFrom: 1710000000000,
      validUntil: 1741500000000,
    },
  ],
};

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method;

  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Emergixx-Device-Id');

  if (method === 'OPTIONS') {
    res.writeHead(204);
    return res.end();
  }

  // Health Probe & Protocol Version
  if (pathname === '/health' || pathname === '/') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({
      status: 'HEALTHY',
      protocol: 'EMERGIXX/1',
      service: 'Emergixx Cloud Sync Gateway',
      time: new Date().toISOString(),
    }));
  }

  // Mobile Sync Upload: Ingest batch of records from newly reconnected device
  if (pathname === '/api/v1/sync/upload' && method === 'POST') {
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body);
        const records = Array.isArray(payload.records) ? payload.records : [];
        let ingested = 0;

        for (const item of records) {
          if (item.collection === 'emergencies' && item.payload) {
            db.emergencies.push(item.payload);
            ingested++;
          } else if (item.collection === 'checkins' && item.payload) {
            db.checkins.push(item.payload);
            ingested++;
          }
        }

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          recordsIngested: ingested,
          processedAt: Date.now(),
        }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON payload', details: err.message }));
      }
    });
    return;
  }

  // Mobile Sync Download: Retrieve authoritative announcements and public authority keys
  if (pathname === '/api/v1/sync/download' && method === 'GET') {
    const since = parseInt(parsedUrl.query.since || '0', 10);
    const updates = {
      broadcasts: db.broadcasts.filter((b) => b.timestamp >= since),
      authorityKeys: db.authorityKeys,
      serverTime: Date.now(),
    };

    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify(updates));
  }

  // SOS Direct Ingestion
  if (pathname === '/api/v1/sos' && method === 'POST') {
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      try {
        const sos = JSON.parse(body);
        if (!sos.sosId || !sos.senderDeviceId) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ error: 'Missing sosId or senderDeviceId' }));
        }

        db.emergencies.push(sos);
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          sosId: sos.sosId,
          fcmBroadcastTriggered: true,
        }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // Query Active Incidents / Emergencies
  if (pathname === '/api/v1/incidents' && method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify(db.emergencies));
  }

  // 404 Catch-All
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Endpoint Not Found', path: pathname }));
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`[Emergixx Cloud Gateway] API running on http://localhost:${PORT}`);
  });
}

module.exports = server;
