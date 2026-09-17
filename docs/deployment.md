# Production Deployment Guide

## 1. Prerequisites

- **Dart SDK**: `^3.0.0`
- **Flutter SDK**: `^3.19.0`
- **Node.js**: `>= 18.0.0`
- **Firebase CLI**: `npx -y firebase-tools@latest`
- **Docker**: For containerized backend deployment

---

## 2. Mobile App Deployment (Android & iOS)

### Android APK / App Bundle Compilation
```bash
cd apps/mobile

# Build production Android App Bundle (AAB) for Google Play
flutter build appbundle --release

# Or build standalone universal APK for direct side-loading in disaster zones
flutter build apk --release
```
The output APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

### iOS Archive & Distribution
```bash
cd apps/mobile

# Build iOS release archive
flutter build ipa --release
```

---

## 3. Command Center & Backend Deployment (Docker)

### Dockerfile (Backend Gateway)
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY backend/package*.json ./
RUN npm ci --only=production
COPY backend/ ./
EXPOSE 8080
CMD ["node", "server.js"]
```

### Dockerfile (Command Center)
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY apps/command-center/package*.json ./
RUN npm ci --only=production
COPY apps/command-center/ ./
EXPOSE 3000
CMD ["node", "server.js"]
```

---

## 4. Firebase Cloud Services Deployment

```bash
# 1. Login to Firebase CLI
npx firebase login

# 2. Select project
npx firebase use emergixx-disaster-response

# 3. Deploy Firestore rules and indexes
npx firebase deploy --only firestore

# 4. Deploy Realtime Database rules
npx firebase deploy --only database

# 5. Deploy Cloud Functions
npx firebase deploy --only functions
```

---

## 5. Environment Variables Configuration

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Ensure the following production secrets are configured:
- `PORT=8080`
- `NODE_ENV=production`
- `FIREBASE_PROJECT_ID=emergixx-disaster-response`
- `GOV_AUTHORITY_PUBLIC_KEY=0123456789abcdef0123456789abcdef...`
