import 'dart:convert';
import 'dart:typed_data';
import 'package:emergixx_models/emergixx_models.dart';
import 'primitives/ed25519.dart';
import 'primitives/sha256.dart';

/// Signs and validates digital signatures on Emergixx messages, alerts, and receipts.
class Signer {
  /// Signs an [EmergixxMessage] using the sender's Ed25519 private seed.
  /// Returns the Base64-encoded 64-byte signature string.
  static String signMessage({
    required EmergixxMessage message,
    required Uint8List seed,
  }) {
    final canonicalBytes =
        Uint8List.fromList(utf8.encode(message.toCanonicalString()));
    final msgHash = Sha256.hash(canonicalBytes);
    final sig = Ed25519.sign(seed: seed, message: msgHash);
    return base64Encode(sig);
  }

  /// Verifies that [message] was signed by the holder of [publicKey].
  static bool verifyMessage({
    required EmergixxMessage message,
    required Uint8List publicKey,
  }) {
    try {
      final sigBytes = base64Decode(message.signature);
      if (sigBytes.length != 64) return false;

      final canonicalBytes =
          Uint8List.fromList(utf8.encode(message.toCanonicalString()));
      final msgHash = Sha256.hash(canonicalBytes);
      return Ed25519.verify(
        publicKey: publicKey,
        message: msgHash,
        signature: sigBytes,
      );
    } catch (_) {
      return false;
    }
  }

  /// Signs an arbitrary string payload (e.g., SOS or check-in receipt).
  static String signPayload({
    required String payload,
    required Uint8List seed,
  }) {
    final bytes = Uint8List.fromList(utf8.encode(payload));
    final hash = Sha256.hash(bytes);
    final sig = Ed25519.sign(seed: seed, message: hash);
    return base64Encode(sig);
  }

  /// Verifies an arbitrary signed payload against an Ed25519 public key.
  static bool verifyPayload({
    required String payload,
    required String signatureBase64,
    required Uint8List publicKey,
  }) {
    try {
      final sigBytes = base64Decode(signatureBase64);
      final bytes = Uint8List.fromList(utf8.encode(payload));
      final hash = Sha256.hash(bytes);
      return Ed25519.verify(
        publicKey: publicKey,
        message: hash,
        signature: sigBytes,
      );
    } catch (_) {
      return false;
    }
  }
}
