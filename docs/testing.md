# Testing & Verification Guide

## 1. Zero-Dependency Offline Test Framework

To guarantee verification can occur in air-gapped disaster recovery bunkers and network-sandboxed environments without requiring access to `pub.dev`, Emergixx includes a zero-dependency Dart test framework (`tests/emergixx_test_framework.dart`).

---

## 2. Test Suite Architecture

The test suite covers four comprehensive domains:

```
+-------------------------------------------------------------------------+
|                        EMERGIXX TEST HIERARCHY                          |
+-------------------------------------------------------------------------+
| Suite                      | Coverage                                    |
+----------------------------+---------------------------------------------+
| tests/crypto_test.dart     | Ed25519, Curve25519 ECDH, AES-256-GCM AEAD, |
|                            | SHA-256, HMAC, Tampering, Replay Protection |
+----------------------------+---------------------------------------------+
| tests/protocol_test.dart   | PacketCodec binary/JSON, Priority Queuing,  |
|                            | SeenMessages LRU Deduplication              |
+----------------------------+---------------------------------------------+
| tests/store_and_forward_   | Multi-hop routing (A -> B -> C -> D),       |
| test.dart                  | TTL decrements, Encounter memory buffer     |
+----------------------------+---------------------------------------------+
| tests/mesh_simulation.dart | Realistic 10, 50, and 100-node disaster     |
|                            | grid simulation with random walk encounters |
+----------------------------+---------------------------------------------+
```

---

## 3. Running Automated Tests

```bash
# Execute full test runner script
./scripts/run_simulation.sh

# Or run individual test suites directly
HOME=$PWD/.dart_home dart run tests/crypto_test.dart
HOME=$PWD/.dart_home dart run tests/protocol_test.dart
HOME=$PWD/.dart_home dart run tests/store_and_forward_test.dart
HOME=$PWD/.dart_home dart run tests/mesh_simulation.dart
```

---

## 4. Benchmark Simulation Results (100-Node Disaster Grid)

From `tests/mesh_simulation.dart`:
- **Nodes**: 100 nodes placed across a $500\text{m} \times 500\text{m}$ disaster area.
- **Physical Radio Range**: 50 meters (BLE GATT).
- **Encounter Cycles**: 15 ticks of mobility.
- **Delivery Rate**: **90.0%** of life-safety distress packets reached the designated responder base.
- **Average Hops**: **6.0 hops** traversed.
- **Duplicates Dropped**: **19,614 duplicate packets** suppressed by LRU index.
- **Routing Loops**: **0 loops** detected.
