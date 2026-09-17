import 'dart:convert';
import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_crypto/emergixx_crypto.dart';
import 'package:emergixx_shared/emergixx_shared.dart';
import '../data/repositories/emergency_repository.dart';
import 'relay_engine.dart';

/// Manages one-touch safety status check-ins:
/// SAFE, NEED HELP, MOVING, UNABLE TO MOVE, UNKNOWN.
class CheckinService {
  final EmergencyRepository repository;
  final RelayEngine relayEngine;

  CheckinService({
    required this.repository,
    required this.relayEngine,
  });

  /// Submits a safety check-in, stores it locally, and propagates it across the mesh.
  Future<CheckInRecord> submitCheckIn({
    required CheckInStatus status,
    String? displayName,
    String? groupId,
    String? note,
    double? latitude,
    double? longitude,
  }) async {
    final identity = await repository.getMyIdentity();
    final now = DateTime.now().millisecondsSinceEpoch;
    final checkinId = 'chk-${identity.deviceId}-$now';

    final checkin = CheckInRecord(
      checkinId: checkinId,
      userId: identity.deviceId,
      deviceId: identity.deviceId,
      displayName: displayName,
      groupId: groupId,
      status: status,
      note: note,
      latitude: latitude,
      longitude: longitude,
      timestamp: now,
      isSyncedToCloud: false,
    );

    await repository.saveCheckIn(checkin);

    // Broadcast check-in to family group or all nearby peers
    final recipient = groupId != null ? 'GROUP:$groupId' : 'BROADCAST_ALL';
    final payloadJson = jsonEncode(checkin.toJson());

    final message = EmergixxMessage(
      messageId: checkinId,
      senderDeviceId: identity.deviceId,
      recipientDeviceId: recipient,
      messageType: MessageType.deliveryStatus,
      timestamp: now,
      createdAt: now,
      expiresAt: now + (24 * 3600 * 1000), // 24 hours TTL
      ttl: 8,
      priority: status == CheckInStatus.needHelp
          ? MessagePriority.critical
          : MessagePriority.normal,
      payload: payloadJson,
      signature: '',
      nonce: 'chk-nonce-$now',
    );

    final sig = Signer.signMessage(message: message, seed: identity.seed);
    final signedMessage = message.copyWith(signature: sig);

    await relayEngine.dispatchOutbound(signedMessage);

    SanitizedLogger.info('CHECKIN', 'Safety status submitted', {
      'checkinId': checkinId,
      'status': status.toWire(),
      'groupId': groupId,
    });

    return checkin;
  }
}
