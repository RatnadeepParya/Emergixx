/// Defines the EMERGIXX/1 protocol specification and capability negotiation rules.
class ProtocolVersion {
  static const String current = 'EMERGIXX/1';
  static const int majorVersion = 1;
  static const int minorVersion = 0;

  static const int maxHopCount = 10;
  static const int defaultTtl = 10;
  static const int maxPacketBytes = 64 * 1024; // 64 KB max packet limit for BLE/P2P

  /// Standard capability flags advertised during discovery.
  static const String capMessage = 'MESSAGE';
  static const String capSos = 'SOS';
  static const String capLocationRelay = 'LOCATION_RELAY';
  static const String capGroup = 'GROUP';
  static const String capVoiceNote = 'VOICE_NOTE_READY';

  static const List<String> standardCapabilities = [
    capMessage,
    capSos,
    capLocationRelay,
    capGroup,
  ];

  /// Validates compatibility between two protocol strings.
  static bool isCompatible(String peerProtocol) {
    if (!peerProtocol.startsWith('EMERGIXX/')) return false;
    final parts = peerProtocol.split('/');
    if (parts.length < 2) return false;
    final versionNum = int.tryParse(parts[1]);
    if (versionNum == null) return false;
    // Backwards compatible with any version in major release 1
    return versionNum == majorVersion;
  }
}
