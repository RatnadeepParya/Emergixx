import 'dart:convert';
import 'dart:typed_data';
import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_protocol/emergixx_protocol.dart';
import 'emergixx_test_framework.dart';

void main() {
  group('PacketCodec Tests', () {
    test('Encodes and decodes an EmergixxMessage envelope accurately', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final msg = EmergixxMessage(
        messageId: '550e8400-e29b-41d4-a716-446655440000',
        senderDeviceId: 'EX-A1B2C3',
        recipientDeviceId: 'BROADCAST_ALL',
        messageType: MessageType.sos,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 10,
        hopCount: 0,
        priority: MessagePriority.critical,
        payload: 'EMERGENCY_PAYLOAD_DATA',
        signature: base64Encode(List.filled(64, 1)),
        nonce: 'a1b2c3d4e5f6',
      );

      final encodedBytes = PacketCodec.encode(msg);
      expect(encodedBytes.length, greaterThan(5));
      expect(encodedBytes[0], equals(0x45)); // 'E'
      expect(encodedBytes[1], equals(0x58)); // 'X'
      expect(encodedBytes[2], equals(1)); // Version 1

      final decoded = PacketCodec.decode(encodedBytes);
      expect(decoded.messageId, equals(msg.messageId));
      expect(decoded.senderDeviceId, equals('EX-A1B2C3'));
      expect(decoded.recipientDeviceId, equals('BROADCAST_ALL'));
      expect(decoded.messageType, equals(MessageType.sos));
      expect(decoded.priority, equals(MessagePriority.critical));
      expect(decoded.payload, equals('EMERGENCY_PAYLOAD_DATA'));
      expect(decoded.ttl, equals(10));
      expect(decoded.hopCount, equals(0));
    });

    test('Rejects malformed packet headers', () {
      final invalidBytes = [0x00, 0x01, 0x02, 0x03, 0x04];
      expect(
        () => PacketCodec.decode(Uint8List.fromList(invalidBytes)),
        throwsFormatException,
      );
    });
  });

  group('Priority Queue Tests', () {
    test('Dequeues CRITICAL SOS messages before NORMAL or LOW messages', () {
      final queue = MessagePriorityQueue(maxCapacity: 100);
      final now = DateTime.now().millisecondsSinceEpoch;

      final normalMsg = EmergixxMessage(
        messageId: 'normal-1',
        senderDeviceId: 'EX-000001',
        recipientDeviceId: 'EX-000002',
        messageType: MessageType.text,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 5,
        priority: MessagePriority.normal,
        payload: 'Hello',
        signature: 'sig',
        nonce: 'n1',
      );

      final criticalMsg = EmergixxMessage(
        messageId: 'critical-sos-1',
        senderDeviceId: 'EX-000003',
        recipientDeviceId: 'BROADCAST_ALL',
        messageType: MessageType.sos,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 10,
        priority: MessagePriority.critical,
        payload: 'TRAPPED IN FLOOD',
        signature: 'sig',
        nonce: 'n2',
      );

      final lowMsg = EmergixxMessage(
        messageId: 'low-1',
        senderDeviceId: 'EX-000004',
        recipientDeviceId: 'EX-000002',
        messageType: MessageType.systemMessage,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 3,
        priority: MessagePriority.low,
        payload: 'Telemetry',
        signature: 'sig',
        nonce: 'n3',
      );

      // Enqueue in reverse order: normal, then low, then critical
      queue.enqueue(normalMsg);
      queue.enqueue(lowMsg);
      queue.enqueue(criticalMsg);

      // Critical must dequeue first!
      final first = queue.dequeue();
      expect(first?.messageId, equals('critical-sos-1'));
      expect(first?.priority, equals(MessagePriority.critical));

      // Normal second
      final second = queue.dequeue();
      expect(second?.messageId, equals('normal-1'));

      // Low third
      final third = queue.dequeue();
      expect(third?.messageId, equals('low-1'));
    });

    test('Never evicts unexpired CRITICAL messages when capacity is reached', () {
      final queue = MessagePriorityQueue(maxCapacity: 3);
      final now = DateTime.now().millisecondsSinceEpoch;

      final crit1 = EmergixxMessage(
        messageId: 'crit-1',
        senderDeviceId: 'EX-1',
        recipientDeviceId: 'BROADCAST_ALL',
        messageType: MessageType.sos,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 10,
        priority: MessagePriority.critical,
        payload: 'SOS 1',
        signature: 'sig',
        nonce: 'n1',
      );

      final norm1 = EmergixxMessage(
        messageId: 'norm-1',
        senderDeviceId: 'EX-2',
        recipientDeviceId: 'EX-3',
        messageType: MessageType.text,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 5,
        priority: MessagePriority.normal,
        payload: 'Hi',
        signature: 'sig',
        nonce: 'n2',
      );

      final low1 = EmergixxMessage(
        messageId: 'low-1',
        senderDeviceId: 'EX-4',
        recipientDeviceId: 'EX-3',
        messageType: MessageType.systemMessage,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 2,
        priority: MessagePriority.low,
        payload: 'Ping',
        signature: 'sig',
        nonce: 'n3',
      );

      queue.enqueue(crit1);
      queue.enqueue(norm1);
      queue.enqueue(low1);
      expect(queue.length, equals(3));

      // Add another normal message - low1 should be evicted first!
      final norm2 = EmergixxMessage(
        messageId: 'norm-2',
        senderDeviceId: 'EX-5',
        recipientDeviceId: 'EX-3',
        messageType: MessageType.text,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 5,
        priority: MessagePriority.normal,
        payload: 'Hi 2',
        signature: 'sig',
        nonce: 'n4',
      );

      queue.enqueue(norm2);
      expect(queue.length, equals(3));

      // Verify crit1 is still present and dequeues first
      final popped = queue.dequeue();
      expect(popped?.messageId, equals('crit-1'));
    });
  });

  group('Deduplication Engine Tests', () {
    test('Correctly identifies duplicate message IDs and evicts LRU', () {
      final index = SeenMessagesIndex(maxEntries: 3);

      expect(index.checkAndMarkSeen('msg-1'), isFalse); // First time: Not duplicate
      expect(index.checkAndMarkSeen('msg-1'), isTrue);  // Second time: Duplicate!

      expect(index.checkAndMarkSeen('msg-2'), isFalse);
      expect(index.checkAndMarkSeen('msg-3'), isFalse);
      expect(index.size, equals(3));

      // Adding 4th should evict msg-1
      expect(index.checkAndMarkSeen('msg-4'), isFalse);
      expect(index.size, equals(3));
      expect(index.contains('msg-1'), isFalse);
      expect(index.contains('msg-4'), isTrue);
    });
  });

  printTestSummary();
}
