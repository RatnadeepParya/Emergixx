import 'enums.dart';

/// Represents a discovered peer in the local mesh network.
class Peer {
  final String peerId; // Canonical identifier (often matching deviceId)
  final String ephemeralId; // Advertised discovery ID e.g. "EX-7A29F1"
  final String? publicKey; // Discovered Ed25519 public key
  final String? x25519PublicKey; // Discovered X25519 encryption key
  final List<String> capabilities;
  final int rssi; // Signal strength in dBm (e.g. -65)
  final DateTime lastSeen;
  final TransportType transport;
  final TrustState trustState;
  final bool isConnected;

  const Peer({
    required this.peerId,
    required this.ephemeralId,
    this.publicKey,
    this.x25519PublicKey,
    this.capabilities = const ['MESSAGE', 'SOS', 'LOCATION_RELAY'],
    required this.rssi,
    required this.lastSeen,
    required this.transport,
    this.trustState = TrustState.unknown,
    this.isConnected = false,
  });

  Peer copyWith({
    String? peerId,
    String? ephemeralId,
    String? publicKey,
    String? x25519PublicKey,
    List<String>? capabilities,
    int? rssi,
    DateTime? lastSeen,
    TransportType? transport,
    TrustState? trustState,
    bool? isConnected,
  }) {
    return Peer(
      peerId: peerId ?? this.peerId,
      ephemeralId: ephemeralId ?? this.ephemeralId,
      publicKey: publicKey ?? this.publicKey,
      x25519PublicKey: x25519PublicKey ?? this.x25519PublicKey,
      capabilities: capabilities ?? this.capabilities,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
      transport: transport ?? this.transport,
      trustState: trustState ?? this.trustState,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toJson() => {
        'peerId': peerId,
        'ephemeralId': ephemeralId,
        if (publicKey != null) 'publicKey': publicKey,
        if (x25519PublicKey != null) 'x25519PublicKey': x25519PublicKey,
        'capabilities': capabilities,
        'rssi': rssi,
        'lastSeen': lastSeen.toIso8601String(),
        'transport': transport.toWire(),
        'trustState': trustState.toWire(),
        'isConnected': isConnected,
      };

  factory Peer.fromJson(Map<String, dynamic> json) => Peer(
        peerId: json['peerId'] as String,
        ephemeralId: json['ephemeralId'] as String,
        publicKey: json['publicKey'] as String?,
        x25519PublicKey: json['x25519PublicKey'] as String?,
        capabilities: (json['capabilities'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['MESSAGE', 'SOS', 'LOCATION_RELAY'],
        rssi: json['rssi'] as int? ?? -70,
        lastSeen: DateTime.parse(json['lastSeen'] as String),
        transport: TransportType.fromWire(json['transport'] as String? ?? 'bluetooth'),
        trustState: TrustState.fromWire(json['trustState'] as String? ?? 'UNKNOWN'),
        isConnected: json['isConnected'] as bool? ?? false,
      );

  Map<String, dynamic> toSqlite() => {
        'peer_id': peerId,
        'ephemeral_id': ephemeralId,
        'public_key': publicKey,
        'x25519_public_key': x25519PublicKey,
        'capabilities': capabilities.join(','),
        'rssi': rssi,
        'last_seen': lastSeen.millisecondsSinceEpoch,
        'transport': transport.toWire(),
        'trust_state': trustState.toWire(),
        'is_connected': isConnected ? 1 : 0,
      };

  factory Peer.fromSqlite(Map<String, dynamic> row) => Peer(
        peerId: row['peer_id'] as String,
        ephemeralId: row['ephemeral_id'] as String,
        publicKey: row['public_key'] as String?,
        x25519PublicKey: row['x25519_public_key'] as String?,
        capabilities: (row['capabilities'] as String?)?.split(',') ??
            const ['MESSAGE', 'SOS', 'LOCATION_RELAY'],
        rssi: row['rssi'] as int? ?? -70,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(row['last_seen'] as int),
        transport: TransportType.fromWire(row['transport'] as String? ?? 'bluetooth'),
        trustState: TrustState.fromWire(row['trust_state'] as String? ?? 'UNKNOWN'),
        isConnected: (row['is_connected'] as int? ?? 0) == 1,
      );
}
