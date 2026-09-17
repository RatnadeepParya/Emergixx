import 'package:flutter/material.dart';
import '../theme/emergixx_theme.dart';
import 'chat_screen.dart';

/// Conversations screen listing active peer-to-peer, group, and broadcast channels.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<Map<String, dynamic>> _threads = [
    {
      'id': 'EX-9D42A1',
      'name': 'Rescue Team Alpha',
      'lastMessage': 'Unit 2 en route to sector 4 with water and blankets.',
      'time': '10:42 AM',
      'unread': 2,
      'isGroup': true,
      'isSos': false,
      'status': 'relayed',
    },
    {
      'id': 'EX-3B91C4',
      'name': 'Sarah Connor',
      'lastMessage': 'Are you near the evacuation center? Power is out in Sector 4.',
      'time': '10:15 AM',
      'unread': 0,
      'isGroup': false,
      'isSos': false,
      'status': 'delivered',
    },
    {
      'id': 'EX-F108C7',
      'name': 'David Miller',
      'lastMessage': 'Need medical assistance at 19.0760, 72.8777! Inhaler needed.',
      'time': '09:50 AM',
      'unread': 1,
      'isGroup': false,
      'isSos': true,
      'status': 'relayed',
    },
    {
      'id': 'BROADCAST_ALL',
      'name': 'Disaster Mesh Broadcast',
      'lastMessage': 'City alert: River cresting at 14:00. Move to designated high ground.',
      'time': '08:30 AM',
      'unread': 0,
      'isGroup': true,
      'isSos': false,
      'status': 'delivered',
    },
  ];

  void _openChat(Map<String, dynamic> thread) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          peerId: thread['id'] as String,
          peerName: thread['name'] as String,
          isGroup: thread['isGroup'] as bool,
        ),
      ),
    );
  }

  void _startNewConversation() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmergixxTheme.surfaceDark,
        title: const Text('Start Peer Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the destination device ID (e.g. EX-A1B2C3):',
              style: TextStyle(color: EmergixxTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'EX-XXXXXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fingerprint),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = textController.text.trim().toUpperCase();
              if (id.isNotEmpty) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      peerId: id,
                      peerName: 'Device $id',
                      isGroup: false,
                    ),
                  ),
                );
              }
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Mesh Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: _threads.isEmpty
          ? const Center(
              child: Text(
                'No active conversations.\nStart a chat with a nearby peer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EmergixxTheme.textSecondary),
              ),
            )
          : ListView.separated(
              itemCount: _threads.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: EmergixxTheme.borderSubtle),
              itemBuilder: (context, index) {
                final item = _threads[index];
                final isGroup = item['isGroup'] as bool;
                final isSos = item['isSos'] as bool;
                final unread = item['unread'] as int;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => _openChat(item),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isSos
                            ? EmergixxTheme.emergencyRedDark
                            : (isGroup ? Colors.indigo.shade800 : EmergixxTheme.surfaceCard),
                        child: Icon(
                          isSos
                              ? Icons.warning
                              : (isGroup ? Icons.groups : Icons.person),
                          color: isSos ? Colors.amber : Colors.white,
                        ),
                      ),
                      if (item['status'] == 'delivered')
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: EmergixxTheme.safeGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['name'] as String,
                          style: TextStyle(
                            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                            color: isSos ? EmergixxTheme.emergencyRed : EmergixxTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        item['time'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: unread > 0 ? EmergixxTheme.safeGreen : EmergixxTheme.textSecondary,
                          fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item['lastMessage'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unread > 0 ? Colors.white : EmergixxTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: EmergixxTheme.emergencyRed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewConversation,
        icon: const Icon(Icons.edit),
        label: const Text('New Message'),
        backgroundColor: EmergixxTheme.safeGreen,
      ),
    );
  }
}
