import 'package:flutter/material.dart';
import 'package:emergixx_models/emergixx_models.dart';
import '../theme/emergixx_theme.dart';
import '../widgets/emergency_button.dart';

/// One-touch safety status check-in screen.
/// Allows disaster victims and field responders to rapidly declare safety status,
/// headcount, and location coordinates across the local mesh network.
class CheckinScreen extends StatefulWidget {
  final CheckInStatus? initialStatus;

  const CheckinScreen({super.key, this.initialStatus});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  late CheckInStatus _selectedStatus;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(text: 'John Doe');
  
  int _dependentsCount = 1;
  int _injuredCount = 0;
  String _targetScope = 'BROADCAST_ALL'; // or GROUP ID
  bool _includeGps = true;
  bool _isSubmitting = false;

  final List<CheckInRecord> _recentCheckIns = [
    CheckInRecord(
      checkinId: 'chk-prev-001',
      userId: 'EX-7A29F1',
      deviceId: 'EX-7A29F1',
      displayName: 'John Doe',
      status: CheckInStatus.safe,
      note: 'Reached civic center shelter. Safe and warm.',
      latitude: 19.0760,
      longitude: 72.8777,
      timestamp: DateTime.now().millisecondsSinceEpoch - 7200000,
      isSyncedToCloud: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? CheckInStatus.safe;
    if (_selectedStatus == CheckInStatus.safe) {
      _noteController.text = 'Safe and accounted for. No injuries.';
    } else if (_selectedStatus == CheckInStatus.needHelp) {
      _noteController.text = 'Need food, clean water, and power.';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _selectStatus(CheckInStatus status) {
    setState(() {
      _selectedStatus = status;
      if (status == CheckInStatus.safe && _noteController.text.isEmpty) {
        _noteController.text = 'Safe and accounted for. No injuries.';
      } else if (status == CheckInStatus.needHelp && _noteController.text.isEmpty) {
        _noteController.text = 'Need assistance and essential supplies.';
      } else if (status == CheckInStatus.moving && _noteController.text.isEmpty) {
        _noteController.text = 'Evacuating towards higher ground.';
      } else if (status == CheckInStatus.unableToMove && _noteController.text.isEmpty) {
        _noteController.text = 'Trapped/blocked by debris or flood water.';
      }
    });
  }

  void _submitCheckIn() {
    setState(() => _isSubmitting = true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final newCheckin = CheckInRecord(
      checkinId: 'chk-loc-$now',
      userId: 'EX-7A29F1',
      deviceId: 'EX-7A29F1',
      displayName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Anonymous',
      groupId: _targetScope == 'BROADCAST_ALL' ? null : _targetScope,
      status: _selectedStatus,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      latitude: _includeGps ? 19.0760 : null,
      longitude: _includeGps ? 72.8777 : null,
      timestamp: now,
      isSyncedToCloud: false,
    );

    setState(() {
      _recentCheckIns.insert(0, newCheckin);
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Check-in broadcast via mesh: ${_selectedStatus.toWire()}',
        ),
        backgroundColor: _getStatusColor(_selectedStatus),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Color _getStatusColor(CheckInStatus status) {
    switch (status) {
      case CheckInStatus.safe:
        return EmergixxTheme.safeGreen;
      case CheckInStatus.needHelp:
        return EmergixxTheme.warningAmber;
      case CheckInStatus.moving:
        return Colors.lightBlueAccent;
      case CheckInStatus.unableToMove:
        return EmergixxTheme.emergencyRed;
      case CheckInStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(CheckInStatus status) {
    switch (status) {
      case CheckInStatus.safe:
        return Icons.verified_user;
      case CheckInStatus.needHelp:
        return Icons.front_hand;
      case CheckInStatus.moving:
        return Icons.directions_walk;
      case CheckInStatus.unableToMove:
        return Icons.warning_amber_rounded;
      case CheckInStatus.unknown:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Check-In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SELECT CURRENT STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: EmergixxTheme.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Status Selector Grid
            _buildStatusTile(
              status: CheckInStatus.safe,
              title: 'I AM SAFE',
              subtitle: 'Unhurt, sheltered, not in immediate danger',
            ),
            const SizedBox(height: 10),
            _buildStatusTile(
              status: CheckInStatus.needHelp,
              title: 'NEED HELP',
              subtitle: 'Require non-critical food, water, power, or aid',
            ),
            const SizedBox(height: 10),
            _buildStatusTile(
              status: CheckInStatus.moving,
              title: 'MOVING / EVACUATING',
              subtitle: 'En route to evacuation point or higher ground',
            ),
            const SizedBox(height: 10),
            _buildStatusTile(
              status: CheckInStatus.unableToMove,
              title: 'UNABLE TO MOVE / TRAPPED',
              subtitle: 'Blocked by debris, water, or physical condition',
            ),
            const SizedBox(height: 24),

            // Headcount section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PARTY HEADCOUNT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: EmergixxTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total People in Group:'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _dependentsCount > 1
                                  ? () => setState(() => _dependentsCount--)
                                  : null,
                            ),
                            Text(
                              '$_dependentsCount',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _dependentsCount++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Injured / Medical Needs:'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _injuredCount > 0
                                  ? () => setState(() => _injuredCount--)
                                  : null,
                            ),
                            Text(
                              '$_injuredCount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _injuredCount > 0
                                    ? EmergixxTheme.emergencyRed
                                    : EmergixxTheme.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _injuredCount++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Target Audience & Location
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BROADCAST SCOPE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: EmergixxTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _targetScope,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.share_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'BROADCAST_ALL',
                          child: Text('All Nearby Mesh Peers & Responders'),
                        ),
                        DropdownMenuItem(
                          value: 'group-family',
                          child: Text('Family Circle Only (Encrypted)'),
                        ),
                        DropdownMenuItem(
                          value: 'group-rescue',
                          child: Text('Rescue Personnel Only'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _targetScope = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Attach Current GPS Location'),
                      subtitle: const Text('19.0760° N, 72.8777° E (± 6m)'),
                      value: _includeGps,
                      activeColor: EmergixxTheme.safeGreen,
                      onChanged: (val) => setState(() => _includeGps = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note & Presets
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Situation Note (Optional)',
                hintText: 'e.g., Safe in basement, battery at 50%, need food tomorrow',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // Quick Note Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip('Sheltering in place'),
                  const SizedBox(width: 8),
                  _buildPresetChip('Need clean water'),
                  const SizedBox(width: 8),
                  _buildPresetChip('Elderly present'),
                  const SizedBox(width: 8),
                  _buildPresetChip('Evacuating on foot'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            EmergencyButton(
              label: 'BROADCAST CHECK-IN',
              subtitle: 'Broadcasts authenticated status across local peers',
              icon: Icons.send_rounded,
              backgroundColor: _getStatusColor(_selectedStatus),
              isLoading: _isSubmitting,
              onPressed: _submitCheckIn,
            ),
            const SizedBox(height: 28),

            // Recent Check-ins Feed
            const Text(
              'RECENT LOCAL CHECK-INS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: EmergixxTheme.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentCheckIns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _recentCheckIns[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(item.status).withOpacity(0.2),
                      child: Icon(
                        _getStatusIcon(item.status),
                        color: _getStatusColor(item.status),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.displayName ?? item.deviceId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item.status.toWire(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _getStatusColor(item.status),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.note != null) ...[
                          const SizedBox(height: 4),
                          Text(item.note!),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              item.isSyncedToCloud ? Icons.cloud_done : Icons.cell_tower,
                              size: 14,
                              color: item.isSyncedToCloud ? Colors.green : Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.isSyncedToCloud ? 'Synced to Cloud' : 'Mesh Relayed',
                              style: const TextStyle(fontSize: 11, color: Colors.white54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTile({
    required CheckInStatus status,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedStatus == status;
    final color = _getStatusColor(status);

    return InkWell(
      onTap: () => _selectStatus(status),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : EmergixxTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: BorderSide(
            color: isSelected ? color : EmergixxTheme.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(_getStatusIcon(status), color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : EmergixxTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EmergixxTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: EmergixxTheme.surfaceDark,
      onPressed: () {
        setState(() {
          if (_noteController.text.isNotEmpty) {
            _noteController.text += ' • $text';
          } else {
            _noteController.text = text;
          }
        });
      },
    );
  }
}
