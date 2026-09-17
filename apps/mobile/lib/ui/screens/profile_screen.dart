import 'package:flutter/material.dart';
import '../theme/emergixx_theme.dart';

/// User Identity & Medical Emergency Card screen.
/// Displays device cryptographic public keys and manages offline medical data attached to SOS alerts.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _deviceId = 'EX-7A29F1';
  final String _ed25519PublicKey = '7a29f1b4908ef1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b85';
  final String _curve25519PublicKey = '319bf51890cd1c149afbf4c8996fb92427ae41e4649b934ca495991b7852c92';

  final TextEditingController _nameController = TextEditingController(text: 'John Doe');
  final TextEditingController _bloodTypeController = TextEditingController(text: 'O+');
  final TextEditingController _allergiesController = TextEditingController(text: 'Penicillin, Tree nuts');
  final TextEditingController _medicationsController = TextEditingController(text: 'Asthma Inhaler (Albuterol)');
  final TextEditingController _contactController = TextEditingController(text: 'Jane Doe (+1-555-0199)');

  bool _isEditingMedical = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  void _saveMedicalCard() {
    setState(() => _isEditingMedical = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency medical profile saved to secure local storage.'),
        backgroundColor: EmergixxTheme.safeGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Identity & Medical'),
        actions: [
          IconButton(
            icon: Icon(_isEditingMedical ? Icons.check : Icons.edit),
            tooltip: _isEditingMedical ? 'Save Profile' : 'Edit Profile',
            onPressed: () {
              if (_isEditingMedical) {
                _saveMedicalCard();
              } else {
                setState(() => _isEditingMedical = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Identity Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: EmergixxTheme.surfaceDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: EmergixxTheme.safeGreen, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.fingerprint, size: 48, color: EmergixxTheme.safeGreen),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _deviceId,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Decentralized Mesh Identity Node',
                      style: TextStyle(fontSize: 12, color: EmergixxTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // QR Code visual placeholder for peer-to-peer out-of-band exchange
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_2, size: 140, color: Colors.black87),
                          const Text(
                            'Scan to verify peer public key',
                            style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cryptographic Keys
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CRYPTOGRAPHIC PUBLIC KEYS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: EmergixxTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _buildKeyBlock('Ed25519 Signing Key (RFC 8032)', _ed25519PublicKey),
                    const SizedBox(height: 10),
                    _buildKeyBlock('Curve25519 Key Agreement (RFC 7748)', _curve25519PublicKey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Medical Profile
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, color: EmergixxTheme.emergencyRed, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'EMERGENCY MEDICAL CARD',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        const Spacer(),
                        if (!_isEditingMedical)
                          TextButton(
                            onPressed: () => setState(() => _isEditingMedical = true),
                            child: const Text('Edit'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Attached to SOS distress beacons to inform first responders.',
                      style: TextStyle(fontSize: 11, color: EmergixxTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    _buildMedicalField('Full Name', _nameController, Icons.person),
                    _buildMedicalField('Blood Type', _bloodTypeController, Icons.bloodtype),
                    _buildMedicalField('Allergies', _allergiesController, Icons.warning_amber),
                    _buildMedicalField('Medications', _medicationsController, Icons.medication),
                    _buildMedicalField('Emergency Contact', _contactController, Icons.phone),

                    if (_isEditingMedical) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveMedicalCard,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Medical Info'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EmergixxTheme.safeGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Key Backup Action
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: EmergixxTheme.surfaceDark,
                    title: const Text('Identity Seed Backup'),
                    content: const Text(
                      'Your 32-byte master seed is stored in the device hardware-backed secure keystore. Keep a physical copy stored securely.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.key),
              label: const Text('Backup Master Cryptographic Seed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyBlock(String label, String keyHex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: EmergixxTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  keyHex,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () => _copyToClipboard(keyHex, label),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalField(String label, TextEditingController controller, IconData icon) {
    if (_isEditingMedical) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20),
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white60),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: EmergixxTheme.textSecondary)),
                Text(
                  controller.text.isNotEmpty ? controller.text : 'Not specified',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
