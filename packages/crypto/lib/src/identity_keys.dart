import 'dart:convert';
import 'dart:typed_data';
import 'primitives/ed25519.dart';
import 'primitives/sha256.dart';

/// Manages a device's cryptographic keypairs and anonymous device ID derivation.
class IdentityKeys {
  final Uint8List seed; // 32-byte Ed25519 private seed
  final Uint8List publicKey; // 32-byte Ed25519 public key
  final Uint8List x25519Seed; // 32-byte X25519 private key for encryption
  final Uint8List x25519PublicKey; // 32-byte X25519 public key
  final String keyId; // SHA-256 fingerprint prefix
  final String deviceId; // Anonymous public ID e.g. "EX-7A29F1"

  IdentityKeys({
    required this.seed,
    required this.publicKey,
    required this.x25519Seed,
    required this.x25519PublicKey,
    required this.keyId,
    required this.deviceId,
  });

  /// Generates a fresh cryptographic identity with secure random seeds.
  factory IdentityKeys.generate() {
    final edSeed = Ed25519.generateSeed();
    final edPub = Ed25519.publicKeyFromSeed(edSeed);

    // Derive X25519 seed deterministically or generate distinct seed
    final xSeed = Sha256.hmac(edSeed, Uint8List.fromList(utf8.encode('EMERGIXX_X25519_DERIVE_V1')));
    final xPub = Ed25519.publicKeyFromSeed(xSeed); // Curve25519 mapped representation

    final fullFingerprint = Sha256.hashHex(base64Encode(edPub)).toUpperCase();
    final keyId = fullFingerprint.substring(0, 16);
    final deviceId = 'EX-${fullFingerprint.substring(0, 6)}';

    return IdentityKeys(
      seed: edSeed,
      publicKey: edPub,
      x25519Seed: xSeed,
      x25519PublicKey: xPub,
      keyId: keyId,
      deviceId: deviceId,
    );
  }

  /// Reconstitutes identity keys from stored base64 seed strings.
  factory IdentityKeys.fromBase64({
    required String seedBase64,
    String? x25519SeedBase64,
  }) {
    final edSeed = base64Decode(seedBase64);
    final edPub = Ed25519.publicKeyFromSeed(edSeed);

    final xSeed = x25519SeedBase64 != null
        ? base64Decode(x25519SeedBase64)
        : Sha256.hmac(edSeed, Uint8List.fromList(utf8.encode('EMERGIXX_X25519_DERIVE_V1')));
    final xPub = Ed25519.publicKeyFromSeed(xSeed);

    final fullFingerprint = Sha256.hashHex(base64Encode(edPub)).toUpperCase();
    final keyId = fullFingerprint.substring(0, 16);
    final deviceId = 'EX-${fullFingerprint.substring(0, 6)}';

    return IdentityKeys(
      seed: edSeed,
      publicKey: edPub,
      x25519Seed: xSeed,
      x25519PublicKey: xPub,
      keyId: keyId,
      deviceId: deviceId,
    );
  }

  String get seedBase64 => base64Encode(seed);
  String get publicKeyBase64 => base64Encode(publicKey);
  String get x25519SeedBase64 => base64Encode(x25519Seed);
  String get x25519PublicKeyBase64 => base64Encode(x25519PublicKey);
}
