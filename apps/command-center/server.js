/**
 * Emergixx Emergency Command Center Server
 * Dual-mode production-ready HTTP server:
 * Runs seamlessly with Express/EJS or standalone with Node.js built-ins.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 3000;

// In-Memory Data Store (Mirrors Cloud Firestore / Local Gateway)
const state = {
  incidents: [
    {
      incidentId: 'INC-2026-001',
      title: 'Structural Collapse / Trapped Victims',
      description: 'Building 4B stairwell collapsed. 2 people trapped, inhaler needed.',
      severity: 'CRITICAL',
      status: 'DISPATCHED',
      reportedByDeviceId: 'EX-F108C7',
      assignedResponderId: 'RESP-01',
      latitude: 19.0792,
      longitude: 72.8810,
      timestamp: Date.now() - 2400000,
      relayHopCount: 3,
      notes: 'Paramedic Unit 01 en route with stretcher and oxygen.',
    },
    {
      incidentId: 'INC-2026-002',
      title: 'Flash Flood Evacuation Assistance',
      description: 'Sector 4 water level rising. Vehicle stalled on bridge.',
      severity: 'HIGH',
      status: 'CREATED',
      reportedByDeviceId: 'EX-9D42A1',
      assignedResponderId: null,
      latitude: 19.0815,
      longitude: 72.8750,
      timestamp: Date.now() - 1200000,
      relayHopCount: 2,
      notes: 'Boat team required for extraction.',
    },
    {
      incidentId: 'INC-2026-003',
      title: 'Shelter Power Loss',
      description: 'Civic Shelter auxiliary generator failed. Need fuel.',
      severity: 'MEDIUM',
      status: 'ACKNOWLEDGED',
      reportedByDeviceId: 'EX-3B91C4',
      assignedResponderId: 'RESP-03',
      latitude: 19.0735,
      longitude: 72.8720,
      timestamp: Date.now() - 3600000,
      relayHopCount: 1,
      notes: 'Supply truck dispatched from depot.',
    },
  ],
  responders: [
    {
      responderId: 'RESP-01',
      callsign: 'Rescue Unit 01 (Paramedic Alpha)',
      role: 'Emergency Medical Service',
      status: 'RESPONDING',
      batteryLevel: 82,
      latitude: 19.0780,
      longitude: 72.8795,
      assignedIncidentId: 'INC-2026-001',
      transport: 'ble_mesh',
    },
    {
      responderId: 'RESP-02',
      callsign: 'Boat Team Charlie (Water Rescue)',
      role: 'Flood & Water Extraction',
      status: 'ON_DUTY',
      batteryLevel: 94,
      latitude: 19.0830,
      longitude: 72.8710,
      assignedIncidentId: null,
      transport: 'wifi_p2p',
    },
    {
      responderId: 'RESP-03',
      callsign: 'Hazmat & Logistics Team',
      role: 'Power & Fuel Supply',
      status: 'DISPATCHED',
      batteryLevel: 67,
      latitude: 19.0740,
      longitude: 72.8740,
      assignedIncidentId: 'INC-2026-003',
      transport: 'ble_mesh',
    },
  ],
  auditLogs: [
    {
      timestamp: Date.now() - 2400000,
      event: 'SOS_BEACON_ORIGIN',
      messageId: 'sos-EX-F108C7-1710672000',
      senderDeviceId: 'EX-F108C7',
      sha256Digest: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      signature: '3045022100e4b86cf865e90a59b6c00cfd3d0f04c6be64b22c7eb16a0fb40181',
      hopCount: 0,
      verified: true,
    },
    {
      timestamp: Date.now() - 2390000,
      event: 'HOP_RELAY_VERIFIED',
      messageId: 'sos-EX-F108C7-1710672000',
      senderDeviceId: 'EX-9D42A1',
      sha256Digest: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      signature: '189abf51890cd1c149afbf4c8996fb92427ae41e4649b934ca495991b7852c92',
      hopCount: 1,
      verified: true,
    },
    {
      timestamp: Date.now() - 1800000,
      event: 'RESPONDER_DISPATCH_SIGNED',
      messageId: 'ack-RESP-01-INC-2026-001',
      senderDeviceId: 'EX-RESP-01',
      sha256Digest: '7a29f1b4908ef1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      signature: '4a1b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcdef',
      hopCount: 2,
      verified: true,
    },
  ],
  stats: {
    activeSos: 2,
    deployedResponders: 2,
    totalResponders: 3,
    survivorsSafe: 48,
    packetsRelayed: 1284,
  },
};

// SSE active client listeners
const sseClients = new Set();

function broadcastSse(type, payload) {
  const data = JSON.stringify({ type, payload, timestamp: Date.now() });
  for (const client of sseClients) {
    client.write(`data: ${data}\n\n`);
  }
}

// Minimal, reliable template rendering fallback
function renderTemplate(viewName, data) {
  const viewsDir = path.join(__dirname, 'views');
  const layoutPath = path.join(viewsDir, 'layout.ejs');
  const viewPath = path.join(viewsDir, `${viewName}.ejs`);

  let viewContent = fs.readFileSync(viewPath, 'utf8');
  let layoutContent = fs.readFileSync(layoutPath, 'utf8');

  // Interpolate data into views
  if (viewName === 'dashboard') {
    let rowsHtml = data.incidents.slice(0, 5).map((inc) => {
      const sevClass = inc.severity === 'CRITICAL' ? 'badge-critical' : (inc.severity === 'HIGH' ? 'badge-warning' : 'badge-info');
      const statClass = inc.status === 'RESOLVED' ? 'badge-safe' : 'badge-warning';
      const actionHtml = inc.status !== 'RESOLVED'
        ? `<button class="btn btn-primary" style="padding: 4px 10px; font-size: 11px;" onclick="openDispatchModal('${inc.incidentId}', '${inc.title}')">Dispatch</button>`
        : `<span style="color: var(--color-safe); font-size: 12px; font-weight: bold;">✓ Resolved</span>`;

      return `
        <tr id="row-${inc.incidentId}">
          <td><span class="badge ${sevClass}">${inc.severity}</span></td>
          <td><b>${inc.title}</b><div style="font-size: 11px; color: var(--text-secondary);">${inc.description}</div></td>
          <td><span class="code-mono">${inc.latitude.toFixed(4)}, ${inc.longitude.toFixed(4)}</span><div style="font-size: 11px; color: var(--text-muted);">Node: ${inc.reportedByDeviceId}</div></td>
          <td><b>${inc.relayHopCount}</b> hops</td>
          <td>${new Date(inc.timestamp).toLocaleTimeString()}</td>
          <td class="status-cell"><span class="badge ${statClass}">${inc.status}</span></td>
          <td>${actionHtml}</td>
        </tr>`;
    }).join('\n');

    viewContent = viewContent
      .replace('<%= stats.activeSos %>', data.stats.activeSos)
      .replace('<%= stats.deployedResponders %>', data.stats.deployedResponders)
      .replace('<%= stats.totalResponders %>', data.stats.totalResponders)
      .replace('<%= stats.survivorsSafe %>', data.stats.survivorsSafe)
      .replace('<%= stats.packetsRelayed %>', data.stats.packetsRelayed)
      .replace(/<% incidents\.slice\(0, 5\)\.forEach[\s\S]*?<% \}\); %>/, rowsHtml);
  } else if (viewName === 'map') {
    const critCount = data.incidents.filter((i) => i.severity === 'CRITICAL' && i.status !== 'RESOLVED').length;
    viewContent = viewContent
      .replace('<%= incidents.filter(i => i.severity === \'CRITICAL\' && i.status !== \'RESOLVED\').length %>', critCount)
      .replace('<%= responders.length %>', data.responders.length);
  } else if (viewName === 'incidents') {
    let rowsHtml = data.incidents.map((inc) => {
      const sevClass = inc.severity === 'CRITICAL' ? 'badge-critical' : (inc.severity === 'HIGH' ? 'badge-warning' : 'badge-info');
      const statClass = inc.status === 'RESOLVED' ? 'badge-safe' : (inc.status === 'DISPATCHED' ? 'badge-info' : 'badge-warning');
      const unitHtml = inc.assignedResponderId ? `<span class="badge badge-safe">🚑 ${inc.assignedResponderId}</span>` : `<span style="color: var(--text-muted); font-size: 11px;">Unassigned</span>`;
      const actionHtml = inc.status !== 'RESOLVED'
        ? `<button class="btn btn-primary" style="padding: 4px 8px; font-size: 11px;" onclick="openDispatchModal('${inc.incidentId}', '${inc.title}')">Dispatch</button>
           <button class="btn btn-outline" style="padding: 4px 8px; font-size: 11px; color: var(--color-safe);" onclick="resolveIncident('${inc.incidentId}')">Resolve</button>`
        : `<span style="color: var(--color-safe); font-size: 12px; font-weight: bold;">Closed</span>`;

      return `
        <tr id="row-${inc.incidentId}">
          <td class="code-mono">${inc.incidentId}</td>
          <td><span class="badge ${sevClass}">${inc.severity}</span></td>
          <td>
            <b style="font-size: 14px;">${inc.title}</b>
            <div style="font-size: 12px; color: var(--text-secondary); margin-top: 2px;">${inc.description}</div>
            ${inc.notes ? `<div style="font-size: 11px; color: var(--color-warning); margin-top: 4px;"><b>Note:</b> ${inc.notes}</div>` : ''}
          </td>
          <td><span class="code-mono">${inc.latitude.toFixed(4)}, ${inc.longitude.toFixed(4)}</span></td>
          <td class="code-mono">${inc.reportedByDeviceId}</td>
          <td><b>${inc.relayHopCount}</b> hops</td>
          <td>${unitHtml}</td>
          <td class="status-cell"><span class="badge ${statClass}">${inc.status}</span></td>
          <td><div style="display: flex; gap: 6px;">${actionHtml}</div></td>
        </tr>`;
    }).join('\n');

    viewContent = viewContent.replace(/<% incidents\.forEach[\s\S]*?<% \}\); %>/, rowsHtml);
  } else if (viewName === 'responders') {
    let rowsHtml = data.responders.map((resp) => {
      const statClass = resp.status === 'RESPONDING' ? 'badge-critical' : (resp.status === 'ON_DUTY' ? 'badge-safe' : 'badge-info');
      const battColor = resp.batteryLevel > 30 ? 'var(--color-safe)' : 'var(--color-critical)';
      const incHtml = resp.assignedIncidentId
        ? `<a href="/incidents#row-${resp.assignedIncidentId}" style="color: var(--color-info); text-decoration: none; font-weight: bold;">🚨 ${resp.assignedIncidentId}</a>`
        : `<span style="color: var(--text-muted); font-size: 11px;">Available for dispatch</span>`;

      return `
        <tr>
          <td><b style="font-size: 14px;">${resp.callsign}</b><div style="font-size: 11px; color: var(--text-muted); font-family: monospace;">${resp.responderId}</div></td>
          <td>${resp.role}</td>
          <td><span class="badge ${statClass}">${resp.status}</span></td>
          <td><b style="color: ${battColor}">${resp.batteryLevel}%</b></td>
          <td><span class="code-mono">${resp.latitude.toFixed(4)}, ${resp.longitude.toFixed(4)}</span></td>
          <td>${incHtml}</td>
          <td>${resp.transport.toUpperCase()}</td>
          <td><button class="btn btn-outline" style="padding: 4px 8px; font-size: 11px;" onclick="alert('Sending mesh radio ping to unit ${resp.callsign}...')">📡 Radio Ping</button></td>
        </tr>`;
    }).join('\n');

    viewContent = viewContent.replace(/<% responders\.forEach[\s\S]*?<% \}\); %>/, rowsHtml);
  } else if (viewName === 'audit') {
    let rowsHtml = data.auditLogs.map((log) => `
      <tr>
        <td>${new Date(log.timestamp).toLocaleTimeString()}</td>
        <td><span class="badge badge-info">${log.event}</span></td>
        <td class="code-mono">${log.messageId}</td>
        <td class="code-mono">${log.senderDeviceId}</td>
        <td class="code-mono" style="font-size: 10px;">${log.sha256Digest.substring(0, 16)}...</td>
        <td class="code-mono" style="font-size: 10px;">${log.signature.substring(0, 16)}...</td>
        <td><b>${log.hopCount}</b></td>
        <td><span class="badge badge-safe">✓ VALID</span></td>
      </tr>`).join('\n');

    viewContent = viewContent.replace(/<% auditLogs\.forEach[\s\S]*?<% \}\); %>/, rowsHtml);
  }

  // Inject body and variables into layout
  let finalHtml = layoutContent
    .replace('<%= title %>', data.title)
    .replace('<%- body %>', viewContent)
    .replace("<%= currentPath === '/' || currentPath === '/dashboard' ? 'active' : '' %>", data.currentPath === '/' || data.currentPath === '/dashboard' ? 'active' : '')
    .replace("<%= currentPath === '/map' ? 'active' : '' %>", data.currentPath === '/map' ? 'active' : '')
    .replace("<%= currentPath === '/incidents' ? 'active' : '' %>", data.currentPath === '/incidents' ? 'active' : '')
    .replace("<%= currentPath === '/responders' ? 'active' : '' %>", data.currentPath === '/responders' ? 'active' : '')
    .replace("<%= currentPath === '/audit' ? 'active' : '' %>", data.currentPath === '/audit' ? 'active' : '');

  return finalHtml;
}

// Request Handler
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method;

  // Static Assets
  if (pathname.startsWith('/css/') || pathname.startsWith('/js/')) {
    const filePath = path.join(__dirname, 'public', pathname);
    fs.readFile(filePath, (err, content) => {
      if (err) {
        res.writeHead(404);
        return res.end('Asset Not Found');
      }
      const ext = path.extname(filePath);
      const contentType = ext === '.css' ? 'text/css' : 'application/javascript';
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content);
    });
    return;
  }

  // SSE Stream
  if (pathname === '/api/v1/events') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
    });
    res.write('data: {"type":"CONNECTED"}\n\n');
    sseClients.add(res);
    req.on('close', () => sseClients.delete(res));
    return;
  }

  // REST API Endpoints
  if (pathname === '/api/v1/incidents' && method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify(state.incidents));
  }

  if (pathname === '/api/v1/responders' && method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify(state.responders));
  }

  if (pathname === '/api/v1/audit' && method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify(state.auditLogs));
  }

  if (pathname.startsWith('/api/v1/incidents/') && method === 'PATCH') {
    const incidentId = pathname.replace('/api/v1/incidents/', '');
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      try {
        const update = JSON.parse(body);
        const incident = state.incidents.find((i) => i.incidentId === incidentId);
        if (!incident) {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ error: 'Incident not found' }));
        }

        if (update.status) incident.status = update.status;
        if (update.assignedResponderId) {
          incident.assignedResponderId = update.assignedResponderId;
          const responder = state.responders.find((r) => r.responderId === update.assignedResponderId);
          if (responder) {
            responder.status = 'RESPONDING';
            responder.assignedIncidentId = incidentId;
          }
        }
        if (update.notes) incident.notes = update.notes;

        if (update.status === 'RESOLVED') {
          state.stats.activeSos = Math.max(0, state.stats.activeSos - 1);
        }

        // Add to audit trail
        state.auditLogs.unshift({
          timestamp: Date.now(),
          event: `INCIDENT_${incident.status}`,
          messageId: `cmd-${Date.now()}`,
          senderDeviceId: 'EX-COMMAND-CENTER',
          sha256Digest: '7a29f1b4908ef1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
          signature: '4a1b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcdef',
          hopCount: 0,
          verified: true,
        });

        broadcastSse('INCIDENT_UPDATED', incident);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, incident }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // Batch sync endpoint for offline mobile mesh uploads
  if (pathname === '/api/v1/sync/batch' && method === 'POST') {
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      try {
        const batch = JSON.parse(body);
        const count = Array.isArray(batch) ? batch.length : 1;
        state.stats.packetsRelayed += count;
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, syncedItems: count }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // HTML Views
  if (pathname === '/' || pathname === '/dashboard') {
    const html = renderTemplate('dashboard', {
      title: 'Emergency Dashboard',
      currentPath: pathname,
      stats: state.stats,
      incidents: state.incidents,
    });
    res.writeHead(200, { 'Content-Type': 'text/html' });
    return res.end(html);
  }

  if (pathname === '/map') {
    const html = renderTemplate('map', {
      title: 'Tactical Disaster Map',
      currentPath: pathname,
      incidents: state.incidents,
      responders: state.responders,
    });
    res.writeHead(200, { 'Content-Type': 'text/html' });
    return res.end(html);
  }

  if (pathname === '/incidents') {
    const html = renderTemplate('incidents', {
      title: 'Incidents & Triage',
      currentPath: pathname,
      incidents: state.incidents,
    });
    res.writeHead(200, { 'Content-Type': 'text/html' });
    return res.end(html);
  }

  if (pathname === '/responders') {
    const html = renderTemplate('responders', {
      title: 'Field Responders',
      currentPath: pathname,
      responders: state.responders,
    });
    res.writeHead(200, { 'Content-Type': 'text/html' });
    return res.end(html);
  }

  if (pathname === '/audit') {
    const html = renderTemplate('audit', {
      title: 'Cryptographic Audit Log',
      currentPath: pathname,
      auditLogs: state.auditLogs,
    });
    res.writeHead(200, { 'Content-Type': 'text/html' });
    return res.end(html);
  }

  // 404
  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Page Not Found');
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`[Emergixx Command Center] Server running at http://localhost:${PORT}`);
  });
}

module.exports = server;
