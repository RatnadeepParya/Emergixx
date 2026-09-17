import 'enums.dart';

/// Represents an acknowledgement or delivery confirmation for a message.
class MessageReceipt {
  final String receiptId; // UUID v4
  final String messageId; // Reference to target EmergixxMessage
  final String recipientDeviceId; // Device that received/read the message
  final DeliveryStatus status; // DELIVERED, READ, FAILED
  final int timestamp; // Milliseconds since epoch
  final String signature; // Signed by recipient

  const MessageReceipt({
    required this.receiptId,
    required this.messageId,
    required this.recipientDeviceId,
    required this.status,
    required this.timestamp,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'receiptId': receiptId,
        'messageId': messageId,
        'recipientDeviceId': recipientDeviceId,
        'status': status.toWire(),
        'timestamp': timestamp,
        'signature': signature,
      };

  factory MessageReceipt.fromJson(Map<String, dynamic> json) => MessageReceipt(
        receiptId: json['receiptId'] as String,
        messageId: json['messageId'] as String,
        recipientDeviceId: json['recipientDeviceId'] as String,
        status: DeliveryStatus.fromWire(json['status'] as String),
        timestamp: json['timestamp'] as int,
        signature: json['signature'] as String,
      );

  Map<String, dynamic> toSqlite() => {
        'receipt_id': receiptId,
        'message_id': messageId,
        'recipient_device_id': recipientDeviceId,
        'status': status.toWire(),
        'timestamp': timestamp,
        'signature': signature,
      };

  factory MessageReceipt.fromSqlite(Map<String, dynamic> row) => MessageReceipt(
        receiptId: row['receipt_id'] as String,
        messageId: row['message_id'] as String,
        recipientDeviceId: row['recipient_device_id'] as String,
        status: DeliveryStatus.fromWire(row['status'] as String),
        timestamp: row['timestamp'] as int,
        signature: row['signature'] as String,
      );
}
