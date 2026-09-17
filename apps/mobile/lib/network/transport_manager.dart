import 'dart:async';
import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_shared/emergixx_shared.dart';
import 'peer_transport.dart';
import 'transports/bluetooth_transport.dart';
import 'transports/wifi_direct_transport.dart';
import 'transports/loopback_transport.dart';

/// Orchestrates multi-radio transports (BLE, Wi-Fi Direct, Loopback),
/// manages automatic failover, and enforces battery-aware duty cycles.
class TransportManager {
  final List<PeerTransport> _transports = [];
  final StreamController<EmergixxMessage> _incomingPacketController =
      StreamController<EmergixxMessage>.broadcast();
  final StreamController<Peer> _peerDiscoveredController =
      StreamController<Peer>.broadcast();

  final Map<String, Peer> _activePeers = {};
  BatteryProfile _batteryProfile = BatteryProfile.fromLevel(100);

  final BluetoothTransport bluetooth = BluetoothTransport();
  final WifiDirectTransport wifiDirect = WifiDirectTransport();
  final LoopbackTransport loopback = LoopbackTransport();

  TransportManager() {
    _transports.addAll([bluetooth, wifiDirect, loopback]);

    // Aggregate streams from all transports
    for (final transport in _transports) {
      transport.onPacketReceived.listen((pkt) {
        _incomingPacketController.add(pkt);
      });

      transport.onPeerDiscovered.listen((peer) {
        _activePeers[peer.peerId] = peer;
        _peerDiscoveredController.add(peer);
      });
    }
  }

  List<Peer> get discoveredPeers => _activePeers.values.toList();
  List<PeerTransport> get activeTransports => _transports;

  Stream<EmergixxMessage> get onPacketReceived =>
      _incomingPacketController.stream;
  Stream<Peer> get onPeerDiscovered => _peerDiscoveredController.stream;

  /// Starts all available transports and begins anonymous discovery.
  Future<void> startMesh({
    required String myEphemeralId,
    required List<String> capabilities,
  }) async {
    for (final transport in _transports) {
      if (await transport.isAvailable()) {
        await transport.startDiscovery();
        await transport.startAdvertising(
          ephemeralId: myEphemeralId,
          capabilities: capabilities,
        );
      }
    }
  }

  /// Stops discovery across all transports to conserve power.
  Future<void> stopMesh() async {
    for (final transport in _transports) {
      await transport.stopDiscovery();
      await transport.stopAdvertising();
    }
  }

  /// Broadcasts packet to all discovered peers across all radio channels.
  Future<int> broadcastPacket(EmergixxMessage packet) async {
    int sentCount = 0;
    for (final peer in _activePeers.values) {
      final success = await sendPacket(peer, packet);
      if (success) sentCount++;
    }
    return sentCount;
  }

  /// Transmits packet to a specific peer using the matching transport.
  Future<bool> sendPacket(Peer targetPeer, EmergixxMessage packet) async {
    for (final transport in _transports) {
      if (transport.transportType == targetPeer.transport) {
        return transport.sendPacket(targetPeer, packet);
      }
    }
    // Fallback: send via first available transport
    if (_transports.isNotEmpty) {
      return _transports.first.sendPacket(targetPeer, packet);
    }
    return false;
  }

  /// Updates current battery profile and adapts duty-cycling.
  void updateBatteryProfile(BatteryProfile profile) {
    _batteryProfile = profile;
    SanitizedLogger.info('POWER', 'Adaptive radio duty cycle updated', {
      'battery': profile.batteryLevel,
      'mode': profile.mode.toWire(),
      'scanWindow': profile.scanWindowSeconds,
      'scanInterval': profile.scanIntervalSeconds,
    });
  }

  Future<void> dispose() async {
    await stopMesh();
    for (final transport in _transports) {
      await transport.dispose();
    }
    await _incomingPacketController.close();
    await _peerDiscoveredController.close();
  }
}
