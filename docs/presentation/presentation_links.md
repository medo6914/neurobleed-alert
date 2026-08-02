# NeuroBleed Alert — Presentation Package

Graduation project presentation links and demo guide.

---

## Links

- **Android APK**: `../../apps/mobile_flutter/build/app/outputs/flutter-apk/app-debug.apk` (see `apk_link.txt`)
- **Flutter Web App (Mobile UI)**: see `web_link.txt`
- **Admin Dashboard (Flutter Web)**: see `admin_link.txt`
- **QR Code**: `qr_demo.png` / `qr_demo.svg` (points to the web app URL)
- **Backend API**: `http://localhost:8000` (Swagger: `http://localhost:8000/docs`)

---

## Demo Accounts

| Role | Email | Password |
|---|---|---|
| Admin | `admin@neurobleed.com` | `Admin123!` |
| Doctor | `doctor@neurobleed.com` | `Doctor123!` |
| Patient | `patient@neurobleed.com` | `Patient123!` |

Seed with: `python -m app.seed_data` (from `backend/fastapi/`)

---

## Demo Flow (for the evaluator)

1. Scan `qr_demo.png` → opens the Flutter Web application.
2. Login as **Doctor** (or scan QR inside the web app).
3. Navigate: Dashboard → Patients → Device → Live Monitoring → Reports → Analytics → Map → Settings.
4. Trigger an **SOS** from a patient detail page — it appears in the admin dashboard instantly.
5. Pair a device (simulation): Devices → Pair New Device.
6. Open the **Admin Dashboard** → login as **Admin** → see the newly registered user / patient / SOS / alerts immediately (same backend, same database).

---

## Files

| File | Purpose |
|---|---|
| `presentation_links.md` | This file |
| `qr_demo.png` / `qr_demo.svg` | QR code → web app URL |
| `apk_link.txt` | Absolute path of the Android APK |
| `web_link.txt` | Deployed Flutter Web URL |
| `admin_link.txt` | Deployed Admin Dashboard URL |
| `demo_accounts.md` | Demo credentials |
| `presentation_checklist.md` | Final verification checklist |
| `index.html` | Presentation landing page (opens when the QR is scanned) |
