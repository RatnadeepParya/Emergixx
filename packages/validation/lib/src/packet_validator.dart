import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_protocol/emergixx_protocol.dart';

/// Validates structural integrity and bounds of incoming Emergixx packets.
class PacketValidator {
  static const int maxPayloadChars = 32768; // 32 KB string payload limit

  /// Validates that an [EmergixxMessage] conforms to protocol boundaries.
  static ValidationResult validate(EmergixxMessage message) {
    if (message.messageId.trim().isEmpty) {
      return ValidationResult.fail('Empty messageId');
    }

    if (!message.senderDeviceId.startsWith('EX-') &&
        message.senderDeviceId != 'AUTHORITY_CIVIL_DEFENSE') {
      return ValidationResult.fail(
          'Invalid senderDeviceId format: ${message.senderDeviceId}');
    }

    if (message.recipientDeviceId.trim().isEmpty) {
      return ValidationResult.fail('Empty recipientDeviceId');
    }

    if (message.payload.length > maxPayloadChars) {
      return ValidationResult.fail(
          'Payload exceeds maximum allowed characters ($maxPayloadChars)');
    }

    if (message.ttl < 0 || message.ttl > ProtocolVersion.maxHopCount) {
      return ValidationResult.fail(
          'Invalid TTL (${message.ttl}): must be between 0 and ${ProtocolVersion.maxHopCount}');
    }

    if (message.hopCount < 0 ||
        message.hopCount > ProtocolVersion.maxHopCount) {
      return ValidationResult.fail(
          'Invalid hopCount (${message.hopCount}): exceeds ${ProtocolVersion.maxHopCount}');
    }

    if (message.signature.trim().isEmpty) {
      return ValidationResult.fail('Missing cryptographic signature');
    }

    if (message.nonce.trim().isEmpty) {
      return ValidationResult.fail('Missing replay protection nonce');
    }

    return ValidationResult.pass();
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult._(this.isValid, this.error);

  factory ValidationResult.pass() => const ValidationResult._(true, null);
  factory ValidationResult.fail(String error) =>
      ValidationResult._(false, error);
}
