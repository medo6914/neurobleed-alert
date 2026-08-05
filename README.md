# NeuroBleed Alert

**AI-Powered Early Brain Hemorrhage Detection** — Graduation Project

A complete medical platform: Android app, Flutter Web app, Admin Dashboard (Flutter Web), Windows desktop, and a FastAPI backend with an AI risk engine, BLE device support, SOS emergency flow, hospital map, reports and real-time monitoring.

## Architecture

| Component | Technology | Location |
|---|---|---|
| Mobile App (Android / iOS / Web / Windows) | Flutter | `apps/mobile_flutter` |
| Web Dashboard | Flutter Web | `apps/web_flutter` |
| Backend | FastAPI + PostgreSQL / SQLite | `backend/fastapi` |
| Shared packages | Dart (core / design_system / shared) | `packages/` |
| AI Engine | scikit-learn / XGBoost / SHAP | `backend/fastapi/app/ai` |

## Getting Started

```bash
# Backend
cd backend/fastapi
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Seed demo users (admin / doctor / patient)
python -m app.seed_data

# Mobile app
cd apps/mobile_flutter
flutter pub get
flutter run
```

### Demo Accounts

| Role | Email | Password |
|---|---|---|
| Admin | `admin@neurobleed.com` | `Admin123!` |
| Doctor | `doctor@neurobleed.com` | `Doctor123!` |
| Patient | `patient@neurobleed.com` | `Patient123!` |

## CI / CD — Cloud Build Pipeline (GitHub Actions)

All builds run automatically on GitHub, no local build required.

| Workflow | Trigger | Produces |
|---|---|---|
| `.github/workflows/android.yml` | push / PR / manual | Debug APK artifact |
| `.github/workflows/web.yml` | push to main / manual | Flutter Web → GitHub Pages |
| `.github/workflows/release.yml` | GitHub Release | Debug APK + Release APK + Web archive attached to the Release |

### 📱 How to Download the Android APK

1. Open the repository on GitHub → **Actions** tab.
2. Select the **Android Build** workflow → latest successful run.
3. Scroll to **Artifacts** → download `app-debug.apk`.
4. Install on the phone (allow "install unknown apps").

> Tip: create a GitHub **Release** and the release workflow attaches `app-debug.apk` and `app-release.apk` directly to the release page.

### 🌐 How to Access the Web App

1. Open the repository on GitHub → **Settings → Pages**.
2. The web build is deployed to GitHub Pages after every push to `main`.
3. Open the Pages URL: `https://<owner>.github.io/<repo>/`.

### 🛡 How to Access the Admin Dashboard

The admin dashboard is the same Flutter Web app — it is role-based:

1. Open the GitHub Pages URL (above).
2. Login with the Admin account: `admin@neurobleed.com` / `Admin123!`.
3. You land in the **Admin Panel** (`/admin`): user management, patients, devices, analytics, alerts, system logs.

### Configuration (Repository Variables / Secrets)

| Name | Where | Used for |
|---|---|---|
| `API_BASE_URL` | Settings → Secrets and variables → Actions → Variables | Web app backend URL (e.g. `https://api.neurobleed.com`) |
| `JKS_BASE64` | Actions → Secrets | Base64 of `neurobleed-keystore.jks` (signed release APK) |
| `KEY_STORE_PASSWORD` | Actions → Secrets | Keystore password |
| `KEY_ALIAS` | Actions → Secrets | Key alias |
| `KEY_PASSWORD` | Actions → Secrets | Key password |

> ⚠️ Never commit `.jks` files, Firebase service-account JSONs, `.env` files, or any credentials — they are already git-ignored.

## Repository Layout

```
apps/
  mobile_flutter/    # Flutter app (android, ios, web, windows, linux, macos)
  web_flutter/       # Flutter Web dashboard
packages/
  core/              # Network, router, storage, localization, repositories
  design_system/     # Colors, typography, reusable components
  shared/            # Domain entities and utilities
backend/
  fastapi/           # FastAPI backend + AI engine
docs/
  ui_reference/      # Design reference images
  presentation/      # Presentation package (QR, links, landing page)
```

## Documentation

- Design reference: `docs/ui_reference/README.md`
- Run guide: `RUN_PROJECT_GUIDE.md`
- Presentation package: `docs/presentation/presentation_links.md`
- Final production report: `FINAL_PRODUCTION_REPORT.md`

## Design Specification Compliance

The UI is implemented strictly from the pixel-verified Vision Design Specification (`docs/ui_reference/DESIGN_SYSTEM.md`).

- **Design tokens only** — every hardcoded color replaced with `NeuroColors` tokens (backgrounds, semantic risk colors, text, gradients, charts). The only remaining literals are spec-verified accent colors (`#AEE4FF`, `#10265A`, `#1ACB58`) and transparency.
- **Dark theme only** — the app is always the spec dark design; the light theme with Material default colors was removed.
- **No default icons** — Android (legacy + adaptive), iOS, web favicon/manifest, splash, login, and admin use the extracted NeuroBleed logo everywhere.
- **Splash** — real logo, elastic scale/fade animation, no white flash (native launch background = dark `#020C23`).
- **Login** — logo, email/password, remember me, forgot password, biometric placeholders, and an animated sign-in button (pulse glow while loading + press feedback).
- **Admin dashboard (8 sections)** — Users, Hospitals, Alerts, Analytics, Devices, Audit Logs, AI Logs, System Health — all wired to real backend endpoints.
- **SOS** — live GPS location status (acquiring / granted + accuracy / disabled), 10s countdown, cancel, emergency call + nearest-hospital shortcut.
- **Map** — OpenStreetMap only; live ETA banner (minutes + distance) from the OSRM route.
- **Reports** — risk gauge, AI analysis, daily recommendations, and a medical timeline.
- **Landing page** — real logo, Hero / Features / AI / Device / Emergency Workflow / Architecture / Demo / QR / Hospitals map / Tech sections; placeholder team members removed.

---

NeuroBleed Alert © 2026 — Graduation Project
