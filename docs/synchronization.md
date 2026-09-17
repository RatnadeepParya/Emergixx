# Distributed Synchronization & Eventual Consistency

## 1. Synchronization Challenge in Disconnected Meshes

In an emergency disaster zone, network partitions are the norm, not the exception:
- Nodes $A$ and $B$ may communicate locally in Sector 4.
- Nodes $C$ and $D$ may communicate locally in Sector 8.
- Neither group has internet access.
- Hours later, Courier Node $E$ walks between the sectors, bridging the partition.
- Finally, Responder Node $F$ reaches a hilltop with a working satellite terminal and connects to Cloud Firestore.

---

## 2. Eventual Consistency & Conflict Resolution

Emergixx achieves multi-master eventual consistency using **State-Based CRDTs (Conflict-Free Replicated Data Types)** and deterministic conflict resolution rules:

### 1. Monotonic Status Progression (SOS Records)
An incident or SOS alert has a strictly ordered state machine:
$$\text{CREATED} \longrightarrow \text{RELAYED} \longrightarrow \text{DISPATCHED} \longrightarrow \text{ACKNOWLEDGED} \longrightarrow \text{RESOLVED}$$

- **State Rule**: A state transition can only advance forward. If Node A has state `CREATED` and receives state `ACKNOWLEDGED`, it unconditionally advances to `ACKNOWLEDGED`.
- A stale update with `CREATED` received after `ACKNOWLEDGED` is silently ignored.

### 2. Last-Write-Wins (LWW) with Lamport Timestamps
For editable fields (such as responder notes or survivor headcounts):
- Every mutation includes a monotonic timestamp and the author's device ID.
- In the event of identical timestamps, the lexicographically higher device ID wins, guaranteeing mathematical determinism across all offline nodes without coordination.

---

## 3. Ephemeral Gateway Synchronization Flow

```
   Offline Mobile Node                                  Cloud Sync Gateway (API)
            |                                                      |
            |--- 1. Detect Connectivity (Cellular/Wi-Fi) ---------->|
            |                                                      |
            |--- 2. POST /api/v1/sync/upload (Batch Pending) ------>|
            |       - Emergencies (Local SOS updates)              |
            |       - Safety Check-ins                             |
            |       - Mesh Telemetry Stats                         |
            |                                                      |
            |                                   3. Validate Ed25519 Sigs
            |                                   4. Ingest into Firestore
            |                                   5. Trigger FCM Alerts
            |<-- 6. 200 OK (Sync Acknowledged) --------------------|
            |                                                      |
            |--- 7. GET /api/v1/sync/download?since=[last_sync] --->|
            |                                                      |
            |<-- 8. 200 OK (Authoritative Data) -------------------|
            |       - Civil Protection Alerts                      |
            |       - Resolved Incidents                           |
            |       - Government Authority Public Keys             |
            |                                                      |
            | 9. Mark local sync_queue items complete              |
            | 10. Inject authoritative updates into local mesh     |
            v                                                      v
```

---

## 4. Idempotency & Batching Controls

- All upload requests include an `Idempotency-Key` formed as `[DeviceId]-[BatchTimestamp]`.
- Retried network calls after dropped TCP connections will not create duplicate entries in Cloud Firestore.
- Upload batches are chunked to **50 items per payload** to prevent buffer overruns on unstable satellite or 2G connections.
