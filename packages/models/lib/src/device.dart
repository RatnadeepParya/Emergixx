/// Represents a local device cryptographic and network identity.
class Device {
  final String deviceId; // e.g. "EX-7A29F1"
  final String publicKey; // Ed25519 public key in base64/hex
  final String? x25519PublicKey; // X25519 public key for encryption
  final String keyId; // Unique key identifier
  final int protocolVersion;
  final List<String> capabilities;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
  final int batteryLevel; // 0 - 100

  const Device({
    required this.deviceId,
    required this.publicKey,
    this.x25519PublicKey,
    required this.keyId,
    this.protocolVersion = 1,
    this.capabilities = const ['MESSAGE', 'SOS', 'LOCATION_RELAY'],
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
    this.batteryLevel = 100,
  });

  Device copyWith({
    String? deviceId,
    String? publicKey,
    String? x25519PublicKey,
    String? keyId,
    int? protocolVersion,
    List<String>? capabilities,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    int? batteryLevel,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      publicKey: publicKey ?? this.publicKey,
      x25519PublicKey: x25519PublicKey ?? this.x25519PublicKey,
      keyId: keyId ?? this.keyId,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      capabilities: capabilities ?? this.capabilities,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'publicKey': publicKey,
        if (x25519PublicKey != null) 'x25519PublicKey': x25519PublicKey,
        'keyId': keyId,
        'protocolVersion': protocolVersion,
        'capabilities': capabilities,
        'createdAt': createdAt.toIso8601String(),
        'lastSeen': lastSeen.toIso8601String(),
        'isOnline': isOnline,
        'batteryLevel': batteryLevel,
      };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        deviceId: json['deviceId'] as String,
        publicKey: json['publicKey'] as String,
        x25519PublicKey: json['x25519PublicKey'] as String?,
        keyId: json['keyId'] as String,
        protocolVersion: json['protocolVersion'] as int? ?? 1,
        capabilities: (json['capabilities'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['MESSAGE', 'SOS', 'LOCATION_RELAY'],
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastSeen: DateTime.parse(json['lastSeen'] as String),
        isOnline: json['isOnline'] as bool? ?? false,
        batteryLevel: json['batteryLevel'] as int? ?? 100,
      );

  Map<String, dynamic> toSqlite() => {
        'device_id': deviceId,
        'public_key': publicKey,
        'x25519_public_key': x25519PublicKey,
        'key_id': keyId,
        'protocol_version': protocolVersion,
        'capabilities': capabilities.join(','),
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_seen': lastSeen.millisecondsSinceEpoch,
        'is_online': isOnline ? 1 : 0,
        'battery_level': batteryLevel,
      };

  factory Device.fromSqlite(Map<String, dynamic> row) => Device(
        deviceId: row['device_id'] as String,
        publicKey: row['public_key'] as String,
        x25519PublicKey: row['x25519_public_key'] as String?,
        keyId: row['key_id'] as String,
        protocolVersion: row['protocol_version'] as int? ?? 1,
        capabilities: (row['capabilities'] as String?)?.split(',') ??
            const ['MESSAGE', 'SOS', 'LOCATION_RELAY'],
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        lastSeen: DateTime.fromMillisecondsSinceEpoch(row['last_seen'] as int),
        isOnline: (row['is_online'] as int? ?? 0) == 1,
        batteryLevel: row['battery_level'] as int? ?? 100,
      );
}
