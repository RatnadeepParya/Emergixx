# Emergency Command Center Operations & Architecture

## 1. Overview

The **Emergixx Emergency Command Center** (`apps/command-center/`) provides disaster incident commanders and municipal emergency management agencies with a centralized tactical dashboard.

It bridges field communications from the decentralized mesh into an intuitive, high-visibility web portal.

```
+-------------------------------------------------------------------------+
|                  COMMAND CENTER OPERATIONAL WORKFLOWS                   |
+-------------------------------------------------------------------------+

  [ Inbound Mesh SOS ] ---> [ Live SSE Stream ] ---> [ Incident Triage ]
                                                             |
                                                             v
  [ Responder Unit ] <--- [ Mesh Radio Ack ] <--- [ Dispatch Modal ]
```

---

## 2. Views & Capabilities

1. **Executive Dashboard (`/dashboard`)**:
   - Real-time KPI summary: Active SOS Alerts, Deployed Responders, Survivors Accounted For, Total Mesh Packets Relayed.
   - Priority triage feed with one-click dispatch triggers.
2. **Tactical Disaster Map (`/map`)**:
   - Powered by Leaflet with high-contrast dark cartographic tiles.
   - Real-time visual markers:
     - 🔴 Pulsing red beacons for active SOS distress alerts.
     - 🚑 Green markers for field responder teams with live battery readouts.
     - 🟢 Green pins for verified survivor safety check-ins.
     - ⛺ Blue icons for civic evacuation shelters and emergency aid depots.
3. **Incident Management & Triage (`/incidents`)**:
   - Filter by severity (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`) and status (`CREATED`, `DISPATCHED`, `ACKNOWLEDGED`, `RESOLVED`).
   - Assign responder units with tactical instructions.
   - Mark incidents resolved upon field confirmation.
4. **Field Responders Roster (`/responders`)**:
   - Team callsigns, specializations (e.g. Paramedic, Water Rescue, Hazmat).
   - Current battery levels, GPS coordinates, assigned tasks.
   - Mesh radio ping controls.
5. **Cryptographic Ledger Audit Trail (`/audit`)**:
   - Immutable audit trail recording every state transition.
   - Displays Ed25519 digital signature fingerprints, SHA-256 digests, and mesh relay hop counts.

---

## 3. Real-Time Telemetry via Server-Sent Events (SSE)

The web client establishes an open HTTP connection to `/api/v1/events`. When any incident is updated or ingested from the field, the server broadcasts an event immediately without requiring constant polling:

```javascript
// Server broadcast
function broadcastSse(type, payload) {
  const data = JSON.stringify({ type, payload, timestamp: Date.now() });
  for (const client of sseClients) {
    client.write(`data: ${data}\n\n`);
  }
}

// Client listener in apps/command-center/public/js/app.js
const es = new EventSource('/api/v1/events');
es.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === 'INCIDENT_NEW' || data.type === 'INCIDENT_UPDATED') {
    updateIncidentRow(data.payload);
    updateKpiCounters();
  }
};
```

---

## 4. Running the Command Center

```bash
# Start standalone HTTP server
node apps/command-center/server.js

# Or start with live file watching
npm run dev --prefix apps/command-center
```
The portal will be accessible at `http://localhost:3000`.
