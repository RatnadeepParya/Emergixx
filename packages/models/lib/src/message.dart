import 'enums.dart';

/// Represents a secure message envelope in the EMERGIXX/1 protocol.
class EmergixxMessage {
  final String messageId; // UUID v4
  final String senderDeviceId; // e.g. "EX-7A29F1"
  final String recipientDeviceId; // "BROADCAST_ALL", "GROUP:<id>", or "EX-XXXXXX"
  final MessageType messageType;
  final int timestamp; // Milliseconds since epoch
  final int createdAt; // Milliseconds since epoch
  final int expiresAt; // Milliseconds since epoch
  final int ttl; // Remaining hops (starts at e.g. 10)
  final int hopCount; // Number of hops traversed so far (starts at 0)
  final MessagePriority priority;
  final String payload; // Ciphertext or structured payload string
  final String signature; // Ed25519 signature of the canonical message hash
  final String nonce; // Replay prevention nonce (e.g. hex random)
  final Map<String, dynamic>? encryptionMetadata; // algo, ephemeralPublicKey, mac, etc.
  final DeliveryStatus deliveryStatus;

  const EmergixxMessage({
    required this.messageId,
    required this.senderDeviceId,
    required this.recipientDeviceId,
    required this.messageType,
    required this.timestamp,
    required this.createdAt,
    required this.expiresAt,
    required this.ttl,
    this.hopCount = 0,
    required this.priority,
    required this.payload,
    required this.signature,
    required this.nonce,
    this.encryptionMetadata,
    this.deliveryStatus = DeliveryStatus.queued,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;
  bool get isBroadcast => recipientDeviceId == 'BROADCAST_ALL';
  bool get isGroup => recipientDeviceId.startsWith('GROUP:');
  bool get isDirect => !isBroadcast && !isGroup;

  EmergixxMessage copyWith({
    String? messageId,
    String? senderDeviceId,
    String? recipientDeviceId,
    MessageType? messageType,
    int? timestamp,
    int? createdAt,
    int? expiresAt,
    int? ttl,
    int? hopCount,
    MessagePriority? priority,
    String? payload,
    String? signature,
    String? nonce,
    Map<String, dynamic>? encryptionMetadata,
    DeliveryStatus? deliveryStatus,
  }) {
    return EmergixxMessage(
      messageId: messageId ?? this.messageId,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      recipientDeviceId: recipientDeviceId ?? this.recipientDeviceId,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      ttl: ttl ?? this.ttl,
      hopCount: hopCount ?? this.hopCount,
      priority: priority ?? this.priority,
      payload: payload ?? this.payload,
      signature: signature ?? this.signature,
      nonce: nonce ?? this.nonce,
      encryptionMetadata: encryptionMetadata ?? this.encryptionMetadata,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }

  /// Creates a canonical representation used for signing and signature verification.
  /// Note: Hop count and mutable delivery status are not included in the signed payload.
  String toCanonicalString() {
    return '$messageId|$senderDeviceId|$recipientDeviceId|${messageType.toWire()}|$timestamp|$createdAt|$expiresAt|${priority.toWire()}|$payload|$nonce';
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'senderDeviceId': senderDeviceId,
        'recipientDeviceId': recipientDeviceId,
        'messageType': messageType.toWire(),
        'timestamp': timestamp,
        'createdAt': createdAt,
        'expiresAt': expiresAt,
        'ttl': ttl,
        'hopCount': hopCount,
        'priority': priority.toWire(),
        'payload': payload,
        'signature': signature,
        'nonce': nonce,
        if (encryptionMetadata != null) 'encryptionMetadata': encryptionMetadata,
        'deliveryStatus': deliveryStatus.toWire(),
      };

  factory EmergixxMessage.fromJson(Map<String, dynamic> json) => EmergixxMessage(
        messageId: json['messageId'] as String,
        senderDeviceId: json['senderDeviceId'] as String,
        recipientDeviceId: json['recipientDeviceId'] as String,
        messageType: MessageType.fromWire(json['messageType'] as String),
        timestamp: json['timestamp'] as int,
        createdAt: json['createdAt'] as int,
        expiresAt: json['expiresAt'] as int,
        ttl: json['ttl'] as int,
        hopCount: json['hopCount'] as int? ?? 0,
        priority: MessagePriority.fromWire(json['priority'] as String),
        payload: json['payload'] as String,
        signature: json['signature'] as String,
        nonce: json['nonce'] as String,
        encryptionMetadata: json['encryptionMetadata'] as Map<String, dynamic>?,
        deliveryStatus: DeliveryStatus.fromWire(
            json['deliveryStatus'] as String? ?? 'QUEUED'),
      );

  Map<String, dynamic> toSqlite() => {
        'message_id': messageId,
        'sender_device_id': senderDeviceId,
        'recipient_device_id': recipientDeviceId,
        'message_type': messageType.toWire(),
        'timestamp': timestamp,
        'created_at': createdAt,
        'expires_at': expiresAt,
        'ttl': ttl,
        'hop_count': hopCount,
        'priority': priority.toWire(),
        'payload': payload,
        'signature': signature,
        'nonce': nonce,
        'encryption_metadata':
            encryptionMetadata != null ? encryptionMetadata.toString() : null,
        'delivery_status': deliveryStatus.toWire(),
      };

  factory EmergixxMessage.fromSqlite(Map<String, dynamic> row) =>
      EmergixxMessage(
        messageId: row['message_id'] as String,
        senderDeviceId: row['sender_device_id'] as String,
        recipientDeviceId: row['recipient_device_id'] as String,
        messageType: MessageType.fromWire(row['message_type'] as String),
        timestamp: row['timestamp'] as int,
        createdAt: row['created_at'] as int,
        expiresAt: row['expires_at'] as int,
        ttl: row['ttl'] as int,
        hopCount: row['hop_count'] as int? ?? 0,
        priority: MessagePriority.fromWire(row['priority'] as String),
        payload: row['payload'] as String,
        signature: row['signature'] as String,
        nonce: row['nonce'] as String,
        deliveryStatus:
            DeliveryStatus.fromWire(row['delivery_status'] as String),
      );
}
