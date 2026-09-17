import 'package:flutter/material.dart';
import 'package:emergixx_shared/emergixx_shared.dart';
import '../theme/emergixx_theme.dart';

/// Clean battery gauge displaying percentage and adaptive power mode.
class BatteryIndicator extends StatelessWidget {
  final BatteryProfile profile;

  const BatteryIndicator({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    Color statusColor = EmergixxTheme.safeGreen;
    IconData icon = Icons.battery_full;

    if (profile.batteryLevel < 10) {
      statusColor = EmergixxTheme.emergencyRed;
      icon = Icons.battery_alert;
    } else if (profile.batteryLevel < 20) {
      statusColor = EmergixxTheme.warningAmber;
      icon = Icons.battery_2_bar;
    } else if (profile.batteryLevel < 50) {
      statusColor = const Color(0xFFFBC02D);
      icon = Icons.battery_4_bar;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: EmergixxTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: BorderSide(color: EmergixxTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: statusColor),
          const SizedBox(width: 6),
          Text(
            '${profile.batteryLevel}%',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            profile.mode.name.toUpperCase(),
            style: TextStyle(
              color: EmergixxTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
