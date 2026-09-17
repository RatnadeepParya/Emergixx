import 'dart:async';
import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_protocol/emergixx_protocol.dart';
import 'package:emergixx_validation/emergixx_validation.dart';
import 'package:emergixx_shared/emergixx_shared.dart';
import '../data/repositories/emergency_repository.dart';
import '../network/transport_manager.dart';

/// Central store-and-forward relay coordinator.
/// Bridges the physical network layer, the routing engine, and the local persistent database.
class RelayEngine {
  final EmergencyRepository repository;
  final TransportManager transportManager;
  final StoreAndForwardRouter router;
  final ReplayProtector replayProtector = ReplayProtector();

  StreamSubscription? _packetSubscription;
  StreamSubscription? _peerSubscription;

  RelayEngine({
    required this.repository,
    required this.transportManager,
    required String myDeviceId,
  }) : router = StoreAndForwardRouter(myDeviceId: myDeviceId) {
    _initListeners();
  }

  void _initListeners() {
    // 1. Process incoming packets
    _packetSubscription = transportManager.onPacketReceived.listen((pkt) async {
      await _processIncoming(pkt);
    });

    // 2. Opportunistically forward queued messages when new peers appear
    _peerSubscription = transportManager.onPeerDiscovered.listen((peer) async {
      await _onPeerEncountered(peer);
    });
  }

  Future<void> _processIncoming(EmergixxMessage packet) async {
    // Validate structural schema
    final val = PacketValidator.validate(packet);
    if (!val.isValid) {
      SanitizedLogger.warn('RELAY', 'Dropping invalid packet: ${val.error}');
      return;
    }

    // Replay protection check
    if (!replayProtector.validateAndRecord(packet)) {
      SanitizedLogger.warn('RELAY', 'Dropping replayed or stale packet: ${packet.messageId}');
      return;
    }

    // Route packet through store-and-forward decision engine
    final decision = router.handleIncomingPacket(packet);

    switch (decision) {
      case RoutingDecision.acceptedLocalOnly:
      case RoutingDecision.acceptedAndRelayed:
        await repository.saveMessage(packet);
        SanitizedLogger.info('RELAY', 'Message accepted for local delivery', {
          'messageId': packet.messageId,
          'type': packet.messageType.toWire(),
          'hops': packet.hopCount,
        });
        break;
      case RoutingDecision.relayedTransit:
        SanitizedLogger.info('RELAY', 'Transit packet buffered for next hop', {
          'messageId': packet.messageId,
          'ttl': packet.ttl,
          'hops': packet.hopCount,
        });
        break;
      case RoutingDecision.droppedDuplicate:
      case RoutingDecision.droppedExpired:
      case RoutingDecision.droppedHopLimit:
      case RoutingDecision.droppedLoopback:
      case RoutingDecision.droppedQueueFull:
        SanitizedLogger.debug('RELAY', 'Packet dropped: ${decision.name}');
        break;
    }
  }

  Future<void> _onPeerEncountered(Peer peer) async {
    await repository.updatePeer(peer);

    // Fetch batch of candidate messages for this peer
    final batch = router.getNextMessagesForPeer(peer, maxBatch: 5);
    for (final message in batch) {
      await transportManager.sendPacket(peer, message);
    }
  }

  /// Sends a locally authored message into the mesh.
  Future<void> dispatchOutbound(EmergixxMessage message) async {
    await repository.saveMessage(message);
    router.queueOutbound(message);

    // Immediately broadcast to all currently connected peers
    await transportManager.broadcastPacket(message);
  }

  void dispose() {
    _packetSubscription?.cancel();
    _peerSubscription?.cancel();
  }
}
