import 'dart:convert';

/// Privacy-conscious structured logging utility that redacts sensitive cryptographic keys,
/// private message plaintext, and personal data before emitting logs.
class SanitizedLogger {
  static const List<String> _redactedKeys = [
    'privatekey',
    'private_key',
    'seed',
    'groupkey',
    'group_key',
    'token',
    'auth',
    'secret',
    'plaintext',
    'password',
  ];

  /// Emits a structured log line.
  static void log(String level, String component, String message,
      [Map<String, dynamic>? metadata]) {
    final timestamp = DateTime.now().toIso8601String();
    final sanitizedMeta = metadata != null ? _sanitizeMap(metadata) : null;

    final entry = {
      'ts': timestamp,
      'lvl': level.toUpperCase(),
      'cmp': component,
      'msg': message,
      if (sanitizedMeta != null) 'meta': sanitizedMeta,
    };

    // Print JSON log line
    // ignore: avoid_print
    print('[EMERGIXX] ${jsonEncode(entry)}');
  }

  static void info(String component, String message,
          [Map<String, dynamic>? metadata]) =>
      log('INFO', component, message, metadata);

  static void warn(String component, String message,
          [Map<String, dynamic>? metadata]) =>
      log('WARN', component, message, metadata);

  static void error(String component, String message,
          [Map<String, dynamic>? metadata]) =>
      log('ERROR', component, message, metadata);

  static void debug(String component, String message,
          [Map<String, dynamic>? metadata]) =>
      log('DEBUG', component, message, metadata);

  static Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    final clean = <String, dynamic>{};
    map.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (_redactedKeys.any((r) => lowerKey.contains(r))) {
        clean[key] = '[REDACTED]';
      } else if (value is Map<String, dynamic>) {
        clean[key] = _sanitizeMap(value);
      } else {
        clean[key] = value;
      }
    });
    return clean;
  }
}
