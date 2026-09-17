# Firebase Cloud Services Integration

## 1. Overview

While Emergixx is built to be 100% operational offline, Google Cloud & Firebase provide centralized cloud synchronization, push alerting, command center reporting, and authoritative government broadcast capabilities when connectivity is available.

---

## 2. Firebase Services Architecture

```
+-------------------------------------------------------------------------+
|                    EMERGIXX FIREBASE CLOUD TOPOLOGY                     |
+-------------------------------------------------------------------------+

  [ Mobile Mesh Network ]                          [ Cloud Infrastructure ]
             |
             v (Opportunistic Uplink)
   +--------------------+       HTTPS       +-----------------------------+
   | Mobile Gateway     |==================>| Firebase Cloud Functions    |
   | Node EX-7A29F1     |                   |  - onSosCreated             |
   +--------------------+                   |  - onCheckInCreated         |
                                            |  - pruneExpiredMessagesCron |
                                            +-----------------------------+
                                                           |
                      +------------------------------------+------------------------------------+
                      |                                    |                                    |
                      v                                    v                                    v
        +---------------------------+        +---------------------------+        +---------------------------+
        |      Cloud Firestore      |        | Realtime Database (RTDB)  |        | Firebase Cloud Messaging  |
        |  - /emergencies           |        |  - /presence              |        |  - /topics/responders     |
        |  - /checkins              |        |  - /active_clusters       |        |  - Critical Audio Sirens  |
        |  - /broadcasts            |        +---------------------------+        +---------------------------+
        |  - /responders            |
        +---------------------------+
```

---

## 3. Configuration & Files

- **`firebase.json`**: Configures Firebase Emulators, Firestore rules and indexes, RTDB rules, Storage rules, and Cloud Functions.
- **`.firebaserc`**: Target project pointer (`emergixx-disaster-response`).
- **`firestore.rules`**: Granular security rules governing document read/writes.
- **`database.rules.json`**: Low-latency RTDB presence rules.
- **`storage.rules`**: Secure file attachments (damage photos, evacuation maps).

---

## 4. Local Emulator Development

Emergixx supports testing the entire cloud integration suite 100% offline using the Firebase Local Emulator Suite:

```bash
# Start all emulators
npx -y firebase-tools emulators:start \
  --only auth,firestore,database,functions,storage
```

| Emulator | Port | Description |
| :--- | :--- | :--- |
| **Emulator UI** | `4000` | Web dashboard for inspecting data and logs |
| **Auth** | `9099` | Anonymous & responder phone authentication |
| **Firestore** | `8080` | Document database |
| **Database (RTDB)**| `9000` | Realtime presence & clusters |
| **Functions** | `5001` | Cloud Functions triggers |
| **Storage** | `9199` | Local blob storage |
