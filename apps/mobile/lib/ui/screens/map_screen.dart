import 'package:flutter/material.dart';
import 'package:emergixx_models/emergixx_models.dart';
import '../theme/emergixx_theme.dart';
import 'chat_screen.dart';

/// Offline tactical emergency map viewer.
/// Renders cached offline GIS data, emergency pins, SOS beacons, and GPS breadcrumbs
/// without requiring active internet or cellular connectivity.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _breadcrumbsEnabled = true;
  String _selectedLayer = 'ALL'; // ALL, SOS, SHELTERS, CHECKINS
  Map<String, dynamic>? _selectedMarker;

  final List<Map<String, dynamic>> _markers = [
    {
      'id': 'my_loc',
      'title': 'My Location (You)',
      'type': 'SELF',
      'lat': 19.0760,
      'lng': 72.8777,
      'details': 'GPS Accuracy: ±6m • Battery: 64%',
      'color': Colors.lightBlueAccent,
      'icon': Icons.my_location,
    },
    {
      'id': 'sos_01',
      'title': 'SOS: Trapped in Stairwell',
      'type': 'SOS',
      'deviceId': 'EX-F108C7',
      'lat': 19.0792,
      'lng': 72.8810,
      'details': 'Building 4B • Inhaler needed • 2 People',
      'color': EmergixxTheme.emergencyRed,
      'icon': Icons.warning_amber_rounded,
    },
    {
      'id': 'shelter_01',
      'title': 'Civic Community Shelter',
      'type': 'SHELTER',
      'lat': 19.0735,
      'lng': 72.8720,
      'details': 'Water, food, generator power available. Capacity: 350',
      'color': Colors.tealAccent,
      'icon': Icons.night_shelter,
    },
    {
      'id': 'chk_01',
      'title': 'Safe Check-in: Sarah C.',
      'type': 'CHECKIN',
      'deviceId': 'EX-3B91C4',
      'lat': 19.0748,
      'lng': 72.8835,
      'details': 'Status: SAFE • Group: Family Circle',
      'color': EmergixxTheme.safeGreen,
      'icon': Icons.verified_user,
    },
    {
      'id': 'chk_02',
      'title': 'Need Help: Evacuating',
      'type': 'CHECKIN',
      'deviceId': 'EX-9D42A1',
      'lat': 19.0815,
      'lng': 72.8750,
      'details': 'Status: NEED HELP • Low vehicle fuel',
      'color': EmergixxTheme.warningAmber,
      'icon': Icons.front_hand,
    },
  ];

  List<Map<String, dynamic>> get _filteredMarkers {
    if (_selectedLayer == 'ALL') return _markers;
    return _markers.where((m) => m['type'] == _selectedLayer || m['type'] == 'SELF').toList();
  }

  void _onMarkerTap(Map<String, dynamic> marker) {
    setState(() {
      _selectedMarker = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Emergency Map'),
        actions: [
          IconButton(
            icon: Icon(_breadcrumbsEnabled ? Icons.timeline : Icons.timeline_outlined),
            tooltip: _breadcrumbsEnabled ? 'Breadcrumbs ON' : 'Breadcrumbs OFF',
            onPressed: () {
              setState(() => _breadcrumbsEnabled = !_breadcrumbsEnabled);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_breadcrumbsEnabled
                      ? 'GPS Breadcrumb trail tracking activated'
                      : 'Breadcrumb trail paused'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Tactical Offline Vector Grid & Map Canvas
          GestureDetector(
            onTap: () => setState(() => _selectedMarker = null),
            child: Container(
              color: const Color(0xFF0C131D),
              child: CustomPaint(
                painter: _TacticalMapPainter(
                  markers: _filteredMarkers,
                  selectedId: _selectedMarker?['id'],
                  showBreadcrumbs: _breadcrumbsEnabled,
                ),
                child: Stack(
                  children: _filteredMarkers.map((m) {
                    // Normalize lat/lng to screen percentages for tactical visualization
                    // Center is 19.0760, 72.8777
                    final dx = 0.5 + ((m['lng'] - 72.8777) * 45);
                    final dy = 0.5 - ((m['lat'] - 19.0760) * 45);

                    return Align(
                      alignment: FractionalOffset(
                        dx.clamp(0.08, 0.92),
                        dy.clamp(0.08, 0.92),
                      ),
                      child: GestureDetector(
                        onTap: () => _onMarkerTap(m),
                        child: _buildMapPin(m),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Offline Status & GPS Coordinates Header
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: EmergixxTheme.surfaceDark.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: BorderSide(color: EmergixxTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.offline_pin, size: 16, color: EmergixxTheme.safeGreen),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'OFFLINE MAP PACK: SECTOR 4 (18.2 MB CACHED)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Text(
                    '19.0760, 72.8777',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.blue.shade200,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Layer Filters Bar
          Positioned(
            top: 66,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLayerChip('ALL', 'All Layers'),
                  const SizedBox(width: 6),
                  _buildLayerChip('SOS', 'SOS Alerts'),
                  const SizedBox(width: 6),
                  _buildLayerChip('SHELTER', 'Shelters'),
                  const SizedBox(width: 6),
                  _buildLayerChip('CHECKIN', 'Check-ins'),
                ],
              ),
            ),
          ),

          // Selected Marker Detail Drawer / Sheet
          if (_selectedMarker != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Card(
                color: EmergixxTheme.surfaceDark,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _selectedMarker!['color'] as Color,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selectedMarker!['icon'] as IconData,
                            color: _selectedMarker!['color'] as Color,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedMarker!['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Coordinates: ${_selectedMarker!['lat']}, ${_selectedMarker!['lng']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _selectedMarker = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedMarker!['details'] as String,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (_selectedMarker!['deviceId'] != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final devId = _selectedMarker!['deviceId'] as String;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        peerId: devId,
                                        peerName: 'Device $devId',
                                        isGroup: false,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: const Text('Direct Mesh Chat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EmergixxTheme.safeGreen,
                                ),
                              ),
                            ),
                          if (_selectedMarker!['deviceId'] != null)
                            const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tactical offline heading bearing calculated'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.navigation_outlined, size: 16),
                              label: const Text('Navigate'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayerChip(String key, String label) {
    final isSelected = _selectedLayer == key;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: Colors.blueAccent.withOpacity(0.35),
      backgroundColor: EmergixxTheme.surfaceDark.withOpacity(0.9),
      onSelected: (_) => setState(() => _selectedLayer = key),
    );
  }

  Widget _buildMapPin(Map<String, dynamic> marker) {
    final color = marker['color'] as Color;
    final icon = marker['icon'] as IconData;
    final isSelected = _selectedMarker?['id'] == marker['id'];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isSelected ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: isSelected ? 12 : 6,
            spreadRadius: isSelected ? 4 : 1,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black87, size: 18),
    );
  }
}

/// Custom painter rendering tactical coordinate grid, range rings, and trail breadcrumbs.
class _TacticalMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> markers;
  final String? selectedId;
  final bool showBreadcrumbs;

  _TacticalMapPainter({
    required this.markers,
    required this.selectedId,
    required this.showBreadcrumbs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2A38)
      ..strokeWidth = 1;

    // Draw tactical grid lines
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw range rings around center
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..color = const Color(0xFF1A3B5C).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 80, ringPaint);
    canvas.drawCircle(center, 160, ringPaint);
    canvas.drawCircle(center, 240, ringPaint);

    // Draw breadcrumb trail
    if (showBreadcrumbs) {
      final trailPaint = Paint()
        ..color = Colors.lightBlueAccent.withOpacity(0.4)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(center.dx - 60, center.dy + 80);
      path.lineTo(center.dx - 30, center.dy + 40);
      path.lineTo(center.dx, center.dy);
      canvas.drawPath(path, trailPaint);

      final dotPaint = Paint()..color = Colors.lightBlueAccent;
      canvas.drawCircle(Offset(center.dx - 60, center.dy + 80), 3, dotPaint);
      canvas.drawCircle(Offset(center.dx - 30, center.dy + 40), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TacticalMapPainter oldDelegate) => true;
}
