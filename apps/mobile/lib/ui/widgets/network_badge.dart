import 'package:flutter/material.dart';
import 'package:emergixx_shared/emergixx_shared.dart';
import '../theme/emergixx_theme.dart';

/// Prominent, high-contrast network status pill indicator.
class NetworkBadge extends StatelessWidget {
  final NetworkState state;
  final int peerCount;

  const NetworkBadge({
    super.key,
    required this.state,
    this.peerCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData icon;
    String label;

    switch (state) {
      case NetworkState.online:
        badgeColor = EmergixxTheme.safeGreen;
        icon = Icons.cloud_done;
        label = 'ONLINE';
        break;
      case NetworkState.meshOnly:
        badgeColor = const Color(0xFF1E88E5); // Mesh Blue
        icon = Icons.hub;
        label = 'MESH ONLY ($peerCount PEERS)';
        break;
      case NetworkState.connecting:
        badgeColor = EmergixxTheme.warningAmber;
        icon = Icons.sync;
        label = 'CONNECTING...';
        break;
      case NetworkState.syncing:
        badgeColor = const Color(0xFF8E24AA); // Purple sync
        icon = Icons.cloud_upload;
        label = 'SYNCING TO CLOUD';
        break;
      case NetworkState.offline:
        badgeColor = EmergixxTheme.borderSubtle;
        icon = Icons.cloud_off;
        label = 'OFFLINE (NO PEERS)';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: BorderSide(color: badgeColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
