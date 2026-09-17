/// Connectivity states displayed prominently in the Emergixx UI.
enum NetworkState {
  online,
  offline,
  meshOnly,
  connecting,
  syncing;

  String toWire() {
    switch (this) {
      case NetworkState.online:
        return 'ONLINE';
      case NetworkState.offline:
        return 'OFFLINE';
      case NetworkState.meshOnly:
        return 'MESH ONLY';
      case NetworkState.connecting:
        return 'CONNECTING';
      case NetworkState.syncing:
        return 'SYNCING';
    }
  }

  String get userMessage {
    switch (this) {
      case NetworkState.online:
        return 'Connected to Internet & Cloud services. Mesh relay active.';
      case NetworkState.offline:
        return 'Internet unavailable. No peers currently in radio range.';
      case NetworkState.meshOnly:
        return 'Internet unavailable. Messages can still be relayed through nearby Emergixx devices.';
      case NetworkState.connecting:
        return 'Establishing peer-to-peer radio link...';
      case NetworkState.syncing:
        return 'Reconnecting to cloud. Synchronizing queued emergency events...';
    }
  }

  static NetworkState fromWire(String wire) {
    switch (wire.toUpperCase()) {
      case 'ONLINE':
        return NetworkState.online;
      case 'MESH ONLY':
      case 'MESH_ONLY':
        return NetworkState.meshOnly;
      case 'CONNECTING':
        return NetworkState.connecting;
      case 'SYNCING':
        return NetworkState.syncing;
      default:
        return NetworkState.offline;
    }
  }
}
