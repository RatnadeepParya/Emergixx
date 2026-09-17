# Emergixx — Enterprise-Grade Decentralized Emergency Communication Platform

[![CI Pipeline](https://github.com/RatnadeepParya/Emergixx/actions/workflows/ci.yml/badge.svg)](https://github.com/RatnadeepParya/Emergixx/actions/workflows/ci.yml)
[![Security Audit](https://github.com/RatnadeepParya/Emergixx/actions/workflows/security.yml/badge.svg)](https://github.com/RatnadeepParya/Emergixx/actions/workflows/security.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Protocol](https://img.shields.io/badge/Protocol-EMERGIXX%2F1-red.svg)](docs/protocol.md)

Emergixx is an enterprise-grade, offline-first decentralized emergency communication mobile application and incident command platform. It enables individuals and first responders to communicate, broadcast emergency SOS alerts, share GPS locations, coordinate rescue groups, and relay messages across peer-to-peer (P2P) mesh networks **even when cellular networks, Wi-Fi internet, and central infrastructure have completely collapsed**.

```text
=============================================================================
                          OFFLINE DISASTER SCENARIO
  Cellular = OFF  |  Mobile Data = OFF  |  Wi-Fi Internet = OFF  |  Cloud = DOWN
=============================================================================
     Device A (Survivor)          Device B (Relay)          Device C (Responder)
     [SOS Broadcast]  ─────────►   [Store & Forward] ─────►  [Acknowledge SOS]
     (Signed Ed25519)              (Transit Ciphertext)      (Response En Route)
=============================================================================
```

---

## Key Capabilities

- **Zero-Internet Local-First Operation**: Full discovery, messaging, SOS broadcasts, check-ins, and group coordination operate purely on device radios (Bluetooth Low Energy, Wi-Fi Direct, Multicast LAN).
- **Multi-Transport Abstraction (`PeerTransport`)**: Pluggable transport architecture supporting BLE GATT services, Wi-Fi P2P, WebRTC local data channels, and loopback simulation.
- **End-to-End Cryptographic Security (`Zero Trust`)**: Ed25519 identity keypairs with SHA-256 fingerprint derivation (`EX-XXXXXX`), digital signatures, and X25519 ECDH + ChaCha20-Poly1305 / AES-256-GCM message encryption.
- **Store-and-Forward Mesh Routing**: Opportunistic multi-hop message relay with TTL controls (max 10 hops), duplicate packet suppression (`SeenMessagesFilter`), priority queuing (`CRITICAL` > `HIGH` > `NORMAL` > `LOW`), and delivery receipts.
- **Life-Saving Emergency Mode**: Dedicated high-contrast, high-stress SOS workflow transmitting medical information, battery percentage, GPS coordinates, and distress notes.
- **Safety Check-In & Family Groups**: One-touch safety status (`I AM SAFE`, `I NEED HELP`, `I AM MOVING`, `I AM UNABLE TO MOVE`) with family mesh synchronization.
- **Battery-Aware Radio Duty Cycling**: Adaptive radio scanning based on battery reserve (>50% Normal, 20-50% Efficient, <20% Emergency Low-Power, <5% Critical) to preserve device survival time.
- **Web Incident Command Center**: Express + EJS web portal featuring interactive offline Leaflet maps, live incident triage, responder dispatching, and audit logs.
- **Idempotent Cloud Synchronization**: Automatic reconciliation with Firebase Firestore and Realtime Database when internet connectivity is re-established.

---

## Monorepo Architecture

```text
emergixx/
├── apps/
│   ├── mobile/             # Flutter (Android & iOS) mobile application
│   └── command-center/     # Web Incident Command Center (Node.js, Express, EJS, Leaflet)
├── packages/
│   ├── protocol/           # EMERGIXX/1 packet serialization, priority queues & routing
│   ├── crypto/             # Ed25519 signing, X25519 ECDH, AEAD & authority verification
│   ├── models/             # Universal models (Message, SOS, Incident, CheckIn, Peer)
│   ├── validation/         # Nonce replay protection and structural packet validation
│   └── shared/             # Logging with PII redaction, battery monitoring, network state
├── functions/              # Firebase Cloud Functions (FCM alerts, sync batching, cron cleanup)
├── backend/                # Node.js Express REST API (/api/v1/) with RBAC
├── docs/                   # 18 in-depth architectural and operational guides
├── tests/                  # Unit tests and multi-node mesh simulator (10, 50, 100 devices)
└── scripts/                # Test orchestration and simulation runners
```

---

## Quick Start

### 1. Prerequisites
- **Dart SDK**: 3.0+
- **Flutter SDK**: 3.19+
- **Node.js**: 18+ (20+ recommended)
- **npm** or **bun**

### 2. Running Core Tests & Mesh Simulation
Emergixx includes a mesh simulator that verifies peer discovery, packet relay, duplicate suppression, and hop limits across simulated devices:

```bash
# Run unit & cryptographic tests
dart test tests/protocol_test.dart
dart test tests/crypto_test.dart
dart test tests/store_and_forward_test.dart

# Run 10-node & 50-node disaster mesh simulation
dart run tests/mesh_simulation.dart --nodes=10
dart run tests/mesh_simulation.dart --nodes=50
```

### 3. Running the Emergency Command Center
```bash
cd apps/command-center
npm install
npm run dev
# Command Center runs at http://localhost:3000
```

### 4. Running the Flutter Mobile Application
```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## Documentation Index

Explore our comprehensive technical guides in [`docs/`](docs/):
- [Architecture Overview](docs/architecture.md)
- [EMERGIXX/1 Protocol Specification](docs/protocol.md)
- [P2P Mesh Networking & Transports](docs/p2p-networking.md)
- [Zero-Trust Cryptography & E2EE](docs/encryption.md)
- [Identity & Key Derivation](docs/identity.md)
- [Offline-First Local Storage](docs/offline-first.md)
- [Cloud Synchronization & Conflict Resolution](docs/synchronization.md)
- [Android Platform & Background Restrictions](docs/android.md)
- [iOS Limitations & Keychain Management](docs/ios.md)
- [Command Center Operations](docs/command-center.md)
- [Disaster Recovery SOP](docs/disaster-recovery.md)
- [Security & Threat Model](docs/security.md)
- [Privacy Principles](docs/privacy.md)
- [Testing & Simulation Guide](docs/testing.md)
- [Production Deployment](docs/deployment.md)

---

## License

Emergixx is licensed under the [MIT License](LICENSE).
Copyright (c) 2026 Ratnadeep Parya.
