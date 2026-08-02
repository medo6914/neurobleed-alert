# FINAL MANUAL ACTIONS — NeuroBleed Alert RC-2

> Generated: 2026-07-26
> Status: **All automated tasks complete. Manual deployment steps required for production.**

---

## 1. API Keys & Credentials Required

| Service       | Variable                 | Where it goes                        | Status         |
|---------------|--------------------------|--------------------------------------|----------------|
| **Firebase**  | `FIREBASE_PROJECT_ID`    | `backend/fastapi/.env`               | ❌ Not set     |
| **Firebase**  | `FIREBASE_API_KEY`       | `backend/fastapi/.env`               | ❌ Not set     |
| **Firebase**  | `FIREBASE_AUTH_DOMAIN`   | `backend/fastapi/.env`               | ❌ Not set     |
| **Twilio**    | `TWILIO_ACCOUNT_SID`     | `backend/fastapi/.env`               | ❌ Not set     |
| **Twilio**    | `TWILIO_AUTH_TOKEN`       | `backend/fastapi/.env`               | ❌ Not set     |
| **Twilio**    | `TWILIO_PHONE_NUMBER`    | `backend/fastapi/.env`               | ❌ Not set     |
| **Twilio**    | `TWILIO_EMERGENCY_PHONE` | `backend/fastapi/.env`               | ❌ Not set     |
| **OpenAI**    | `OPENAI_API_KEY`         | `backend/fastapi/.env`               | ❌ Not set     |
| **SMTP**      | `SMTP_HOST`              | `backend/fastapi/.env`               | ❌ Not set     |
| **SMTP**      | `SMTP_PORT`              | `backend/fastapi/.env`               | ❌ Not set     |
| **SMTP**      | `SMTP_USER`              | `backend/fastapi/.env`               | ❌ Not set     |
| **SMTP**      | `SMTP_PASSWORD`          | `backend/fastapi/.env`               | ❌ Not set     |
| **AWS**       | `AWS_ACCESS_KEY_ID`      | `backend/fastapi/.env`               | ❌ Not set     |
| **AWS**       | `AWS_SECRET_ACCESS_KEY`  | `backend/fastapi/.env`               | ❌ Not set     |
| **Sentry**    | `SENTRY_DSN`             | `backend/fastapi/.env`               | ❌ Not set     |
| **Secret**    | `SECRET_KEY`             | `backend/fastapi/.env`               | ⚠️ Default     |
| **JWT**       | (used in config)         | `backend/fastapi/.env`               | ⚠️ Default     |

## 2. Missing Files

| File                                    | Required For                | Status         |
|-----------------------------------------|-----------------------------|----------------|
| `google-services.json`                  | Android Firebase Auth + FCM | ❌ Missing     |
| `GoogleService-Info.plist`              | iOS Firebase Auth + FCM     | ❌ Missing     |
| `firebase-adminsdk.json`                | Backend Firebase Admin SDK  | ❌ Missing     |
| `android/app/upload-keystore.jks`       | APK/AAB signing             | ❌ Missing     |
| `android/key.properties`               | Android signing config      | ❌ Missing     |
| App launcher icons (custom)             | Branded app icon            | ⚠️ Default only |

## 3. Certificate Requirements

| Certificate        | Purpose                      | Provider                    |
|--------------------|------------------------------|-----------------------------|
| Android Keystore   | Sign APK/AAB for Play Store  | Self-generated via `keytool` |
| Apple P12 / P8     | Push notifications + Sign in with Apple | Apple Developer Account |
| SSL/TLS Certificate| HTTPS for production backend | Let's Encrypt / CA          |

## 4. External Accounts

| Account                      | Purpose                                      |
|------------------------------|----------------------------------------------|
| **Google Firebase**          | Push notifications, auth, Firestore          |
| **Google Play Console**      | Android app distribution                     |
| **Apple Developer**          | iOS app distribution, push notifications     |
| **Twilio**                   | SMS/OTP, emergency SOS alerts                |
| **OpenAI**                   | AI predictions, RAG engine                   |
| **Sentry**                   | Error tracking (optional)                    |
| **AWS**                      | S3 backup bucket (optional)                  |
| **SMTP Provider**            | Email alerts, password reset                 |
| **GitHub**                   | CI/CD pipeline (optional)                    |

## 5. Software Development Kits (SDKs)

| SDK              | Required For       | Install Guide                                      |
|------------------|--------------------|----------------------------------------------------|
| Android SDK      | APK/AAB builds     | `flutter config --android-sdk <path>`              |
| Visual Studio    | Windows builds     | Install "Desktop development with C++" workload    |
| Xcode (macOS)    | iOS builds         | macOS only, install via App Store                  |
| CocoaPods (macOS)| iOS dependencies   | `sudo gem install cocoapods`                       |

## 6. Manual Deployment Steps

### 6.1 Backend

```bash
# 1. Install PostgreSQL + Redis (or use cloud equivalents)
# 2. Configure .env with real values
# 3. Run database migrations
cd backend/fastapi
alembic upgrade head
# 4. Seed initial data (roles, permissions, admin user)
python -m app.seed_data
# 5. Start server with production config
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
# 6. Set up reverse proxy (nginx/caddy) with SSL
# 7. Set up systemd service or Docker container for auto-restart
```

### 6.2 Flutter Android

```bash
# 1. Install Android SDK (set ANDROID_HOME)
# 2. Create keystore:
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# 3. Create android/key.properties:
#     storePassword=<password>
#     keyPassword=<password>
#     keyAlias=upload
#     storeFile=app/upload-keystore.jks

# 4. Build:
cd apps/mobile_flutter
flutter build apk --release
flutter build appbundle --release

# 5. Upload AAB to Google Play Console
```

### 6.3 Flutter iOS (macOS only)

```bash
cd apps/mobile_flutter
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode
# Configure signing team
# Product → Archive
# Upload to App Store Connect
```

### 6.4 Flutter Web

```bash
cd apps/mobile_flutter
flutter build web --release
# Deploy build/web/ to: Vercel, Netlify, Firebase Hosting, S3, etc.
```

### 6.5 Flutter Windows (Visual Studio required)

```bash
cd apps/mobile_flutter
flutter build windows --release
# Distribute the build/windows/runner/Release/ folder
```

### 6.6 Firebase Setup

```text
1. Create Firebase project: https://console.firebase.google.com
2. Enable Authentication methods:
   - Email/Password
   - Google Sign-In
   - Apple Sign-In
3. Enable Cloud Firestore
4. Enable Cloud Messaging (FCM)
5. Download google-services.json → android/app/
6. Download GoogleService-Info.plist → ios/Runner/
7. Generate service account key → backend/fastapi/credentials/firebase.json
8. Update .env:
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_API_KEY=your-api-key
   FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
   FIREBASE_CREDENTIALS_PATH=./credentials/firebase.json
```

### 6.7 Twilio Setup

```text
1. Create Twilio account: https://twilio.com
2. Buy a phone number with SMS capabilities
3. Copy Account SID and Auth Token
4. Update .env:
   TWILIO_ACCOUNT_SID=your-sid
   TWILIO_AUTH_TOKEN=your-token
   TWILIO_PHONE_NUMBER=+1234567890
   TWILIO_EMERGENCY_PHONE=+1234567890
```

## 7. Remaining Hardware Validation

| Item                           | Status                | Notes                                              |
|--------------------------------|-----------------------|----------------------------------------------------|
| BLE real device scan           | 🔶 Code ready, no HW  | Test with ESP32, nRF Connect, or BLE peripheral    |
| BLE connect/disconnect         | 🔶 Code ready, no HW  | Requires real BLE device paired                    |
| BLE read/write characteristic  | 🔶 Code ready, no HW  | Test with specific service UUIDs                   |
| BLE notifications              | 🔶 Code ready, no HW  | Requires device that sends notifications           |
| BLE MTU negotiation            | 🔶 Code ready, no HW  | Automatic in flutter_blue_plus                     |
| BLE reconnection               | 🔶 Code ready, no HW  | Test after connection drop                         |
| Android 12/13/14 permissions   | 🔶 Code ready, no HW  | Test on physical Android 12+ device                |
| iOS BLE permissions            | 🔶 Code ready, no HW  | Test on physical iOS device                        |

## 8. Remaining iOS-Only Steps

| Step                               | Requirement               |
|------------------------------------|---------------------------|
| Archive build via Xcode            | macOS + Xcode 15+         |
| Code signing with Apple Developer  | Apple Developer Account   |
| App Store Connect setup            | Apple Developer Account   |
| TestFlight distribution            | Apple Developer Account   |
| Push notification certificates     | Apple Developer Account   |

## 9. Items Impossible to Automate

1. Creating Firebase project and downloading credentials
2. Creating Twilio account and purchasing phone number
3. Creating Apple Developer account
4. Creating Google Play Console account
5. Physical BLE peripheral testing (ESP32, nRF Connect, etc.)
6. Physical device testing (multiple Android/iOS versions)
7. Keystore generation for Android signing
8. Android SDK installation and configuration
9. Visual Studio installation for Windows builds
10. Production SSL certificate setup
11. DNS configuration for production domain
12. Manual QA testing of every screen and button
13. App Store / Play Store listing creation
14. Privacy policy and terms of service generation
15. CI/CD pipeline configuration (GitHub Actions, etc.)

## 10. Production Configuration Checklist

- [ ] `SECRET_KEY` changed to random 64+ char string
- [ ] `ENVIRONMENT=production`
- [ ] `DATABASE_URL` points to production PostgreSQL
- [ ] `REDIS_URL` points to production Redis
- [ ] All Firebase secrets filled in
- [ ] All Twilio secrets filled in
- [ ] CORS origins limited to production domains
- [ ] Rate limiting enabled
- [ ] HTTPS enforced
- [ ] Database backup configured
- [ ] Monitoring (Sentry / Prometheus) configured
- [ ] CI/CD pipeline set up
- [ ] Automated tests pass in CI
