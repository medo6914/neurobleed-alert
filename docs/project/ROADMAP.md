# Execution Roadmap — NeuroBleed Alert v1.0

> 15 Phases to Production-Ready Startup Prototype

---

## Overview

```
Phase 1:  Foundation            ████████░░░░░░░░░░░░  2 weeks
Phase 2:  Flutter Mobile        ████████░░░░░░░░░░░░  3 weeks
Phase 3:  Flutter Web Dashboard ██████░░░░░░░░░░░░░░  2 weeks
Phase 4:  Backend               ████████░░░░░░░░░░░░  3 weeks
Phase 5:  Database              ██████░░░░░░░░░░░░░░  2 weeks
Phase 6:  Authentication        ████████░░░░░░░░░░░░  2 weeks
Phase 7:  AI Platform           ██████████░░░░░░░░░░  4 weeks
Phase 8:  Hospital Platform     ██████████░░░░░░░░░░  4 weeks
Phase 9:  Device Platform       ██████░░░░░░░░░░░░░░  2 weeks
         ─────────────────────────────────────────────
Phase 10: Hardware Firmware     ████████████████████  ⏸️ FROZEN
Phase 11: PCB Design            ████████████████████  ⏸️ FROZEN
Phase 12: Prototype Assembly    ████████████████████  ⏸️ FROZEN
Phase 13: Hardware Testing      ████████████████████  ⏸️ FROZEN
         ─────────────────────────────────────────────
Phase 14: Integration Testing   ████████░░░░░░░░░░░░  3 weeks
Phase 15: Production RC         ██████░░░░░░░░░░░░░░  2 weeks
                                   
         Total Active:  29 weeks (~7 months)
         Total Frozen:  TBD (awaiting hardware command)
```

---

## Phase 1: Foundation

**Duration**: 2 weeks | **MoSCoW**: Must Have | **Dependencies**: None

### Goals
- Project scaffold complete
- Docker Compose working
- CI pipeline passing

### Tasks
| ID | Task | Owner |
|----|------|-------|
| D12-01 | Docker Compose Development (PostgreSQL, Redis, FastAPI) | DevOps |
| D12-03 | CI Pipeline (GitHub Actions — lint, test, build) | DevOps |
| D12-06 | Environment Management (.env, profiles) | DevOps |
| D12-07 | Secrets Management | DevOps |
| — | Monorepo structure validation | All |
| — | Flutter SDK + Isar code generation setup | Flutter |

### Deliverables
- ✅ `docker-compose up` starts all services
- ✅ PRs trigger CI (lint + test)
- ✅ `.env.example` + secrets guide

---

## Phase 2: Flutter Mobile

**Duration**: 3 weeks | **MoSCoW**: Must Have | **Dependencies**: Phase 1

### Goals
- Full mobile app: Login, Register, Dashboard, Patients, Alerts
- Arabic + English with RTL/LTR and dynamic switching
- Design system fully integrated

### Tasks
| ID | Task | Owner |
|----|------|-------|
| L4-01 | Arabic Translation Strings | Flutter |
| L4-02 | English Translation Strings | Flutter |
| L4-03 | RTL Layout Support | Flutter |
| L4-04 | LTR Layout Support | Flutter |
| L4-05 | Dynamic Language Switcher | Flutter |
| L4-06 | Backend Localized Messages | Backend |
| I2-08 | Login Screen | Flutter |
| I2-09 | Register Screen | Flutter |
| I2-10 | Role-Based UI Navigation | Flutter |
| M9-02 | Patient List Screen | Flutter |
| M9-03 | Patient Detail Screen | Flutter |
| M9-06 | Device Management Screen | Flutter |
| M9-08 | Alert List Screen | Flutter |
| O5-08 | Sentry Error Tracking | Flutter |

### Deliverables
- ✅ Flutter app with auth flow
- ✅ AR/EN + RTL/LTR switching
- ✅ Patient list + detail + device + alert screens

---

## Phase 3: Flutter Web Dashboard

**Duration**: 2 weeks | **MoSCoW**: Should Have | **Dependencies**: Phase 2

### Goals
- Hospital admin dashboard
- Patient management web interface
- Super admin panel for tenant management

### Tasks
| ID | Task | Owner |
|----|------|-------|
| M9-04 | Patient Management Web Dashboard | Flutter Web |
| E1-07 | Super Admin Panel (tenants, hospitals) | Flutter Web |
| — | Dashboard analytics (patient count, alerts, device status) | Flutter Web |
| — | Responsive layout for desktop + tablet | Flutter Web |

### Deliverables
- ✅ Web dashboard sharing packages with mobile
- ✅ Admin + hospital admin views

---

## Phase 4: Backend

**Duration**: 3 weeks | **MoSCoW**: Must Have | **Dependencies**: Phase 1

### Goals
- FastAPI Clean Architecture
- API versioning + OpenAPI
- WebSocket, MQTT, Redis Streams
- Health checks

### Tasks
| ID | Task | Owner |
|----|------|-------|
| E1-03 | Organization CRUD API | Backend |
| E1-04 | Hospital CRUD API | Backend |
| E1-05 | Department CRUD API | Backend |
| E1-06 | Branch CRUD API | Backend |
| A3-01 | API Versioning Strategy | Backend |
| A3-02 | OpenAPI Documentation | Backend |
| A3-03 | WebSocket Server | Backend |
| A3-04 | MQTT Broker Integration | Backend |
| P6-03 | Redis Cache Layer | Backend |
| P6-06 | Background Workers (ARQ) | Backend |
| P6-07 | Redis Streams Queue | Backend |
| O5-06 | Health Check Endpoints | Backend |

### Deliverables
- ✅ All enterprise CRUD APIs
- ✅ WebSocket + MQTT endpoints
- ✅ OpenAPI docs at /docs
- ✅ Redis cache + streams working

---

## Phase 5: Database

**Duration**: 2 weeks | **MoSCoW**: Must Have | **Dependencies**: Phase 4

### Goals
- Multi-tenant database schema
- All SQLAlchemy models
- Alembic migrations
- Connection pooling

### Tasks
| ID | Task | Owner |
|----|------|-------|
| E1-01 | Multi-Tenant Database Schema | Backend |
| P6-04 | Connection Pooling | Backend |
| — | All SQLAlchemy models (10+ tables) | Backend |
| — | Alembic initial migration | Backend |
| — | Pydantic schemas for all models | Backend |
| — | Seed data script | Backend |

### Deliverables
- ✅ All tables created with tenant isolation
- ✅ Migrations version-controlled
- ✅ Seed data for development

---

## Phase 6: Authentication

**Duration**: 2 weeks | **MoSCoW**: Must Have | **Dependencies**: Phase 5

### Goals
- Full RBAC with fine-grained permissions
- Session management
- Refresh token rotation
- Rate limiting

### Tasks
| ID | Task | Owner |
|----|------|-------|
| I2-01 | RBAC Role Definitions | Backend |
| I2-02 | Permission Matrix Design | Backend |
| I2-03 | Fine-Grained Permission Enforcement | Backend |
| I2-04 | Audit Log System | Backend |
| I2-05 | Session Management API | Backend |
| I2-06 | Refresh Token Rotation | Backend |
| P6-05 | API Rate Limiting | Backend |
| E1-02 | Tenant Isolation Middleware | Backend |

### Deliverables
- ✅ Role-based access on all endpoints
- ✅ Sessions visible and revocable
- ✅ Every mutation logged to audit trail
- ✅ Rate limits enforced

---

## Phase 7: AI Platform

**Duration**: 4 weeks | **MoSCoW**: Should Have | **Dependencies**: Phase 5

### Goals
- AI Gateway microservice
- XGBoost risk engine
- RAG + knowledge base (foundation)

### Tasks
| ID | Task | Owner |
|----|------|-------|
| AI8-01 | AI Gateway Microservice | AI |
| AI8-02 | Cloud AI Risk Engine (XGBoost) | AI |
| AI8-04 | RAG Engine (LangChain + FAISS) | AI |
| AI8-05 | Medical Knowledge Base | AI |
| AI8-06 | PubMed Integration | AI |
| AI8-07 | Explainable AI (SHAP) | AI |
| AI8-08 | AI Monitoring Dashboard | AI |
| AI8-03 | TinyML Model Export | AI |

### Deliverables
- ✅ Risk engine returning scores via API
- ✅ RAG answering clinical queries
- ✅ SHAP explanations per prediction

---

## Phase 8: Hospital Platform

**Duration**: 4 weeks | **MoSCoW**: Must Have | **Dependencies**: Phases 4, 5, 6

### Goals
- Full patient management
- Device management
- Alert management
- Clinical reports
- Emergency workflow

### Tasks
| ID | Task | Owner |
|----|------|-------|
| M9-01 | Patient CRUD Backend API | Backend |
| M9-05 | Device CRUD Backend API | Backend |
| M9-07 | Alert CRUD Backend API | Backend |
| M9-09 | Clinical Reports Generator | Backend |
| M9-10 | Risk Assessment Dashboard | Full Stack |
| M9-11 | Knowledge Center | Full Stack |
| M9-12 | Emergency Workflow | Full Stack |
| A3-05 | FHIR R4 API Adapter | Backend |
| A3-06 | HL7 v2 Message Parser | Backend |

### Deliverables
- ✅ Complete medical data management
- ✅ Alert engine with severity escalation
- ✅ PDF report generation
- ✅ FHIR/HL7 compatibility layer

---

## Phase 9: Device Platform

**Duration**: 2 weeks | **MoSCoW**: Must Have | **Dependencies**: Phase 8

### Goals
- Device registration + provisioning API
- Device diagnostics
- No firmware — API layer only

### Tasks
| ID | Task | Owner |
|----|------|-------|
| M9-05 | Device CRUD Backend API (refine) | Backend |
| H10-17 | Device Registration API | Backend |
| H10-18 | Device Diagnostics API | Backend |
| H10-15 | Device Pairing (BLE — Flutter side) | Flutter |
| H10-16 | Device Provisioning Flow (Flutter) | Flutter |

### Deliverables
- ✅ Devices registerable and assignable
- ✅ Diagnostics readable from API
- ✅ Flutter pairing flow ready

---

## Phase 10: Hardware Firmware

**⚠️ FROZEN — Awaiting "ابدأ جزء الجهاز" command**

**Duration**: TBD | **MoSCoW**: Must Have (when unfrozen)

### Tasks
| ID | Task |
|----|------|
| H10-01 through H10-19 | All 19 firmware tasks |

### Preconditions
1. All software phases (1–9) complete and tested
2. Integration tests passing
3. Explicit command received: "ابدأ جزء الجهاز"

---

## Phase 11: PCB Design

**⚠️ FROZEN — Awaiting "ابدأ جزء الجهاز" command**

- Schematic design
- PCB layout
- BOM generation
- Prototype fabrication order

---

## Phase 12: Prototype Assembly

**⚠️ FROZEN**

- Assemble first prototype unit
- Power-on test
- Sensor calibration

---

## Phase 13: Hardware Testing

**⚠️ FROZEN**

- Sensor accuracy test
- Battery life test
- BLE range test
- Signal quality test
- Reliability test

---

## Phase 14: Integration Testing

**Duration**: 3 weeks | **MoSCoW**: Must Have | **Dependencies**: Phases 1–9

### Goals
- All tests passing
- Observability stack deployed
- Scaling verified
- Backup systems operational

### Tasks
| ID | Task | Owner |
|----|------|-------|
| T11-01 | Flutter Unit Tests | Flutter |
| T11-02 | Flutter Widget Tests | Flutter |
| T11-03 | Flutter Integration Tests | Flutter |
| T11-04 | Backend API Tests | Backend |
| T11-05 | Backend Unit Tests | Backend |
| T11-06 | Performance / Load Tests | QA |
| T11-07 | Security Tests | QA |
| O5-01 | Centralized Logging (Loki) | DevOps |
| O5-02 | Application Metrics (Prometheus) | DevOps |
| O5-03 | Distributed Tracing (Tempo) | DevOps |
| O5-04 | Prometheus Exporters | DevOps |
| O5-05 | Grafana Dashboards | DevOps |
| O5-07 | Alerting Rules | DevOps |
| P6-01 | Horizontal Scaling Design | DevOps |
| P6-02 | Load Balancer Config | DevOps |
| B7-01 | Automatic Database Backup | DevOps |
| B7-04 | Streaming Replication | DevOps |
| D12-02 | Docker Compose Production | DevOps |
| D12-04 | CD Pipeline | DevOps |
| D12-05 | Release Pipeline | DevOps |

### Deliverables
- ✅ 90%+ test coverage across all layers
- ✅ Grafana dashboards operational
- ✅ Load testing passes at 2x expected traffic
- ✅ Database backups running on schedule

---

## Phase 15: Production Release Candidate

**Duration**: 2 weeks | **MoSCoW**: Must Have | **Dependencies**: Phase 14

### Goals
- Final polish
- Documentation complete
- Release artifacts ready

### Tasks
| ID | Task | Owner |
|----|------|-------|
| — | Bug bash + fix all P0/P1 bugs | All |
| — | Finalize deployment guide | DevOps |
| — | Runbook for on-call rotation | DevOps |
| — | Security audit final pass | QA |
| — | Performance validation report | QA |
| — | Regulatory compliance checklist | Legal |
| — | Version 1.0.0 tag + release notes | All |

### Deliverables
- ✅ v1.0.0 tagged in GitHub
- ✅ Release notes with known issues
- ✅ Deployment guide + runbook
- ✅ Production Docker Compose verified

---

## Dependency Graph

```
Phase 1 (Foundation)
  ├──► Phase 2 (Flutter Mobile) ──► Phase 3 (Flutter Web)
  └──► Phase 4 (Backend) ──► Phase 5 (Database)
                                └──► Phase 6 (Authentication)
                                      └──► Phase 8 (Hospital Platform)
                                            ├──► Phase 9 (Device Platform)
                                            └──► Phase 7 (AI Platform)
                                                   └──► Phase 14 (Integration Testing)
                                                         └──► Phase 15 (Production RC)

Phase 10–13 (Hardware) ── FROZEN ──► Phase 14 (after unfreeze)
```

---

## Phase Timeline

```
Month 1  │░░░░░░░░░░░░│ Phase 1 (Foundation)
         │░░░░░░░░░░░░│ Phase 2 (Flutter Mobile)
Month 2  │░░░░░░░░░░░░│ Phase 2 (cont.)
         │░░░░░░░░░░░░│ Phase 3 (Flutter Web)
Month 3  │░░░░░░░░░░░░│ Phase 4 (Backend)
         │░░░░░░░░░░░░│ Phase 4 (cont.)
Month 4  │░░░░░░░░░░░░│ Phase 5 (Database)
         │░░░░░░░░░░░░│ Phase 6 (Authentication)
Month 5  │░░░░░░░░░░░░│ Phase 7 (AI Platform)
         │░░░░░░░░░░░░│ Phase 7 (cont.)
Month 6  │░░░░░░░░░░░░│ Phase 8 (Hospital Platform)
         │░░░░░░░░░░░░│ Phase 8 (cont.)
Month 7  │░░░░░░░░░░░░│ Phase 8 (cont.) + Phase 9 (Device Platform)
         │░░░░░░░░░░░░│ Phase 14 (Integration Testing)
Month 8  │░░░░░░░░░░░░│ Phase 14 (cont.)
         │░░░░░░░░░░░░│ Phase 15 (Production RC)

Active:  7 months (Months 1–8)
Frozen:  Hardware (Phases 10–13) — duration TBD
```

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Scope creep on AI Platform | Medium | High | Strict MoSCoW — AI is "Should Have" |
| Twilio/API dependency delays | Medium | Medium | Mock services for development |
| Multi-tenancy complexity | Medium | Medium | Start with simple tenant_id column, optimize later |
| Team availability | Medium | High | Clear task ownership, async communication |
| Integration surprises | Medium | Medium | Weekly integration syncs |
| Hardware unfrozen too early | Low | High | Blocked by explicit command only |
