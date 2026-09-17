# Security Architecture & Threat Model

## 1. Threat Model & Adversarial Assumptions

In catastrophic emergency conditions, communication networks may face hostile environments:
- **Untrusted / Compromised Intermediate Nodes**: Bad actors or compromised devices running rogue mesh code attempting to eavesdrop, drop, or alter transit packets.
- **Replay Attacks**: Attackers recording previous SOS distress beacons and re-broadcasting them to waste emergency search-and-rescue resources.
- **Sybil Attacks**: An adversary generating thousands of virtual device identities to flood the store-and-forward routing queues.
- **Man-in-the-Middle (MITM)**: An active attacker attempting to intercept peer-to-peer key exchanges.
- **Hoax / False SOS Broadcasts**: Malicious actors sending falsified mass evacuation alerts.

---

## 2. Threat Analysis & Mitigations

| Threat | Attack Vector | Emergixx Defense Mechanism |
| :--- | :--- | :--- |
| **Eavesdropping on Private Chat** | Relay node sniffing transit payloads. | **Curve25519 ECDH + AES-256-GCM authenticated encryption**. Intermediate relay nodes only see outer routing headers. Payload remains ciphertext. |
| **Packet Tampering in Transit** | Modifying GPS coordinates in an SOS beacon. | **Ed25519 Digital Signatures (RFC 8032)** over the entire header and payload. Any modified byte invalidates the signature; packet is dropped immediately. |
| **Replay Attacks** | Re-sending an old SOS alert from 3 days ago. | **Cryptographic Nonce + 120-second Clock Drift Window + Expiration TTL**. Packets matching previously recorded nonces or expired TTL are rejected. |
| **Sybil Queue Exhaustion** | Flooding mesh with millions of fake low-priority messages. | **Deficit Round Robin (DRR) Scheduling + Strict Priority Queues**. Critical SOS alerts bypass normal queues; low-priority traffic is aggressively rate-limited and dropped first when memory exceeds 50 MB. |
| **MITM Key Interception** | Injecting a fake public key during discovery. | **Out-of-band QR Code Verification**. Users physically scan their partner's verified fingerprint, transitioning their trust state to `TrustState.trusted`. |
| **Fake Civil Defense Alerts** | Rogue node broadcasting fake evacuation orders. | **Government Authority Key Pinning**. The mobile application binary contains pinned root public keys for recognized civil defense authorities (`CIVIL_PROTECTION_AUTH_01`). Unsigned broadcasts are discarded. |

---

## 3. Cryptographic Verification Guarantees

Every packet arriving over a radio transport is subjected to the three-tier validation pipeline:
1. **`PacketValidator.validate(packet)`**: Verifies schema integrity, maximum payload size (64 KB limit), valid enum ranges, and non-empty IDs.
2. **`ReplayProtector.validateAndRecord(packet)`**: Validates nonce uniqueness and verifies clock timestamps are within acceptable drift parameters.
3. **`Signer.verifyMessage(message, authorPublicKey)`**: Validates the RFC 8032 Ed25519 signature against the sender's public key.
