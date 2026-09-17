import 'package:flutter/material.dart';
import 'package:emergixx_models/emergixx_models.dart';
import '../theme/emergixx_theme.dart';
import '../widgets/message_bubble.dart';

/// One-to-one or group encrypted emergency peer chat screen.
/// Operates entirely over local mesh transports (BLE / Wi-Fi Direct) with store-and-forward routing.
class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  MessagePriority _selectedPriority = MessagePriority.normal;
  final String _myDeviceId = 'EX-7A29F1';
  final List<EmergixxMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  void _loadInitialMessages() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _messages.addAll([
      EmergixxMessage(
        messageId: 'msg-demo-1',
        senderDeviceId: widget.peerId,
        recipientDeviceId: _myDeviceId,
        messageType: MessageType.chat,
        timestamp: now - 3600000,
        createdAt: now - 3600000,
        expiresAt: now + 86400000,
        ttl: 10,
        hopCount: 2,
        priority: MessagePriority.normal,
        payload: 'Are you near the evacuation center? Power is out in Sector 4.',
        signature: 'sig_verified_ed25519',
        nonce: 'nonce-1',
        deliveryStatus: DeliveryStatus.delivered,
      ),
      EmergixxMessage(
        messageId: 'msg-demo-2',
        senderDeviceId: _myDeviceId,
        recipientDeviceId: widget.peerId,
        messageType: MessageType.chat,
        timestamp: now - 1800000,
        createdAt: now - 1800000,
        expiresAt: now + 86400000,
        ttl: 10,
        hopCount: 1,
        priority: MessagePriority.normal,
        payload: 'Yes, sheltering inside the gym. First aid team is set up here.',
        signature: 'sig_verified_ed25519',
        nonce: 'nonce-2',
        deliveryStatus: DeliveryStatus.delivered,
      ),
    ]);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage({bool isSos = false, String? customText}) {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final msg = EmergixxMessage(
      messageId: 'msg-$_myDeviceId-$now',
      senderDeviceId: _myDeviceId,
      recipientDeviceId: widget.peerId,
      messageType: isSos ? MessageType.sos : MessageType.chat,
      timestamp: now,
      createdAt: now,
      expiresAt: now + (48 * 3600 * 1000),
      ttl: 10,
      hopCount: 0,
      priority: isSos ? MessagePriority.critical : _selectedPriority,
      payload: text,
      signature: 'sig_ed25519_local',
      nonce: 'nonce-$now',
      deliveryStatus: DeliveryStatus.sent,
    );

    setState(() {
      _messages.add(msg);
      _textController.clear();
      _selectedPriority = MessagePriority.normal;
    });

    // Simulate multi-hop mesh delivery progression
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.messageId == msg.messageId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              deliveryStatus: DeliveryStatus.relayed,
              hopCount: 1,
            );
          }
        });
      }
    });

    _scrollToBottom();
  }

  void _attachLocation() {
    const coords = '📍 My GPS: 19.0760° N, 72.8777° E (Accuracy: ±6m)';
    _sendMessage(customText: coords);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.isGroup
                  ? Colors.blue.withOpacity(0.2)
                  : EmergixxTheme.surfaceCard,
              child: Icon(
                widget.isGroup ? Icons.groups : Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.isGroup
                        ? 'Mesh Group • 4 Members'
                        : 'ID: ${widget.peerId} • 1 Hop away',
                    style: const TextStyle(fontSize: 11, color: EmergixxTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: EmergixxTheme.safeGreen),
            tooltip: 'End-to-End Encryption Fingerprint',
            onPressed: _showEncryptionDetails,
          ),
        ],
      ),
      body: Column(
        children: [
          // Security Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: EmergixxTheme.surfaceDark,
            child: Row(
              children: [
                const Icon(Icons.lock, size: 14, color: EmergixxTheme.safeGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isGroup
                        ? '256-bit AES-GCM Encrypted Group • Mesh Store-and-Forward'
                        : 'Curve25519 AEAD • Verified Ed25519: ${widget.peerId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: EmergixxTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderDeviceId == _myDeviceId;
                return MessageBubble(message: message, isMe: isMe);
              },
            ),
          ),

          // Priority Indicator if elevated
          if (_selectedPriority != MessagePriority.normal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: _selectedPriority == MessagePriority.critical
                  ? EmergixxTheme.emergencyRedDark
                  : Colors.amber.shade900,
              child: Row(
                children: [
                  const Icon(Icons.priority_high, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Queue Priority: ${_selectedPriority.name.toUpperCase()} (Bypasses regular traffic)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () => setState(() => _selectedPriority = MessagePriority.normal),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: EmergixxTheme.surfaceDark,
              border: Border(top: BorderSide(color: EmergixxTheme.borderSubtle)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment options popup
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                    tooltip: 'Emergency Attachments',
                    onSelected: (val) {
                      if (val == 'location') _attachLocation();
                      if (val == 'priority_high') {
                        setState(() => _selectedPriority = MessagePriority.high);
                      }
                      if (val == 'priority_critical') {
                        setState(() => _selectedPriority = MessagePriority.critical);
                      }
                      if (val == 'emergency_sos') {
                        _sendMessage(isSos: true, customText: 'URGENT: Requesting immediate backup at my position!');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'location',
                        child: Row(
                          children: [
                            Icon(Icons.my_location, color: Colors.lightBlueAccent, size: 20),
                            SizedBox(width: 10),
                            Text('Attach GPS Location'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'priority_high',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.amber, size: 20),
                            SizedBox(width: 10),
                            Text('Set Priority: HIGH'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'priority_critical',
                        child: Row(
                          children: [
                            Icon(Icons.report, color: EmergixxTheme.emergencyRed, size: 20),
                            SizedBox(width: 10),
                            Text('Set Priority: CRITICAL'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'emergency_sos',
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.redAccent, size: 20),
                            SizedBox(width: 10),
                            Text('Quick SOS Alert'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Message Input Field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type mesh message...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: EmergixxTheme.surfaceCard,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  CircleAvatar(
                    backgroundColor: _selectedPriority == MessagePriority.critical
                        ? EmergixxTheme.emergencyRed
                        : EmergixxTheme.safeGreen,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEncryptionDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: EmergixxTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: EmergixxTheme.safeGreen),
                  SizedBox(width: 10),
                  Text(
                    'Cryptographic Identity Verification',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Every mesh packet in Emergixx is cryptographically signed and encrypted. Intermediate relays forward ciphertext packets without ever possessing private keys.',
                style: TextStyle(color: EmergixxTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildCryptoField('Peer Device ID', widget.peerId),
              _buildCryptoField('Key Agreement', 'Curve25519 ECDH (RFC 7748)'),
              _buildCryptoField('Authenticated Cipher', 'AES-256-GCM / HMAC-SHA256'),
              _buildCryptoField('Digital Signature', 'Ed25519 (RFC 8032)'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Verified Identity'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCryptoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
