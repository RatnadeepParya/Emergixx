import 'enums.dart';

/// Represents a critical life-safety SOS broadcast event.
class SosRecord {
  final String sosId; // Unique ID (UUID v4)
  final String senderDeviceId; // e.g. "EX-7A29F1"
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final int batteryLevel; // Percentage 0 - 100
  final SosStatus status;
  final String emergencyType; // "MEDICAL", "TRAPPED", "FIRE", "FLOOD", "GENERAL"
  final String message; // Distress message
  final String? medicalInfo; // Medical conditions, allergies, blood type
  final int timestamp; // Milliseconds since epoch
  final int relayHopCount;
  final String? acknowledgedByResponderId;
  final int? acknowledgedAt;
  final int? resolvedAt;
  final String? resolutionNotes;

  const SosRecord({
    required this.sosId,
    required this.senderDeviceId,
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    required this.batteryLevel,
    this.status = SosStatus.created,
    required this.emergencyType,
    required this.message,
    this.medicalInfo,
    required this.timestamp,
    this.relayHopCount = 0,
    this.acknowledgedByResponderId,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolutionNotes,
  });

  SosRecord copyWith({
    String? sosId,
    String? senderDeviceId,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    int? batteryLevel,
    SosStatus? status,
    String? emergencyType,
    String? message,
    String? medicalInfo,
    int? timestamp,
    int? relayHopCount,
    String? acknowledgedByResponderId,
    int? acknowledgedAt,
    int? resolvedAt,
    String? resolutionNotes,
  }) {
    return SosRecord(
      sosId: sosId ?? this.sosId,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      status: status ?? this.status,
      emergencyType: emergencyType ?? this.emergencyType,
      message: message ?? this.message,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      timestamp: timestamp ?? this.timestamp,
      relayHopCount: relayHopCount ?? this.relayHopCount,
      acknowledgedByResponderId:
          acknowledgedByResponderId ?? this.acknowledgedByResponderId,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'sosId': sosId,
        'senderDeviceId': senderDeviceId,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'batteryLevel': batteryLevel,
        'status': status.toWire(),
        'emergencyType': emergencyType,
        'message': message,
        'medicalInfo': medicalInfo,
        'timestamp': timestamp,
        'relayHopCount': relayHopCount,
        'acknowledgedByResponderId': acknowledgedByResponderId,
        'acknowledgedAt': acknowledgedAt,
        'resolvedAt': resolvedAt,
        'resolutionNotes': resolutionNotes,
      };

  factory SosRecord.fromJson(Map<String, dynamic> json) => SosRecord(
        sosId: json['sosId'] as String,
        senderDeviceId: json['senderDeviceId'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        altitude: (json['altitude'] as num?)?.toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        batteryLevel: json['batteryLevel'] as int? ?? 100,
        status: SosStatus.fromWire(json['status'] as String? ?? 'CREATED'),
        emergencyType: json['emergencyType'] as String? ?? 'GENERAL',
        message: json['message'] as String? ?? '',
        medicalInfo: json['medicalInfo'] as String?,
        timestamp: json['timestamp'] as int,
        relayHopCount: json['relayHopCount'] as int? ?? 0,
        acknowledgedByResponderId:
            json['acknowledgedByResponderId'] as String?,
        acknowledgedAt: json['acknowledgedAt'] as int?,
        resolvedAt: json['resolvedAt'] as int?,
        resolutionNotes: json['resolutionNotes'] as String?,
      );

  Map<String, dynamic> toSqlite() => {
        'sos_id': sosId,
        'sender_device_id': senderDeviceId,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'battery_level': batteryLevel,
        'status': status.toWire(),
        'emergency_type': emergencyType,
        'message': message,
        'medical_info': medicalInfo,
        'timestamp': timestamp,
        'relay_hop_count': relayHopCount,
        'acknowledged_by_responder_id': acknowledgedByResponderId,
        'acknowledged_at': acknowledgedAt,
        'resolved_at': resolvedAt,
        'resolution_notes': resolutionNotes,
      };

  factory SosRecord.fromSqlite(Map<String, dynamic> row) => SosRecord(
        sosId: row['sos_id'] as String,
        senderDeviceId: row['sender_device_id'] as String,
        latitude: (row['latitude'] as num?)?.toDouble(),
        longitude: (row['longitude'] as num?)?.toDouble(),
        altitude: (row['altitude'] as num?)?.toDouble(),
        accuracy: (row['accuracy'] as num?)?.toDouble(),
        batteryLevel: row['battery_level'] as int? ?? 100,
        status: SosStatus.fromWire(row['status'] as String),
        emergencyType: row['emergency_type'] as String,
        message: row['message'] as String,
        medicalInfo: row['medical_info'] as String?,
        timestamp: row['timestamp'] as int,
        relayHopCount: row['relay_hop_count'] as int? ?? 0,
        acknowledgedByResponderId:
            row['acknowledged_by_responder_id'] as String?,
        acknowledgedAt: row['acknowledged_at'] as int?,
        resolvedAt: row['resolved_at'] as int?,
        resolutionNotes: row['resolution_notes'] as String?,
      );
}
