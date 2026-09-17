import 'dart:async';
import 'package:emergixx_models/emergixx_models.dart';

/// Provider abstraction for physical and virtual device-to-device communication.
/// Decouples business logic from Bluetooth, Wi-Fi Direct, WebRTC, or local networking.
abstract class PeerTransport {
  TransportType get transportType;

  /// Returns true if this transport hardware is present and enabled.
  Future<bool> isAvailable();

  /// Starts scanning/listening for nearby survivor and responder devices.
  Future<void> startDiscovery();

  /// Stops discovery to conserve battery.
  Future<void> stopDiscovery();

  /// Advertises local anonymous presence beacon with minimal metadata.
  Future<void> startAdvertising({
    required String ephemeralId,
    required List<String> capabilities,
  });

  /// Stops advertising.
  Future<void> stopAdvertising();

  /// Transmits an [EmergixxMessage] packet to [targetPeer].
  /// Returns true if the link-layer transmission succeeded.
  Future<bool> sendPacket(Peer targetPeer, EmergixxMessage packet);

  /// Stream of incoming verified wire packets.
  Stream<EmergixxMessage> get onPacketReceived;

  /// Stream of discovered nearby peers.
  Stream<Peer> get onPeerDiscovered;

  /// Stream of lost peer IDs.
  Stream<String> get onPeerLost;

  /// Disposes resources.
  Future<void> dispose();
}
