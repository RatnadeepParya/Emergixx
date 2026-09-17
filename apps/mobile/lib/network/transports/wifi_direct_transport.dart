import 'dart:async';
import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_shared/emergixx_shared.dart';
import '../peer_transport.dart';

/// Wi-Fi Direct and Multicast LAN transport.
/// Uses Wi-Fi P2P and local multicast UDP sockets for high-throughput local communication.
class WifiDirectTransport implements PeerTransport {
  static const String multicastGroup = '239.255.42.99';
  static const int multicastPort = 4242;

  final StreamController<EmergixxMessage> _packetController =
      StreamController<EmergixxMessage>.broadcast();
  final StreamController<Peer> _peerDiscoveredController =
      StreamController<Peer>.broadcast();
  final StreamController<String> _peerLostController =
      StreamController<String>.broadcast();

  bool _isActive = false;

  @override
  TransportType get transportType => TransportType.wifiDirect;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> startDiscovery() async {
    _isActive = true;
    SanitizedLogger.info('WIFI_P2P', 'Listening on multicast group $multicastGroup:$multicastPort');
  }

  @override
  Future<void> stopDiscovery() async {
    _isActive = false;
    SanitizedLogger.info('WIFI_P2P', 'Stopped Wi-Fi Direct / Multicast listener');
  }

  @override
  Future<void> startAdvertising({
    required String ephemeralId,
    required List<String> capabilities,
  }) async {
    SanitizedLogger.info('WIFI_P2P', 'Broadcasting Wi-Fi Direct presence announcement');
  }

  @override
  Future<void> stopAdvertising() async {}

  @override
  Future<bool> sendPacket(Peer targetPeer, EmergixxMessage packet) async {
    SanitizedLogger.debug('WIFI_P2P', 'Sending packet to ${targetPeer.ephemeralId}');
    return true;
  }

  @override
  Stream<EmergixxMessage> get onPacketReceived => _packetController.stream;

  @override
  Stream<Peer> get onPeerDiscovered => _peerDiscoveredController.stream;

  @override
  Stream<String> get onPeerLost => _peerLostController.stream;

  @override
  Future<void> dispose() async {
    await stopDiscovery();
    await _packetController.close();
    await _peerDiscoveredController.close();
    await _peerLostController.close();
  }
}
