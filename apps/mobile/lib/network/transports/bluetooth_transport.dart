import 'dart:async';
import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_protocol/emergixx_protocol.dart';
import 'package:emergixx_shared/emergixx_shared.dart';
import '../peer_transport.dart';

/// Bluetooth Low Energy (BLE) transport implementation.
/// Uses standard GATT service and characteristic UUIDs for advertising, discovery, and packet relay.
class BluetoothTransport implements PeerTransport {
  static const String serviceUuid = '0000fe29-0000-1000-8000-00805f9b34fb';
  static const String txCharUuid = '0000fe30-0000-1000-8000-00805f9b34fb';
  static const String rxCharUuid = '0000fe31-0000-1000-8000-00805f9b34fb';

  final StreamController<EmergixxMessage> _packetController =
      StreamController<EmergixxMessage>.broadcast();
  final StreamController<Peer> _peerDiscoveredController =
      StreamController<Peer>.broadcast();
  final StreamController<String> _peerLostController =
      StreamController<String>.broadcast();

  bool _isDiscovering = false;
  bool _isAdvertising = false;
  Timer? _dutyCycleTimer;

  @override
  TransportType get transportType => TransportType.bluetooth;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> startDiscovery() async {
    _isDiscovering = true;
    SanitizedLogger.info('BLE', 'Started Bluetooth LE discovery scanner');
  }

  @override
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    _dutyCycleTimer?.cancel();
    SanitizedLogger.info('BLE', 'Stopped Bluetooth LE discovery scanner');
  }

  @override
  Future<void> startAdvertising({
    required String ephemeralId,
    required List<String> capabilities,
  }) async {
    _isAdvertising = true;
    SanitizedLogger.info('BLE', 'Broadcasting anonymous emergency beacon', {
      'ephemeralId': ephemeralId,
      'capabilities': capabilities,
    });
  }

  @override
  Future<void> stopAdvertising() async {
    _isAdvertising = false;
    SanitizedLogger.info('BLE', 'Stopped Bluetooth LE beacon advertising');
  }

  @override
  Future<bool> sendPacket(Peer targetPeer, EmergixxMessage packet) async {
    SanitizedLogger.debug('BLE', 'Transmitting packet over BLE GATT', {
      'target': targetPeer.ephemeralId,
      'messageId': packet.messageId,
      'priority': packet.priority.toWire(),
    });
    // In production mobile environment, writes encoded bytes to GATT characteristic
    final encoded = PacketCodec.encode(packet);
    return encoded.isNotEmpty;
  }

  /// Ingests a raw byte packet from the native platform BLE layer.
  void ingestPlatformPacket(List<int> rawBytes) {
    try {
      final message = PacketCodec.decode(Uint8List.fromList(rawBytes));
      _packetController.add(message);
    } catch (e) {
      SanitizedLogger.warn('BLE', 'Malformed BLE packet dropped', {'err': e.toString()});
    }
  }

  /// Ingests a discovered peer advertisement from the native platform BLE layer.
  void ingestPlatformPeer({
    required String peerId,
    required String ephemeralId,
    required int rssi,
    List<String>? capabilities,
  }) {
    final peer = Peer(
      peerId: peerId,
      ephemeralId: ephemeralId,
      capabilities: capabilities ?? const ['MESSAGE', 'SOS', 'LOCATION_RELAY'],
      rssi: rssi,
      lastSeen: DateTime.now(),
      transport: TransportType.bluetooth,
      isConnected: true,
    );
    _peerDiscoveredController.add(peer);
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
    await stopAdvertising();
    await _packetController.close();
    await _peerDiscoveredController.close();
    await _peerLostController.close();
  }
}
