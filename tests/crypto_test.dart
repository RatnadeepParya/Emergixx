import 'dart:convert';
import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_crypto/emergixx_crypto.dart';
import 'package:emergixx_validation/emergixx_validation.dart';
import 'emergixx_test_framework.dart';

void main() {
  group('Cryptographic Identity & Signatures', () {
    test('Generates Ed25519 keypair and derives EX-XXXXXX device ID', () {
      final identity = IdentityKeys.generate();

      expect(identity.seed.length, equals(32));
      expect(identity.publicKey.length, equals(32));
      expect(identity.deviceId, startsWith('EX-'));
      expect(identity.deviceId.length, equals(9)); // "EX-" + 6 hex chars
      expect(identity.keyId.length, equals(16));
    });

    test('Signs message and verifies valid signature', () {
      final identity = IdentityKeys.generate();
      final now = DateTime.now().millisecondsSinceEpoch;

      final message = EmergixxMessage(
        messageId: 'test-msg-1',
        senderDeviceId: identity.deviceId,
        recipientDeviceId: 'BROADCAST_ALL',
        messageType: MessageType.sos,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 10,
        priority: MessagePriority.critical,
        payload: 'NEED IMMEDIATE RESCUE AT 19.0760, 72.8777',
        signature: '',
        nonce: 'test-nonce-123',
      );

      final signature = Signer.signMessage(
        message: message,
        seed: identity.seed,
      );

      final signedMessage = message.copyWith(signature: signature);

      final isValid = Signer.verifyMessage(
        message: signedMessage,
        publicKey: identity.publicKey,
      );
      expect(isValid, isTrue);
    });

    test('Rejects tampered message payload', () {
      final identity = IdentityKeys.generate();
      final now = DateTime.now().millisecondsSinceEpoch;

      final message = EmergixxMessage(
        messageId: 'test-msg-2',
        senderDeviceId: identity.deviceId,
        recipientDeviceId: 'EX-999999',
        messageType: MessageType.text,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 5,
        priority: MessagePriority.normal,
        payload: 'Original legitimate content',
        signature: '',
        nonce: 'nonce-abc',
      );

      final signature = Signer.signMessage(message: message, seed: identity.seed);
      final signedMessage = message.copyWith(signature: signature);

      // Malicious tamper
      final tamperedMessage = signedMessage.copyWith(
        payload: 'TAMPERED malicious content',
      );

      final isValid = Signer.verifyMessage(
        message: tamperedMessage,
        publicKey: identity.publicKey,
      );
      expect(isValid, isFalse);
    });
  });

  group('End-to-End AEAD Encryption', () {
    test('Encrypts and decrypts direct message between two devices', () {
      final alice = IdentityKeys.generate();
      final bob = IdentityKeys.generate();

      const plaintext = 'Secret offline rendezvous coordinates: 28.6139, 77.2090';
      const msgId = 'msg-secret-42';

      final ciphertext = EncryptionEngine.encryptDirectMessage(
        senderPrivateKey: alice.x25519Seed,
        recipientPublicKey: bob.x25519PublicKey,
        plaintext: plaintext,
        messageId: msgId,
      );

      expect(ciphertext, isNot(contains(plaintext)));

      final decrypted = EncryptionEngine.decryptDirectMessage(
        recipientPrivateKey: bob.x25519Seed,
        senderPublicKey: alice.x25519PublicKey,
        ciphertextEnvelope: ciphertext,
        messageId: msgId,
      );

      expect(decrypted, equals(plaintext));
    });

    test('Encrypts and decrypts group message using symmetric group key', () {
      final groupKey = EncryptionEngine.generateGroupKey();
      const plaintext = 'Family: Meet at North Shelter evacuation point';
      const msgId = 'group-msg-99';

      final ciphertext = EncryptionEngine.encryptGroupMessage(
        groupKey: groupKey,
        plaintext: plaintext,
        messageId: msgId,
      );

      final decrypted = EncryptionEngine.decryptGroupMessage(
        groupKey: groupKey,
        ciphertextEnvelope: ciphertext,
        messageId: msgId,
      );

      expect(decrypted, equals(plaintext));
    });

    test('Throws error when tampered ciphertext is decrypted', () {
      final groupKey = EncryptionEngine.generateGroupKey();
      final ciphertext = EncryptionEngine.encryptGroupMessage(
        groupKey: groupKey,
        plaintext: 'Top Secret Message',
        messageId: 'm1',
      );

      // Corrupt payload
      final decodedJson = utf8.decode(base64Decode(ciphertext));
      final map = jsonDecode(decodedJson) as Map<String, dynamic>;
      map['ct'] = base64Encode(utf8.encode('corrupted'));
      final corruptedEnvelope = base64Encode(utf8.encode(jsonEncode(map)));

      expect(
        () => EncryptionEngine.decryptGroupMessage(
          groupKey: groupKey,
          ciphertextEnvelope: corruptedEnvelope,
          messageId: 'm1',
        ),
        throwsStateError,
      );
    });
  });

  group('Replay Protection & Authority Verification', () {
    test('Detects and blocks replayed messages with identical nonces', () {
      final protector = ReplayProtector();
      final now = DateTime.now().millisecondsSinceEpoch;

      final msg = EmergixxMessage(
        messageId: 'replay-msg-1',
        senderDeviceId: 'EX-AA11BB',
        recipientDeviceId: 'BROADCAST_ALL',
        messageType: MessageType.broadcast,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 10,
        priority: MessagePriority.high,
        payload: 'Alert',
        signature: 'sig',
        nonce: 'nonce-12345',
      );

      // First time should pass
      expect(protector.validateAndRecord(msg), isTrue);

      // Replay attempt with same nonce should be rejected
      expect(protector.validateAndRecord(msg), isFalse);
    });

    test('Rejects messages with severe clock drift', () {
      final protector = ReplayProtector(maxClockDriftMs: 60000); // 1 minute limit
      final staleTimestamp = DateTime.now().millisecondsSinceEpoch - 120000; // 2 minutes ago

      final staleMsg = EmergixxMessage(
        messageId: 'stale-msg',
        senderDeviceId: 'EX-AA11BB',
        recipientDeviceId: 'BROADCAST_ALL',
        messageType: MessageType.broadcast,
        timestamp: staleTimestamp,
        createdAt: staleTimestamp,
        expiresAt: staleTimestamp + 3600000,
        ttl: 10,
        priority: MessagePriority.high,
        payload: 'Alert',
        signature: 'sig',
        nonce: 'nonce-stale',
      );

      expect(protector.validateAndRecord(staleMsg), isFalse);
    });

    test('Verifies official disaster warning signed by registered Civil Defense authority', () {
      final authorityKeys = IdentityKeys.generate();
      final civilDefenseAuthority = AuthorityRecord(
        authorityId: 'AUTH-CIVIL-DEFENSE',
        name: 'Civil Defense & Disaster Management',
        category: 'CIVIL_DEFENSE',
        publicKey: authorityKeys.publicKey,
        registeredAt: DateTime.now(),
      );

      AuthorityVerifier.registerAuthority(civilDefenseAuthority);

      final now = DateTime.now().millisecondsSinceEpoch;
      final alertMsg = EmergixxMessage(
        messageId: 'official-alert-1',
        senderDeviceId: authorityKeys.deviceId,
        recipientDeviceId: 'BROADCAST_ALL',
        messageType: MessageType.broadcast,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 7200000,
        ttl: 10,
        priority: MessagePriority.critical,
        payload: 'OFFICIAL CYCLONE WARNING: Evacuate coastal sector B immediately.',
        signature: '',
        nonce: 'auth-nonce-001',
      );

      final sig = Signer.signMessage(message: alertMsg, seed: authorityKeys.seed);
      final signedAlert = alertMsg.copyWith(signature: sig);

      final verifiedAuth = AuthorityVerifier.verifyBroadcastAuthority(signedAlert);
      expect(verifiedAuth, isNotNull);
      expect(verifiedAuth?.authorityId, equals('AUTH-CIVIL-DEFENSE'));
      expect(verifiedAuth?.name, equals('Civil Defense & Disaster Management'));
    });
  });

  printTestSummary();
}
