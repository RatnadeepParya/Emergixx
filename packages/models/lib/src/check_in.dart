import 'enums.dart';

/// Represents a safety check-in by an individual or family member.
class CheckInRecord {
  final String checkinId; // UUID v4
  final String userId; // Anonymous or authenticated ID
  final String deviceId; // e.g. "EX-7A29F1"
  final String? displayName; // Optional local name e.g. "Sarah (Daughter)"
  final String? groupId; // Optional emergency group ID
  final CheckInStatus status;
  final String? note; // Optional message e.g. "Reached rooftop shelter"
  final double? latitude;
  final double? longitude;
  final int timestamp; // Milliseconds since epoch
  final bool isSyncedToCloud;

  const CheckInRecord({
    required this.checkinId,
    required this.userId,
    required this.deviceId,
    this.displayName,
    this.groupId,
    required this.status,
    this.note,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.isSyncedToCloud = false,
  });

  CheckInRecord copyWith({
    String? checkinId,
    String? userId,
    String? deviceId,
    String? displayName,
    String? groupId,
    CheckInStatus? status,
    String? note,
    double? latitude,
    double? longitude,
    int? timestamp,
    bool? isSyncedToCloud,
  }) {
    return CheckInRecord(
      checkinId: checkinId ?? this.checkinId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      note: note ?? this.note,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      isSyncedToCloud: isSyncedToCloud ?? this.isSyncedToCloud,
    );
  }

  Map<String, dynamic> toJson() => {
        'checkinId': checkinId,
        'userId': userId,
        'deviceId': deviceId,
        'displayName': displayName,
        'groupId': groupId,
        'status': status.toWire(),
        'note': note,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
        'isSyncedToCloud': isSyncedToCloud,
      };

  factory CheckInRecord.fromJson(Map<String, dynamic> json) => CheckInRecord(
        checkinId: json['checkinId'] as String,
        userId: json['userId'] as String,
        deviceId: json['deviceId'] as String,
        displayName: json['displayName'] as String?,
        groupId: json['groupId'] as String?,
        status: CheckInStatus.fromWire(json['status'] as String),
        note: json['note'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        timestamp: json['timestamp'] as int,
        isSyncedToCloud: json['isSyncedToCloud'] as bool? ?? false,
      );

  Map<String, dynamic> toSqlite() => {
        'checkin_id': checkinId,
        'user_id': userId,
        'device_id': deviceId,
        'display_name': displayName,
        'group_id': groupId,
        'status': status.toWire(),
        'note': note,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
        'is_synced': isSyncedToCloud ? 1 : 0,
      };

  factory CheckInRecord.fromSqlite(Map<String, dynamic> row) => CheckInRecord(
        checkinId: row['checkin_id'] as String,
        userId: row['user_id'] as String,
        deviceId: row['device_id'] as String,
        displayName: row['display_name'] as String?,
        groupId: row['group_id'] as String?,
        status: CheckInStatus.fromWire(row['status'] as String),
        note: row['note'] as String?,
        latitude: (row['latitude'] as num?)?.toDouble(),
        longitude: (row['longitude'] as num?)?.toDouble(),
        timestamp: row['timestamp'] as int,
        isSyncedToCloud: (row['is_synced'] as int? ?? 0) == 1,
      );
}
