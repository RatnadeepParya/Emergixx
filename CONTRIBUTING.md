# Contributing to Emergixx

Thank you for your interest in contributing to **Emergixx**. Emergixx is built to preserve human life and communication during extreme crises, natural disasters, and total network failures. Because reliability is critical to life safety, our quality bar and security standards are stringent.

---

## Architectural Ground Rules

1. **Local-First & Offline-by-Default**
   - Core messaging, SOS alerts, and discovery must **never** depend on an active internet connection.
   - Cloud services (Firebase Firestore, RTDB, FCM) are strictly synchronization and aggregation layers, never the primary local source of truth.
2. **Zero Trust & End-to-End Encryption**
   - Private communication must always be encrypted using audited primitives (`Ed25519` / `X25519` / `ChaCha20-Poly1305` / `AES-GCM`).
   - Intermediate relay nodes must never have access to plaintext messages or private keys.
3. **Battery Conservation**
   - In disaster zones, power is scarce. All background radio scanning (BLE, Wi-Fi Direct) must strictly respect adaptive power duty-cycles based on remaining battery levels.
4. **No Fake or Mock Emergency Functionality**
   - Every emergency action (SOS, check-in, relay, location snapshot) must execute a real operation. Never simulate success if hardware or OS constraints prevent it; report true status to the user.

---

## Monorepo Layout

- `apps/mobile`: Primary Flutter mobile client for Android and iOS.
- `apps/command-center`: Web incident command center for dispatchers and search-and-rescue teams (Node.js, Express, EJS, Leaflet).
- `packages/protocol`: Wire format definitions, serialization, priority queues, and deduplication for `EMERGIXX/1`.
- `packages/crypto`: Cryptographic identities, key derivation, digital signatures, and payload encryption.
- `packages/models`: Universal data transfer objects and database entity models.
- `packages/validation`: Replay attack protection, clock drift validation, and packet schema enforcement.
- `packages/shared`: Logging with PII redaction, battery monitoring, and network state machine.
- `functions/`: Firebase Cloud Functions for alerts and maintenance.
- `backend/`: Node.js Express REST API for administrative dispatch.
- `docs/`: In-depth architectural, protocol, and operational documentation.
- `tests/`: Automated unit, cryptographic, store-and-forward, and 100-node mesh simulation suites.

---

## Development Workflow

1. Fork the repository and create your branch from `master` or `main`:
   ```bash
   git checkout -b feature/adaptive-beaconing
   ```
2. Run automated tests and static analysis:
   ```bash
   dart test tests/protocol_test.dart
   dart test tests/crypto_test.dart
   dart test tests/store_and_forward_test.dart
   dart run tests/mesh_simulation.dart --nodes=10
   ```
3. Commit with semantic, clear messages:
   ```bash
   git commit -m "feat(protocol): implement priority queue starvation avoidance"
   ```
4. Submit a Pull Request targeting `master`. Ensure the PR template checklist is fully satisfied.

---

## Code Review & Branch Protection

- All PRs require at least one approving review from a `CODEOWNER`.
- All CI status checks (Protocol tests, Static analysis, Backend tests) must pass.
- Force pushing to `master` is strictly prohibited.
