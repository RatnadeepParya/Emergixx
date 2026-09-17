# Cloud Firestore Architecture & Security Rules

## 1. Overview

Cloud Firestore serves as the permanent cloud data store for Emergixx. It stores emergency incidents, safety check-ins, responder rosters, and authoritative civil defense announcements.

---

## 2. Document Collections Schema

### `/emergencies/{sosId}`
Stores SOS distress alerts ingested from the mesh network or mobile clients.
```json
{
  "sosId": "sos-EX-7A29F1-1710672000",
  "senderDeviceId": "EX-7A29F1",
  "latitude": 19.0760,
  "longitude": 72.8777,
  "altitude": 14.2,
  "accuracy": 6.0,
  "emergencyType": "TRAPPED",
  "message": "Stairwell collapsed on 4th floor.",
  "medicalInfo": "Blood Type O+, Asthma",
  "status": "DISPATCHED",
  "assignedResponderId": "RESP-01",
  "batteryLevel": 42,
  "timestamp": 1710672000000,
  "relayHopCount": 3,
  "syncedAt": 1710672500000
}
```

### `/checkins/{checkinId}`
Stores survivor and responder safety check-in declarations.
```json
{
  "checkinId": "chk-EX-3B91C4-1710673000",
  "userId": "EX-3B91C4",
  "deviceId": "EX-3B91C4",
  "displayName": "Sarah Connor",
  "groupId": "group-family",
  "status": "SAFE",
  "note": "Sheltering at Civic Center.",
  "latitude": 19.0748,
  "longitude": 72.8835,
  "timestamp": 1710673000000
}
```

### `/broadcasts/{broadcastId}`
Authoritative announcements issued by civil defense authorities.
```json
{
  "broadcastId": "gov-alert-001",
  "title": "Civil Protection Alert: Flood Warning",
  "message": "River levels rising in Sector 4.",
  "severity": "HIGH",
  "issuedBy": "CIVIL_PROTECTION_AUTH_01",
  "authoritySignature": "3045022100a98f12...",
  "timestamp": 1710665000000,
  "expiresAt": 1710751400000
}
```

---

## 3. Security Rules Architecture (`firestore.rules`)

Emergixx implements a strict zero-trust security rule set:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isResponder() {
      return isAuthenticated() &&
        (request.auth.token.role == 'responder' || request.auth.token.role == 'admin');
    }

    // Emergencies collection
    match /emergencies/{sosId} {
      // Anyone can read emergency SOS records to enable community mutual aid
      allow read: if true;

      // Unauthenticated mobile devices can create SOS records (life safety priority)
      allow create: if request.resource.data.sosId == sosId
                    && request.resource.data.emergencyType is string
                    && request.resource.data.timestamp is int;

      // Only certified responders and command center operators can update status
      allow update: if isResponder() ||
        (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'assignedResponderId', 'notes']));

      allow delete: if false; // Deletion strictly forbidden to preserve life-safety audit logs
    }

    // Broadcasts collection (Authoritative Announcements)
    match /broadcasts/{broadcastId} {
      allow read: if true;
      allow write: if isResponder(); // Only authenticated authorities can write broadcasts
    }
  }
}
```

---

## 4. Indexing & Query Optimizations

To support rapid triage queries during disaster emergencies, composite indexes are defined in `firestore.indexes.json`:
1. `emergencies`: `status` (ASC) + `severity` (DESC) + `timestamp` (DESC)
2. `emergencies`: `latitude` (ASC) + `longitude` (ASC) + `status` (ASC)
3. `checkins`: `groupId` (ASC) + `timestamp` (DESC)
