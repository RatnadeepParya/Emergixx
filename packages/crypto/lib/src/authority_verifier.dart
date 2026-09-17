import 'dart:typed_data';
import 'package:emergixx_models/emergixx_models.dart';
import 'signer.dart';

/// Represents a verified public safety organization or authority.
class AuthorityRecord {
  final String authorityId;
  final String name; // e.g. "National Disaster Management Authority"
  final String category; // "CIVIL_DEFENSE", "RED_CROSS", "FIRST_RESPONDER", "COMMUNITY"
  final Uint8List publicKey; // Ed25519 public key
  final DateTime registeredAt;

  const AuthorityRecord({
    required this.authorityId,
    required this.name,
    required this.category,
    required this.publicKey,
    required this.registeredAt,
  });
}

/// Verifies digitally signed official emergency broadcasts against trusted authorities.
class AuthorityVerifier {
  static final Map<String, AuthorityRecord> _authorities = {};

  /// Registers a trusted authority with their public key.
  static void registerAuthority(AuthorityRecord authority) {
    _authorities[authority.authorityId] = authority;
  }

  /// Removes an authority if revoked.
  static void revokeAuthority(String authorityId) {
    _authorities.remove(authorityId);
  }

  /// Lists all currently trusted authorities.
  static List<AuthorityRecord> getTrustedAuthorities() =>
      _authorities.values.toList();

  /// Verifies if an [EmergixxMessage] is an officially signed emergency broadcast.
  /// Returns the matching [AuthorityRecord] if verified, or null if not from a verified authority.
  static AuthorityRecord? verifyBroadcastAuthority(EmergixxMessage message) {
    if (message.messageType != MessageType.broadcast &&
        message.messageType != MessageType.emergencyUpdate) {
      return null;
    }

    // Check if senderDeviceId or authority tag matches a registered authority
    for (final authority in _authorities.values) {
      final isValid = Signer.verifyMessage(
        message: message,
        publicKey: authority.publicKey,
      );
      if (isValid) {
        return authority;
      }
    }
    return null;
  }

  /// Validates an authority signature on a raw text payload.
  static AuthorityRecord? verifyPayloadAuthority({
    required String payload,
    required String signatureBase64,
  }) {
    for (final authority in _authorities.values) {
      final isValid = Signer.verifyPayload(
        payload: payload,
        signatureBase64: signatureBase64,
        publicKey: authority.publicKey,
      );
      if (isValid) {
        return authority;
      }
    }
    return null;
  }
}
