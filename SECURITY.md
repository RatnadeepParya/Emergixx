# Security Policy

## Life-Safety & Threat Model

Emergixx is an emergency communication protocol and mobile application deployed during natural disasters, infrastructure blackouts, and search-and-rescue operations. Because users may rely on Emergixx in life-threatening scenarios, we treat security vulnerabilities with extreme urgency.

### Core Guarantees
1. **Zero-Trust Relaying**: Any device in the mesh may relay messages for any other device without being able to read encrypted message contents.
2. **Tamper-Resistant Signatures**: All messages, emergency SOS broadcasts, and safety check-ins are cryptographically signed with Ed25519.
3. **Replay & Amplification Immunity**: Nonce caches and timestamp validation prevent packet replaying, and hop limits/deduplication prevent mesh broadcast storms.
4. **Verified Civil Alerts**: Official emergency broadcasts require signature verification against an established authority public key.

---

## Supported Versions

Only the latest active protocol release receives security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.x (EMERGIXX/1) | :white_check_mark: |
| < 1.0   | :x:                |

---

## Reporting a Vulnerability

**DO NOT file public GitHub issues for security vulnerabilities.**

To report a vulnerability:
1. Privately disclose the issue via GitHub Security Advisories:
   [https://github.com/RatnadeepParya/Emergixx/security/advisories/new](https://github.com/RatnadeepParya/Emergixx/security/advisories/new)
2. Include:
   - Vulnerability category (e.g. Cryptographic flaw, Denial of Service / Mesh storm, Replay attack, Identity spoofing)
   - Detailed proof of concept or reproduction script
   - Expected impact on offline nodes and relay reliability
3. The maintainers will acknowledge receipt within 24 hours and provide a CVE / patch timeline.
