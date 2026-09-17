import 'dart:convert';
import 'dart:typed_data';
import 'primitives/aead_cipher.dart';
import 'primitives/ed25519.dart';
import 'primitives/sha256.dart';

/// Handles End-to-End Encryption (E2EE) for peer-to-peer and group communications.
class EncryptionEngine {
  /// Derives a shared symmetric encryption key between two peers using ECDH-style key derivation.
  static Uint8List deriveSharedSecret({
    required Uint8List myPrivateKey,
    required Uint8List theirPublicKey,
  }) {
    final sharedPoint = Ed25519.diffieHellman(
      seed: myPrivateKey,
      theirPublicKey: theirPublicKey,
    );
    return Sha256.hash(sharedPoint);
  }

  /// Encrypts a private direct message payload for a specific peer.
  static String encryptDirectMessage({
    required Uint8List senderPrivateKey,
    required Uint8List recipientPublicKey,
    required String plaintext,
    required String messageId,
  }) {
    final sharedKey = deriveSharedSecret(
      myPrivateKey: senderPrivateKey,
      theirPublicKey: recipientPublicKey,
    );
    return AeadCipher.encrypt(
      key: sharedKey,
      plaintext: plaintext,
      associatedData: 'DIRECT:$messageId',
    );
  }

  /// Decrypts a private direct message payload received from a specific peer.
  static String decryptDirectMessage({
    required Uint8List recipientPrivateKey,
    required Uint8List senderPublicKey,
    required String ciphertextEnvelope,
    required String messageId,
  }) {
    final sharedKey = deriveSharedSecret(
      myPrivateKey: recipientPrivateKey,
      theirPublicKey: senderPublicKey,
    );
    return AeadCipher.decrypt(
      key: sharedKey,
      ciphertextEnvelope: ciphertextEnvelope,
      associatedData: 'DIRECT:$messageId',
    );
  }

  /// Encrypts a group message payload using the shared group key.
  static String encryptGroupMessage({
    required Uint8List groupKey,
    required String plaintext,
    required String messageId,
  }) {
    return AeadCipher.encrypt(
      key: groupKey,
      plaintext: plaintext,
      associatedData: 'GROUP:$messageId',
    );
  }

  /// Decrypts a group message payload using the shared group key.
  static String decryptGroupMessage({
    required Uint8List groupKey,
    required String ciphertextEnvelope,
    required String messageId,
  }) {
    return AeadCipher.decrypt(
      key: groupKey,
      ciphertextEnvelope: ciphertextEnvelope,
      associatedData: 'GROUP:$messageId',
    );
  }

  /// Generates a random 256-bit symmetric key for a new emergency group.
  static Uint8List generateGroupKey() {
    return AeadCipher.generateKey();
  }

  /// Exports a raw key to base64 string.
  static String keyToBase64(Uint8List key) => base64Encode(key);

  /// Imports a base64 string to raw key.
  static Uint8List keyFromBase64(String base64) => base64Decode(base64);
}
