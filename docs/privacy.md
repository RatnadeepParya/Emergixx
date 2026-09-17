# Privacy & Data Protection Architecture

## 1. Privacy First Principles

Emergixx is engineered to safeguard user privacy while preserving life-safety capabilities:
- **No PII Collection by Default**: Users are not required to provide their real names, phone numbers, email addresses, or social identities to use Emergixx.
- **Ephemeral Device Identifiers**: To prevent physical tracking of survivors by radio packet sniffers, Bluetooth LE MAC addresses rotate periodically per OS standards, and the protocol supports rotating ephemeral identifiers (`ephemeralId`).
- **Zero-Knowledge Relaying**: Intermediate couriers transport ciphertext without knowing who is talking to whom beyond the pseudonymous `EX-XXXXXX` routing tokens.

---

## 2. Medical Data Privacy (Emergency Card)

Emergency medical data (blood type, allergies, medications, emergency contacts) is:
1. **Locally Encrypted**: Stored in the device hardware-backed secure storage (`SecureIdentityStore`).
2. **Selective Disclosure**: Only attached to explicitly user-initiated emergency distress beacons (`triggerSos()`).
3. **Never Shared in Normal Chat**: Regular peer-to-peer chat packets contain zero medical or biometric metadata.

---

## 3. Automatic Data Purging & Retention

To comply with data minimization principles:
- **Normal Chat Messages**: Retained for a maximum of 48 hours in local SQLite storage before being automatically deleted.
- **Resolved SOS Alerts**: Automatically removed from active triage queues once marked resolved.
- **Deduplication LRU Cache**: Entries in `SeenMessagesIndex` expire after 72 hours.
- **User-Initiated Wipe**: The Settings screen includes an immediate **Reset Cryptographic Identity & Clear Storage** action that destroys the master seed, wipes all SQLite tables, and purges all cached keys.

---

## 4. Cloud Data Safeguards

When data is synchronized to Cloud Firestore:
- Private chat messages are **never synchronized to the cloud**. Only public emergency distress alerts (`/emergencies`) and safety check-ins (`/checkins`) are ingested.
- All communications with the cloud gateway occur exclusively over TLS 1.3.
