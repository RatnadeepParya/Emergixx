import 'package:flutter/material.dart';
import '../theme/emergixx_theme.dart';

/// Application configuration, radio transport control, and privacy/retention management.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _adaptiveBattery = true;
  bool _emergencyLowPower = false;
  bool _bleTransportEnabled = true;
  bool _wifiDirectEnabled = true;
  bool _backgroundRelayEnabled = true;
  String _retentionPeriod = '48h';
  double _offlineMapCacheMb = 18.2;

  void _clearCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmergixxTheme.surfaceDark,
        title: const Text('Clear Mesh Transit Cache?'),
        content: const Text(
          'This will purge all queued store-and-forward transit packets and deduplication logs. Locally delivered messages and SOS records will not be deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transit cache purged successfully.'),
                  backgroundColor: EmergixxTheme.safeGreen,
                ),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _resetIdentity() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmergixxTheme.surfaceDark,
        title: const Text('Reset Cryptographic Identity?'),
        content: const Text(
          'WARNING: This will generate a new Ed25519/Curve25519 key pair and change your EX-XXXXXX device ID. Existing peers will need to re-verify you.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EmergixxTheme.emergencyRed),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New cryptographic identity generated.'),
                  backgroundColor: EmergixxTheme.emergencyRed,
                ),
              );
            },
            child: const Text('Reset Identity'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Mesh Controls'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Battery & Duty Cycle
          _buildSectionHeader('BATTERY & ADAPTIVE DUTY-CYCLE'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Adaptive Battery Throttling'),
                  subtitle: const Text('Dynamically throttles radio duty-cycle as battery drains'),
                  value: _adaptiveBattery,
                  activeColor: EmergixxTheme.safeGreen,
                  onChanged: (v) => setState(() => _adaptiveBattery = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Force Ultra-Low Power Mode'),
                  subtitle: const Text('Locks BLE scan window to 100ms / 5000ms interval'),
                  value: _emergencyLowPower,
                  activeColor: Colors.amber,
                  onChanged: (v) => setState(() => _emergencyLowPower = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Physical Mesh Transports
          _buildSectionHeader('PHYSICAL RADIO TRANSPORTS'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Bluetooth LE (GATT) Mesh'),
                  subtitle: const Text('Short-range, ultra-low-energy local peer discovery'),
                  value: _bleTransportEnabled,
                  activeColor: EmergixxTheme.safeGreen,
                  onChanged: (v) => setState(() => _bleTransportEnabled = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Wi-Fi Direct / P2P Multicast'),
                  subtitle: const Text('High-throughput peer transfers for clusters'),
                  value: _wifiDirectEnabled,
                  activeColor: EmergixxTheme.safeGreen,
                  onChanged: (v) => setState(() => _wifiDirectEnabled = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Background Store-and-Forward Relay'),
                  subtitle: const Text('Allows device to relay encrypted traffic for neighbors while sleeping'),
                  value: _backgroundRelayEnabled,
                  activeColor: EmergixxTheme.safeGreen,
                  onChanged: (v) => setState(() => _backgroundRelayEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Offline Storage & Data Retention
          _buildSectionHeader('STORAGE & DATA RETENTION'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Message Retention Window'),
                  subtitle: const Text('Auto-prune delivered peer messages older than:'),
                  trailing: DropdownButton<String>(
                    value: _retentionPeriod,
                    dropdownColor: EmergixxTheme.surfaceDark,
                    items: const [
                      DropdownMenuItem(value: '24h', child: Text('24 Hours')),
                      DropdownMenuItem(value: '48h', child: Text('48 Hours')),
                      DropdownMenuItem(value: '7d', child: Text('7 Days')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _retentionPeriod = v);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Offline Map Pack Cache'),
                  subtitle: Text('Sector 4 Regional Tile Pack (${_offlineMapCacheMb.toStringAsFixed(1)} MB)'),
                  trailing: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Offline map pack up to date')),
                      );
                    },
                    child: const Text('Update'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Purge Transit Cache'),
                  subtitle: const Text('Flushes message deduplication index and relay queues'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.orangeAccent),
                    onPressed: _clearCache,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Security & Cryptography
          _buildSectionHeader('SECURITY & PROTOCOL'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.verified, color: EmergixxTheme.safeGreen),
                  title: Text('Emergixx Protocol Version'),
                  subtitle: Text('EMERGIXX/1 • Binary Frame Codec v1.0'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.security, color: Colors.blueAccent),
                  title: Text('Cryptographic Ciphers'),
                  subtitle: Text('Ed25519 • Curve25519 • AES-256-GCM • SHA-256'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: EmergixxTheme.emergencyRed),
                  title: const Text('Reset Cryptographic Identity', style: TextStyle(color: EmergixxTheme.emergencyRed)),
                  subtitle: const Text('Generates new keys and identity seed'),
                  onTap: _resetIdentity,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Footer
          const Center(
            child: Text(
              'Emergixx v1.0.0+1 (Field Tested)\nOffline-First Decentralized Emergency Platform',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: EmergixxTheme.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
