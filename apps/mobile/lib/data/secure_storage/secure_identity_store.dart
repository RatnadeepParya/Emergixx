import 'package:emergixx_crypto/emergixx_crypto.dart';
import '../database/database_helper.dart';

/// Secure local store for device private cryptographic keys.
/// Private keys are stored in secure device storage and NEVER sent to the cloud.
class SecureIdentityStore {
  static const String _keySeed = 'emergixx_ed25519_seed';
  static const String _keyXSeed = 'emergixx_x25519_seed';

  IdentityKeys? _cachedKeys;

  /// Retrieves the existing identity or generates a fresh cryptographic keypair.
  Future<IdentityKeys> getOrCreateIdentity() async {
    if (_cachedKeys != null) return _cachedKeys!;

    final db = DatabaseHelper.instance;
    final storedSeed = await db.getSetting(_keySeed);
    final storedXSeed = await db.getSetting(_keyXSeed);

    if (storedSeed != null) {
      _cachedKeys = IdentityKeys.fromBase64(
        seedBase64: storedSeed,
        x25519SeedBase64: storedXSeed,
      );
    } else {
      // Generate new cryptographic identity
      final freshKeys = IdentityKeys.generate();
      await db.setSetting(_keySeed, freshKeys.seedBase64);
      await db.setSetting(_keyXSeed, freshKeys.x25519SeedBase64);
      _cachedKeys = freshKeys;
    }

    return _cachedKeys!;
  }

  /// Wipes local keys (e.g. upon explicit device reset).
  Future<void> wipeIdentity() async {
    final db = DatabaseHelper.instance;
    await db.setSetting(_keySeed, '');
    await db.setSetting(_keyXSeed, '');
    _cachedKeys = null;
  }
}
