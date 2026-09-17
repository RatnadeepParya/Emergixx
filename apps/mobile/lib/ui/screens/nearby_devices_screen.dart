import 'package:flutter/material.dart';
import 'package:emergixx_models/emergixx_models.dart';
import '../theme/emergixx_theme.dart';
import '../widgets/peer_card.dart';
import 'chat_screen.dart';

/// Screen listing all discovered peer nodes in the physical vicinity.
/// Manages peer trust states, signal metrics, and direct mesh communication.
class NearbyDevicesScreen extends StatefulWidget {
  const NearbyDevicesScreen({super.key});

  @override
  State<NearbyDevicesScreen> createState() => _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends State<NearbyDevicesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isScanning = true;
  String _filter = 'ALL'; // ALL, BLE, WIFI, TRUSTED

  final List<Peer> _peers = [
    Peer(
      deviceId: 'EX-3B91C4',
      ephemeralId: 'EX-3B91C4',
      publicKey: '3b91c4d92a831e649afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      transport: TransportType.bluetooth,
      lastSeen: DateTime.now().millisecondsSinceEpoch - 12000,
      rssi: -58,
      trustState: TrustState.trusted,
    ),
    Peer(
      deviceId: 'EX-9D42A1',
      ephemeralId: 'EX-9D42A1',
      publicKey: '9d42a18412fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      transport: TransportType.wifiDirect,
      lastSeen: DateTime.now().millisecondsSinceEpoch - 45000,
      rssi: -72,
      trustState: TrustState.known,
    ),
    Peer(
      deviceId: 'EX-F108C7',
      ephemeralId: 'EX-F108C7',
      publicKey: 'f108c792348fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      transport: TransportType.bluetooth,
      lastSeen: DateTime.now().millisecondsSinceEpoch - 90000,
      rssi: -84,
      trustState: TrustState.unknown,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    });
  }

  void _changeTrust(Peer peer, TrustState newState) {
    setState(() {
      final idx = _peers.indexWhere((p) => p.deviceId == peer.deviceId);
      if (idx != -1) {
        _peers[idx] = _peers[idx].copyWith(trustState: newState);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated ${peer.ephemeralId} trust: ${newState.name.toUpperCase()}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _connectToPeer(Peer peer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          peerId: peer.deviceId,
          peerName: 'Device ${peer.ephemeralId}',
          isGroup: false,
        ),
      ),
    );
  }

  List<Peer> get _filteredPeers {
    if (_filter == 'BLE') {
      return _peers.where((p) => p.transport == TransportType.bluetooth).toList();
    } else if (_filter == 'WIFI') {
      return _peers.where((p) => p.transport == TransportType.wifiDirect).toList();
    } else if (_filter == 'TRUSTED') {
      return _peers.where((p) => p.trustState == TrustState.trusted).toList();
    }
    return _peers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Mesh Peers'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop_circle_outlined : Icons.play_circle_outline),
            tooltip: _isScanning ? 'Pause Discovery' : 'Resume Discovery',
            onPressed: _toggleScanning,
          ),
        ],
      ),
      body: Column(
        children: [
          // Radar Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: EmergixxTheme.surfaceDark,
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isScanning
                            ? EmergixxTheme.safeGreen.withOpacity(0.2 + (_pulseController.value * 0.3))
                            : Colors.grey.withOpacity(0.2),
                      ),
                      child: Icon(
                        Icons.radar,
                        color: _isScanning ? EmergixxTheme.safeGreen : Colors.grey,
                        size: 28,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isScanning ? 'P2P SCANNING ACTIVE' : 'SCANNING PAUSED',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _isScanning ? EmergixxTheme.safeGreen : Colors.grey,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_peers.length} devices in physical radio range. Relaying encrypted traffic.',
                        style: const TextStyle(fontSize: 12, color: EmergixxTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All (${_peers.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('BLE', 'BLE GATT'),
                const SizedBox(width: 8),
                _buildFilterChip('WIFI', 'Wi-Fi Direct'),
                const SizedBox(width: 8),
                _buildFilterChip('TRUSTED', 'Trusted Only'),
              ],
            ),
          ),

          // Discovered Peers List
          Expanded(
            child: _filteredPeers.isEmpty
                ? const Center(
                    child: Text(
                      'No peers found matching filter.\nKeep Bluetooth & Wi-Fi enabled.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: EmergixxTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPeers.length,
                    itemBuilder: (context, index) {
                      final peer = _filteredPeers[index];
                      return PeerCard(
                        peer: peer,
                        onConnect: () => _connectToPeer(peer),
                        onTrustChanged: (trust) => _changeTrust(peer, trust),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: Colors.blueAccent.withOpacity(0.3),
      backgroundColor: EmergixxTheme.surfaceDark,
      onSelected: (_) => setState(() => _filter = key),
    );
  }
}
