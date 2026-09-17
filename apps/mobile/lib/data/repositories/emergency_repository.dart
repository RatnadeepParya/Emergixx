import 'dart:convert';
import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_crypto/emergixx_crypto.dart';
import '../database/database_helper.dart';
import '../secure_storage/secure_identity_store.dart';

/// Repository coordinating local-first data access for messages, SOS alerts, check-ins, and mesh peers.
class EmergencyRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SecureIdentityStore _secureStore = SecureIdentityStore();

  Future<IdentityKeys> getMyIdentity() => _secureStore.getOrCreateIdentity();

  // Messages
  Future<void> saveMessage(EmergixxMessage message) async {
    await _db.insertMessage(message);
  }

  Future<List<EmergixxMessage>> getMessages({String? recipientId}) =>
      _db.getAllMessages(recipientId: recipientId);

  Future<void> updateMessageStatus(String messageId, DeliveryStatus status) =>
      _db.updateMessageStatus(messageId, status);

  // SOS Records
  Future<void> saveSosRecord(SosRecord sos) async {
    await _db.insertSosRecord(sos);
    // Queue for cloud sync when connectivity is restored
    await _db.enqueueSync(
      collection: 'emergencies',
      recordId: sos.sosId,
      action: 'UPSERT',
      payloadJson: jsonEncode(sos.toJson()),
    );
  }

  Future<List<SosRecord>> getSosRecords() => _db.getAllSosRecords();

  Future<void> updateSosStatus(String sosId, SosStatus status,
          {String? responderId, String? notes}) =>
      _db.updateSosStatus(sosId, status,
          responderId: responderId, notes: notes);

  // Safety Check-Ins
  Future<void> saveCheckIn(CheckInRecord checkin) async {
    await _db.insertCheckIn(checkin);
    await _db.enqueueSync(
      collection: 'checkins',
      recordId: checkin.checkinId,
      action: 'CREATE',
      payloadJson: jsonEncode(checkin.toJson()),
    );
  }

  Future<List<CheckInRecord>> getCheckIns({String? groupId}) =>
      _db.getCheckIns(groupId: groupId);

  // Peers
  Future<void> updatePeer(Peer peer) => _db.upsertPeer(peer);

  Future<List<Peer>> getDiscoveredPeers() => _db.getAllPeers();

  Future<void> setPeerTrust(String peerId, TrustState state) =>
      _db.updatePeerTrust(peerId, state);

  // Groups
  Future<void> createGroup(EmergencyGroup group) => _db.insertGroup(group);

  Future<List<EmergencyGroup>> getGroups() => _db.getAllGroups();

  // Cloud Sync Queue
  Future<List<Map<String, dynamic>>> getPendingSyncQueue() =>
      _db.getPendingSyncItems();

  Future<void> markSyncSuccess(String syncId) =>
      _db.markSyncComplete(syncId);
}
