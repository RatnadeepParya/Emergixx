// Emergixx Command Center Client Application
document.addEventListener('DOMContentLoaded', () => {
  initRealtimeEvents();
  initMapIfPresent();
});

// Real-time Server-Sent Events (SSE) listener
function initRealtimeEvents() {
  if (!window.EventSource) return;
  const es = new EventSource('/api/v1/events');

  es.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      if (data.type === 'INCIDENT_NEW' || data.type === 'INCIDENT_UPDATED') {
        console.log('Realtime event received:', data);
        updateIncidentRow(data.payload);
        updateKpiCounters();
      }
    } catch (err) {
      console.error('Failed to parse SSE event:', err);
    }
  };

  es.onerror = (err) => {
    console.warn('SSE connection interrupted, retrying automatically...', err);
  };
}

// Leaflet Map Initialization
let mapInstance = null;
let markerLayerGroup = null;

function initMapIfPresent() {
  const mapEl = document.getElementById('leaflet-map');
  if (!mapEl || typeof L === 'undefined') return;

  // Center around disaster theater (e.g. 19.0760, 72.8777)
  mapInstance = L.map('leaflet-map', {
    zoomControl: true,
    attributionControl: false,
  }).setView([19.0760, 72.8777], 14);

  // High contrast dark tile layer (CARTO Dark Matter or fallback)
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    maxZoom: 19,
    subdomains: 'abcd',
  }).addTo(mapInstance);

  markerLayerGroup = L.layerGroup().addTo(mapInstance);

  // Load initial markers from API
  fetch('/api/v1/incidents')
    .then((res) => res.json())
    .then((incidents) => {
      incidents.forEach((inc) => addIncidentMarker(inc));
    })
    .catch((err) => console.error('Failed to load map incidents:', err));

  fetch('/api/v1/responders')
    .then((res) => res.json())
    .then((responders) => {
      responders.forEach((resp) => addResponderMarker(resp));
    })
    .catch((err) => console.error('Failed to load responders:', err));
}

function addIncidentMarker(inc) {
  if (!mapInstance || !inc.latitude || !inc.longitude) return;

  const isCritical = inc.severity === 'CRITICAL';
  const color = isCritical ? '#FF3B30' : (inc.severity === 'HIGH' ? '#FF9500' : '#0A84FF');

  const circle = L.circleMarker([inc.latitude, inc.longitude], {
    radius: isCritical ? 12 : 9,
    fillColor: color,
    color: '#ffffff',
    weight: 2,
    opacity: 1,
    fillOpacity: 0.85,
  });

  circle.bindPopup(`
    <div style="font-family: sans-serif; min-width: 180px;">
      <div style="font-weight: bold; font-size: 14px; margin-bottom: 4px; color: ${color}">
        ${inc.title}
      </div>
      <div style="font-size: 11px; margin-bottom: 6px; color: #555;">
        Status: <b>${inc.status}</b> | Severity: <b>${inc.severity}</b>
      </div>
      <div style="font-size: 12px; margin-bottom: 8px;">
        ${inc.description || 'No additional details provided'}
      </div>
      <div style="font-size: 10px; font-family: monospace; color: #888;">
        ID: ${inc.incidentId}
      </div>
    </div>
  `);

  circle.addTo(markerLayerGroup);
}

function addResponderMarker(resp) {
  if (!mapInstance || !resp.latitude || !resp.longitude) return;

  const marker = L.circleMarker([resp.latitude, resp.longitude], {
    radius: 8,
    fillColor: '#34C759',
    color: '#ffffff',
    weight: 2,
    opacity: 1,
    fillOpacity: 0.9,
  });

  marker.bindPopup(`
    <div style="font-family: sans-serif;">
      <div style="font-weight: bold; font-size: 13px; color: #34C759">
        🚑 ${resp.callsign}
      </div>
      <div style="font-size: 11px; color: #444;">
        Status: <b>${resp.status.toUpperCase()}</b> | Battery: <b>${resp.batteryLevel}%</b>
      </div>
    </div>
  `);

  marker.addTo(markerLayerGroup);
}

// Modal handling
function openDispatchModal(incidentId, title) {
  const modal = document.getElementById('dispatch-modal');
  if (!modal) return;
  document.getElementById('modal-incident-id').value = incidentId;
  document.getElementById('modal-incident-title').innerText = title;
  modal.classList.add('active');
}

function closeDispatchModal() {
  const modal = document.getElementById('dispatch-modal');
  if (modal) modal.classList.remove('active');
}

function submitDispatch() {
  const incidentId = document.getElementById('modal-incident-id').value;
  const responderId = document.getElementById('modal-responder-select').value;
  const notes = document.getElementById('modal-dispatch-notes').value;

  fetch(`/api/v1/incidents/${incidentId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      status: 'DISPATCHED',
      assignedResponderId: responderId,
      notes: notes,
    }),
  })
    .then((res) => res.json())
    .then(() => {
      closeDispatchModal();
      window.location.reload();
    })
    .catch((err) => alert('Failed to dispatch unit: ' + err.message));
}

function resolveIncident(incidentId) {
  if (!confirm('Mark incident ' + incidentId + ' as RESOLVED?')) return;

  fetch(`/api/v1/incidents/${incidentId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status: 'RESOLVED' }),
  })
    .then((res) => res.json())
    .then(() => window.location.reload())
    .catch((err) => alert('Failed to resolve incident: ' + err.message));
}

function updateIncidentRow(payload) {
  // If incident row exists in DOM, update status badge
  const row = document.getElementById(`row-${payload.incidentId}`);
  if (row) {
    const statusCell = row.querySelector('.status-cell');
    if (statusCell) {
      statusCell.innerHTML = `<span class="badge badge-info">${payload.status}</span>`;
    }
  }
}

function updateKpiCounters() {
  fetch('/api/v1/incidents')
    .then((res) => res.json())
    .then((list) => {
      const activeEl = document.getElementById('kpi-active-sos');
      if (activeEl) {
        const count = list.filter((i) => i.status !== 'RESOLVED').length;
        activeEl.innerText = count;
      }
    });
}
