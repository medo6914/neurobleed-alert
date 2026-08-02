# NeuroBleed Alert - Agent Instructions

## Project Structure
- `apps/mobile_flutter/` - Flutter mobile app (Clean Architecture)
- `backend/fastapi/` - FastAPI Python backend
- `packages/core/` - Shared Dart core library
- `packages/shared/` - Shared Dart models/utilities
- `packages/design_system/` - Shared Flutter UI components

## Android Build (Critical)
- Java home: `F:\jdk21`
- Android SDK: `F:\Android\Sdk`
- GRADLE_USER_HOME: `F:\Android\Gradle`
- Gradle version: 9.1.0
- AGP version: 8.11.1
- Gradle wrapper uses `--no-daemon --offline` for reliability
- **ALWAYS set `JAVA_TOOL_OPTIONS=-Djava.net.preferIPv4Stack=true`** to prevent IPv6 DNS hangs
- Batch file for signing report: `C:\Users\medom\signing_report.bat`
- NDK: `F:\Android\Sdk\ndk\28.2.13676358`

## Gradle Build Troubleshooting
If Gradle hangs during build:
1. Kill any stale Java processes: `taskkill /F /IM java.exe`
2. Clean stale lock files: `del "F:\Android\Gradle\caches\modules-2\modules-2.lock" /f`
3. Clean daemon registry: `del "F:\Android\Gradle\daemon\9.1.0\registry.bin" /f /q`
4. Re-run with `--no-daemon --offline`

## ADB/WiFi
- Device IP: 192.168.1.3 (port 5555)
- Connect: `adb connect 192.168.1.3`
- Device is a physical Android device (not emulator)

## Backend
- FastAPI with PostgreSQL (async SQLAlchemy)
- Firebase Admin SDK for notifications
- Twilio for SMS
- ML/AI: scikit-learn, xgboost, shap
- Start: `uvicorn main:app --reload` in `backend/fastapi/`

## Running Tests
- Flutter: `flutter test` (no specific test runner metadata found)
- Python: `pytest` in `backend/fastapi/`
- Lint: `dart analyze` for Flutter, `ruff` for Python
