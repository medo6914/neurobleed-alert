# Project Board — NeuroBleed Alert v1.0

> Production-Ready Startup Prototype — Full Task Inventory

---

## EPIC 1: Enterprise Architecture

**MoSCoW Priority**: Must Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| E1-01 | Multi-Tenant Database Schema | Must Have | 5 | FDN-01 | Separate data per hospital/organization via tenant_id |
| E1-02 | Tenant Isolation Middleware | Must Have | 4 | E1-01 | Automatically scope all queries to current tenant |
| E1-03 | Organization CRUD API | Must Have | 4 | E1-01 | Create/read/update/delete organizations |
| E1-04 | Hospital CRUD API | Must Have | 4 | E1-03 | Hospitals belong to organizations |
| E1-05 | Department CRUD API | Should Have | 4 | E1-04 | Departments within hospitals |
| E1-06 | Branch CRUD API | Should Have | 4 | E1-04 | Branches within hospitals |
| E1-07 | Super Admin Panel | Should Have | 3 | E1-04 | Manage tenants from Flutter Web dashboard |

---

## EPIC 2: Identity & Security

**MoSCoW Priority**: Must Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| I2-01 | RBAC Role Definitions | Must Have | 6 | E1-01 | Roles: Super Admin, Hospital Admin, Doctor, Nurse, Paramedic |
| I2-02 | Permission Matrix Design | Must Have | 6 | I2-01 | Define all permissions per resource + action |
| I2-03 | Fine-Grained Permission Enforcement | Must Have | 6 | I2-02 | Middleware checks permissions per endpoint |
| I2-04 | Audit Log System | Must Have | 6 | — | Log all state-changing operations to audit_log table |
| I2-05 | Session Management API | Must Have | 6 | I2-01 | List active sessions, revoke by ID |
| I2-06 | Refresh Token Rotation | Must Have | 6 | — | Rotate refresh tokens on each use, 30-day expiry |
| I2-07 | MFA Architecture (Future) | Won't Have | — | — | Design for future TOTP/WebAuthn support, not implemented yet |
| I2-08 | Login Screen (Flutter) | Must Have | 2 | I2-01 | Email/password login with validation |
| I2-09 | Register Screen (Flutter) | Must Have | 2 | I2-01 | Self-registration with role selection |
| I2-10 | Role-Based UI Navigation | Must Have | 2 | I2-01 | Show/hide screens based on user role |

---

## EPIC 3: API & Integration

**MoSCoW Priority**: Should Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| A3-01 | API Versioning Strategy | Must Have | 4 | — | URL-prefix versioning /v1/, /v2/ |
| A3-02 | OpenAPI / Swagger Documentation | Must Have | 4 | A3-01 | Auto-generated from FastAPI routes |
| A3-03 | WebSocket Server | Must Have | 4 | — | Real-time vital sign broadcasting |
| A3-04 | MQTT Broker Integration | Should Have | 4 | — | Device telemetry ingestion via MQTT |
| A3-05 | FHIR R4 API Adapter | Could Have | 4 | — | Translate internal models to/from FHIR resources |
| A3-06 | HL7 v2 Message Parser | Could Have | 4 | — | Parse HL7 messages for hospital integration |
| A3-07 | Third-Party API Rate Limiter | Should Have | 6 | — | Configurable rate limits per external API |
| A3-08 | FHIR R4 Implementation — Patient Resource | Could Have | 8 | M9-01 | Map patient CRUD to FHIR Patient resource |
| A3-09 | FHIR R4 Implementation — Observation Resource | Could Have | 8 | M9-07 | Map vital signs + alerts to FHIR Observation |
| A3-10 | HL7 v2 ADT Message Parser | Could Have | 8 | — | Parse admission/transfer/discharge messages |
| A3-11 | HL7 v2 ORU Message Parser | Could Have | 8 | — | Parse observation result messages |
| A3-12 | EMR Integration — Epic | Could Have | 8 | A3-08 | Epic FHIR R4 integration module |
| A3-13 | EMR Integration — Seha / Cerner | Could Have | 8 | A3-08 | Seha/Cerner integration module |

---

## EPIC 4: Localization

**MoSCoW Priority**: Must Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| L4-01 | Arabic Translation Strings | Must Have | 2 | — | All UI strings translated to Arabic |
| L4-02 | English Translation Strings | Must Have | 2 | — | All UI strings in English (default) |
| L4-03 | RTL Layout Support | Must Have | 2 | L4-01 | Flutter RTL rendering for Arabic |
| L4-04 | LTR Layout Support | Must Have | 2 | L4-02 | Standard left-to-right for English |
| L4-05 | Dynamic Language Switcher | Must Have | 2 | L4-03, L4-04 | Switch language at runtime without restart |
| L4-06 | Backend Localized Messages | Should Have | 4 | L4-01 | API error messages in Arabic/English based on Accept-Language |

---

## EPIC 5: Observability

**MoSCoW Priority**: Should Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| O5-01 | Centralized Logging (Loki) | Should Have | 14 | DEP-01 | Collect all service logs in Loki |
| O5-02 | Application Metrics (Prometheus) | Should Have | 14 | DEP-01 | Expose metrics from FastAPI + Flutter |
| O5-03 | Distributed Tracing (Tempo) | Could Have | 14 | DEP-01 | Trace requests across services |
| O5-04 | Prometheus Exporters | Should Have | 14 | — | Export Redis, PostgreSQL metrics |
| O5-05 | Grafana Dashboards | Should Have | 14 | O5-02 | System, Medical, AI, Device dashboards |
| O5-06 | Health Check Endpoints | Must Have | 4 | — | /health for all services |
| O5-07 | Alerting Rules (Grafana) | Could Have | 14 | O5-05 | Alert on critical metric thresholds |
| O5-08 | Sentry Error Tracking | Should Have | 2 | — | Flutter + Python crash reporting |

---

## EPIC 6: Performance & Scalability

**MoSCoW Priority**: Should Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| P6-01 | Database Connection Pool Tuning | Must Have | 5 | — | Configure pool_size, max_overflow, pool_pre_ping for production |
| P6-02 | Horizontal Scaling Design | Should Have | 14 | DEP-01 | Stateless services behind load balancer |
| P6-03 | Load Balancer Config (Nginx) | Should Have | 14 | P6-02 | Reverse proxy + round-robin |
| P6-04 | Redis Cache Layer | Must Have | 4 | — | Cache frequent queries, session store |
| P6-05 | Database Connection Pooling | Must Have | 4 | — | SQLAlchemy async pool management |
| P6-06 | API Rate Limiting | Must Have | 6 | — | Enforce limits per endpoint per tenant |
| P6-07 | Background Workers (ARQ) | Should Have | 4 | — | Async task processing for sync, reports |
| P6-08 | Redis Streams Queue | Must Have | 4 | — | Message queue for telemetry + alerts |

---

## EPIC 7: Backup & Reliability

**MoSCoW Priority**: Should Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| B7-01 | Automatic Database Backup | Should Have | 14 | DEP-01 | Daily pg_dump to S3-compatible storage |
| B7-02 | Point-in-Time Recovery | Could Have | 14 | B7-01 | WAL archiving for PITR |
| B7-03 | Disaster Recovery Playbook | Should Have | 14 | — | Documented recovery procedures |
| B7-04 | Streaming Replication | Could Have | 14 | DEP-01 | PostgreSQL hot standby |
| B7-05 | High Availability Docker Config | Could Have | 14 | DEP-01 | Multi-instance failover setup |

---

## EPIC 8: AI Platform

**MoSCoW Priority**: Should Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| AI8-01 | AI Gateway Microservice | Should Have | 7 | — | FastAPI gateway for all AI services |
| AI8-02 | Cloud AI Risk Engine | Should Have | 7 | AI8-01 | XGBoost ensemble risk assessment |
| AI8-03 | TinyML Model Export | Could Have | 7 | AI8-02 | Convert model to TFLite for edge |
| AI8-04 | RAG Engine (LangChain + FAISS) | Could Have | 7 | AI8-01 | Retrieval-augmented generation for queries |
| AI8-05 | Medical Knowledge Base | Could Have | 7 | — | PostgreSQL + pgvector for embeddings |
| AI8-06 | PubMed Integration | Could Have | 7 | AI8-05 | Fetch and index medical literature |
| AI8-07 | Explainable AI (SHAP/LIME) | Could Have | 7 | AI8-02 | Feature importance per prediction |
| AI8-08 | AI Monitoring Dashboard | Could Have | 7 | AI8-01 | Model drift, latency, accuracy metrics |
| AI8-09 | Clinical Validation Study — IRB Protocol | Should Have | 7 | — | Design and submit IRB protocol for ICH monitoring study |
| AI8-10 | Clinical Validation Study — Data Collection | Should Have | 7 | AI8-09 | Collect patient data at pilot hospitals for model validation |
| AI8-11 | Clinical Validation Study — Results Publication | Could Have | 7 | AI8-10 | Publish results in peer-reviewed medical journal |

---

## EPIC 9: Medical Platform

**MoSCoW Priority**: Must Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| M9-01 | Patient CRUD Backend API | Must Have | 8 | E1-01 | Create, read, update, delete patients |
| M9-02 | Patient List Screen (Flutter Mobile) | Must Have | 2 | M9-01 | Search, filter, sort patients |
| M9-03 | Patient Detail Screen (Flutter Mobile) | Must Have | 2 | M9-02 | Full patient info + vitals display |
| M9-04 | Patient Management (Flutter Web) | Must Have | 3 | M9-01 | Dashboard for hospital admin |
| M9-05 | Device CRUD Backend API | Must Have | 8 | E1-01 | Register, pair, update devices |
| M9-06 | Device Management Screen (Flutter) | Must Have | 2 | M9-05 | List, pair, diagnostics view |
| M9-07 | Alert CRUD Backend API | Must Have | 8 | M9-01 | Create, list, acknowledge alerts |
| M9-08 | Alert List Screen (Flutter Mobile) | Must Have | 2 | M9-07 | Filter by severity, acknowledge |
| M9-09 | Clinical Reports Generator | Should Have | 8 | M9-01 | PDF/HTML report generation |
| M9-10 | Risk Assessment Dashboard | Should Have | 8 | AI8-02 | Display AI risk scores per patient |
| M9-11 | Knowledge Center | Could Have | 8 | — | Searchable medical guidelines |
| M9-12 | Emergency Workflow | Should Have | 8 | M9-07 | SOS button, emergency contact sequence |
| M9-13 | Subscription / Billing API | Should Have | 8 | I2-01 | Plan management, invoicing, payment integration |
| M9-14 | Subscription Management Screen (Web) | Should Have | 3 | M9-13 | Hospital admin manages subscription, payment method |
| M9-15 | Clinical Reports Generator — PDF Export | Should Have | 8 | M9-01 | Generate PDF patient summary + vital trends |
| M9-16 | Support Ticket System (In-App) | Could Have | 8 | — | Submit, track, resolve support requests |
| M9-17 | Training Portal (Web) | Could Have | 3 | — | Video guides, certification, user manual |

---

## EPIC 10: Hardware Platform

**⚠️ FROZEN — Awaiting "ابدأ جزء الجهاز" command**

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| H10-01 | ESP32-S3 Firmware Scaffold | Must Have | 10 | — | FreeRTOS project structure |
| H10-02 | MAX30102 PPG Driver | Must Have | 10 | H10-01 | Heart rate + SpO2 sensor driver |
| H10-03 | NIRS rSO2 Driver | Must Have | 10 | H10-01 | Cerebral oxygen saturation sensor |
| H10-04 | MPU6050 IMU Driver | Should Have | 10 | H10-01 | Motion artifact detection |
| H10-05 | Signal Processing Pipeline | Must Have | 10 | H10-02, H10-03 | Filter, denoise, normalize |
| H10-06 | Feature Extraction | Must Have | 10 | H10-05 | Extract 18 clinical features |
| H10-07 | TinyML Runtime | Should Have | 10 | H10-06 | TFLite Micro inference on device |
| H10-08 | BLE 5.0 Manager | Must Have | 10 | H10-01 | GATT services, advertising, pairing |
| H10-09 | SIM7000G Cellular Module | Should Have | 10 | H10-01 | LTE-M/NB-IoT for remote patients |
| H10-10 | OTA Update Mechanism | Should Have | 10 | H10-01 | Dual-slot bootloader + rollback |
| H10-11 | Battery Management | Must Have | 10 | H10-01 | Fuel gauge, charging, low-battery alert |
| H10-12 | Power Optimization | Must Have | 10 | H10-11 | Power state machine (Active/Monitor/Sleep/Deep Sleep) |
| H10-13 | Watchdog Timer | Must Have | 10 | H10-01 | System recovery on freeze |
| H10-14 | Error Recovery | Must Have | 10 | H10-13 | Graceful error handling + reset |
| H10-15 | Device Pairing (BLE) | Must Have | 10 | H10-08 | Secure pairing with Flutter app |
| H10-16 | Device Provisioning Flow | Must Have | 10 | H10-08 | First-time setup via mobile app |
| H10-17 | Device Registration API | Must Have | 10 | M9-05 | Register device to patient/hospital |
| H10-18 | Device Diagnostics API | Should Have | 10 | H10-01 | Self-test, signal quality, battery status |
| H10-19 | Firmware Versioning | Must Have | 10 | H10-10 | Semver, changelog, rollback support |

---

## EPIC 11: Testing

**MoSCoW Priority**: Must Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| T11-01 | Flutter Unit Tests | Must Have | 14 | All Flutter | Test entities, utils, tokens |
| T11-02 | Flutter Widget Tests | Must Have | 14 | All Flutter | Test all components + screens |
| T11-03 | Flutter Integration Tests | Must Have | 14 | All Flutter | Critical flows: auth, patients, alerts |
| T11-04 | Backend API Tests (pytest) | Must Have | 14 | All Backend | Test all endpoints |
| T11-05 | Backend Unit Tests (pytest) | Must Have | 14 | All Backend | Test services, models |
| T11-06 | Performance / Load Tests | Should Have | 14 | All | k6 or locust for API endpoints |
| T11-07 | Security Tests | Should Have | 14 | All | OWASP scan, penetration test |
| T11-08 | Firmware Tests | Won't Have | 14 | EPIC 10 | Hardware-in-the-loop testing (frozen) |
| T11-09 | Hardware Validation | Won't Have | 14 | EPIC 10 | Sensor accuracy, battery life (frozen) |

---

---

## EPIC 13: Regulatory & Compliance

**MoSCoW Priority**: Should Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| R13-01 | SFDA Registration — Application Prep | Should Have | 8 | — | Prepare SFDA medical device registration dossier |
| R13-02 | SFDA Registration — Submission | Should Have | 14 | R13-01 | Submit SFDA Class II/III application |
| R13-03 | FDA 510(k) — Regulatory Consultant | Should Have | 14 | — | Engage FDA regulatory consultant |
| R13-04 | FDA 510(k) — Premarket Notification Prep | Should Have | 14 | R13-03 | Prepare 510(k) submission with clinical data |
| R13-05 | FDA 510(k) — Submission | Could Have | 15 | R13-04 | Submit FDA 510(k) premarket notification |
| R13-06 | CE Marking (EU MDR) — Technical File | Could Have | 14 | — | Prepare EU MDR technical documentation |
| R13-07 | CE Marking — Notified Body Submission | Could Have | 14 | R13-06 | Submit to EU notified body for review |
| R13-08 | HIPAA Compliance Audit | Should Have | 14 | — | Third-party HIPAA compliance assessment |
| R13-09 | PDPL (KSA) Compliance Audit | Should Have | 14 | — | Saudi PDPL personal data protection compliance |
| R13-10 | ISO 13485 QMS Documentation | Could Have | 14 | — | Quality management system for medical devices |
| R13-11 | ISO 14971 Risk Management File | Could Have | 14 | — | Complete ISO 14971 risk management documentation |

---

## EPIC 14: Technical Debt (Pre-v1.0)

**MoSCoW Priority**: Must Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| T14-01 | Isar Local Database Initialization | Must Have | 1 | — | Complete Isar init in local_database_service.dart (TD-03) |
| T14-02 | WebSocket Authentication Guard | Must Have | 4 | I2-01 | Add JWT verification on WS upgrade (TD-09) |
| T14-03 | Refresh Token Rotation Implementation | Must Have | 6 | — | Rotate refresh tokens on each use (TD-10) |
| T14-04 | WebSocket CORS / Origin Validation | Must Have | 4 | — | Add origin check for WS connections (TD-20) |

---

## EPIC 15: Business Operations

**MoSCoW Priority**: Should Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| B15-01 | Pricing Tier Configuration API | Should Have | 8 | M9-13 | Configurable pricing tiers in backend |
| B15-02 | Payment Gateway Integration | Should Have | 8 | M9-13 | Stripe/Moyasar for subscription billing |
| B15-03 | Hospital Onboarding Flow | Should Have | 8 | E1-04 | Step-by-step hospital setup wizard |
| B15-04 | Analytics Dashboard — Business KPIs | Should Have | 3 | — | MRR, active patients, devices deployed |
| B15-05 | Email Notification System | Should Have | 8 | — | Transactional emails (invoices, alerts, reports) |
| B15-06 | Multi-Currency Support | Could Have | 8 | M9-13 | USD, SAR, AED, EGP |
| B15-07 | Local Tax Handling (VAT) | Could Have | 8 | B15-06 | 15% KSA VAT, 5% UAE VAT |

---

## EPIC 12: DevOps

**MoSCoW Priority**: Must Have

| ID | Task | Priority | Phase | Dependencies | Description |
|----|------|----------|-------|-------------|-------------|
| D12-01 | Docker Compose Development | Must Have | 1 | — | PostgreSQL, Redis, FastAPI services |
| D12-02 | Docker Compose Production | Should Have | 14 | D12-01 | Multi-service with monitoring stack |
| D12-03 | CI Pipeline (GitHub Actions) | Must Have | 1 | — | Lint, test, build for all packages |
| D12-04 | CD Pipeline (GitHub Actions) | Should Have | 14 | D12-03 | Deploy to staging on tag |
| D12-05 | Release Pipeline | Should Have | 14 | D12-04 | Versioning, changelog, artifacts |
| D12-06 | Environment Management | Must Have | 1 | — | .env files, Docker profiles |
| D12-07 | Secrets Management | Must Have | 1 | — | GitHub Secrets, Docker secrets |
| D12-08 | Docker Health Checks — All Services | Must Have | 14 | D12-01 | Add health checks with depends_on condition |
| D12-09 | Flutter Web Build in CI | Should Have | 14 | D12-03 | Add `flutter build web` to CI pipeline |
| D12-10 | Per-Package CI Jobs | Should Have | 14 | D12-03 | Run tests for each Flutter package independently |

---

## MoSCoW Summary

| Priority | Total Tasks | Breakdown |
|----------|-------------|-----------|
| **Must Have** | 52 | Core features required for v1.0 |
| **Should Have** | 32 | Important but can be deferred |
| **Could Have** | 22 | Nice to have, if time permits |
| **Won't Have** | 3 | Explicitly excluded (MFA, Firmware tests, Hardware validation) |
| **Frozen** | 19 | Hardware Platform — awaiting command |
| **Total** | **128** | 15 Epics, 128 total tasks |

## Phase-to-Epic Mapping

| Phase | Epics |
|-------|-------|
| 1. Foundation | EPIC 12 (DevOps), EPIC 14 (Tech Debt — Isar init) |
| 2. Flutter Mobile | EPIC 4 (Localization), EPIC 2 (Auth screens), EPIC 9 (Medical — mobile) |
| 3. Flutter Web Dashboard | EPIC 9 (Medical — web), EPIC 1 (Admin panel), EPIC 15 (Business — analytics) |
| 4. Backend | EPIC 1 (Enterprise — API), EPIC 3 (API — versioning, WS, MQTT), EPIC 6 (Redis, Queue), EPIC 14 (Tech Debt — WS auth, CORS) |
| 5. Database | EPIC 1 (Multi-tenant schema), EPIC 7 (Backup — schema) |
| 6. Authentication | EPIC 2 (RBAC, Permissions, Sessions, Tokens), EPIC 14 (Refresh token rotation) |
| 7. AI Platform | EPIC 8 (All AI tasks + clinical validation) |
| 8. Hospital Platform | EPIC 9 (Medical), EPIC 15 (Business — billing, onboarding), EPIC 13 (Regulatory — SFDA prep) |
| 9. Device Platform | EPIC 10 (Hardware — API + Management, not firmware) |
| 10. Hardware Firmware | EPIC 10 (Frozen — awaiting command) |
| 11. PCB Design | EPIC 10 (Frozen) |
| 12. Prototype Assembly | EPIC 10 (Frozen) |
| 13. Hardware Testing | EPIC 11 (Frozen) |
| 14. Integration Testing | EPIC 11 (Tests), EPIC 5 (Observability), EPIC 6 (Scaling), EPIC 7 (Backup), EPIC 12 (CD), EPIC 13 (Regulatory), EPIC 15 (Multi-currency, tax) |
| 15. Production Release Candidate | EPIC 13 (FDA submission), final polish, documentation, release |
