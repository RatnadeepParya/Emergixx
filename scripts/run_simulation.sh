#!/usr/bin/env bash
set -e

echo "================================================================"
echo "          EMERGIXX CORE SUITE & DISASTER SIMULATOR"
echo "================================================================"

export HOME="$PWD/.dart_home"
export PATH="/opt/homebrew/bin:$PATH"
mkdir -p "$HOME/.dart-tool"

echo "[1/4] Running Protocol & Packet Codec Tests..."
dart run tests/protocol_test.dart

echo "[2/4] Running Zero-Trust Cryptography & Signature Tests..."
dart run tests/crypto_test.dart

echo "[3/4] Running Store-and-Forward Multi-Hop Relay Tests..."
dart run tests/store_and_forward_test.dart

echo "[4/4] Running Multi-Node Disaster Mesh Simulation (10, 50, 100 Nodes)..."
dart run tests/mesh_simulation.dart --nodes=10
dart run tests/mesh_simulation.dart --nodes=50
dart run tests/mesh_simulation.dart --nodes=100

echo "================================================================"
echo "✓ ALL EMERGIXX TESTS & MESH SIMULATIONS COMPLETED SUCCESSFULLY!"
echo "================================================================"
