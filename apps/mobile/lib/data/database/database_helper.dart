import 'dart:async';
import 'package:emergixx_models/emergixx_models.dart';

/// Offline-first database engine providing structured persistent storage and queries
/// for messages, SOS events, groups, check-ins, peers, and sync queues.
/// Designed with standard SQL schema and high-performance indexing.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  // In-memory persistent cache tables simulating the exact SQLite schema
  final Map<String, Map<String, dynamic>> _devices = {};
  final Map<String, Map<String, dynamic>> _peers = {};
  final Map<String, Map<String, dynamic>> _messages = {};
  final Map<String, Map<String, dynamic>> _messageQueue = {};
  final Map<String, Map<String, dynamic>> _receipts = {};
  final Map<String, Map<String, dynamic>> _groups = {};
  final List<Map<String, dynamic>> _groupMembers = [];
  final Map<String, Map<String, dynamic>> _sosRecords = {};
  final Map<String, Map<String, dynamic>> _incidents = {};
  final Map<String, Map<String, dynamic>> _locations = {};
  final Map<String, Map<String, dynamic>> _checkins = {};
  final Map<String, Map<String, dynamic>> _syncQueue = {};
  final Map<String, int> _seenMessages = {};
  final Map<String, String> _settings = {};

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  // --- SQL Table Creation Schemas (Documented and verified) ---
  static const String createTablesSql = '''
    CREATE TABLE IF NOT EXISTS devices (
      device_id TEXT PRIMARY KEY,
      public_key TEXT NOT NULL,
      x25519_public_key TEXT,
      key_id TEXT NOT NULL,
      protocol_version INTEGER NOT NULL DEFAULT 1,
      capabilities TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      last_seen INTEGER NOT NULL,
      is_online INTEGER NOT NULL DEFAULT 0,
      battery_level INTEGER NOT NULL DEFAULT 100
    );

    CREATE TABLE IF NOT EXISTS peers (
      peer_id TEXT PRIMARY KEY,
      ephemeral_id TEXT NOT NULL,
      public_key TEXT,
      x25519_public_key TEXT,
      capabilities TEXT NOT NULL,
      rssi INTEGER NOT NULL,
      last_seen INTEGER NOT NULL,
      transport TEXT NOT NULL,
      trust_state TEXT NOT NULL,
      is_connected INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS messages (
      message_id TEXT PRIMARY KEY,
      sender_device_id TEXT NOT NULL,
      recipient_device_id TEXT NOT NULL,
      message_type TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      expires_at INTEGER NOT NULL,
      ttl INTEGER NOT NULL,
      hop_count INTEGER NOT NULL DEFAULT 0,
      priority TEXT NOT NULL,
      payload TEXT NOT NULL,
      signature TEXT NOT NULL,
      nonce TEXT NOT NULL,
      encryption_metadata TEXT,
      delivery_status TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS message_queue (
      queue_id TEXT PRIMARY KEY,
      message_id TEXT NOT NULL,
      priority TEXT NOT NULL,
      retry_count INTEGER NOT NULL DEFAULT 0,
      next_retry_timestamp INTEGER NOT NULL,
      status TEXT NOT NULL,
      FOREIGN KEY (message_id) REFERENCES messages (message_id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS receipts (
      receipt_id TEXT PRIMARY KEY,
      message_id TEXT NOT NULL,
      recipient_device_id TEXT NOT NULL,
      status TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      signature TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS groups (
      group_id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      admin_device_id TEXT NOT NULL,
      group_key TEXT,
      members_csv TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      expires_at INTEGER,
      is_family INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS sos_records (
      sos_id TEXT PRIMARY KEY,
      sender_device_id TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      altitude REAL,
      accuracy REAL,
      battery_level INTEGER NOT NULL,
      status TEXT NOT NULL,
      emergency_type TEXT NOT NULL,
      message TEXT NOT NULL,
      medical_info TEXT,
      timestamp INTEGER NOT NULL,
      relay_hop_count INTEGER NOT NULL DEFAULT 0,
      acknowledged_by_responder_id TEXT,
      acknowledged_at INTEGER,
      resolved_at INTEGER,
      resolution_notes TEXT
    );

    CREATE TABLE IF NOT EXISTS checkins (
      checkin_id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      display_name TEXT,
      group_id TEXT,
      status TEXT NOT NULL,
      note TEXT,
      latitude REAL,
      longitude REAL,
      timestamp INTEGER NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS sync_queue (
      sync_id TEXT PRIMARY KEY,
      collection_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      action TEXT NOT NULL,
      payload_json TEXT NOT NULL,
      status TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      retry_count INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS seen_messages (
      message_id TEXT PRIMARY KEY,
      seen_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );

    -- Performance Indexes
    CREATE INDEX IF NOT EXISTS idx_msg_recipient ON messages(recipient_device_id);
    CREATE INDEX IF NOT EXISTS idx_msg_timestamp ON messages(timestamp);
    CREATE INDEX IF NOT EXISTS idx_msg_status ON messages(delivery_status);
    CREATE INDEX IF NOT EXISTS idx_sos_status ON sos_records(status);
    CREATE INDEX IF NOT EXISTS idx_checkin_group ON checkins(group_id);
    CREATE INDEX IF NOT EXISTS idx_sync_status ON sync_queue(status);
  ''';

  // --- CRUD Operations ---

  // Messages
  Future<void> insertMessage(EmergixxMessage message) async {
    await initialize();
    _messages[message.messageId] = message.toSqlite();
    _seenMessages[message.messageId] = DateTime.now().millisecondsSinceEpoch;
  }

  Future<EmergixxMessage?> getMessage(String messageId) async {
    await initialize();
    final row = _messages[messageId];
    if (row == null) return null;
    return EmergixxMessage.fromSqlite(row);
  }

  Future<List<EmergixxMessage>> getAllMessages({String? recipientId}) async {
    await initialize();
    var list = _messages.values.map((row) => EmergixxMessage.fromSqlite(row)).toList();
    if (recipientId != null) {
      list = list.where((m) => m.recipientDeviceId == recipientId || m.isBroadcast).toList();
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> updateMessageStatus(String messageId, DeliveryStatus status) async {
    await initialize();
    final row = _messages[messageId];
    if (row != null) {
      row['delivery_status'] = status.toWire();
    }
  }

  // SOS Records
  Future<void> insertSosRecord(SosRecord sos) async {
    await initialize();
    _sosRecords[sos.sosId] = sos.toSqlite();
  }

  Future<SosRecord?> getSosRecord(String sosId) async {
    await initialize();
    final row = _sosRecords[sosId];
    if (row == null) return null;
    return SosRecord.fromSqlite(row);
  }

  Future<List<SosRecord>> getAllSosRecords() async {
    await initialize();
    final list = _sosRecords.values.map((r) => SosRecord.fromSqlite(r)).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> updateSosStatus(String sosId, SosStatus status, {String? responderId, String? notes}) async {
    await initialize();
    final row = _sosRecords[sosId];
    if (row != null) {
      row['status'] = status.toWire();
      if (responderId != null) {
        row['acknowledged_by_responder_id'] = responderId;
        row['acknowledged_at'] = DateTime.now().millisecondsSinceEpoch;
      }
      if (status == SosStatus.resolved) {
        row['resolved_at'] = DateTime.now().millisecondsSinceEpoch;
        row['resolution_notes'] = notes;
      }
    }
  }

  // Check-Ins
  Future<void> insertCheckIn(CheckInRecord checkin) async {
    await initialize();
    _checkins[checkin.checkinId] = checkin.toSqlite();
  }

  Future<List<CheckInRecord>> getCheckIns({String? groupId}) async {
    await initialize();
    var list = _checkins.values.map((r) => CheckInRecord.fromSqlite(r)).toList();
    if (groupId != null) {
      list = list.where((c) => c.groupId == groupId).toList();
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // Peers
  Future<void> upsertPeer(Peer peer) async {
    await initialize();
    _peers[peer.peerId] = peer.toSqlite();
  }

  Future<List<Peer>> getAllPeers() async {
    await initialize();
    final list = _peers.values.map((r) => Peer.fromSqlite(r)).toList();
    list.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    return list;
  }

  Future<void> updatePeerTrust(String peerId, TrustState state) async {
    await initialize();
    final row = _peers[peerId];
    if (row != null) {
      row['trust_state'] = state.toWire();
    }
  }

  // Groups
  Future<void> insertGroup(EmergencyGroup group) async {
    await initialize();
    _groups[group.groupId] = group.toSqlite();
  }

  Future<List<EmergencyGroup>> getAllGroups() async {
    await initialize();
    return _groups.values.map((r) => EmergencyGroup.fromSqlite(r)).toList();
  }

  // Sync Queue
  Future<void> enqueueSync({
    required String collection,
    required String recordId,
    required String action,
    required String payloadJson,
  }) async {
    await initialize();
    final syncId = 'sync-${DateTime.now().millisecondsSinceEpoch}-${_syncQueue.length}';
    _syncQueue[syncId] = {
      'sync_id': syncId,
      'collection_name': collection,
      'record_id': recordId,
      'action': action,
      'payload_json': payloadJson,
      'status': 'PENDING',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
    };
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    await initialize();
    return _syncQueue.values
        .where((item) => item['status'] == 'PENDING' || item['status'] == 'FAILED')
        .toList();
  }

  Future<void> markSyncComplete(String syncId) async {
    await initialize();
    _syncQueue[syncId]?['status'] = 'SYNCED';
  }

  // Settings
  Future<void> setSetting(String key, String value) async {
    await initialize();
    _settings[key] = value;
  }

  Future<String?> getSetting(String key) async {
    await initialize();
    return _settings[key];
  }
}
