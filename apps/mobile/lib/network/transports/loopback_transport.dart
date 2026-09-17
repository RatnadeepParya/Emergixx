import 'dart:async';
import 'package:emergixx_models/emergixx_models.dart';
import '../peer_transport.dart';

/// Simulated loopback transport for unit testing, field troubleshooting, and local emulation.
class LoopbackTransport implements PeerTransport {
  final StreamController<EmergixxMessage> _packetController =
      StreamController<EmergixxMessage>.broadcast();
  final StreamController<Peer> _peerDiscoveredController =
      StreamController<Peer>.broadcast();
  final StreamController<String> _peerLostController =
      StreamController<String>.broadcast();

  final List<Peer> _simulatedPeers = [];

  @override
  TransportType get transportType => TransportType.loopback;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> startDiscovery() async {
    // Emit initial simulated peer for immediate testing
    if (_simulatedPeers.isEmpty) {
      final peer = Peer(
        peerId: 'EX-SIMULATED-01',
        ephemeralId: 'EX-7F42A1',
        capabilities: const ['MESSAGE', 'SOS', 'LOCATION_RELAY'],
        rssi: -58,
        lastSeen: DateTime.now(),
        transport: TransportType.loopback,
        trustState: TrustState.known,
        isConnected: true,
      );
      _simulatedPeers.add(peer);
      _peerDiscoveredController.add(peer);
    }
  }

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> startAdvertising({
    required String ephemeralId,
    required List<String> capabilities,
  }) async {}

  @override
  Future<void> stopAdvertising() async {}

  @override
  Future<bool> sendPacket(Peer targetPeer, EmergixxMessage packet) async {
    // Loop back with simulated ack or echo
    return true;
  }

  void injectPeer(Peer peer) {
    _simulatedPeers.add(peer);
    _peerDiscoveredController.add(peer);
  }

  void injectPacket(EmergixxMessage message) {
    _packetController.add(message);
  }

  @override
  Stream<EmergixxMessage> get onPacketReceived => _packetController.stream;

  @override
  Stream<Peer> get onPeerDiscovered => _peerDiscoveredController.stream;

  @override
  Stream<String> get onPeerLost => _peerLostController.stream;

  @override
  Future<void> dispose() async {
    await _packetController.close();
    await _peerDiscoveredController.close();
    await _peerLostController.close();
  }
}
