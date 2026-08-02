# RELEASE CHECKLIST — NeuroBleed Alert RC-2

> Use this checklist to verify production readiness before each release.

---

## Pre-Build

- [ ] `flutter analyze` passes with 0 errors, 0 warnings
- [ ] `flutter test` passes 50/50
- [ ] `pytest` passes 119/133 (14 skipped OK)
- [ ] No `TODO`, `FIXME`, `HACK`, `MOCK`, `SIMULATED`, `DEBUG`, `PRINT` in source
- [ ] No placeholder pages (Text placeholders)
- [ ] `pubspec.yaml` version number updated
- [ ] All merge conflicts resolved
- [ ] All branches merged to main

## Environment & Credentials

- [ ] `SECRET_KEY` set to unique random value (64+ chars)
- [ ] `ENVIRONMENT=production`
- [ ] `DATABASE_URL` points to production PostgreSQL
- [ ] `REDIS_URL` points to production Redis
- [ ] `FIREBASE_PROJECT_ID` set
- [ ] `FIREBASE_API_KEY` set
- [ ] `FIREBASE_AUTH_DOMAIN` set
- [ ] `FIREBASE_CREDENTIALS_PATH` points to valid service account JSON
- [ ] `TWILIO_ACCOUNT_SID` set
- [ ] `TWILIO_AUTH_TOKEN` set
- [ ] `TWILIO_PHONE_NUMBER` set (purchased number with SMS)
- [ ] `TWILIO_EMERGENCY_PHONE` set (verified emergency number)
- [ ] `OPENAI_API_KEY` set
- [ ] `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASSWORD` configured
- [ ] `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` set (if using S3 backups)
- [ ] `SENTRY_DSN` configured
- [ ] CORS origins set to production domain(s)

## Android Build

- [ ] Android SDK installed (API 34+)
- [ ] ANDROID_HOME environment variable set
- [ ] `google-services.json` in `android/app/`
- [ ] `android/key.properties` configured with keystore path
- [ ] Keystore generated and backed up securely
- [ ] `minSdk = 21` confirmed in `build.gradle.kts`
- [ ] App icon replaced with custom branded design
- [ ] App name in `AndroidManifest.xml` set
- [ ] BLE permissions in `AndroidManifest.xml` verified
- [ ] `flutter build apk --release` succeeds
- [ ] `flutter build appbundle --release` succeeds
- [ ] APK signed and verified (`jarsigner -verify`)
- [ ] APK installed and launches on physical Android device
- [ ] BLE permissions granted on Android 12+ device
- [ ] BLE permissions granted on Android 13+ device

## iOS Build

- [ ] macOS + Xcode 15+ available
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Apple Developer account active
- [ ] Bundle identifier matches App Store Connect
- [ ] Signing team selected in Xcode project
- [ ] `NSBluetoothAlwaysUsageDescription` set in `Info.plist`
- [ ] `NSBluetoothPeripheralUsageDescription` set in `Info.plist`
- [ ] `flutter build ios --release` succeeds
- [ ] Archive created and validated in Xcode
- [ ] TestFlight build uploaded and distributed

## Web Build

- [ ] `flutter build web --release` succeeds
- [ ] `build/web/` deployed to hosting provider (Vercel/Netlify/Firebase/S3)
- [ ] HTTPS configured
- [ ] PWA manifest updated
- [ ] SEO meta tags added

## Windows Build (optional)

- [ ] Visual Studio with "Desktop development with C++" installed
- [ ] `flutter build windows --release` succeeds

## Backend Deployment

- [ ] PostgreSQL server running and accessible
- [ ] Redis server running and accessible
- [ ] `alembic upgrade head` runs without errors
- [ ] Seed data loaded (roles, permissions, admin user)
- [ ] `.env` file in `backend/fastapi/` fully configured
- [ ] Gunicorn/uvicorn serving with 4+ workers
- [ ] Reverse proxy (nginx/Caddy) configured with SSL
- [ ] Systemd service or Docker container configured for auto-restart
- [ ] Health endpoint (`/health`) responds 200
- [ ] Database backups configured with retention policy
- [ ] Log rotation configured
- [ ] Rate limiting enabled

## Firebase Validation (Requires Credentials)

- [ ] Firebase Authentication: Email/Password login works
- [ ] Firebase Authentication: Google login works
- [ ] Firebase Authentication: Apple login works
- [ ] FCM token generated on app startup
- [ ] Foreground push notifications received
- [ ] Background push notifications received
- [ ] Notification tap navigates to correct screen
- [ ] Topic-based push subscriptions work
- [ ] Firestore read/write operations work

## Twilio Validation (Requires Credentials)

- [ ] SMS OTP sent to phone number
- [ ] OTP verification flow completes successfully
- [ ] Emergency SOS SMS sends to emergency contact
- [ ] Error handling: invalid phone number
- [ ] Error handling: API timeout
- [ ] Error handling: rate limit exceeded

## BLE Hardware Validation (Physical Device Required)

- [ ] Android 12+ scan permission dialog appears
- [ ] Android 13+ nearby devices permission dialog appears
- [ ] Scan discovers real BLE devices (ESP32, nRF Connect, etc.)
- [ ] Connect to BLE peripheral succeeds
- [ ] Service discovery returns real services
- [ ] Characteristic read returns expected data
- [ ] Characteristic write succeeds
- [ ] Notifications received from BLE peripheral
- [ ] Disconnect works gracefully
- [ ] Reconnection works after unexpected disconnect
- [ ] BLE disabled state shows appropriate message
- [ ] Permissions denied state shows appropriate message
- [ ] iOS BLE permissions requested correctly

## Manual QA

### Authentication
- [ ] Splash → Onboarding → Login flow works
- [ ] Register new account completes
- [ ] Login with existing account works
- [ ] Forgot password flow works
- [ ] Reset password flow works
- [ ] Logout works
- [ ] JWT token refresh works
- [ ] Session persists across app restart

### Navigation
- [ ] All 60 routes navigable without errors
- [ ] Bottom navigation works (ShellScreen)
- [ ] Back navigation works correctly
- [ ] Deep linking works

### Dashboard
- [ ] Dashboard loads with correct data
- [ ] Quick action buttons work
- [ ] Activity feed displays

### Patients
- [ ] Patient search returns results
- [ ] Register new patient form submits
- [ ] Patient detail screen loads correctly
- [ ] Patient edit works
- [ ] Admission screen works
- [ ] Discharge screen works
- [ ] Patient notes add/view works
- [ ] Medical info screen works
- [ ] Emergency contacts screen works
- [ ] Medical timeline loads
- [ ] Vitals history displays
- [ ] Alerts history loads
- [ ] Risk history loads
- [ ] Audit history loads

### Devices
- [ ] Device list loads
- [ ] Device detail screen loads
- [ ] Register device works
- [ ] Edit device works
- [ ] Assign device works
- [ ] Device health screen loads
- [ ] Device diagnostics loads
- [ ] OTA update screen loads
- [ ] Device history loads
- [ ] Pair device scan works
- [ ] Provision device works

### Monitoring
- [ ] Live monitoring screen loads
- [ ] Patient monitor screen loads

### AI
- [ ] AI dashboard loads
- [ ] Risk assessment triggers
- [ ] Risk history displays

### Analytics
- [ ] Analytics dashboard loads
- [ ] Patient analytics loads
- [ ] Device fleet screen loads
- [ ] Alert analytics loads
- [ ] Hospital admin screen loads

### Emergency
- [ ] SOS screen loads
- [ ] Countdown timer works
- [ ] Cancel works during countdown
- [ ] SOS sends (with backend + Twilio)

### Reports
- [ ] Reports screen loads
- [ ] Report list displays from API
- [ ] Preview/download actions show appropriate message

### Notifications
- [ ] Notifications screen loads
- [ ] Subscription data displays
- [ ] Dismiss notifications works (swipe)

### Admin Panel
- [ ] Admin screen loads
- [ ] System stats display
- [ ] Management menu items navigate correctly
- [ ] System information displays

### Settings
- [ ] Settings screen loads
- [ ] Dark mode toggle works
- [ ] Language toggle works
- [ ] Profile info displays

### Knowledge Center
- [ ] Knowledge center loads
- [ ] Search works
- [ ] Category filter works

### General UI
- [ ] All forms validate correctly
- [ ] All error states display appropriate messages
- [ ] All loading states display spinners
- [ ] No white screens on any navigation
- [ ] No unhandled exceptions
- [ ] Pull-to-refresh works on list screens
- [ ] Empty states display correctly
- [ ] Responsive layout works on phone
- [ ] Responsive layout works on tablet
- [ ] Responsive layout works on desktop (web)
- [ ] No overflow or clipped widgets
- [ ] All animations smooth

## Post-Release

- [ ] Monitor Sentry for production errors (first 24 hours)
- [ ] Monitor server health and performance
- [ ] Check Firebase Console for auth activity
- [ ] Verify push notification delivery rates
- [ ] Verify SMS delivery (Twilio console)
- [ ] Check database backup ran successfully
- [ ] Review server access logs
- [ ] Confirm SSL certificate valid
- [ ] Confirm DNS resolution correct
- [ ] Run smoke test in production
