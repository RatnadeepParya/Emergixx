/// Protocol message types supported by EMERGIXX/1.
enum MessageType {
  text,
  sos,
  location,
  broadcast,
  groupMessage,
  ack,
  deliveryStatus,
  emergencyUpdate,
  systemMessage;

  String toWire() {
    switch (this) {
      case MessageType.text:
        return 'TEXT';
      case MessageType.sos:
        return 'SOS';
      case MessageType.location:
        return 'LOCATION';
      case MessageType.broadcast:
        return 'BROADCAST';
      case MessageType.groupMessage:
        return 'GROUP_MESSAGE';
      case MessageType.ack:
        return 'ACK';
      case MessageType.deliveryStatus:
        return 'DELIVERY_STATUS';
      case MessageType.emergencyUpdate:
        return 'EMERGENCY_UPDATE';
      case MessageType.systemMessage:
        return 'SYSTEM_MESSAGE';
    }
  }

  static MessageType fromWire(String wire) {
    switch (wire.toUpperCase()) {
      case 'TEXT':
        return MessageType.text;
      case 'SOS':
        return MessageType.sos;
      case 'LOCATION':
        return MessageType.location;
      case 'BROADCAST':
        return MessageType.broadcast;
      case 'GROUP_MESSAGE':
        return MessageType.groupMessage;
      case 'ACK':
        return MessageType.ack;
      case 'DELIVERY_STATUS':
        return MessageType.deliveryStatus;
      case 'EMERGENCY_UPDATE':
        return MessageType.emergencyUpdate;
      case 'SYSTEM_MESSAGE':
        return MessageType.systemMessage;
      default:
        return MessageType.text;
    }
  }
}

/// Priority tier determining queue precedence and store-and-forward eviction resistance.
enum MessagePriority {
  critical(0), // SOS, life-safety alerts
  high(1),     // Responder acks, incident updates
  normal(2),   // Direct survivor messages, safe check-ins
  low(3);      // Background sync, system telemetry

  final int level;
  const MessagePriority(this.level);

  String toWire() => name.toUpperCase();

  static MessagePriority fromWire(String wire) {
    switch (wire.toUpperCase()) {
      case 'CRITICAL':
        return MessagePriority.critical;
      case 'HIGH':
        return MessagePriority.high;
      case 'NORMAL':
        return MessagePriority.normal;
      case 'LOW':
        return MessagePriority.low;
      default:
        return MessagePriority.normal;
    }
  }
}

/// Complete lifecycle states for emergency SOS broadcasts.
enum SosStatus {
  created,
  relaying,
  received,
  acknowledged,
  responding,
  resolved,
  expired,
  cancelled;

  String toWire() => name.toUpperCase();

  static SosStatus fromWire(String wire) {
    switch (wire.toUpperCase()) {
      case 'CREATED':
        return SosStatus.created;
      case 'RELAYING':
        return SosStatus.relaying;
      case 'RECEIVED':
        return SosStatus.received;
      case 'ACKNOWLEDGED':
        return SosStatus.acknowledged;
      case 'RESPONDING':
        return SosStatus.responding;
      case 'RESOLVED':
        return SosStatus.resolved;
      case 'EXPIRED':
        return SosStatus.expired;
      case 'CANCELLED':
        return SosStatus.cancelled;
      default:
        return SosStatus.created;
    }
  }
}

/// One-touch safety check-in status options.
enum CheckInStatus {
  safe,
  needHelp,
  moving,
  unableToMove,
  unknown;

  String toWire() {
    switch (this) {
      case CheckInStatus.safe:
        return 'I_AM_SAFE';
      case CheckInStatus.needHelp:
        return 'I_NEED_HELP';
      case CheckInStatus.moving:
        return 'I_AM_MOVING';
      case CheckInStatus.unableToMove:
        return 'I_AM_UNABLE_TO_MOVE';
      case CheckInStatus.unknown:
        return 'UNKNOWN';
    }
  }

  String toDisplayLabel() {
    switch (this) {
      case CheckInStatus.safe:
        return "I'M SAFE";
      case CheckInStatus.needHelp:
        return 'NEED HELP';
      case CheckInStatus.moving:
        return 'I AM MOVING';
      case CheckInStatus.unableToMove:
        return 'UNABLE TO MOVE';
      case CheckInStatus.unknown:
        return 'STATUS UNKNOWN';
    }
  }

  static CheckInStatus fromWire(String wire) {
    switch (wire.toUpperCase()) {
      case 'I_AM_SAFE':
      case 'SAFE':
        return CheckInStatus.safe;
      case 'I_NEED_HELP':
      case 'NEED_HELP':
        return CheckInStatus.needHelp;
      case 'I_AM_MOVING':
      case 'MOVING':
        return CheckInStatus.moving;
      case 'I_AM_UNABLE_TO_MOVE':
      case 'UNABLE_TO_MOVE':
        return CheckInStatus.unableToMove;
      default:
        return CheckInStatus.unknown;
    }
  }
}

/// Trust classification for mesh devices and emergency alert issuers.
enum TrustState {
  unknown,
  known,
  trusted,
  blocked;

  String toWire() => name.toUpperCase();

  static TrustState fromWire(String wire) {
    switch (wire.toUpperCase()) {
      case 'UNKNOWN':
        return TrustState.unknown;
      case 'KNOWN':
        return TrustState.known;
      case 'TRUSTED':
        return TrustState.trusted;
      case 'BLOCKED':
        return TrustState.blocked;
      default:
        return TrustState.unknown;
    }
  }
}

/// Delivery tracking states for outbound messages.
enum DeliveryStatus {
  queued,
  relaying,
  delivered,
  read,
  expired,
  failed;

  String toWire() => name.toUpperCase();

  static DeliveryStatus fromWire(String wire) {
    switch (wire.toUpperCase()) {
      case 'QUEUED':
        return DeliveryStatus.queued;
      case 'RELAYING':
        return DeliveryStatus.relaying;
      case 'DELIVERED':
        return DeliveryStatus.delivered;
      case 'READ':
        return DeliveryStatus.read;
      case 'EXPIRED':
        return DeliveryStatus.expired;
      case 'FAILED':
        return DeliveryStatus.failed;
      default:
        return DeliveryStatus.queued;
    }
  }
}

/// Underlying radio or virtual transport mechanism.
enum TransportType {
  bluetooth,
  wifiDirect,
  webRtc,
  nearby,
  loopback;

  String toWire() => name;

  static TransportType fromWire(String wire) {
    switch (wire.toLowerCase()) {
      case 'bluetooth':
      case 'ble':
        return TransportType.bluetooth;
      case 'wifidirect':
      case 'wifi_direct':
      case 'wifi':
        return TransportType.wifiDirect;
      case 'webrtc':
        return TransportType.webRtc;
      case 'nearby':
        return TransportType.nearby;
      case 'loopback':
        return TransportType.loopback;
      default:
        return TransportType.bluetooth;
    }
  }
}
