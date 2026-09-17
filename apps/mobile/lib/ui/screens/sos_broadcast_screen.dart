import 'package:flutter/material.dart';
import 'package:emergixx_models/emergixx_models.dart';
import '../theme/emergixx_theme.dart';

/// Interactive SOS Broadcast screen for tailoring life-safety alerts and tracking mesh relay progress.
class SosBroadcastScreen extends StatefulWidget {
  const SosBroadcastScreen({super.key});

  @override
  State<SosBroadcastScreen> createState() => _SosBroadcastScreenState();
}

class _SosBroadcastScreenState extends State<SosBroadcastScreen> {
  String _selectedType = 'TRAPPED';
  final TextEditingController _noteController = TextEditingController(
    text: 'Trapped inside building. Need medical assistance.',
  );
  final TextEditingController _medicalController = TextEditingController(
    text: 'Blood Type: O+ | Asthma inhaler needed',
  );

  bool _isBroadcasting = false;
  int _relayedHops = 3;
  String _responderAck = 'Rescue Unit 04 (Acknowledged 4 mins ago)';

  final List<String> _types = [
    'TRAPPED',
    'MEDICAL',
    'FLOOD',
    'FIRE',
    'EVACUATE',
    'GENERAL',
  ];

  void _submitSos() {
    setState(() {
      _isBroadcasting = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS Broadcast active! Propagating through mesh network.'),
        backgroundColor: EmergixxTheme.emergencyRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Emergency SOS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live Status Banner if broadcasting
            if (_isBroadcasting) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EmergixxTheme.emergencyRedDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EmergixxTheme.emergencyRed, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.radar, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'RELAYING ACROSS MESH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hop Count: $_relayedHops hops | Responder: $_responderAck',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Emergency Category Chips
            const Text(
              'EMERGENCY CATEGORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: EmergixxTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: EmergixxTheme.emergencyRed,
                  backgroundColor: EmergixxTheme.surfaceDark,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : EmergixxTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Distress Note Field
            const Text(
              'DISTRESS DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: EmergixxTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: EmergixxTheme.surfaceDark,
                hintText: 'Describe your emergency and immediate danger...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: EmergixxTheme.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Medical Information Field
            const Text(
              'CRITICAL MEDICAL INFO (OPTIONAL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: EmergixxTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _medicalController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: EmergixxTheme.surfaceDark,
                hintText: 'Allergies, chronic conditions, blood type...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: EmergixxTheme.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location Snapshot Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EmergixxTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: BorderSide(color: EmergixxTheme.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.my_location, color: Colors.blueAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COORDINATES TO BE BROADCAST:',
                          style: TextStyle(
                            fontSize: 11,
                            color: EmergixxTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '19.0760° N, 72.8777° E (Accuracy: ±4.2m)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Broadcast Trigger Button
            ElevatedButton.icon(
              onPressed: _submitSos,
              icon: const Icon(Icons.send_rounded),
              label: Text(_isBroadcasting ? 'UPDATE ACTIVE SOS' : 'BROADCAST SOS NOW'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EmergixxTheme.emergencyRed,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
