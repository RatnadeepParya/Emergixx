import 'dart:collection';

/// Lightweight in-memory index for detecting and suppressing duplicate mesh packets.
/// Uses a bounded LinkedHashMap to provide O(1) membership checks with LRU eviction.
class SeenMessagesIndex {
  final int maxEntries;
  final LinkedHashMap<String, int> _seen = LinkedHashMap<String, int>();

  SeenMessagesIndex({this.maxEntries = 5000});

  int get size => _seen.length;

  /// Checks if [messageId] has already been seen.
  /// If NOT seen, marks it as seen and returns `false` (is NOT duplicate).
  /// If already seen, returns `true` (is duplicate, MUST DROP).
  bool checkAndMarkSeen(String messageId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_seen.containsKey(messageId)) {
      // Re-insert to update LRU order
      _seen.remove(messageId);
      _seen[messageId] = now;
      return true; // Duplicate!
    }

    // Evict oldest if full
    if (_seen.length >= maxEntries) {
      _seen.remove(_seen.keys.first);
    }

    _seen[messageId] = now;
    return false; // New message
  }

  /// Checks if [messageId] is in cache without marking.
  bool contains(String messageId) => _seen.containsKey(messageId);

  /// Manually registers a messageId as seen.
  void markSeen(String messageId) {
    checkAndMarkSeen(messageId);
  }

  /// Clears all entries from index.
  void clear() {
    _seen.clear();
  }

  /// Purges entries older than [maxAgeMs].
  void purgeOld(int maxAgeMs) {
    final cutoff = DateTime.now().millisecondsSinceEpoch - maxAgeMs;
    _seen.removeWhere((id, timestamp) => timestamp < cutoff);
  }
}
