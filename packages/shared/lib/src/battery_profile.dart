/// Battery awareness and adaptive duty-cycling profiles to maximize phone survival time in crises.
enum PowerMode {
  normal,             // Battery > 50%
  powerEfficient,     // Battery 20% - 50%
  emergencyLowPower,  // Battery 5% - 19%
  critical;           // Battery < 5%

  String toWire() => name.toUpperCase();
}

class BatteryProfile {
  final int batteryLevel; // 0 - 100
  final bool isCharging;
  final PowerMode mode;

  /// Scan duration in seconds during each duty cycle.
  final int scanWindowSeconds;

  /// Sleep duration between scan cycles.
  final int scanIntervalSeconds;

  /// Whether background store-and-forward relaying is permitted in this mode.
  final bool canRelayTransitTraffic;

  /// Whether continuous high-accuracy GPS querying is permitted.
  final bool allowContinuousGps;

  const BatteryProfile({
    required this.batteryLevel,
    required this.isCharging,
    required this.mode,
    required this.scanWindowSeconds,
    required this.scanIntervalSeconds,
    required this.canRelayTransitTraffic,
    required this.allowContinuousGps,
  });

  /// Derives the optimal adaptive profile based on battery percentage and charging state.
  factory BatteryProfile.fromLevel(int level, {bool isCharging = false}) {
    if (isCharging || level > 50) {
      return BatteryProfile(
        batteryLevel: level,
        isCharging: isCharging,
        mode: PowerMode.normal,
        scanWindowSeconds: 30,
        scanIntervalSeconds: 0, // Continuous or high-frequency scanning
        canRelayTransitTraffic: true,
        allowContinuousGps: true,
      );
    } else if (level >= 20) {
      return BatteryProfile(
        batteryLevel: level,
        isCharging: isCharging,
        mode: PowerMode.powerEfficient,
        scanWindowSeconds: 15,
        scanIntervalSeconds: 45, // 15s on / 45s off
        canRelayTransitTraffic: true,
        allowContinuousGps: false, // On-demand GPS only
      );
    } else if (level >= 5) {
      return BatteryProfile(
        batteryLevel: level,
        isCharging: isCharging,
        mode: PowerMode.emergencyLowPower,
        scanWindowSeconds: 5,
        scanIntervalSeconds: 120, // 5s on / 2 minutes off
        canRelayTransitTraffic: false, // Drop non-essential background relays
        allowContinuousGps: false,
      );
    } else {
      // Critical mode (< 5%)
      return BatteryProfile(
        batteryLevel: level,
        isCharging: isCharging,
        mode: PowerMode.critical,
        scanWindowSeconds: 2,
        scanIntervalSeconds: 300, // Minimal beaconing, SOS transmission only
        canRelayTransitTraffic: false,
        allowContinuousGps: false,
      );
    }
  }
}
