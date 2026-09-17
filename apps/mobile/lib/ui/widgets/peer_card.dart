import 'package:flutter/material.dart';
import 'package:emergixx_models/emergixx_models.dart';
import '../theme/emergixx_theme.dart';

/// Card representing a nearby discovered peer node in the local mesh.
class PeerCard extends StatelessWidget {
  final Peer peer;
  final VoidCallback? onConnect;
  final ValueChanged<TrustState>? onTrustChanged;

  const PeerCard({
    super.key,
    required this.peer,
    this.onConnect,
    this.onTrustChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color trustColor;
    switch (peer.trustState) {
      case TrustState.trusted:
        trustColor = EmergixxTheme.safeGreen;
        break;
      case TrustState.known:
        trustColor = const Color(0xFF1E88E5);
        break;
      case TrustState.blocked:
        trustColor = EmergixxTheme.emergencyRed;
        break;
      case TrustState.unknown:
        trustColor = EmergixxTheme.textSecondary;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EmergixxTheme.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: trustColor, width: 1.5),
              ),
              child: Icon(
                peer.transport == TransportType.bluetooth
                    ? Icons.bluetooth
                    : Icons.wifi,
                color: trustColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        peer.ephemeralId,
                        style: const TextStyle(
                          color: EmergixxTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: trustColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          peer.trustState.name.toUpperCase(),
                          style: TextStyle(
                            color: trustColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Signal: ${peer.rssi} dBm | Transports: ${peer.transport.toWire().toUpperCase()}',
                    style: const TextStyle(
                      color: EmergixxTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: EmergixxTheme.textPrimary),
              onPressed: onConnect,
              tooltip: 'Send Direct Message',
            ),
          ],
        ),
      ),
    );
  }
}
