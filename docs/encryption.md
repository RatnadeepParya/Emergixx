# End-to-End Encryption & Cryptography

## 1. Cryptographic Principles

Emergixx enforces strict end-to-end encryption (E2EE) and authenticates all messages.
- **Zero-Knowledge Relaying**: Intermediate nodes relay packets based solely on outer cleartext envelopes (Recipient ID, Message ID, TTL, Hop Count). They cannot read the contents of private messages.
- **Cryptographic Non-Repudiation**: Every packet is digitally signed by the original author's Ed25519 private key. Signatures cannot be forged or modified in transit.
- **Forward Secrecy & Key Agreement**: Peer-to-peer channels utilize ephemeral or static Curve25519 Diffie-Hellman key exchanges combined with HKDF key derivation.

---

## 2. Cryptographic Primitives

```
+-------------------------------------------------------------------------+
|                    EMERGIXX CRYPTOGRAPHIC PRIMITIVES                    |
+-------------------------------------------------------------------------+
| Function                 | Algorithm / Standard                         |
+--------------------------+----------------------------------------------+
| Digital Signatures       | Ed25519 (EdDSA over Curve25519, RFC 8032)   |
| Key Agreement            | X25519 / Curve25519 Diffie-Hellman (RFC 7748)|
| Key Derivation           | HKDF-SHA256 (RFC 5869)                       |
| Authenticated Encryption | AES-256-GCM / HMAC-SHA256 AEAD (RFC 5116)    |
| Cryptographic Hash       | SHA-256 (FIPS 180-4, RFC 6234)               |
| Message Authentication   | HMAC-SHA256 (RFC 2104)                       |
+-------------------------------------------------------------------------+
```

---

## 3. Key Generation & Derivation

A node generates a single cryptographically secure 32-byte master seed from the operating system's hardware random number generator (`/dev/urandom` / `SecRandomCopyBytes`).

From this 32-byte seed:
1. **Ed25519 Signing Key Pair**:
   $$\text{privateKey} = H(\text{seed}), \quad \text{publicKey} = A = s \cdot B$$
   where $B$ is the Ed25519 base point.
2. **Curve25519 Encryption Key Pair**:
   Derived by mapping the Ed25519 private scalar into Montgomery space via the Birational Equivalence:
   $$u = \frac{1 + y}{1 - y} \pmod{2^{255}-19}$$
3. **Device Identifier (`EX-XXXXXX`)**:
   $$\text{deviceId} = \text{"EX-"} + \text{Hex}(\text{SHA256}(\text{publicKey})[0..3]).\text{toUpperCase()}$$

---

## 4. End-to-End Direct Chat Encryption Flow

```
   Sender (Alice)                                    Recipient (Bob)
         |                                                 |
         | 1. Compute Shared Secret:                       |
         |    S = Curve25519(AlicePriv, BobPub)            |
         | 2. Derive Encryption & MAC Keys via HKDF:       |
         |    (K_enc, K_mac) = HKDF-SHA256(S, salt, info)  |
         | 3. Encrypt Payload:                             |
         |    C = Encrypt(K_enc, IV, Plaintext)            |
         |    Tag = HMAC-SHA256(K_mac, C || IV || Header)  |
         | 4. Sign Entire Packet:                          |
         |    Sig = Ed25519_Sign(AliceSignPriv, Packet)    |
         |                                                 |
         |============== Store-and-Forward Mesh ===========>|
         |                   (Relay Nodes)                 |
         |                                                 |
         |                                 5. Verify Ed25519 Signature:
         |                                    Verify(AliceSignPub, Sig)
         |                                 6. Compute Shared Secret:
         |                                    S = Curve25519(BobPriv, AlicePub)
         |                                 7. Derive (K_enc, K_mac) via HKDF
         |                                 8. Verify Tag & Decrypt Payload
```

---

## 5. Group Encryption (AES-256-GCM)

For emergency coordination groups (e.g., "Search & Rescue Unit Alpha" or "Family Circle"):
- The group creator generates a random 256-bit symmetric key ($K_{\text{group}}$).
- $K_{\text{group}}$ is shared with members either:
  1. Offline via scanning an encrypted visual QR code in person.
  2. Over the mesh encrypted via pairwise Curve25519 key exchange to each approved member device ID.
- Group messages are encrypted using AES-256-GCM with a unique 96-bit initialization vector ($IV$) per message:
  $$C, \text{Tag} = \text{AES-256-GCM-Encrypt}(K_{\text{group}}, IV, \text{Plaintext})$$

---

## 6. SOS Beacon Security & Authentication

SOS alerts require immediate readability by any nearby responder while preventing malicious tampering or fake emergency hoaxes:
- **Payload**: Stored in canonical structured JSON containing GPS coordinates, emergency type, medical notes, and battery status.
- **Authentication**: Signed with author's Ed25519 private key.
- **Relay Rules**: Intermediate nodes can inspect the cleartext metadata (to triage triage priority) but cannot alter any field without invalidating the 64-byte Ed25519 signature.
- **Tampering Detection**: If any coordinate or character is modified in transit, `Signer.verifyMessage()` returns `false`, and the packet is immediately purged from the network.

---

## 7. Replay Attack & Clock Drift Protection

To prevent malicious actors from recording and re-broadcasting resolved SOS distress beacons:
1. **Cryptographic Nonce**: Every message contains a unique 16-byte random nonce.
2. **Clock Drift Window**: Nodes reject messages with timestamps exceeding $\pm 120\text{ seconds}$ of local time unless valid multi-hop routing headers are established.
3. **Nonce Cache**: Nodes maintain a memory table of recent message IDs and nonces. Repeated nonces from the same device ID are dropped.
