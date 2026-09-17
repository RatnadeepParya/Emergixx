# Emergixx Mesh Wire Protocol Specification (`EMERGIXX/1`)

## 1. Protocol Overview

The **Emergixx Protocol (`EMERGIXX/1`)** is an opportunistic, store-and-forward mesh transmission protocol designed for constrained, high-latency, intermittently connected wireless environments.

Every packet transmitted over Bluetooth LE (GATT MTU 512) or Wi-Fi Direct is framed using either a compact binary encoding or canonical JSON encapsulation.

---

## 2. Binary Packet Wire Format

A standard binary packet consists of a **32-byte Fixed Header** followed by a variable-length payload and an attached 64-byte Ed25519 signature:

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|          Magic (0x4558)       |  Version (1)  |  MsgType (1B) |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Priority (1B) |   TTL (1B)    | HopCount (1B) |  Reserved(1B) |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      Timestamp (64 bits)                      |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      ExpiresAt (64 bits)                      |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                     Payload Length (32 bits)                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Sender Device ID (8 bytes)                 |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                  Recipient Device ID (8 bytes)                |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      Message Nonce (16 bytes)                 |
|                                                               |
|                                                               |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        Payload Data...                        |
|                     (Variable Length, N bytes)                |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                  Ed25519 Signature (64 bytes)                 |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

### Field Definitions

| Field | Length | Description |
| :--- | :--- | :--- |
| **Magic** | 2 bytes | Protocol identifier: `0x4558` (`EX`). |
| **Version** | 1 byte | Protocol version: `1` (`EMERGIXX/1`). |
| **MsgType** | 1 byte | `0x01`=SOS, `0x02`=Chat, `0x03`=Ack, `0x04`=Checkin, `0x05`=Broadcast, `0x06`=Telemetry. |
| **Priority** | 1 byte | `0x00`=Critical, `0x01`=High, `0x02`=Normal, `0x03`=Low. |
| **TTL** | 1 byte | Time-To-Live hop counter. Decremented by 1 at each forward. Dropped if 0. Default: 10. |
| **HopCount** | 1 byte | Incremented by 1 at each forward. Tracks geographical mesh distance traversed. |
| **Timestamp**| 8 bytes | Milliseconds since Unix epoch (Big-Endian 64-bit int). |
| **ExpiresAt**| 8 bytes | Expiration epoch timestamp. Dropped when expired. Default SOS: +72 hrs; Chat: +48 hrs. |
| **Length** | 4 bytes | Byte length of following payload data. |
| **SenderId** | 8 bytes | Compact ASCII representation of sender `EX-XXXXXX`. |
| **Recipient**| 8 bytes | Target device ID or `BROADCAST_ALL` or `GROUP:[ID]`. |
| **Nonce** | 16 bytes| Cryptographic unique replay prevention nonce. |
| **Payload** | N bytes | Ciphertext (AES-256-GCM) or cleartext SOS structured JSON. |
| **Signature**| 64 bytes| RFC 8032 Ed25519 digital signature over the entire header and payload. |

---

## 3. Store-and-Forward Routing Rules

1. **Self-Origination Check**: If `packet.senderDeviceId == myDeviceId`, drop immediately (prevents echo loops).
2. **Duplicate Detection ($O(1)$ LRU Index)**:
   - Every node maintains a bounded LRU cache of recently seen `messageId`s (default: 5,000 entries).
   - If `SeenMessagesIndex.contains(packet.messageId)`, drop with `RoutingDecision.droppedDuplicate`.
3. **Expiration & Hop Bounds**:
   - If `now > packet.expiresAt`, drop with `RoutingDecision.droppedExpired`.
   - If `packet.ttl <= 1` (or `packet.hopCount >= maxHopLimit`), do not forward further.
4. **Local Delivery vs Transit Forwarding**:
   - If `packet.recipientDeviceId == myDeviceId`: deliver locally.
   - If `packet.recipientDeviceId == 'BROADCAST_ALL'`: deliver locally **AND** queue for relay.
   - If `packet.recipientDeviceId.startsWith('GROUP:')`: deliver locally (if member) **AND** queue for relay.
   - If `packet.recipientDeviceId != myDeviceId`: queue for relay without local delivery.
5. **Encounter Memory Buffer**:
   - In opportunistic store-and-forward networks, a message must propagate to multiple distinct encounters.
   - The router records which peer IDs have received which messages (`Map<messageId, Set<peerId>>`).
   - A message is only forwarded to peer $P$ if $P \notin \text{ForwardedPeers}(M)$.

---

## 4. Priority Queue Scheduling & Starvation Prevention

The router maintains four queues:

1. **Critical Queue** (SOS alerts): Dispatched immediately. Starvation ratio: 8:1.
2. **High Queue** (Responder acknowledgments, safety check-ins).
3. **Normal Queue** (End-to-end encrypted peer chat messages).
4. **Low Queue** (Telemetry, diagnostics, peer discovery sync).

### Deficit Round Robin (DRR) Scheduling
To prevent the high-volume chat traffic from starving low-priority telemetry, or continuous distress beacons from permanently blocking normal communication, the queue implements weighted deficit round-robin dispatch: for every 8 critical packets dispatched, at least 1 normal/high packet is guaranteed a transmission slot.

---

## 5. Wire Codecs & Implementations

- Dart implementation: [`packages/protocol/lib/src/packet_codec.dart`](file:///Users/ratnadeepparya/Documents/Development/AntiGravity/Emergixx/packages/protocol/lib/src/packet_codec.dart)
- Unit tests: [`tests/protocol_test.dart`](file:///Users/ratnadeepparya/Documents/Development/AntiGravity/Emergixx/tests/protocol_test.dart)
