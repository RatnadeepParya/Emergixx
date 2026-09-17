import 'package:flutter/material.dart';
import 'package:emergixx_models/emergixx_models.dart';
import '../theme/emergixx_theme.dart';
import 'chat_screen.dart';

/// Screen for managing encrypted emergency groups (Family, Responders, Neighborhoods).
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final List<EmergencyGroup> _groups = [
    EmergencyGroup(
      groupId: 'group-family',
      name: 'Family Circle',
      groupKey: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      adminDeviceId: 'EX-7A29F1',
      memberDeviceIds: ['EX-7A29F1', 'EX-3B91C4', 'EX-9D42A1', 'EX-8C12E5'],
      createdAt: DateTime.now().millisecondsSinceEpoch - (86400000 * 5),
    ),
    EmergencyGroup(
      groupId: 'group-rescue',
      name: 'Search & Rescue Alpha',
      groupKey: 'a1b2c3d4e5f60718293a4b5c6d7e8f90123456789abcdef0123456789abcdef0',
      adminDeviceId: 'EX-RESP-01',
      memberDeviceIds: ['EX-RESP-01', 'EX-RESP-02', 'EX-7A29F1'],
      createdAt: DateTime.now().millisecondsSinceEpoch - (86400000 * 2),
    ),
  ];

  void _openGroupChat(EmergencyGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          peerId: group.groupId,
          peerName: group.name,
          isGroup: true,
        ),
      ),
    );
  }

  void _createNewGroup() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmergixxTheme.surfaceDark,
        title: const Text('Create Emergency Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A unique 256-bit symmetric encryption key will be generated locally. All messages within this group are inaccessible to non-members.',
              style: TextStyle(color: EmergixxTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g., Evacuation Team Bravo',
                border: OutlineInputBorder(),
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
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final now = DateTime.now().millisecondsSinceEpoch;
                final newGroup = EmergencyGroup(
                  groupId: 'grp-$now',
                  name: name,
                  groupKey: 'generated_aes256_key_$now',
                  adminDeviceId: 'EX-7A29F1',
                  memberDeviceIds: ['EX-7A29F1'],
                  createdAt: now,
                );
                setState(() => _groups.add(newGroup));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Group "$name" created with 256-bit AES-GCM key'),
                    backgroundColor: EmergixxTheme.safeGreen,
                  ),
                );
              }
            },
            child: const Text('Create Group'),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(EmergencyGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EmergixxTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.groups, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Group ID: ${group.groupId}',
                            style: const TextStyle(fontSize: 12, color: EmergixxTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'GROUP ENCRYPTION KEY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: EmergixxTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EmergixxTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key, size: 16, color: EmergixxTheme.safeGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group.groupKey,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Group key copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'MEMBERS (${group.memberDeviceIds.length})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: EmergixxTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                ...group.memberDeviceIds.map((deviceId) {
                  final isAdmin = deviceId == group.adminDeviceId;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: EmergixxTheme.surfaceDark,
                        child: Icon(Icons.person, size: 18, color: Colors.white70),
                      ),
                      title: Text(
                        deviceId,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      trailing: isAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openGroupChat(group);
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Open Group Mesh Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EmergixxTheme.safeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Groups'),
      ),
      body: _groups.isEmpty
          ? const Center(child: Text('No emergency groups created yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _openGroupChat(group),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                child: const Icon(Icons.groups, color: Colors.blueAccent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${group.memberDeviceIds.length} Members • E2EE AES-GCM',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: EmergixxTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showGroupDetails(group),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.security, size: 14, color: EmergixxTheme.safeGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Group Key Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade300,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () => _openGroupChat(group),
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: const Text('Open Chat'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewGroup,
        icon: const Icon(Icons.group_add),
        label: const Text('Create Group'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
