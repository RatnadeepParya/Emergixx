import 'package:flutter/material.dart';
import '../theme/emergixx_theme.dart';

/// Dedicated, stress-tested high-visibility Emergency Mode screen.
/// Optimized for one-handed operation, panic scenarios, low battery, and smoke/night environments.
class EmergencyModeScreen extends StatefulWidget {
  const EmergencyModeScreen({super.key});

  @override
  State<EmergencyModeScreen> createState() => _EmergencyModeScreenState();
}

class _EmergencyModeScreenState extends State<EmergencyModeScreen> {
  bool _isSosActive = false;
  String _statusText = 'READY TO BROADCAST';
  final double _latitude = 19.0760;
  final double _longitude = 72.8777;
  final int _batteryLevel = 18;
  final String _deviceId = 'EX-7A29F1';

  void _toggleSos() {
    setState(() {
      _isSosActive = !_isSosActive;
      _statusText = _isSosActive
          ? 'BROADCASTING DISTRESS BEACON...'
          : 'SOS STANDBY';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'EMERGENCY MODE',
          style: TextStyle(
            color: EmergixxTheme.emergencyRed,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // High-Stress Distress Status Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSosActive
                      ? EmergixxTheme.emergencyRedDark
                      : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSosActive
                        ? EmergixxTheme.emergencyRed
                        : Colors.white24,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isSosActive ? Icons.warning : Icons.shield,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Survival Telemetry Grid
              Card(
                color: const Color(0xFF161616),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDataRow(Icons.pin_drop, 'GPS LOCATION',
                          '$_latitude, $_longitude (±4m)'),
                      const Divider(color: Colors.white12, height: 24),
                      _buildDataRow(Icons.battery_alert, 'BATTERY RESERVE',
                          '$_batteryLevel% (Low Power Relay)'),
                      const Divider(color: Colors.white12, height: 24),
                      _buildDataRow(Icons.fingerprint, 'ANONYMOUS ID', _deviceId),
                      const Divider(color: Colors.white12, height: 24),
                      _buildDataRow(Icons.access_time, 'BEACON TIMESTAMP',
                          DateTime.now().toLocal().toString().substring(0, 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Emergency Message Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EmergixxTheme.emergencyRed.withOpacity(0.5)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE DISTRESS MESSAGE:',
                      style: TextStyle(
                        color: EmergixxTheme.emergencyRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '"Trapped inside building. Need medical assistance. Water level rising."',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Giant Tactile Action Trigger
              SizedBox(
                height: 72,
                child: ElevatedButton.icon(
                  onPressed: _toggleSos,
                  icon: Icon(
                    _isSosActive ? Icons.stop_circle : Icons.emergency,
                    size: 32,
                  ),
                  label: Text(
                    _isSosActive ? 'CEASE SOS BROADCAST' : 'TRANSMIT SOS BEACON',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSosActive
                        ? Colors.grey.shade800
                        : EmergixxTheme.emergencyRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
