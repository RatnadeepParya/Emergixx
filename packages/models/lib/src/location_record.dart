/// Represents a geographic location snapshot with accuracy and emergency flags.
class LocationRecord {
  final String locationId; // UUID v4
  final String deviceId; // e.g. "EX-7A29F1"
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy; // In meters
  final int timestamp; // Milliseconds since epoch
  final bool isEmergency; // True if captured as part of an SOS broadcast
  final bool isApproximate; // True if intentionally coarsened for privacy

  const LocationRecord({
    required this.locationId,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    required this.timestamp,
    this.isEmergency = false,
    this.isApproximate = false,
  });

  Map<String, dynamic> toJson() => {
        'locationId': locationId,
        'deviceId': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'timestamp': timestamp,
        'isEmergency': isEmergency,
        'isApproximate': isApproximate,
      };

  factory LocationRecord.fromJson(Map<String, dynamic> json) => LocationRecord(
        locationId: json['locationId'] as String,
        deviceId: json['deviceId'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        altitude: (json['altitude'] as num?)?.toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        timestamp: json['timestamp'] as int,
        isEmergency: json['isEmergency'] as bool? ?? false,
        isApproximate: json['isApproximate'] as bool? ?? false,
      );

  Map<String, dynamic> toSqlite() => {
        'location_id': locationId,
        'device_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'timestamp': timestamp,
        'is_emergency': isEmergency ? 1 : 0,
        'is_approximate': isApproximate ? 1 : 0,
      };

  factory LocationRecord.fromSqlite(Map<String, dynamic> row) => LocationRecord(
        locationId: row['location_id'] as String,
        deviceId: row['device_id'] as String,
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        altitude: (row['altitude'] as num?)?.toDouble(),
        accuracy: (row['accuracy'] as num?)?.toDouble(),
        timestamp: row['timestamp'] as int,
        isEmergency: (row['is_emergency'] as int? ?? 0) == 1,
        isApproximate: (row['is_approximate'] as int? ?? 0) == 1,
      );
}
