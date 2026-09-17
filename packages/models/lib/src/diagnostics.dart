import 'enums.dart';

/// Live diagnostic snapshot for mesh network monitoring, field troubleshooting, and telemetry.
class MeshDiagnostics {
  final int discoveredPeersCount;
  final int connectedPeersCount;
  final List<TransportType> activeTransports;
  final int pendingOutboundQueue;
  final int storeAndForwardRelayQueue;
  final int duplicatePacketsDropped;
  final int totalPacketsRelayed;
  final int batteryLevel;
  final String powerMode; // "NORMAL", "POWER_EFFICIENT", "EMERGENCY_LOW_POWER", "CRITICAL"
  final int? lastCloudSyncTimestamp;
  final int averageHopCount;

  const MeshDiagnostics({
    required this.discoveredPeersCount,
    required this.connectedPeersCount,
    required this.activeTransports,
    required this.pendingOutboundQueue,
    required this.storeAndForwardRelayQueue,
    required this.duplicatePacketsDropped,
    required this.totalPacketsRelayed,
    required this.batteryLevel,
    required this.powerMode,
    this.lastCloudSyncTimestamp,
    this.averageHopCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'discoveredPeersCount': discoveredPeersCount,
        'connectedPeersCount': connectedPeersCount,
        'activeTransports': activeTransports.map((t) => t.toWire()).toList(),
        'pendingOutboundQueue': pendingOutboundQueue,
        'storeAndForwardRelayQueue': storeAndForwardRelayQueue,
        'duplicatePacketsDropped': duplicatePacketsDropped,
        'totalPacketsRelayed': totalPacketsRelayed,
        'batteryLevel': batteryLevel,
        'powerMode': powerMode,
        'lastCloudSyncTimestamp': lastCloudSyncTimestamp,
        'averageHopCount': averageHopCount,
      };

  factory MeshDiagnostics.fromJson(Map<String, dynamic> json) =>
      MeshDiagnostics(
        discoveredPeersCount: json['discoveredPeersCount'] as int? ?? 0,
        connectedPeersCount: json['connectedPeersCount'] as int? ?? 0,
        activeTransports: (json['activeTransports'] as List<dynamic>?)
                ?.map((e) => TransportType.fromWire(e.toString()))
                .toList() ??
            const [TransportType.bluetooth],
        pendingOutboundQueue: json['pendingOutboundQueue'] as int? ?? 0,
        storeAndForwardRelayQueue:
            json['storeAndForwardRelayQueue'] as int? ?? 0,
        duplicatePacketsDropped:
            json['duplicatePacketsDropped'] as int? ?? 0,
        totalPacketsRelayed: json['totalPacketsRelayed'] as int? ?? 0,
        batteryLevel: json['batteryLevel'] as int? ?? 100,
        powerMode: json['powerMode'] as String? ?? 'NORMAL',
        lastCloudSyncTimestamp: json['lastCloudSyncTimestamp'] as int?,
        averageHopCount: json['averageHopCount'] as int? ?? 0,
      );
}
