import 'dart:convert';
import 'dart:typed_data';
import 'package:emergixx_models/emergixx_models.dart';
import 'protocol_version.dart';

/// Encodes and decodes Emergixx wire packets across peer transport layers.
class PacketCodec {
  /// Encodes an [EmergixxMessage] into a compact UTF-8 byte array with a 2-byte magic header.
  static Uint8List encode(EmergixxMessage message) {
    final jsonMap = message.toJson();
    final jsonStr = jsonEncode(jsonMap);
    final payloadBytes = utf8.encode(jsonStr);

    if (payloadBytes.length > ProtocolVersion.maxPacketBytes) {
      throw ArgumentError(
        'Packet size (${payloadBytes.length} bytes) exceeds protocol maximum of ${ProtocolVersion.maxPacketBytes} bytes',
      );
    }

    // Packet frame: [Magic: 0x45 0x58 (EX)] [Version: 0x01] [PayloadLength: 2 bytes] [Payload]
    final frame = Uint8List(5 + payloadBytes.length);
    frame[0] = 0x45; // 'E'
    frame[1] = 0x58; // 'X'
    frame[2] = ProtocolVersion.majorVersion; // 1
    ByteData.view(frame.buffer).setUint16(3, payloadBytes.length, Endian.big);
    frame.setRange(5, frame.length, payloadBytes);
    return frame;
  }

  /// Decodes raw packet bytes into an [EmergixxMessage].
  static EmergixxMessage decode(Uint8List rawBytes) {
    if (rawBytes.length < 5) {
      throw FormatException('Raw packet is too short (${rawBytes.length} bytes)');
    }

    // Verify magic header
    if (rawBytes[0] != 0x45 || rawBytes[1] != 0x58) {
      // Fallback: Check if raw JSON was sent without framing header
      try {
        final rawStr = utf8.decode(rawBytes);
        final map = jsonDecode(rawStr) as Map<String, dynamic>;
        return EmergixxMessage.fromJson(map);
      } catch (_) {
        throw FormatException('Invalid packet magic header: expected EX');
      }
    }

    final version = rawBytes[2];
    if (version != ProtocolVersion.majorVersion) {
      throw FormatException('Unsupported packet protocol version: $version');
    }

    final length = ByteData.view(rawBytes.buffer).getUint16(3, Endian.big);
    if (rawBytes.length < 5 + length) {
      throw FormatException('Truncated packet payload');
    }

    final payloadBytes = rawBytes.sublist(5, 5 + length);
    final jsonStr = utf8.decode(payloadBytes);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return EmergixxMessage.fromJson(map);
  }

  /// Encodes message into JSON string.
  static String encodeToJson(EmergixxMessage message) =>
      jsonEncode(message.toJson());

  /// Decodes message from JSON string.
  static EmergixxMessage decodeFromJson(String jsonStr) =>
      EmergixxMessage.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}
