/// Represents a timeline milestone or action inside an incident lifecycle.
class IncidentTimelineEvent {
  final String eventId;
  final int timestamp;
  final String title;
  final String description;
  final String actor; // e.g. "EX-7A29F1 (Survivor)", "Responder Unit 4"
  final String type; // "SOS_TRIGGERED", "RELAY_HOPS", "RESPONDER_ACK", "STATUS_CHANGE"

  const IncidentTimelineEvent({
    required this.eventId,
    required this.timestamp,
    required this.title,
    required this.description,
    required this.actor,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp,
        'title': title,
        'description': description,
        'actor': actor,
        'type': type,
      };

  factory IncidentTimelineEvent.fromJson(Map<String, dynamic> json) =>
      IncidentTimelineEvent(
        eventId: json['eventId'] as String,
        timestamp: json['timestamp'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        actor: json['actor'] as String,
        type: json['type'] as String,
      );
}

/// Represents an emergency incident aggregating one or more SOS alerts, survivors, and responders.
class Incident {
  final String incidentId;
  final String title;
  final String description;
  final String status; // "OPEN", "ACTIVE_RESPONSE", "RESOLVED", "CLOSED"
  final String priority; // "CRITICAL", "HIGH", "NORMAL", "LOW"
  final List<String> sosRecordIds;
  final List<String> assignedResponderIds;
  final double? latitude;
  final double? longitude;
  final int createdAt;
  final int updatedAt;
  final int? resolvedAt;
  final List<IncidentTimelineEvent> timeline;

  const Incident({
    required this.incidentId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.sosRecordIds = const [],
    this.assignedResponderIds = const [],
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.timeline = const [],
  });

  Map<String, dynamic> toJson() => {
        'incidentId': incidentId,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'sosRecordIds': sosRecordIds,
        'assignedResponderIds': assignedResponderIds,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'resolvedAt': resolvedAt,
        'timeline': timeline.map((e) => e.toJson()).toList(),
      };

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        incidentId: json['incidentId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        status: json['status'] as String? ?? 'OPEN',
        priority: json['priority'] as String? ?? 'CRITICAL',
        sosRecordIds: (json['sosRecordIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        assignedResponderIds: (json['assignedResponderIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        createdAt: json['createdAt'] as int,
        updatedAt: json['updatedAt'] as int,
        resolvedAt: json['resolvedAt'] as int?,
        timeline: (json['timeline'] as List<dynamic>?)
                ?.map((e) =>
                    IncidentTimelineEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
