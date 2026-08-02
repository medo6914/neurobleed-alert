# Phase 8 Execution Plan — Hospital Platform

**Target Branch**: `phase8-hospital-platform` (create from `phase7-development`)  
**Duration**: 4 weeks (estimated)  
**MoSCoW Priority**: Must Have  
**Dependencies**: Phases 4, 5, 6, 7  

---

## 1. Goals

1. **Full Patient Management** — CRUD + search + filter backend and Flutter UI
2. **Device Management** — Register, pair, assign devices to patients
3. **Alert Management** — Create, list, acknowledge, escalate alerts
4. **Clinical Reports** — PDF/HTML report generation for patient summaries
5. **Risk Assessment Dashboard** — Display AI risk scores per patient per device
6. **Knowledge Center** — Searchable medical guidelines (Phase 7 RAG + new Flutter UI)
7. **Emergency Workflow** — SOS button, emergency contact sequence, SMS alerts
8. **FHIR/HL7 Compatibility** — Adapter layer for hospital interoperability

---

## 2. Deliverables

| ID | Task | MoSCoW | Owner | Dependencies |
|----|------|--------|-------|-------------|
| M9-01 | Patient CRUD Backend API | Must Have | Backend | E1-01 (Phase 1) |
| M9-02 | Patient List Screen (Flutter Mobile) | Must Have | Flutter | M9-01 |
| M9-03 | Patient Detail Screen (Flutter Mobile) | Must Have | Flutter | M9-02 |
| M9-04 | Patient Management (Flutter Web) | Must Have | Flutter | M9-01 |
| M9-05 | Device CRUD Backend API | Must Have | Backend | E1-01 |
| M9-06 | Device Management Screen (Flutter) | Must Have | Flutter | M9-05 |
| M9-07 | Alert CRUD Backend API | Must Have | Backend | M9-01 |
| M9-08 | Alert List Screen (Flutter Mobile) | Must Have | Flutter | M9-07 |
| M9-09 | Clinical Reports Generator | Should Have | Backend | M9-01 |
| M9-10 | Risk Assessment Dashboard | Should Have | Full Stack | AI8-02, M9-01 |
| M9-11 | Knowledge Center | Could Have | Full Stack | AI8-04 (Phase 7) |
| M9-12 | Emergency Workflow | Should Have | Full Stack | M9-07 |
| M9-13 | Subscription / Billing API | Should Have | Backend | I2-01 |
| M9-14 | Subscription Management Screen (Web) | Should Have | Flutter Web | M9-13 |
| M9-15 | PDF Report Export | Should Have | Backend | M9-09 |
| M9-16 | Support Ticket System (In-App) | Could Have | Full Stack | — |
| M9-17 | Training Portal (Web) | Could Have | Flutter Web | — |
| A3-05 | FHIR R4 API Adapter | Should Have | Backend | M9-01 |
| A3-06 | HL7 v2 Message Parser | Should Have | Backend | M9-01 |

---

## 3. Architecture

### Backend Architecture Additions

```
backend/fastapi/app/
├── api/v1/
│   ├── patients.py          (new or extend existing)
│   ├── devices.py           (extend existing)
│   ├── alerts.py            (new or extend existing)
│   ├── clinical_reports.py  (new)
│   ├── emergency.py         (new)
│   ├── subscriptions.py     (new)
│   └── fhir.py              (new — FHIR adapter)
├── models/
│   ├── patient.py           (extend)
│   ├── device.py            (extend)
│   ├── alert.py             (extend)
│   ├── clinical_report.py   (new)
│   ├── emergency_contact.py (new)
│   └── subscription.py      (new)
├── schemas/
│   ├── patient.py           (extend)
│   ├── device.py            (extend)
│   ├── alert.py             (extend)
│   ├── clinical_report.py   (new)
│   └── emergency.py         (new)
├── services/
│   ├── patient_service.py   (new — domain logic)
│   ├── alert_service.py     (new — escalation engine)
│   ├── report_generator.py  (new — PDF/HTML)
│   └── emergency_service.py (new — SMS + escalation)
├── core/
│   ├── fhir_mapping.py      (new — FHIR resources)
│   └── hl7_parser.py        (new — HL7 v2)
└── integrations/
    ├── sms_provider.py      (new — Twilio/SES)
    └── email_provider.py    (new — SendGrid/SES)
```

### Flutter Architecture Additions

```
apps/mobile_flutter/lib/
├── features/
│   ├── patients/
│   │   ├── screens/         (list, detail, form)
│   │   ├── providers/       (CRUD state management)
│   │   └── widgets/         (patient card, search)
│   ├── devices/
│   │   ├── screens/         (list, pairing, diagnostics)
│   │   └── providers/
│   ├── alerts/
│   │   ├── screens/         (list, detail, filter)
│   │   └── providers/
│   ├── reports/
│   │   ├── screens/         (report list, viewer)
│   │   └── providers/
│   ├── emergency/
│   │   ├── screens/         (SOS, contact form)
│   │   └── providers/
│   └── knowledge/
│       ├── screens/         (search, browse, view)
│       └── providers/       (wires to Phase 7 AI RAG)

packages/core/lib/
├── network/
│   ├── endpoints/
│   │   ├── patient_endpoints.dart   (new)
│   │   ├── device_endpoints.dart    (extend)
│   │   ├── alert_endpoints.dart     (new)
│   │   ├── report_endpoints.dart    (new)
│   │   └── emergency_endpoints.dart (new)
│   └── dtos/
│       ├── patient/                 (new)
│       ├── device/                  (extend)
│       └── alert/                   (new)
└── models/
    ├── patient.dart                 (new — domain model)
    ├── alert.dart                   (new)
    └── report.dart                  (new)
```

---

## 4. API Changes

### New Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/patients` | List patients (search, filter, paginate) |
| POST | `/v1/patients` | Create patient |
| GET | `/v1/patients/{id}` | Get patient details |
| PUT | `/v1/patients/{id}` | Update patient |
| DELETE | `/v1/patients/{id}` | Soft-delete patient |
| GET | `/v1/patients/{id}/history` | Patient full history (vitals + AI reports) |
| GET | `/v1/devices` | List devices |
| POST | `/v1/devices/register` | Register device |
| PUT | `/v1/devices/{id}/pair` | Pair device to patient |
| GET | `/v1/devices/{id}/diagnostics` | Device diagnostics |
| GET | `/v1/alerts` | List alerts (filter by severity, status) |
| PUT | `/v1/alerts/{id}/acknowledge` | Acknowledge alert |
| POST | `/v1/alerts/escalate` | Trigger escalation |
| GET | `/v1/reports/{patient_id}` | Generate clinical report (PDF/HTML) |
| POST | `/v1/emergency/sos` | Trigger emergency workflow |
| POST | `/v1/emergency/contacts` | Manage emergency contacts |
| GET | `/v1/fhir/Patient/{id}` | FHIR R4 patient resource |
| POST | `/v1/fhir/$export` | FHIR bulk export |
| POST | `/v1/billing/subscribe` | Create subscription |
| GET | `/v1/billing/invoices` | List invoices |

### Existing Endpoints Modified

- `POST /v1/ai/risk/assess` — Link assessment to device_id (add optional field)
- `GET /v1/ai/dashboard/stats` — Add active_devices, alerts_by_severity fields
- `POST /v1/auth/register` — Add hospital_id, subscription_tier fields

---

## 5. Flutter Changes

### New Screens

| Screen | Route | Description |
|--------|-------|-------------|
| Patient List | `/patients` | Search, filter, sort, paginate |
| Patient Detail | `/patients/:id` | Vitals, AI reports, device info |
| Patient Form | `/patients/new`, `/patients/:id/edit` | Create/edit patient |
| Device List | `/devices` | Registered devices, status |
| Device Pairing | `/devices/pair` | BLE/QR pairing flow |
| Alert List | `/alerts` | Filter by severity, acknowledge |
| Report Viewer | `/reports/:id` | PDF viewer |
| Emergency SOS | `/emergency` | One-tap SOS with countdown |
| Knowledge Center | `/knowledge` | Search + browse medical guidelines |
| Subscription | `/settings/subscription` | Plan management |

### New Providers

| Provider | State | Description |
|----------|-------|-------------|
| `patientListProvider` | `AsyncValue<List<Patient>>` | Paginated patient list |
| `patientDetailProvider` | `AsyncValue<Patient>` | Single patient with full history |
| `deviceListProvider` | `AsyncValue<List<Device>>` | Device registry |
| `devicePairingProvider` | `DevicePairingState` | BLE pairing state machine |
| `alertListProvider` | `AsyncValue<List<Alert>>` | Alert feed |
| `alertAcknowledgeProvider` | `AsyncValue<void>` | Acknowledge mutation |
| `reportProvider` | `AsyncValue<Report>` | Report generation |
| `emergencyProvider` | `EmergencyState` | SOS + contact management |
| `subscriptionProvider` | `AsyncValue<Subscription>` | Billing state |

---

## 6. Database Changes

### New Migrations

| Table | Purpose |
|-------|---------|
| `clinical_reports` | Generated PDF/HTML report metadata |
| `emergency_contacts` | Patient emergency contacts |
| `emergency_events` | SOS event log |
| `subscriptions` | Hospital subscription/billing |
| `invoices` | Billing records |
| `support_tickets` | In-app support system |

### Existing Tables — Extended Columns

| Table | New Columns |
|-------|-------------|
| `patients` | `hospital_id` (FK), `insurance_provider`, `emergency_contact_id`, `advanced_directives` (JSON) |
| `devices` | `firmware_version`, `last_diagnostic_at`, `battery_level`, `signal_strength` |
| `alerts` | `escalation_level`, `acknowledged_by` (FK), `acknowledged_at`, `notes` |
| `ai_reports` | `device_id` (FK), `review_notes` |
| `users` | `hospital_id` (FK), `subscription_tier`, `email_verified_at` |

### FHIR/HL7 Tables

| Table | Purpose |
|-------|---------|
| `fhir_resources` | FHIR resource cache |
| `hl7_messages` | Inbound HL7 v2 message log |
| `hl7_mappings` | HL7 segment → DB field mapping |

---

## 7. AI Changes (Phase 7 Integration)

- **Risk Assessment Dashboard**: Wires `DashboardStatsResponse` from Phase 7 into new full-screen dashboard with per-patient filtering
- **Knowledge Center**: Wires `KnowledgeSearchResponse` from Phase 7 RAG into dedicated screen with browse categories
- **Reports**: Includes SHAP explanation and AI risk trend in clinical PDF reports
- **Alerts**: AI risk scores trigger alert creation when exceeding configurable thresholds

---

## 8. Hardware Impact

- Device management APIs must align with ESP32-S3 sensor data format
- Device diagnostics endpoint must match firmware telemetry schema
- BLE pairing flow in Flutter communicates with ESP32-S3 via flutter_blue_plus
- No firmware changes in Phase 8 (API layer only)

---

## 9. Verification Strategy

### Backend
1. `pytest -v` — All existing 119 tests pass
2. New test files: `test_patients.py`, `test_devices.py`, `test_alerts.py`, `test_reports.py`, `test_emergency.py`, `test_fhir.py`
3. Postman/curl E2E for each new endpoint
4. FHIR R4 validation against official FHIR validator

### Flutter
1. `flutter analyze` — No warnings
2. `dart analyze` — No warnings  
3. `flutter test` — Widget tests for each new screen
4. `integration_test/` — E2E flows for patient CRUD, alert acknowledge, emergency SOS

### Integration
1. Patient create → device pair → read vitals → alert triggered → acknowledge → report generated
2. SOS workflow: button press → contacts notified → escalation if no response
3. FHIR export: patient data → FHIR JSON → validate

---

## 10. Estimated Implementation Order

| Step | Task | Duration | Dependencies |
|------|------|----------|-------------|
| 1 | Patient CRUD Backend API | 3 days | Phase 4 API structure |
| 2 | Patient List/Detail Flutter Screens | 3 days | Step 1 |
| 3 | Device CRUD Backend API | 2 days | Phase 4 device scaffold |
| 4 | Device Management Flutter Screens | 2 days | Step 3 |
| 5 | Alert CRUD Backend API | 2 days | Step 1 |
| 6 | Alert List Flutter Screen | 2 days | Step 5 |
| 7 | Risk Assessment Dashboard (Full Stack) | 3 days | Step 1, Phase 7 |
| 8 | Clinical Reports Generator (Backend) | 3 days | Step 1 |
| 9 | PDF Report Export | 2 days | Step 8 |
| 10 | Emergency Workflow Backend | 2 days | Step 1, 5 |
| 11 | Emergency SOS Flutter Screen | 2 days | Step 10 |
| 12 | Knowledge Center (Flutter + RAG wire) | 2 days | Phase 7 |
| 13 | FHIR R4 API Adapter | 3 days | Step 1 |
| 14 | HL7 v2 Message Parser | 2 days | Step 1 |
| 15 | Subscription/Billing Backend | 2 days | Step 1 |
| 16 | Subscription Screen (Flutter Web) | 2 days | Step 15 |
| 17 | Support Ticket System | 2 days | — |
| 18 | Training Portal (Flutter Web) | 2 days | — |
| | **Total** | **~35 days (7 weeks)** | |

**Recommended ordering rationale**: Build foundational CRUD first (Patients → Devices → Alerts), then composite features (Dashboard → Reports → Emergency), then integration (FHIR/HL7), then business features (Subscriptions → Support → Training).

---

## 11. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| FHIR R4 schema complexity | Medium | High | Start with core resources (Patient, Observation, Condition); extend incrementally |
| HL7 v2 parser ambiguity | Medium | Medium | Use HAPI FHIR (Java) or open-source parser; isolate behind adapter |
| BLE pairing reliability | Medium | High | Mock BLE for testing; real device testing in Phase 10 |
| Emergency SMS delivery | Low | High | Use Twilio with delivery receipts; fallback to email + push |
| PDF report formatting | Low | Medium | Use WeasyPrint / wkhtmltopdf; template-first approach |
| Subscription billing integration | Low | Medium | Start with Stripe test mode; defer until Phase 9 |
| Scope creep from hospital requirements | High | Medium | Strict MoSCoW prioritization; defer "Could Haves" to Phase 9 |

---

## 12. Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| Phase 4 — Backend | Required | API structure, middleware, error handling |
| Phase 5 — Database | Required | PostgreSQL, Alembic, repository pattern |
| Phase 6 — Authentication | Required | JWT, RBAC, all new endpoints need auth |
| Phase 7 — AI Platform | Required | Risk scores, RAG search, dashboard stats |
| Twilio / SMS provider | External | Emergency workflow |
| Stripe / billing | External | Subscription management |
| PDF library (ReportLab / WeasyPrint) | Python | Clinical report generation |
| FHIR validator (HL7.org) | External | FHIR compliance testing |
| flutter_blue_plus | Flutter | BLE device pairing |
| flutter_pdfview | Flutter | In-app PDF viewing |

---

## 13. Branching Strategy

```bash
# Create Phase 8 branch from Phase 7
git checkout phase7-development
git checkout -b phase8-hospital-platform
git push origin phase8-hospital-platform

# Feature branches
git checkout -b feature/patient-crud
git checkout -b feature/device-management
git checkout -b feature/alert-engine
git checkout -b feature/clinical-reports
git checkout -b feature/emergency-workflow
git checkout -b feature/fhir-adapter
```

---

**Prepared by**: OpenCode AI  
**Document**: `PHASE8_EXECUTION_PLAN.md`
