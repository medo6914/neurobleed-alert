# Missing Environment Variables Report

Generated: 2026-07-26

## Legend
- ✅ **Set** — has a real (non-empty, non-placeholder) value
- ⚠️ **Defaulted** — has a default or placeholder value, needs real credential
- ❌ **Missing** — not defined in `.env` or `.env.example`, only in source
- 🚫 **Not in .env.example** — present in source or `.env` but absent from template

---

## Python / Pydantic Settings (`app/config.py`)

These are auto-loaded from `.env` via pydantic-settings `BaseSettings`.

| Variable | Status | Current Value | Source File | Notes |
|---|---|---|---|---|
| `DATABASE_URL` | ✅ | `postgresql+asyncpg://neurobleed:neurobleed_dev@localhost:5432/neurobleed` | `app/config.py:5` | Dev-only value |
| `REDIS_URL` | ✅ | `redis://localhost:6379/0` | `app/config.py:6` | Dev-only; graceful degrade if unavailable |
| `SECRET_KEY` | ⚠️ | `neurobleed-dev-secret-key-not-for-production` | `app/config.py:7` | **Must change for production** |
| `ALGORITHM` | ⚠️ | `HS256` (hardcoded default) | `app/config.py:8` | OK for production |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | ⚠️ | `60` (hardcoded default) | `app/config.py:9` | Adjust as needed |
| `ENVIRONMENT` | ✅ | `development` | `app/config.py:10` | Change to `production` for prod |
| `REFRESH_TOKEN_EXPIRE_DAYS` | ⚠️ | `30` (hardcoded default) | `app/config.py:11` | Adjust as needed |
| `FIREBASE_CREDENTIALS_PATH` | ⚠️ | `./credentials/firebase.json` | `app/config.py:13` | File does not exist |
| `FIREBASE_API_KEY` | ⚠️ | empty | `app/config.py:14` | **REQUIRED for Firebase** |
| `FIREBASE_PROJECT_ID` | ⚠️ | empty | `app/config.py:15` | **REQUIRED for Firebase** |
| `TWILIO_ACCOUNT_SID` | ⚠️ | empty | `app/config.py:17` | **REQUIRED for SMS alerts** |
| `TWILIO_AUTH_TOKEN` | ⚠️ | empty | `app/config.py:18` | **REQUIRED for SMS alerts** |
| `TWILIO_PHONE_NUMBER` | ⚠️ | empty | `app/config.py:19` | **REQUIRED for SMS alerts** |
| `GOOGLE_CLIENT_ID` | ❌ | `None` (missing from `.env`) | `app/config.py:21` | Required for Google OAuth |
| `GOOGLE_CLIENT_SECRET` | ❌ | `None` (missing from `.env`) | `app/config.py:22` | Required for Google OAuth |
| `SMTP_HOST` | ⚠️ | `smtp.gmail.com` | `app/config.py:24` | OK default, needs credentials |
| `SMTP_PORT` | ⚠️ | `587` | `app/config.py:25` | OK default |
| `SMTP_USER` | ⚠️ | empty | `app/config.py:26` | **REQUIRED for email alerts** |
| `SMTP_PASSWORD` | ⚠️ | empty | `app/config.py:27` | **REQUIRED for email alerts** |
| `SMTP_FROM_EMAIL` | ❌ | `noreply@neurobleed.com` (hardcoded) | `app/config.py:28` | Missing from `.env` |
| `REPORT_STORAGE_PATH` | ❌ | `./reports` (hardcoded) | `app/config.py:30` | Missing from `.env` |
| `REPORT_BASE_URL` | ❌ | `/reports` (hardcoded) | `app/config.py:31` | Missing from `.env` |

---

## Python `os.getenv()` (not in pydantic Settings)

| Variable | Status | Current Value | Source File | Notes |
|---|---|---|---|---|
| `PUBMED_EMAIL` | ❌ | Defaults to `ai@neurobleed.local` | `app/ai/pubmed_client.py:8` | Missing from `.env`, needed for NCBI API |
| `PUBMED_API_KEY` | ❌ | Defaults to `""` | `app/ai/pubmed_client.py:9` | Missing from `.env`, recommended by NCBI |

---

## Dart `String.fromEnvironment` / `bool.fromEnvironment` (compile-time defines)

These are passed via `--dart-define` at build time, not from `.env`.

| Variable | Status | Current Value | Source File | Notes |
|---|---|---|---|---|
| `API_BASE_URL` | ⚠️ | `http://localhost:8000` | `env_config.dart:33`, `app_config.dart:3` | Dev default; **MUST override for production** |
| `PRODUCTION` | ⚠️ | `false` | `env_config.dart:37`, `app_config.dart:13` | Must set `true` for production builds |
| `APP_VERSION` | ⚠️ | `1.0.0` | `env_config.dart:47`, `app_config.dart:24` | Must match release version |
| `BUILD_NUMBER` | ⚠️ | `1` | `env_config.dart:49` | Must match release build number |
| `FEATURE_OFFLINE_FIRST` | ⚠️ | `true` | `env_config.dart:51` | Feature flag; OK default |
| `FEATURE_SYNC_ENABLED` | ⚠️ | `true` | `env_config.dart:53` | Feature flag; OK default |
| `FIREBASE_API_KEY` | ⚠️ | `""` | `env_config.dart:62` | **REQUIRED for Firebase** |
| `FIREBASE_PROJECT_ID` | ⚠️ | `""` | `env_config.dart:63` | **REQUIRED for Firebase** |
| `FIREBASE_APP_ID` | ⚠️ | `""` | `env_config.dart:66` | **REQUIRED for Firebase** |
| `USE_FIREBASE_EMULATOR` | ⚠️ | `true` | `app_config.dart:17` | Set `false` for production |

---

## Extra Variables in `.env` / `.env.example` (not consumed by source)

| Variable | Present in `.env` | Present in `.env.example` | Consumed in Source? | Notes |
|---|---|---|---|---|
| `TWILIO_EMERGENCY_PHONE` | ✅ (empty) | ✅ | ❌ No | Safe to remove if unused |
| `OPENAI_API_KEY` | ✅ (empty) | ✅ | ❌ No | Reserved for future AI features |
| `MODEL_PATH` | ✅ | ✅ | ❌ No | Referenced in `ModelManager.MODELS_DIR` by convention |
| `LLM_MODEL` | ✅ | ✅ | ❌ No | Reserved for future LLM features |
| `ALERT_EMAIL` | ✅ | ✅ | ❌ No | Maybe used by email alerting? Not in current source |
| `BACKUP_DIR` | ✅ | ✅ | ❌ No | Not referenced in source |
| `BACKUP_RETENTION_DAYS` | ✅ | ✅ | ❌ No | Not referenced in source |
| `SENTRY_DSN` | ✅ (empty) | ✅ | ❌ No | Not referenced in source |
| `PROMETHEUS_PORT` | ✅ | ✅ | ❌ No | Not referenced in source |
| `GRAFANA_PORT` | ✅ | ✅ | ❌ No | Not referenced in source |
| `MQTT_BROKER` | ✅ | ✅ | ❌ No | Reserved for future IoT features |
| `MQTT_PORT` | ✅ | ✅ | ❌ No | Reserved for future IoT features |
| `MQTT_USERNAME` | ✅ (empty) | ✅ | ❌ No | Reserved for future IoT features |
| `MQTT_PASSWORD` | ✅ (empty) | ✅ | ❌ No | Reserved for future IoT features |
| `PDF_REPORT_URL` | ✅ | ✅ | ❌ No | Not referenced in source |
| `FIREBASE_AUTH_DOMAIN` | ❌ | ✅ | ❌ No | Missing from `.env` |
| `AWS_ACCESS_KEY_ID` | ❌ | ✅ | ❌ No | Missing from `.env` |
| `AWS_SECRET_ACCESS_KEY` | ❌ | ✅ | ❌ No | Missing from `.env` |
| `AWS_BACKUP_BUCKET` | ❌ | ✅ | ❌ No | Missing from `.env` |

---

## Summary

| Category | ✅ Set | ⚠️ Defaulted/Empty | ❌ Missing from `.env` | 🚫 Not in `.env.example` |
|---|---|---|---|---|
| Python Settings | 3 | 15 | 6 | — |
| Python `os.getenv()` | 0 | 0 | 2 | — |
| Dart `fromEnvironment` | 0 | 10 | 0 | — |
| Extra `.env` vars | 0 | 0 | 4 | 6 |

### Critical Gaps (blocks production deployment)

1. **`SECRET_KEY`** — must be a long random string for production
2. **`FIREBASE_CREDENTIALS_PATH`** — file `./credentials/firebase.json` does not exist
3. **`FIREBASE_API_KEY`** / **`FIREBASE_PROJECT_ID`** — needed by both Python and Dart
4. **`FIREBASE_APP_ID`** — needed by Dart; not in `.env.example`
5. **`TWILIO_ACCOUNT_SID`** / **`TWILIO_AUTH_TOKEN`** / **`TWILIO_PHONE_NUMBER`** — required for SMS alerts
6. **`GOOGLE_CLIENT_ID`** / **`GOOGLE_CLIENT_SECRET`** — missing from `.env` entirely; needed for Google OAuth
7. **`SMTP_USER`** / **`SMTP_PASSWORD`** — required for email alerts
8. **`PUBMED_EMAIL`** / **`PUBMED_API_KEY`** — missing from `.env`; needed for NCBI/PubMed queries
9. **All Dart `--dart-define` values** — must be provided at build time for production
