import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'sha256.dart';

/// Authenticated Encryption with Associated Data (AEAD) using HKDF-SHA256 + Stream Keystream + HMAC-SHA256.
/// Guarantees confidentiality, integrity, and authenticity for offline P2P message payloads.
class AeadCipher {
  /// Generates a random 32-byte cryptographic key.
  static Uint8List generateKey() {
    final rng = Random.secure();
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = rng.nextInt(256);
    }
    return key;
  }

  /// Encrypts [plaintext] under [key] with optional [associatedData].
  /// Returns a Base64-encoded envelope containing {iv, ciphertext, mac}.
  static String encrypt({
    required Uint8List key,
    required String plaintext,
    String associatedData = '',
  }) {
    final rng = Random.secure();
    final iv = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      iv[i] = rng.nextInt(256);
    }

    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

    // Derive encryption and authentication keys using HKDF expansion
    final encKey = Sha256.hmac(key, Uint8List.fromList(utf8.encode('EMERGIXX_ENC_KEY_V1')));
    final macKey = Sha256.hmac(key, Uint8List.fromList(utf8.encode('EMERGIXX_MAC_KEY_V1')));

    // Generate pseudo-random keystream using CTR block expansion
    final ciphertext = Uint8List(plaintextBytes.length);
    int blockCount = (plaintextBytes.length + 31) ~/ 32;

    for (int b = 0; b < blockCount; b++) {
      final counterBytes = Uint8List(4);
      ByteData.view(counterBytes.buffer).setUint32(0, b, Endian.big);

      final blockInput = Uint8List(iv.length + counterBytes.length);
      blockInput.setRange(0, iv.length, iv);
      blockInput.setRange(iv.length, blockInput.length, counterBytes);

      final keystream = Sha256.hmac(encKey, blockInput);
      int start = b * 32;
      int end = (start + 32 > plaintextBytes.length)
          ? plaintextBytes.length
          : start + 32;

      for (int i = start; i < end; i++) {
        ciphertext[i] = plaintextBytes[i] ^ keystream[i - start];
      }
    }

    // Compute HMAC authentication tag over IV + AssociatedData + Ciphertext
    final adBytes = Uint8List.fromList(utf8.encode(associatedData));
    final macInput = Uint8List(iv.length + adBytes.length + ciphertext.length);
    macInput.setRange(0, iv.length, iv);
    macInput.setRange(iv.length, iv.length + adBytes.length, adBytes);
    macInput.setRange(iv.length + adBytes.length, macInput.length, ciphertext);

    final mac = Sha256.hmac(macKey, macInput);

    // Pack into portable base64 envelope
    final envelope = {
      'v': 1,
      'iv': base64Encode(iv),
      'ct': base64Encode(ciphertext),
      'mac': base64Encode(mac),
    };

    return base64Encode(utf8.encode(jsonEncode(envelope)));
  }

  /// Decrypts Base64 [ciphertextEnvelope] under [key] with [associatedData].
  /// Throws [StateError] if authentication tag fails or data is tampered.
  static String decrypt({
    required Uint8List key,
    required String ciphertextEnvelope,
    String associatedData = '',
  }) {
    final envelopeJson =
        utf8.decode(base64Decode(ciphertextEnvelope.trim()));
    final Map<String, dynamic> envelope =
        jsonDecode(envelopeJson) as Map<String, dynamic>;

    final iv = base64Decode(envelope['iv'] as String);
    final ciphertext = base64Decode(envelope['ct'] as String);
    final mac = base64Decode(envelope['mac'] as String);

    final encKey = Sha256.hmac(key, Uint8List.fromList(utf8.encode('EMERGIXX_ENC_KEY_V1')));
    final macKey = Sha256.hmac(key, Uint8List.fromList(utf8.encode('EMERGIXX_MAC_KEY_V1')));

    // Verify MAC
    final adBytes = Uint8List.fromList(utf8.encode(associatedData));
    final macInput = Uint8List(iv.length + adBytes.length + ciphertext.length);
    macInput.setRange(0, iv.length, iv);
    macInput.setRange(iv.length, iv.length + adBytes.length, adBytes);
    macInput.setRange(iv.length + adBytes.length, macInput.length, ciphertext);

    final expectedMac = Sha256.hmac(macKey, macInput);

    // Constant-time equality check
    if (mac.length != expectedMac.length) {
      throw StateError('AEAD authentication failed: MAC length mismatch');
    }
    int diff = 0;
    for (int i = 0; i < mac.length; i++) {
      diff |= mac[i] ^ expectedMac[i];
    }
    if (diff != 0) {
      throw StateError('AEAD authentication failed: Tampered or invalid ciphertext');
    }

    // Decrypt keystream
    final plaintextBytes = Uint8List(ciphertext.length);
    int blockCount = (ciphertext.length + 31) ~/ 32;

    for (int b = 0; b < blockCount; b++) {
      final counterBytes = Uint8List(4);
      ByteData.view(counterBytes.buffer).setUint32(0, b, Endian.big);

      final blockInput = Uint8List(iv.length + counterBytes.length);
      blockInput.setRange(0, iv.length, iv);
      blockInput.setRange(iv.length, blockInput.length, counterBytes);

      final keystream = Sha256.hmac(encKey, blockInput);
      int start = b * 32;
      int end = (start + 32 > ciphertext.length)
          ? ciphertext.length
          : start + 32;

      for (int i = start; i < end; i++) {
        plaintextBytes[i] = ciphertext[i] ^ keystream[i - start];
      }
    }

    return utf8.decode(plaintextBytes);
  }
}
