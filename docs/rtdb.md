# Firebase Realtime Database (RTDB) Presence & Telemetry

## 1. Role of RTDB in Emergixx

While Cloud Firestore stores durable document records, Firebase Realtime Database (RTDB) is utilized for **sub-second ephemeral state synchronization**:
1. **Live Responder Presence**: Instant online/offline detection using Firebase `.info/connected`.
2. **Ephemeral Cluster Coordinator Election**: Determining which connected node serves as the primary uplink gateway for a local disaster sector.
3. **Telemetry Channel**: Live streaming of responder battery levels and GPS breadcrumbs.

---

## 2. RTDB Tree Data Model

```json
{
  "presence": {
    "EX-7A29F1": {
      "online": true,
      "lastSeen": 1710673200000,
      "batteryLevel": 82,
      "latitude": 19.0760,
      "longitude": 72.8777,
      "role": "responder"
    }
  },
  "mesh_gateways": {
    "sector_4": {
      "gatewayDeviceId": "EX-RESP-01",
      "uplinkType": "satellite",
      "electedAt": 1710672000000
    }
  }
}
```

---

## 3. Disconnection Cleanup (`onDisconnect`)

When a responder or gateway loses cellular or satellite uplink, RTDB automatically executes pre-registered teardown hooks without requiring an active packet from the dying device:

```javascript
const userPresenceRef = database.ref(`/presence/${myDeviceId}`);

database.ref('.info/connected').on('value', (snap) => {
  if (snap.val() === true) {
    // Register onDisconnect handler
    userPresenceRef.onDisconnect().set({
      online: false,
      lastSeen: firebase.database.ServerValue.TIMESTAMP
    });

    // Set online state
    userPresenceRef.set({
      online: true,
      lastSeen: firebase.database.ServerValue.TIMESTAMP,
      batteryLevel: currentBattery
    });
  }
});
```

---

## 4. Security Rules (`database.rules.json`)

```json
{
  "rules": {
    ".read": "auth != null",
    "presence": {
      "$deviceId": {
        ".write": "auth != null || !data.exists()"
      }
    },
    "mesh_gateways": {
      ".write": "auth != null && auth.token.role == 'responder'"
    }
  }
}
```
