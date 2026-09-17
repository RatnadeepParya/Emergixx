import 'package:emergixx_models/emergixx_models.dart';
import 'deduplication_engine.dart';
import 'priority_queue.dart';
import 'protocol_version.dart';

/// Opportunistic store-and-forward mesh router with peer encounter memory.
/// Retains messages in transit cache so newly encountered peers can receive forwarded packets,
/// while avoiding re-sending the same packet repeatedly to the same peer.
class StoreAndForwardRouter {
  final String myDeviceId;
  final SeenMessagesIndex seenMessages;
  final MessagePriorityQueue relayQueue;
  final MessagePriorityQueue outboundQueue;

  // Tracks which peers have already received a given messageId: Map<messageId, Set<peerId>>
  final Map<String, Set<String>> _forwardedPeers = {};

  int totalRelayedCount = 0;
  int duplicateDropCount = 0;
  int expiredDropCount = 0;
  int hopExceededDropCount = 0;

  StoreAndForwardRouter({
    required this.myDeviceId,
    SeenMessagesIndex? seenMessagesIndex,
    MessagePriorityQueue? relayQueueInstance,
    MessagePriorityQueue? outboundQueueInstance,
  })  : seenMessages = seenMessagesIndex ?? SeenMessagesIndex(),
        relayQueue = relayQueueInstance ?? MessagePriorityQueue(maxCapacity: 1000),
        outboundQueue =
            outboundQueueInstance ?? MessagePriorityQueue(maxCapacity: 500);

  /// Processes an incoming packet received from a nearby peer.
  RoutingDecision handleIncomingPacket(EmergixxMessage message) {
    // 1. Check if packet originated from self (loopback echo)
    if (message.senderDeviceId == myDeviceId) {
      return RoutingDecision.droppedLoopback;
    }

    // 2. Check for duplicate packet
    final isDuplicate = seenMessages.checkAndMarkSeen(message.messageId);
    if (isDuplicate) {
      duplicateDropCount++;
      return RoutingDecision.droppedDuplicate;
    }

    // 3. Check expiration
    if (message.isExpired) {
      expiredDropCount++;
      return RoutingDecision.droppedExpired;
    }

    // 4. Check hop limits and TTL
    if (message.hopCount >= ProtocolVersion.maxHopCount || message.ttl <= 0) {
      hopExceededDropCount++;
      return RoutingDecision.droppedHopLimit;
    }

    // 5. Determine if destination includes self
    final isForMe = message.recipientDeviceId == myDeviceId ||
        message.isBroadcast ||
        message.isGroup;

    // 6. Prepare transit forward packet if TTL remains
    bool queuedForRelay = false;
    if (message.ttl > 1 &&
        (message.isBroadcast || message.isGroup || message.recipientDeviceId != myDeviceId)) {
      final forwardPacket = message.copyWith(
        ttl: message.ttl - 1,
        hopCount: message.hopCount + 1,
      );
      queuedForRelay = relayQueue.enqueue(forwardPacket);
      if (queuedForRelay) {
        totalRelayedCount++;
      }
    }

    if (isForMe && queuedForRelay) {
      return RoutingDecision.acceptedAndRelayed;
    } else if (isForMe) {
      return RoutingDecision.acceptedLocalOnly;
    } else if (queuedForRelay) {
      return RoutingDecision.relayedTransit;
    } else {
      return RoutingDecision.droppedQueueFull;
    }
  }

  /// Queues a locally authored outbound message.
  bool queueOutbound(EmergixxMessage message) {
    seenMessages.markSeen(message.messageId);
    return outboundQueue.enqueue(message);
  }

  /// Selects the next batch of candidate messages to forward to a discovered [peer].
  /// Uses encounter memory to ensure each message is only transmitted once per unique peer.
  List<EmergixxMessage> getNextMessagesForPeer(Peer peer, {int maxBatch = 5}) {
    final List<EmergixxMessage> batch = [];
    final peerKey = peer.peerId.isNotEmpty ? peer.peerId : peer.ephemeralId;

    // 1. Check outbound messages
    for (final msg in outboundQueue.toList()) {
      if (batch.length >= maxBatch) break;
      final sentSet = _forwardedPeers.putIfAbsent(msg.messageId, () => <String>{});
      if (!sentSet.contains(peerKey) && _shouldSendToPeer(msg, peer)) {
        batch.add(msg);
        sentSet.add(peerKey);
      }
    }

    // 2. Check transit relay messages
    for (final msg in relayQueue.toList()) {
      if (batch.length >= maxBatch) break;
      final sentSet = _forwardedPeers.putIfAbsent(msg.messageId, () => <String>{});
      if (!sentSet.contains(peerKey) && _shouldSendToPeer(msg, peer)) {
        batch.add(msg);
        sentSet.add(peerKey);
      }
    }

    return batch;
  }

  bool _shouldSendToPeer(EmergixxMessage msg, Peer peer) {
    // Never send message back to original sender
    if (msg.senderDeviceId == peer.peerId ||
        msg.senderDeviceId == peer.ephemeralId) {
      return false;
    }

    // Broadcasts and SOS alerts are forwarded to everyone
    if (msg.isBroadcast || msg.messageType == MessageType.sos) {
      return true;
    }

    // Specifically addressed to this peer
    if (msg.recipientDeviceId == peer.peerId ||
        msg.recipientDeviceId == peer.ephemeralId) {
      return true;
    }

    // Opportunistic group or transit forwarding
    return true;
  }

  /// Purges old encounter records for messages no longer in memory.
  void cleanupEncounterLog() {
    final activeIds = {
      ...outboundQueue.toList().map((m) => m.messageId),
      ...relayQueue.toList().map((m) => m.messageId),
    };
    _forwardedPeers.removeWhere((id, _) => !activeIds.contains(id));
  }
}

/// Routing disposition for incoming packets.
enum RoutingDecision {
  acceptedLocalOnly,
  acceptedAndRelayed,
  relayedTransit,
  droppedDuplicate,
  droppedExpired,
  droppedHopLimit,
  droppedLoopback,
  droppedQueueFull,
}
