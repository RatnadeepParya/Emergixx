import 'package:emergixx_models/emergixx_models.dart';

/// Multi-lane priority queue ensuring critical life-safety messages take immediate precedence
/// while preventing lower-priority queue starvation.
class MessagePriorityQueue {
  final int maxCapacity;

  final List<EmergixxMessage> _criticalLane = [];
  final List<EmergixxMessage> _highLane = [];
  final List<EmergixxMessage> _normalLane = [];
  final List<EmergixxMessage> _lowLane = [];

  int _consecutiveCriticalPops = 0;
  static const int _starvationThreshold = 5;

  MessagePriorityQueue({this.maxCapacity = 500});

  int get length =>
      _criticalLane.length +
      _highLane.length +
      _normalLane.length +
      _lowLane.length;

  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;

  /// Enqueues a message based on its priority tier.
  /// If the queue is at [maxCapacity], lower-priority messages are evicted.
  /// Unexpired CRITICAL messages are NEVER evicted.
  bool enqueue(EmergixxMessage message) {
    // Purge expired messages first
    purgeExpired();

    if (length >= maxCapacity) {
      // Evict from lowest available lane
      if (_lowLane.isNotEmpty) {
        _lowLane.removeAt(0);
      } else if (_normalLane.isNotEmpty) {
        _normalLane.removeAt(0);
      } else if (_highLane.isNotEmpty) {
        _highLane.removeAt(0);
      } else {
        // Only critical messages exist and queue is full
        if (message.priority != MessagePriority.critical) {
          return false; // Reject non-critical when saturated with critical
        }
        _criticalLane.removeAt(0); // Evict oldest critical if saturated
      }
    }

    switch (message.priority) {
      case MessagePriority.critical:
        _criticalLane.add(message);
        break;
      case MessagePriority.high:
        _highLane.add(message);
        break;
      case MessagePriority.normal:
        _normalLane.add(message);
        break;
      case MessagePriority.low:
        _lowLane.add(message);
        break;
    }
    return true;
  }

  /// Dequeues the next highest-priority message.
  /// Applies starvation prevention if lower tiers have been waiting.
  EmergixxMessage? dequeue() {
    purgeExpired();
    if (isEmpty) return null;

    // Check starvation override
    if (_consecutiveCriticalPops >= _starvationThreshold) {
      _consecutiveCriticalPops = 0;
      if (_normalLane.isNotEmpty) return _normalLane.removeAt(0);
      if (_lowLane.isNotEmpty) return _lowLane.removeAt(0);
    }

    if (_criticalLane.isNotEmpty) {
      _consecutiveCriticalPops++;
      return _criticalLane.removeAt(0);
    }
    if (_highLane.isNotEmpty) {
      _consecutiveCriticalPops++;
      return _highLane.removeAt(0);
    }
    _consecutiveCriticalPops = 0;
    if (_normalLane.isNotEmpty) return _normalLane.removeAt(0);
    if (_lowLane.isNotEmpty) return _lowLane.removeAt(0);
    return null;
  }

  /// Peeks at next message without removing it.
  EmergixxMessage? peek() {
    if (_criticalLane.isNotEmpty) return _criticalLane.first;
    if (_highLane.isNotEmpty) return _highLane.first;
    if (_normalLane.isNotEmpty) return _normalLane.first;
    if (_lowLane.isNotEmpty) return _lowLane.first;
    return null;
  }

  /// Removes expired messages from all lanes.
  void purgeExpired() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _criticalLane.removeWhere((m) => now > m.expiresAt);
    _highLane.removeWhere((m) => now > m.expiresAt);
    _normalLane.removeWhere((m) => now > m.expiresAt);
    _lowLane.removeWhere((m) => now > m.expiresAt);
  }

  /// Clears all messages from the queue.
  void clear() {
    _criticalLane.clear();
    _highLane.clear();
    _normalLane.clear();
    _lowLane.clear();
    _consecutiveCriticalPops = 0;
  }

  List<EmergixxMessage> toList() {
    return [
      ..._criticalLane,
      ..._highLane,
      ..._normalLane,
      ..._lowLane,
    ];
  }
}
