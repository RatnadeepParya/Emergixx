import 'package:flutter/material.dart';
import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_shared/emergixx_shared.dart';
import '../theme/emergixx_theme.dart';
import '../widgets/network_badge.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/emergency_button.dart';
import 'emergency_mode_screen.dart';
import 'sos_broadcast_screen.dart';
import 'checkin_screen.dart';
import 'messages_screen.dart';
import 'groups_screen.dart';
import 'nearby_devices_screen.dart';
import 'map_screen.dart';
import 'diagnostics_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Primary Emergency Hub exposing prominent life-safety controls and real-time mesh status.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NetworkState _networkState = NetworkState.meshOnly;
  BatteryProfile _batteryProfile = BatteryProfile.fromLevel(64);
  int _nearbyDevicesCount = 3;
  String _myDeviceId = 'EX-7A29F1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EMERGixx • $_myDeviceId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Mesh Diagnostics',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Device Identity & Medical',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // System Status Bar (Network & Battery)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NetworkBadge(
                    state: _networkState,
                    peerCount: _nearbyDevicesCount,
                  ),
                  BatteryIndicator(profile: _batteryProfile),
                ],
              ),
              const SizedBox(height: 12),

              // Network Status Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EmergixxTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: BorderSide(color: EmergixxTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _networkState.userMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: EmergixxTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Primary Life-Safety Action: SEND SOS
              EmergencyButton(
                label: 'SEND SOS',
                subtitle: 'Broadcast emergency distress beacon with GPS & Medical info',
                icon: Icons.emergency,
                backgroundColor: EmergixxTheme.emergencyRed,
                isPrimary: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SosBroadcastScreen()),
                ),
              ),
              const SizedBox(height: 16),

              // Secondary Life-Safety Action: NEED HELP
              EmergencyButton(
                label: 'NEED HELP',
                subtitle: 'Request non-critical assistance, food, shelter, or supplies',
                icon: Icons.front_hand,
                backgroundColor: EmergixxTheme.warningAmber,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CheckinScreen(
                      initialStatus: CheckInStatus.needHelp,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tertiary Action: I'M SAFE
              EmergencyButton(
                label: "I'M SAFE",
                subtitle: 'Notify family and rescue teams that you are safe & unhurt',
                icon: Icons.verified_user,
                backgroundColor: EmergixxTheme.safeGreen,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CheckinScreen(
                      initialStatus: CheckInStatus.safe,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // High-Contrast Emergency Mode Trigger
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyModeScreen()),
                ),
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                label: const Text('ACTIVATE HIGH-STRESS EMERGENCY MODE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: EmergixxTheme.emergencyRedDark,
                  side: const BorderSide(color: EmergixxTheme.emergencyRed, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Operations Navigation Grid
              const Text(
                'FIELD OPERATIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: EmergixxTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNavCard(
                    title: 'P2P Messages',
                    subtitle: 'E2EE Mesh Chat',
                    icon: Icons.chat_bubble_outline,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MessagesScreen()),
                    ),
                  ),
                  _buildNavCard(
                    title: 'Nearby Peers',
                    subtitle: '$_nearbyDevicesCount in range',
                    icon: Icons.radar,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NearbyDevicesScreen()),
                    ),
                  ),
                  _buildNavCard(
                    title: 'Offline Map',
                    subtitle: 'Local Shelters & GPS',
                    icon: Icons.map_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    ),
                  ),
                  _buildNavCard(
                    title: 'Family Groups',
                    subtitle: 'Coordination',
                    icon: Icons.group_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GroupsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.blueAccent),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: EmergixxTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: EmergixxTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
