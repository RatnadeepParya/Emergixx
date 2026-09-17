import 'dart:collection';
import 'package:emergixx_models/emergixx_models.dart';

/// Protects against message replay attacks and timestamp manipulation in offline mesh networks.
class ReplayProtector {
  final int maxClockDriftMs;
  final int maxNonceCacheSize;

  // Stores seen nonces: Map<senderDeviceId, LinkedHashSet<nonce>>
  final Map<String, LinkedHashSet<String>> _seenNonces = {};

  ReplayProtector({
    this.maxClockDriftMs = 300000, // 5 minutes window
    this.maxNonceCacheSize = 2000,
  });

  /// Validates that [message] is fresh and has not been replayed.
  /// Returns `true` if valid, `false` if replayed or timestamp is invalid.
  bool validateAndRecord(EmergixxMessage message) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Clock drift check (allow up to maxClockDriftMs into past/future to accommodate unsynced offline RTCs)
    final diff = (now - message.timestamp).abs();
    if (diff > maxClockDriftMs) {
      return false; // Stale message or malicious future timestamp
    }

    // 2. Nonce check per sender
    final senderNonces =
        _seenNonces.putIfAbsent(message.senderDeviceId, () => LinkedHashSet<String>());

    if (senderNonces.contains(message.nonce)) {
      return false; // Replay detected!
    }

    // Record nonce and evict oldest if cache limit reached
    if (senderNonces.length >= maxNonceCacheSize) {
      senderNonces.remove(senderNonces.first);
    }
    senderNonces.add(message.nonce);
    return true;
  }

  /// Clears recorded nonces.
  void clear() {
    _seenNonces.clear();
  }
}
