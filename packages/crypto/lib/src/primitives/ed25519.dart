import 'dart:math';
import 'dart:typed_data';

/// Pure Dart implementation of Ed25519 signatures, verification, and Curve25519 ECDH key exchange (RFC 8032).
/// Uses SHA-512 internally as specified in RFC 8032.
class Ed25519 {
  static final BigInt _q = (BigInt.one << 255) - BigInt.from(19);
  static final BigInt _l = (BigInt.one << 252) +
      BigInt.parse('27742317777372353535851937790883648493');

  static BigInt _mod(BigInt x) => (x % _q + _q) % _q;
  static BigInt _modL(BigInt x) => (x % _l + _l) % _l;

  static final BigInt _d = _mod(-BigInt.from(121665) *
      BigInt.from(121666).modInverse(_q));
  static final BigInt _i =
      BigInt.from(2).modPow((_q - BigInt.one) ~/ BigInt.from(4), _q);

  static final BigInt _by =
      _mod(BigInt.from(4) * BigInt.from(5).modInverse(_q));
  static final BigInt _bx = _recoverX(_by);

  static List<BigInt> get _b => [_bx, _by, BigInt.one, _mod(_bx * _by)];

  /// Generates a random 32-byte Ed25519 seed (private key).
  static Uint8List generateSeed() {
    final rng = Random.secure();
    final seed = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      seed[i] = rng.nextInt(256);
    }
    return seed;
  }

  /// Derives the 32-byte public key from the 32-byte private seed.
  static Uint8List publicKeyFromSeed(Uint8List seed) {
    final h = _sha512(seed);
    BigInt a = _decodeScalar(h.sublist(0, 32));
    final aPoint = _scalarMult(_b, a);
    return _encodePoint(aPoint);
  }

  /// Computes a shared secret point between private seed and peer public key.
  static Uint8List diffieHellman({
    required Uint8List seed,
    required Uint8List theirPublicKey,
  }) {
    final h = _sha512(seed);
    final a = _decodeScalar(h.sublist(0, 32));
    final theirPoint = _decodePoint(theirPublicKey);
    if (theirPoint == null) {
      throw ArgumentError('Invalid peer public key');
    }
    final sharedPoint = _scalarMult(theirPoint, a);
    return _encodePoint(sharedPoint);
  }

  /// Signs a message using the 32-byte private seed and public key.
  static Uint8List sign({
    required Uint8List seed,
    required Uint8List message,
  }) {
    final pubKey = publicKeyFromSeed(seed);
    final h = _sha512(seed);
    final a = _decodeScalar(h.sublist(0, 32));
    final prefix = h.sublist(32, 64);

    final rHashInput = Uint8List(32 + message.length);
    rHashInput.setRange(0, 32, prefix);
    rHashInput.setRange(32, rHashInput.length, message);
    final rHash = _sha512(rHashInput);
    final r = _decode64Bytes(rHash) % _l;

    final rPoint = _scalarMult(_b, r);
    final rBytes = _encodePoint(rPoint);

    final kHashInput = Uint8List(32 + 32 + message.length);
    kHashInput.setRange(0, 32, rBytes);
    kHashInput.setRange(32, 64, pubKey);
    kHashInput.setRange(64, kHashInput.length, message);
    final k = _decode64Bytes(_sha512(kHashInput)) % _l;

    final s = _modL(r + (k * a));
    final sBytes = _encodeInt(s);

    final sig = Uint8List(64);
    sig.setRange(0, 32, rBytes);
    sig.setRange(32, 64, sBytes);
    return sig;
  }

  /// Verifies an Ed25519 64-byte signature against a 32-byte public key and message.
  static bool verify({
    required Uint8List publicKey,
    required Uint8List message,
    required Uint8List signature,
  }) {
    if (signature.length != 64 || publicKey.length != 32) return false;

    final rBytes = signature.sublist(0, 32);
    final sBytes = signature.sublist(32, 64);
    final s = _decodeInt(sBytes);
    if (s >= _l) return false;

    final aPoint = _decodePoint(publicKey);
    if (aPoint == null) return false;

    final kHashInput = Uint8List(32 + 32 + message.length);
    kHashInput.setRange(0, 32, rBytes);
    kHashInput.setRange(32, 64, publicKey);
    kHashInput.setRange(64, kHashInput.length, message);
    final k = _decode64Bytes(_sha512(kHashInput)) % _l;

    final sb = _scalarMult(_b, s);
    final ka = _scalarMult(aPoint, k);
    final rPoint = _decodePoint(rBytes);
    if (rPoint == null) return false;

    final rhs = _edwardsAdd(rPoint, ka);
    final sbEncoded = _encodePoint(sb);
    final rhsEncoded = _encodePoint(rhs);

    if (sbEncoded.length != rhsEncoded.length) return false;
    for (int i = 0; i < sbEncoded.length; i++) {
      if (sbEncoded[i] != rhsEncoded[i]) return false;
    }
    return true;
  }

  // --- Internal Edwards Curve Arithmetic ---

  static BigInt _recoverX(BigInt y) {
    BigInt xx = _mod((y * y - BigInt.one) *
        (BigInt.one + _d * y * y).modInverse(_q));
    BigInt x = xx.modPow((_q + BigInt.from(3)) ~/ BigInt.from(8), _q);
    if (_mod(x * x - xx) != BigInt.zero) {
      x = _mod(x * _i);
    }
    if (x.isOdd) x = _q - x;
    return x;
  }

  static BigInt _decodeInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = bytes.length - 1; i >= 0; i--) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  static BigInt _decode64Bytes(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = bytes.length - 1; i >= 0; i--) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  static Uint8List _encodeInt(BigInt val) {
    final bytes = Uint8List(32);
    BigInt v = val;
    for (int i = 0; i < 32; i++) {
      bytes[i] = (v & BigInt.from(0xff)).toInt();
      v >>= 8;
    }
    return bytes;
  }

  static BigInt _decodeScalar(Uint8List bytes) {
    final clamped = Uint8List.fromList(bytes.sublist(0, 32));
    clamped[0] &= 248;
    clamped[31] &= 127;
    clamped[31] |= 64;
    return _decodeInt(clamped);
  }

  static Uint8List _encodePoint(List<BigInt> p) {
    BigInt zInv = p[2].modInverse(_q);
    BigInt x = _mod(p[0] * zInv);
    BigInt y = _mod(p[1] * zInv);
    Uint8List s = _encodeInt(y);
    if (x.isOdd) {
      s[31] |= 0x80;
    }
    return s;
  }

  static List<BigInt>? _decodePoint(Uint8List bytes) {
    final yBytes = Uint8List.fromList(bytes);
    final sign = (yBytes[31] & 0x80) != 0;
    yBytes[31] &= 0x7f;
    BigInt y = _decodeInt(yBytes);
    if (y >= _q) return null;

    BigInt xx = _mod((y * y - BigInt.one) *
        (BigInt.one + _d * y * y).modInverse(_q));
    if (xx == BigInt.zero) {
      if (sign) return null;
      return [BigInt.zero, y, BigInt.one, BigInt.zero];
    }
    BigInt x = xx.modPow((_q + BigInt.from(3)) ~/ BigInt.from(8), _q);
    if (_mod(x * x - xx) != BigInt.zero) {
      x = _mod(x * _i);
    }
    if (_mod(x * x - xx) != BigInt.zero) return null;

    if (x.isOdd != sign) {
      x = _q - x;
    }
    return [x, y, BigInt.one, _mod(x * y)];
  }

  static List<BigInt> _edwardsAdd(List<BigInt> p1, List<BigInt> p2) {
    BigInt a = _mod((p1[1] - p1[0]) * (p2[1] - p2[0]));
    BigInt b = _mod((p1[1] + p1[0]) * (p2[1] + p2[0]));
    BigInt c = _mod(BigInt.from(2) * _d * p1[3] * p2[3]);
    BigInt d = _mod(BigInt.from(2) * p1[2] * p2[2]);
    BigInt e = _mod(b - a);
    BigInt f = _mod(d - c);
    BigInt g = _mod(d + c);
    BigInt h = _mod(b + a);

    return [_mod(e * f), _mod(g * h), _mod(f * g), _mod(e * h)];
  }

  static List<BigInt> _scalarMult(List<BigInt> p, BigInt scalar) {
    List<BigInt> r = [BigInt.zero, BigInt.one, BigInt.one, BigInt.zero];
    List<BigInt> q = p;
    BigInt s = scalar;
    while (s > BigInt.zero) {
      if (s.isOdd) {
        r = _edwardsAdd(r, q);
      }
      q = _edwardsAdd(q, q);
      s >>= 1;
    }
    return r;
  }

  // --- Pure Dart SHA-512 implementation for RFC 8032 ---
  static Uint8List _sha512(Uint8List msg) {
    final List<BigInt> k = [
      BigInt.parse('428a2f98d728ae22', radix: 16),
      BigInt.parse('7137449123ef65cd', radix: 16),
      BigInt.parse('b5c0fbcfec4d3b2f', radix: 16),
      BigInt.parse('e9b5dba58189dbbc', radix: 16),
      BigInt.parse('3956c25bf348b538', radix: 16),
      BigInt.parse('59f111f1b605d019', radix: 16),
      BigInt.parse('923f82a4af194f9b', radix: 16),
      BigInt.parse('ab1c5ed5da6d8118', radix: 16),
      BigInt.parse('d807aa98a3030242', radix: 16),
      BigInt.parse('12835b0145706fbe', radix: 16),
      BigInt.parse('243185be4ee4b28c', radix: 16),
      BigInt.parse('550c7dc3d5ffb4e2', radix: 16),
      BigInt.parse('72be5d74f27b896f', radix: 16),
      BigInt.parse('80deb1fe3b1696b1', radix: 16),
      BigInt.parse('9bdc06a725c71235', radix: 16),
      BigInt.parse('c19bf174cf692694', radix: 16),
      BigInt.parse('e49b69c19ef14ad2', radix: 16),
      BigInt.parse('efbe4786384f25e3', radix: 16),
      BigInt.parse('0fc19dc68b8cd5b5', radix: 16),
      BigInt.parse('240ca1cc77ac9c65', radix: 16),
      BigInt.parse('2de92c6f592b0275', radix: 16),
      BigInt.parse('4a7484aa6ea6e483', radix: 16),
      BigInt.parse('5cb0a9dcbd41fbd4', radix: 16),
      BigInt.parse('76f988da831153b5', radix: 16),
      BigInt.parse('983e5152ee66dfab', radix: 16),
      BigInt.parse('a831c66d2db43210', radix: 16),
      BigInt.parse('b00327c898fb213f', radix: 16),
      BigInt.parse('bf597fc7beef0ee4', radix: 16),
      BigInt.parse('c6e00bf33da88fc2', radix: 16),
      BigInt.parse('d5a79147930aa725', radix: 16),
      BigInt.parse('06ca6351e003826f', radix: 16),
      BigInt.parse('142929670a0e6e70', radix: 16),
      BigInt.parse('27b70a8546d22ffc', radix: 16),
      BigInt.parse('2e1b21385c26c926', radix: 16),
      BigInt.parse('4d2c6dfc5ac42aed', radix: 16),
      BigInt.parse('53380d139d95b3df', radix: 16),
      BigInt.parse('650a73548baf63de', radix: 16),
      BigInt.parse('766a0abb3c77b2a8', radix: 16),
      BigInt.parse('81c2c92e47867871', radix: 16),
      BigInt.parse('92722c851482353b', radix: 16),
      BigInt.parse('a2bfe8a14cf10364', radix: 16),
      BigInt.parse('a81a664bbc423001', radix: 16),
      BigInt.parse('c24b8b70d0f89791', radix: 16),
      BigInt.parse('c76c51a30654be30', radix: 16),
      BigInt.parse('d192e819d6ef5218', radix: 16),
      BigInt.parse('d69906245565a910', radix: 16),
      BigInt.parse('f40e35855771202a', radix: 16),
      BigInt.parse('106aa07032bbd1b8', radix: 16),
      BigInt.parse('19a4c116b8d2d0c8', radix: 16),
      BigInt.parse('1e376c085141ab53', radix: 16),
      BigInt.parse('2748774cdf8eeb99', radix: 16),
      BigInt.parse('34b0bcb5e19b48a8', radix: 16),
      BigInt.parse('391c0cb3c5c95a63', radix: 16),
      BigInt.parse('4ed8aa4ae3418acb', radix: 16),
      BigInt.parse('5b9cca4f7763e373', radix: 16),
      BigInt.parse('682e6ff3d6b2b8a3', radix: 16),
      BigInt.parse('748f82ee5defb2fc', radix: 16),
      BigInt.parse('78a5636f43172f60', radix: 16),
      BigInt.parse('84c87814a1f0ab72', radix: 16),
      BigInt.parse('8cc702081a6439ec', radix: 16),
      BigInt.parse('90befffa23631e28', radix: 16),
      BigInt.parse('a4506cebde82bde9', radix: 16),
      BigInt.parse('bef9a3f7b2c67915', radix: 16),
      BigInt.parse('c67178f2e372532b', radix: 16),
      BigInt.parse('ca273eceea26619c', radix: 16),
      BigInt.parse('d186b8c721c0c207', radix: 16),
      BigInt.parse('eada7dd6cde0eb1e', radix: 16),
      BigInt.parse('f57d4f7fee6ed178', radix: 16),
      BigInt.parse('06f067aa72176fba', radix: 16),
      BigInt.parse('0a637dc5a2c898a6', radix: 16),
      BigInt.parse('113f9804bef90dae', radix: 16),
      BigInt.parse('1b710b35131c471b', radix: 16),
      BigInt.parse('28db77f523047d84', radix: 16),
      BigInt.parse('32caab7b40c72493', radix: 16),
      BigInt.parse('3c9ebe0a15c9bebc', radix: 16),
      BigInt.parse('431d67c49c100d4c', radix: 16),
      BigInt.parse('4cc5d4becb3e42b6', radix: 16),
      BigInt.parse('597f299cfc657e2a', radix: 16),
      BigInt.parse('5fcb6fab3ad6faec', radix: 16),
      BigInt.parse('6c44198c4a475817', radix: 16),
    ];

    final mask64 = (BigInt.one << 64) - BigInt.one;

    BigInt rotr64(BigInt x, int n) {
      return ((x >> n) | (x << (64 - n))) & mask64;
    }

    final List<BigInt> h = [
      BigInt.parse('6a09e667f3bcc908', radix: 16),
      BigInt.parse('bb67ae8584caa73b', radix: 16),
      BigInt.parse('3c6ef372fe94f82b', radix: 16),
      BigInt.parse('a54ff53a5f1d36f1', radix: 16),
      BigInt.parse('510e527fade682d1', radix: 16),
      BigInt.parse('9b05688c2b3e6c1f', radix: 16),
      BigInt.parse('1f83d9abfb41bd6b', radix: 16),
      BigInt.parse('5be0cd19137e2179', radix: 16),
    ];

    int len = msg.length;
    int bitLen = len * 8;
    int padLen = (len + 17 + 127) & ~127;
    Uint8List padded = Uint8List(padLen);
    padded.setRange(0, len, msg);
    padded[len] = 0x80;

    ByteData bd = ByteData.view(padded.buffer);
    bd.setUint64(padLen - 8, bitLen, Endian.big);

    List<BigInt> w = List<BigInt>.filled(80, BigInt.zero);

    for (int i = 0; i < padLen; i += 128) {
      for (int t = 0; t < 16; t++) {
        final hi = bd.getUint32(i + t * 8, Endian.big);
        final lo = bd.getUint32(i + t * 8 + 4, Endian.big);
        w[t] = (BigInt.from(hi) << 32) | BigInt.from(lo);
      }
      for (int t = 16; t < 80; t++) {
        final s0 = rotr64(w[t - 15], 1) ^
            rotr64(w[t - 15], 8) ^
            (w[t - 15] >> 7);
        final s1 = rotr64(w[t - 2], 19) ^
            rotr64(w[t - 2], 61) ^
            (w[t - 2] >> 6);
        w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & mask64;
      }

      BigInt a = h[0];
      BigInt b = h[1];
      BigInt c = h[2];
      BigInt d = h[3];
      BigInt e = h[4];
      BigInt f = h[5];
      BigInt g = h[6];
      BigInt hVal = h[7];

      for (int t = 0; t < 80; t++) {
        final s1 = rotr64(e, 14) ^ rotr64(e, 18) ^ rotr64(e, 41);
        final ch = (e & f) ^ (~e & g & mask64);
        final temp1 = (hVal + s1 + ch + k[t] + w[t]) & mask64;
        final s0 = rotr64(a, 28) ^ rotr64(a, 34) ^ rotr64(a, 39);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & mask64;

        hVal = g;
        g = f;
        f = e;
        e = (d + temp1) & mask64;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & mask64;
      }

      h[0] = (h[0] + a) & mask64;
      h[1] = (h[1] + b) & mask64;
      h[2] = (h[2] + c) & mask64;
      h[3] = (h[3] + d) & mask64;
      h[4] = (h[4] + e) & mask64;
      h[5] = (h[5] + f) & mask64;
      h[6] = (h[6] + g) & mask64;
      h[7] = (h[7] + hVal) & mask64;
    }

    final out = Uint8List(64);
    final outBd = ByteData.view(out.buffer);
    for (int i = 0; i < 8; i++) {
      final hi = (h[i] >> 32).toInt();
      final lo = (h[i] & BigInt.from(0xffffffff)).toInt();
      outBd.setUint32(i * 8, hi, Endian.big);
      outBd.setUint32(i * 8 + 4, lo, Endian.big);
    }
    return out;
  }
}
