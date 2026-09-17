# Decentralized Cryptographic Identity

## 1. Zero-Dependency Identity Philosophy

Emergixx does not rely on:
- Phone numbers or SMS verification codes (inoperable when cell towers collapse).
- Email addresses or centralized OAuth accounts (inoperable without DNS and internet).
- Centralized user registries or blockchain networks.

Every device is an autonomous, self-authenticating cryptographic entity.

---

## 2. Device Identifier Anatomy (`EX-XXXXXX`)

```
  +----+   +-------------------------------+
  | EX | - |  6 HEXADECIMAL DIGITS (24-bit)|
  +----+   +-------------------------------+
    |                     |
    |                     +---> Upper 24 bits of SHA-256(Ed25519 Public Key)
    +-------------------------> Emergixx System Prefix
```

### Example:
- **Master Seed**: `32-byte hardware RNG seed`
- **Ed25519 Public Key**: `7a29f1b4908ef1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
- **SHA-256 Digest**: `7a29f1c784...`
- **Device ID**: `EX-7A29F1`

This provides a human-readable, verbal callsign suitable for radio readback during rescue operations (e.g., *"Calling Unit Echo-Xray Seven-Alpha-Two-Nine-Foxtrot-One"*).

---

## 3. Hardware-Backed Secure Storage

Private keys are protected by operating system hardware enclaves:
- **Android**: Android Keystore Provider (`KeyGenParameterSpec`, `MasterKeys.AES256_GCM_SPEC`), stored in ARM TrustZone or StrongBox Keymaster.
- **iOS**: Apple Keychain Services (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), secured by the Apple Secure Enclave.
- **Master Key Derivation**: AES-256-GCM hardware key wraps the 32-byte Ed25519 master seed. Plaintext seeds never reside in unencrypted flash memory.

---

## 4. Out-of-Band Identity Verification (QR Code)

To guard against active Man-in-the-Middle (MITM) attacks during local peer encounters:
1. Two users in physical proximity open their **Profile Screen**.
2. Node A displays a dynamic verification QR code encoding:
   ```json
   {
     "v": 1,
     "id": "EX-7A29F1",
     "signPub": "7a29f1b4908ef1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
     "dhPub": "319bf51890cd1c149afbf4c8996fb92427ae41e4649b934ca495991b7852c92",
     "name": "John Doe",
     "bloodType": "O+"
   }
   ```
3. Node B scans the QR code using the camera.
4. Node B verifies the public key hashes to `EX-7A29F1` and transitions Node A's trust state in the local SQLite database from `TrustState.unknown` to `TrustState.trusted`.

---

## 5. Trust States Lifecycle

```
             Discovered on Radio Advertisement
                           |
                           v
                 +-------------------+
                 | TrustState.unknown|
                 +-------------------+
                   |               |
   User manually   |               | Out-of-band QR
   blocks node     |               | key verification
                   v               v
           +-------------+  +---------------+
           |   blocked   |  |    trusted    |
           +-------------+  +---------------+
                   ^               |
                   |               | Node exhibits malicious
                   +---------------+ replay or payload spoofing
```
