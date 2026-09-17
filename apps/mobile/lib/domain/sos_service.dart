import 'dart:convert';
import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_crypto/emergixx_crypto.dart';
import 'package:emergixx_shared/emergixx_shared.dart';
import '../data/repositories/emergency_repository.dart';
import 'relay_engine.dart';

/// Manages the full lifecycle of emergency SOS distress broadcasts:
/// SOS_CREATE -> SOS_RELAY -> SOS_ACKNOWLEDGE -> SOS_RESOLVED.
class SosService {
  final EmergencyRepository repository;
  final RelayEngine relayEngine;

  SosService({
    required this.repository,
    required this.relayEngine,
  });

  /// Initiates an emergency SOS broadcast across the peer-to-peer mesh.
  Future<SosRecord> triggerSos({
    required String emergencyType,
    required String messageText,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    String? medicalInfo,
    required int batteryLevel,
  }) async {
    final identity = await repository.getMyIdentity();
    final now = DateTime.now().millisecondsSinceEpoch;
    final sosId = 'sos-${identity.deviceId}-$now';

    final sos = SosRecord(
      sosId: sosId,
      senderDeviceId: identity.deviceId,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy,
      batteryLevel: batteryLevel,
      status: SosStatus.created,
      emergencyType: emergencyType,
      message: messageText,
      medicalInfo: medicalInfo,
      timestamp: now,
      relayHopCount: 0,
    );

    // Save locally
    await repository.saveSosRecord(sos);

    // Pack into signed critical mesh message envelope
    final payloadJson = jsonEncode(sos.toJson());
    final envelope = EmergixxMessage(
      messageId: sosId,
      senderDeviceId: identity.deviceId,
      recipientDeviceId: 'BROADCAST_ALL',
      messageType: MessageType.sos,
      timestamp: now,
      createdAt: now,
      expiresAt: now + (72 * 3600 * 1000), // 72 hours survival TTL
      ttl: 10,
      hopCount: 0,
      priority: MessagePriority.critical,
      payload: payloadJson,
      signature: '',
      nonce: 'nonce-$now',
    );

    final signature = Signer.signMessage(
      message: envelope,
      seed: identity.seed,
    );

    final signedEnvelope = envelope.copyWith(signature: signature);

    // Dispatch to mesh via store-and-forward engine
    await relayEngine.dispatchOutbound(signedEnvelope);

    SanitizedLogger.info('SOS', 'Life-safety emergency broadcast triggered', {
      'sosId': sosId,
      'type': emergencyType,
      'battery': batteryLevel,
    });

    return sos;
  }

  /// Acknowledges an incoming SOS (used by Responders).
  Future<void> acknowledgeSos({
    required String sosId,
    required String responderId,
    String? notes,
  }) async {
    await repository.updateSosStatus(
      sosId,
      SosStatus.acknowledged,
      responderId: responderId,
      notes: notes,
    );
  }

  /// Marks an active emergency as successfully resolved.
  Future<void> resolveSos({
    required String sosId,
    String? resolutionNotes,
  }) async {
    await repository.updateSosStatus(
      sosId,
      SosStatus.resolved,
      notes: resolutionNotes,
    );
  }
}
