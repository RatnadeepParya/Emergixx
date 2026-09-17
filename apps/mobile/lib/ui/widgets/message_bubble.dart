import 'package:flutter/material.dart';
import 'package:emergixx_models/emergixx_models.dart';
import '../theme/emergixx_theme.dart';

/// Chat bubble displaying encrypted message state, hop count, and delivery status.
class MessageBubble extends StatelessWidget {
  final EmergixxMessage message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isSos = message.messageType == MessageType.sos;
    final isBroadcast = message.isBroadcast;

    Color bubbleColor = isMe
        ? (isSos ? EmergixxTheme.emergencyRedDark : const Color(0xFF1E88E5))
        : (isSos ? EmergixxTheme.emergencyRedDark : EmergixxTheme.surfaceCard);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: isSos
              ? Border.all(color: EmergixxTheme.emergencyRed, width: 2)
              : Border.all(color: EmergixxTheme.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSos ? Icons.warning : Icons.lock,
                  size: 14,
                  color: isSos ? Colors.amber : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  isSos
                      ? 'EMERGENCY SOS'
                      : (isBroadcast ? 'BROADCAST' : 'END-TO-END ENCRYPTED'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSos ? Colors.amber : Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${message.hopCount} HOPS',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.payload,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateTime.fromMillisecondsSinceEpoch(message.timestamp)
                      .toLocal()
                      .toString()
                      .substring(11, 16),
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Icon(
                    message.deliveryStatus == DeliveryStatus.delivered
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
