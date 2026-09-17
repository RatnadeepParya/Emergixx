# Emergixx System Architecture

## 1. Executive Summary

**Emergixx** is an enterprise-grade, offline-first, decentralized emergency communication platform engineered to maintain life-safety communications when cellular networks, power grids, and internet backbones suffer catastrophic failure.

The architectural foundation of Emergixx is **strictly peer-to-peer and local-first**. Centralized cloud infrastructure is treated strictly as an opportunistic enhancement when connectivity is available, rather than a prerequisite for communication.

```
+-------------------------------------------------------------------------+
|                        EMERGIXX SYSTEM TOPOLOGY                         |
+-------------------------------------------------------------------------+

  [ Disconnected Disaster Theater ]              [ Connected Base / Cloud ]
 
   +------------+         BLE GATT          +------------+
   |   Node A   |<=========================>|   Node B   |
   | (Survivor) |                           |  (Courier) |
   +------------+                           +------------+
         ^                                        ^
         | Wi-Fi Direct                           | Opportunistic
         v                                        v Gateway
   +------------+         BLE GATT          +------------+       HTTPS      +------------------+
   |   Node C   |<=========================>|   Node D   |=================>| Central Cloud /  |
   | (Shelter)  |                           | (Responder)|                  | Firebase Gateway |
   +------------+                           +------------+                  +------------------+
                                                                                     |
                                                                                     v
                                                                            +------------------+
                                                                            | Command Center   |
                                                                            |  Web Dashboard   |
                                                                            +------------------+
```

---

## 2. Core Architectural Pillars

1. **Zero-Trust Store-and-Forward Mesh (Delay-Tolerant Networking)**
   - Nodes operate autonomously without a centralized broker.
   - When a peer comes within physical radio range (Bluetooth LE or Wi-Fi Direct), messages queued for transit are opportunistically exchanged.
   - Intermediate relay nodes forward encrypted ciphertext packets without possessing the keys to decrypt them.
2. **Cryptographic Identity Autonomy**
   - Device identities are derived directly from asymmetric cryptographic keys (Ed25519 and Curve25519) generated entirely on the device.
   - No phone numbers, email addresses, or central SIM registration required.
   - Device identifiers follow the deterministic format `EX-[HEX6]` (e.g. `EX-7A29F1`).
3. **Adaptive Battery Duty-Cycling**
   - Continuous high-power radio scanning depletes mobile batteries rapidly in survival situations.
   - Emergixx implements a dynamic 4-tier battery state machine (`Normal`, `PowerEfficient`, `EmergencyLowPower`, `Critical`) that automatically scales scan intervals from 1000ms down to 10,000ms and throttles Wi-Fi Direct.
4. **Strict Life-Safety Priority Queuing**
   - Packets are prioritized into four strict queues: `CRITICAL` (SOS alerts) > `HIGH` (Rescue acknowledgments) > `NORMAL` (Peer chat) > `LOW` (Telemetry & diagnostic encounters).
   - Starvation prevention ensures lower priority messages eventually progress while guaranteeing critical distress beacons are always dispatched first.
5. **Bidirectional Opportunistic Cloud Synchronization**
   - Whenever any node in the mesh achieves cellular or Wi-Fi internet connectivity, it acts as an **ephemeral gateway**.
   - Accumulated distress records, safety check-ins, and casualty counts are batched and uploaded to Cloud Firestore.
   - Authoritative civil defense broadcasts and rescue dispatch status updates are downloaded and re-injected into the offline mesh.

---

## 3. Layered Component Architecture

```
+------------------------------------------------------------------+
|                     PRESENTATION LAYER (UI)                     |
|  HomeScreen • SosBroadcastScreen • ChatScreen • MapScreen       |
|  DiagnosticsScreen • CheckinScreen • Command Center Web Portal  |
+------------------------------------------------------------------+
                                |
+------------------------------------------------------------------+
|                      DOMAIN & SERVICE LAYER                      |
|  SosService • CheckinService • RelayEngine • SyncService        |
+------------------------------------------------------------------+
                                |
+------------------------------------------------------------------+
|                    STORE-AND-FORWARD ROUTER                      |
|  StoreAndForwardRouter • MessagePriorityQueue • SeenMessagesLRU  |
|  ReplayProtector • PacketValidator                              |
+------------------------------------------------------------------+
                                |
+------------------------------------------------------------------+
|                   CRYPTOGRAPHIC ENGINE (E2EE)                    |
|  Ed25519 Signer • Curve25519 ECDH • AES-256-GCM / HMAC-SHA256    |
|  AuthorityVerifier • Hardware Secure Keystore / Keychain        |
+------------------------------------------------------------------+
         |                                           |
+----------------------+                   +-----------------------+
|  LOCAL STORAGE LAYER |                   | PHYSICAL NETWORK LAYER|
|  SQLite Database     |                   | Bluetooth LE GATT     |
|  SecureIdentityStore |                   | Wi-Fi Direct / P2P    |
|  SyncQueue           |                   | Cloud HTTP Gateway    |
+----------------------+                   +-----------------------+
```

---

## 4. Trust Boundaries & Security Segregation

| Domain | Boundary | Protection Mechanism |
| :--- | :--- | :--- |
| **Peer-to-Peer Transit** | Untrusted Intermediate Relays | AES-256-GCM authenticated encryption; intermediate nodes only see outer envelope routing metadata (Recipient ID, Message ID, TTL, Hop Count). |
| **SOS Distress Beacons** | Public Broadcast Domain | Signed with author's Ed25519 private key. Payload is cleartext for emergency responders, but tamper-proof. |
| **Emergency Groups** | Group Membership Boundary | 256-bit symmetric group key distributed out-of-band via secure QR or pairwise Curve25519 key exchange. |
| **Civil Defense Alerts** | National Authority Domain | Public key pinned in client binary; messages verified against trusted government authority registry. |
| **Cloud Synchronization** | Mobile Device to Cloud | TLS 1.3 + Firebase App Check + Firestore security rules validating Ed25519 sender device ID ownership. |

---

## 5. Failure Modes & Degradation Handling

1. **Total Radio Blackout (No nearby peers & no cellular)**
   - Local device stores all created SOS beacons, messages, and check-ins in durable SQLite storage.
   - Background service continues duty-cycled radio beacons awaiting encounters.
2. **High-Density Node Flooding (e.g. 1000+ nodes in evacuation stadium)**
   - Seen message LRU deduplication drops re-transmitted packets in $O(1)$ time.
   - Priority queue drops lowest-priority telemetry packets first when queue capacity is reached.
   - Hop limit (default 10 hops) and 72-hour TTL prevent broadcast storms and routing loops.
3. **Severe Battery Depletion (<15%)**
   - Wi-Fi Direct interface is automatically disabled.
   - Bluetooth advertising window is narrowed to 100ms every 5,000ms.
   - Screen enforces high-contrast OLED true black emergency mode to minimize display power consumption.
