# Offline-First Architecture & SQLite Storage

## 1. Local-First Design Paradigm

In Emergixx, **the local device is the single source of truth**.
- Operations (sending SOS, chatting, logging safety check-ins, discovering peers) commit to the local SQLite database **immediately**.
- The UI never waits for network confirmation.
- Cloud synchronization is completely decoupled and handled asynchronously in the background.

---

## 2. Database Configuration & Reliability

- **Engine**: SQLite 3 with Write-Ahead Logging (`PRAGMA journal_mode = WAL`).
- **Synchronous Setting**: `PRAGMA synchronous = NORMAL` (ensures crash durability during sudden phone battery deaths).
- **Foreign Keys**: `PRAGMA foreign_keys = ON`.
- **Database File**: `emergixx_local.db` located in the application sandbox directory.

---

## 3. Schema Architecture (Tables & Indexes)

```
+--------------------------------------------------------------------------+
|                     EMERGIXX SQLITE TABLE TOPOLOGY                       |
+--------------------------------------------------------------------------+

     +-----------------------+              +-----------------------+
     |       messages        |              |      sos_records      |
     +-----------------------+              +-----------------------+
     | PK message_id         |              | PK sos_id             |
     |    sender_device_id   |              |    sender_device_id   |
     |    recipient_device_id|              |    latitude, longitude|
     |    priority           |              |    emergency_type     |
     |    payload            |              |    status             |
     |    signature          |              |    timestamp          |
     |    delivery_status    |              +-----------------------+
     +-----------------------+                         |
                 |                                     |
                 v                                     v
     +-------------------------------------------------------------+
     |                         sync_queue                          |
     | PK sync_id | collection | record_id | action | status | ts  |
     +-------------------------------------------------------------+
```

### Table Specifications

1. **`messages`**: Stores all inbound, outbound, and transit mesh messages.
   - Indexes: `idx_messages_recipient`, `idx_messages_timestamp`, `idx_messages_priority`.
2. **`sos_records`**: Stores all life-safety SOS alerts created locally or relayed across the mesh.
   - Indexes: `idx_sos_status`, `idx_sos_timestamp`.
3. **`checkins`**: Personal safety declarations (`SAFE`, `NEED_HELP`, `MOVING`, etc.).
   - Indexes: `idx_checkins_group`, `idx_checkins_timestamp`.
4. **`peers`**: Physical radio neighbor directory with RSSI, trust state, and encounter timestamps.
   - Indexes: `idx_peers_trust`.
5. **`groups`**: Encrypted emergency coordination groups and AES-GCM group keys.
6. **`group_members`**: Join table mapping devices to emergency groups.
7. **`transit_queue`**: Store-and-forward transit packets awaiting opportunistic peer encounters.
8. **`sync_queue`**: Decoupled change log tracking local mutations pending cloud upload.
9. **`breadcrumbs`**: High-frequency offline GPS trail coordinates for search-and-rescue backtrack navigation.
10. **`map_tiles`**: Cached offline vector map tiles and spatial metadata.

---

## 4. Sync Queue Transaction Pattern

Whenever a life-safety record is created locally, it is written inside a single atomic SQLite transaction with its corresponding sync queue entry:

```sql
BEGIN TRANSACTION;

-- 1. Insert local SOS record
INSERT INTO sos_records (
  sos_id, sender_device_id, latitude, longitude, emergency_type, message, status, timestamp
) VALUES (
  'sos-EX-7A29F1-1710672000', 'EX-7A29F1', 19.0760, 72.8777, 'TRAPPED', 'Need rescue', 'CREATED', 1710672000
);

-- 2. Enqueue for cloud sync when connection returns
INSERT INTO sync_queue (
  sync_id, collection, record_id, action, payload_json, status, created_at
) VALUES (
  'sync-001', 'emergencies', 'sos-EX-7A29F1-1710672000', 'UPSERT', '{"sosId":"..."}', 'PENDING', 1710672000
);

COMMIT;
```

---

## 5. Automatic Data Retention & Pruning

To keep disk usage below 50 MB on budget smartphones:
- Delivered normal chat messages are pruned after 48 hours.
- Expired transit packets are deleted when `expires_at < current_time`.
- Resolved SOS alerts are archived for 7 days then deleted locally if confirmed synced to cloud.
