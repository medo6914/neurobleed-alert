# Architecture Approval Document

> Architecture Approval — Final Review Before Implementation

---

## Review Scope

This document provides the final architectural review and approval for the NeuroBleed Alert system redesign. It covers all 14 architectural domains plus an overall assessment.

---

## 1. Flutter Architecture — REVIEW

### What Was Reviewed
- Feature-First Clean Architecture (Presentation → Application → Domain → Data)
- Riverpod for state management with Dependency Injection
- GoRouter for navigation with auth guards
- Isar for local database (offline-first)
- Dio for networking with interceptors
- Design System package (design_system/)
- Full directory structure

### Decision: ✅ **APPROVED**

### Strengths
- Clean separation of concerns (4 layers + core + shared)
- Repository pattern with interface abstractions
- Feature-first organization prevents feature coupling
- Design System as a separate package enables theming consistency
- Isar over Hive/SQLite for time-series medical data

### Minor Recommendations
| # | Issue | Priority | Action |
|---|-------|----------|--------|
| F-01 | Consider `riverpod_generator` for reducing boilerplate | Low | Adopt in Phase 2 |
| F-02 | Add `flutter_gen` for type-safe asset access | Low | Add to build pipeline |
| F-03 | Consider `freezed` for immutable entities | Medium | Add for all domain entities |

### Risks
- **Low**: Riverpod learning curve for new team members (mitigated by comprehensive examples)

---

## 2. Backend Architecture — REVIEW

### What Was Reviewed
- FastAPI as primary framework (decision validated vs NestJS)
- Clean Architecture (Routes → Services → Repositories → Models)
- Redis Streams for async messaging
- PostgreSQL with partitioning for time-series data
- Alembic for migrations
- JWT-based authentication with OTP

### Decision: ✅ **APPROVED**

### Strengths
- FastAPI remains the best choice for Python ML ecosystem integration
- Service layer separates business logic from API endpoints
- Repository pattern enables testability
- Redis Streams provides exactly the right messaging semantics

### Critical Requirements
| # | Requirement | Owner | Deadline |
|---|-------------|-------|----------|
| B-01 | Production SECRET_KEY via environment variable (never default) | DevOps | Milestone 1 |
| B-02 | CORS restricted to known origins only | Backend | Milestone 1 |
| B-03 | Rate limiting on auth endpoints (100 req/min/IP) | Backend | Milestone 1 |
| B-04 | HTTPS enforced in production | DevOps | Milestone 1 |

### Risks
- **Medium**: Async SQLAlchemy + Alembic migration complexity
  - **Mitigation**: Keep migration env.py from current prototype (works with async)

---

## 3. Database Architecture — REVIEW

### What Was Reviewed
- PostgreSQL primary database
- Time-series partitioning by day
- pgvector for AI embeddings
- Redis for caching + streams + pub/sub
- Isar for Flutter local storage

### Decision: ✅ **APPROVED**

### Schema Review Summary
| Table | Status | Notes |
|-------|--------|-------|
| hospitals | ✅ Approved | Add geo-location fields |
| users | ✅ Approved | UUID + email indexed |
| patients | ✅ Approved | Add GCS score, height, weight, BMI |
| devices | ✅ Approved | Add OTA fields |
| sensor_readings | ✅ Approved | Partition by recorded_at |
| alerts | ✅ Approved | Add alert_category |
| ai_reports | ✅ Approved | Version-controlled |
| audit_logs | ✅ Approved | 7-year retention design |

### Recommendations
| # | Issue | Priority |
|---|-------|----------|
| D-01 | Add `deleted_at` for soft delete on patient records | Medium |
| D-02 | Add `version` column for optimistic locking | Medium |
| D-03 | Add table comments in PostgreSQL for documentation | Low |

### Risks
- **Low**: PostgreSQL skill requirement — mitigated by Docker test environment

---

## 4. AI Architecture — REVIEW

### What Was Reviewed
- AI Gateway (FastAPI microservice, port 8001)
- Risk Engine (XGBoost ensemble, ONNX Runtime)
- LLM Engine (Mistral 7B, vLLM, GGUF quantized)
- RAG Engine (LangChain + FAISS + all-MiniLM-L6-v2)
- Medical Knowledge Base (PostgreSQL + pgvector)
- PubMed Integration (Biopython + Entrez API)
- TinyML Engine (TFLite Micro for ESP32-S3)
- Report Generator (LLM + templates)

### Decision: ✅ **APPROVED**

### Critical Requirements
| # | Requirement | Priority |
|---|-------------|----------|
| AI-01 | Medical disclaimer on ALL LLM outputs (non-negotiable) | Critical |
| AI-02 | Risk Engine must never fail open (fail to safe — alert on error) | Critical |
| AI-03 | LLM temperature locked to 0.2 for medical factual queries | High |
| AI-04 | All AI decisions logged to audit trail | High |

### Risks
- **Medium**: LLM inference cost (self-hosting vs API)
  - **Mitigation**: Mistral 7B self-hosted for primary, GPT-4 as fallback
- **Medium**: TinyML model accuracy on edge
  - **Mitigation**: Dual assessment (edge + cloud), cloud wins on disagreement

---

## 5. Security Architecture — REVIEW

### What Was Reviewed
- JWT-based Authentication
- RBAC (Admin, Doctor, Nurse, Paramedic)
- TLS 1.2+ for all communications
- AES-256 for data at rest
- Certificate Pinning
- Audit Logs
- Rate Limiting

### Decision: ✅ **APPROVED**

### Required Before Production
| # | Requirement | Criticality |
|---|-------------|-------------|
| S-01 | Implement JWT auth with refresh token rotation | Critical |
| S-02 | Rate limiting on ALL endpoints (not just auth) | Critical |
| S-03 | SQL injection prevention (parameterized queries — already using ORM) | High |
| S-04 | XSS protection on web dashboard (Content-Security-Policy headers) | High |
| S-05 | CSRF protection for state-changing operations | High |
| S-06 | Security headers (HSTS, X-Frame-Options, X-Content-Type-Options) | High |
| S-07 | Dependency vulnerability scanning (pip audit, npm audit) | Medium |
| S-08 | Regular penetration testing schedule | High |

### Risks
- **Medium**: OTP in Redis vs in-memory — mitigated by Redis Streams design
- **Low**: JWT secret key management — mitigated by env-based config and rotation

---

## 6. Device Architecture — REVIEW

### What Was Reviewed
- ESP32-S3 as primary MCU
- MAX30102 PPG, NIRS rSO2, MPU6050 IMU
- BLE 5.0 for in-hospital, SIM7000G 4G for remote
- FreeRTOS scheduler with task priorities
- HAL → Middleware → Service → Application layers
- OTA with dual-slot bootloader
- TinyML Runtime for edge inference

### Decision: ✅ **APPROVED** (Architecture only — no firmware code)

### Constraints
| # | Constraint | Impact |
|---|-----------|--------|
| D-01 | No firmware implementation yet | Architecture designed, code deferred |
| D-02 | ESP32-S3 RAM limited (512KB SRAM + 8MB PSRAM) | TinyML model < 500KB |
| D-03 | Battery life target > 14 days | Power state machine critical |

### Risks
- **Medium**: NIRS sensor availability/cost — may need to specify custom or off-the-shelf
- **Low**: BLE connection stability in hospital environments

---

## 7. Cloud Architecture — REVIEW

### What Was Reviewed
- Docker containerization for all services
- Multi-service architecture (backend, ai-gateway, risk-engine, llm, rag)
- Redis for caching + message queue
- PostgreSQL + replica for high availability
- Object storage (S3-compatible) for backups + firmware
- Horizontal scaling for stateless services

### Decision: ✅ **APPROVED**

### Deployment Strategy
```
Development:    Docker Compose (single machine)
Staging:        Docker Compose + deployed services
Production:     Kubernetes (EKS/GKE/AKS) — Phase 2
```

### Recommendations
| # | Recommendation | Priority |
|---|---------------|----------|
| C-01 | Use Docker Compose with profiles for dev/staging/prod | Medium |
| C-02 | Add container health checks to all services | High |
| C-03 | Resource limits for each container (prevent noisy neighbors) | High |
| C-04 | Use Docker secrets (not env vars) for sensitive data | High |

---

## 8. Networking Architecture — REVIEW

### What Was Reviewed
- REST API (FastAPI) for CRUD operations
- WebSocket for real-time updates
- MQTT for device-to-cloud communication
- BLE GATT for device-to-app communication
- Redis Pub/Sub for inter-service messaging

### Decision: ✅ **APPROVED**

### Protocol Decision Matrix
| Use Case | Protocol | Rationale |
|----------|----------|-----------|
| Device Telemetry | MQTT over TLS (LTE) | Low bandwidth, QoS, persistent connection |
| Device Data (Local) | BLE GATT | Low power, 10m range, direct to phone |
| Real-Time Vitals | WebSocket | Bidirectional, low latency |
| CRUD Operations | REST/HTTPS | Standard, cacheable, tooling support |
| Inter-Service | Redis Pub/Sub | <1ms latency, existing infrastructure |

### Risks
- **Low**: MQTT broker single point of failure — mitigated by EMQX cluster (Phase 2)

---

## 9. Documentation — REVIEW

### What Was Reviewed
- Architecture documentation (15 documents)
- SRS, SDD, API Reference templates
- User Manuals, Admin Guide, Deployment Guide
- Testing Manual
- Firmware Design Document
- Quality & Regulatory Reference

### Decision: ✅ **APPROVED**

### Status
| Document | Status | Due |
|----------|--------|-----|
| SRS | Template ready | Milestone 1 |
| SDD | Template ready | Milestone 2 |
| API Reference | Auto-generated (OpenAPI) | Milestone 1 |
| Developer Guide | Template ready | Milestone 2 |
| User Manuals | Template ready | Milestone 3 |
| Deployment Guide | Template ready | Milestone 1 |

---

## 10. Testing Strategy — REVIEW

### What Was Reviewed
- Unit Tests (Domain + Application layers)
- Widget Tests (Presentation layer)
- Integration Tests (Full feature flows)
- API Tests (Backend endpoints)
- Performance Tests (Load testing)
- Golden Tests (Visual regression)

### Decision: ✅ **APPROVED**

### Coverage Targets
| Layer | Target | Tool |
|-------|--------|------|
| Domain Entities | 100% | flutter_test |
| Use Cases | 100% | flutter_test + mocktail |
| Repositories (Impl) | 90% | flutter_test + mocktail |
| Providers | 90% | flutter_test |
| Widgets | 80% | flutter_test |
| Integration | Critical flows | integration_test |
| Backend API | 90%+ | pytest + httpx |
| Backend Services | 90%+ | pytest |
| Backend Models | 100% | pytest |

### Critical Test Cases
| Test ID | Scenario | Type | Priority |
|---------|----------|------|----------|
| T-001 | User registers, logs in, gets token | E2E | Critical |
| T-002 | Create patient, add reading, verify risk score | E2E | Critical |
| T-003 | Device sends reading via MQTT, alert generated | Integration | Critical |
| T-004 | Offline mode: create patient, sync when online | Integration | Critical |
| T-005 | Concurrent 1000 risk assessments, verify <1s P99 | Performance | High |
| T-006 | Alert delivery within 5 seconds end-to-end | Performance | High |

---

## 11. Deployment Architecture — REVIEW

### What Was Reviewed
- Docker containerization
- Multi-stage Dockerfiles for optimization
- Docker Compose for development + staging
- GitHub Actions for CI/CD
- Environment-based configuration
- Health check endpoints

### Decision: ✅ **APPROVED**

### Deployment Pipeline
```
Git Push → GitHub Actions → Build → Test → Docker Image → Deploy
              │                            │
              ▼                            ▼
         Lint + Unit Tests           Push to Container Registry
              │                            │
              ▼                            ▼
         Integration Tests          Deploy to Staging
              │                            │
              ▼                            ▼
         Security Scan              Smoke Tests → Production
```

### Environments
| Environment | URL | Database | Purpose |
|-------------|-----|----------|---------|
| Development | localhost:8000 | PostgreSQL (Docker) | Local development |
| Staging | staging.neurobleed.com | PostgreSQL (staging) | Integration testing |
| Production | api.neurobleed.com | PostgreSQL (prod) | Live system |

---

## 12. Remaining Risks Register

| Risk ID | Risk | Probability | Impact | Mitigation | Owner |
|---------|------|-------------|--------|------------|-------|
| R-001 | LLM hallucination in medical reports | Medium | Critical | Temperature 0.2, rules engine override, disclaimer | AI Team |
| R-002 | False negative AI (missed ICH) | Low | Critical | Dual engine (edge + cloud), rules override | AI Team |
| R-003 | Database performance with time-series | Medium | High | Partitioning, proper indexing, Redis cache | Backend |
| R-004 | HIPAA/GDPR compliance audit | Medium | High | Architecture designed for compliance, external audit needed | Legal |
| R-005 | BLE interference in hospital | Low | Medium | LTE fallback, signal quality monitoring | Hardware |
| R-006 | Battery life below target | Medium | Medium | Power state machine optimization | Hardware |
| R-007 | Team skill gaps (Flutter, embedded) | Medium | Medium | Documentation, code reviews, learning resources | Management |
| R-008 | Scope creep (gold-plating) | High | Medium | Strict milestone boundaries, feature freeze per phase | PM |

---

## 13. Architecture Approval Decision

### ✅ **ARCHITECTURE APPROVED**

The NeuroBleed Alert system architecture is approved for implementation.

### Conditions
1. All **Critical** requirements identified in this document must be implemented before production deployment
2. **High** priority recommendations should be addressed during the relevant milestone
3. Architecture decisions may be revisited with written justification and re-review
4. The Architecture Book must be kept in sync with implementation changes

### Signatures
```
┌─────────────────────────────────────────────────────┐
│                                                      │
│  Architecture Review Completed By:                   │
│  Role: CTO + Principal Software Architect            │
│  Date: July 14, 2026                                 │
│                                                      │
│  Status: ✅ APPROVED                                  │
│                                                      │
│  Next: Awaiting "ابدأ Milestone 1" command          │
│        to begin implementation                       │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## 14. Implementation Queue

After "ابدأ Milestone 1", the following implementation order is planned:

```
Milestone 1 (Foundation):
  1. Backend project structure (Clean Architecture)
  2. Database models + Alembic
  3. Core services (Auth, Security)
  4. CI/CD pipeline (GitHub Actions)

Milestone 2 (Backend API):
  1. Patient CRUD endpoints
  2. Sensor reading endpoints
  3. Alert endpoints
  4. Device management endpoints
  5. API tests

Milestone 3 (Flutter App):
  1. Project scaffold + architecture
  2. Core (Network, Router, Theme, Localization)
  3. Auth feature (Login, Register, Google Sign-In, OTP)
  4. Dashboard feature
  5. Patient feature
  6. Offline-first implementation
  7. Widget tests + integration tests

Milestone 4 (AI Service):
  1. AI Gateway
  2. Risk Engine
  3. Medical Rules Engine
  4. Report Generator

Milestone 5 (Real-Time & Devices):
  1. WebSocket server
  2. MQTT broker integration
  3. Redis Streams consumers
  4. Observability stack

Milestone 6 (Dashboard & Deployment):
  1. Flutter Web Dashboard (replaces HTML version)
  2. Docker production configuration
  3. Performance testing
  4. Documentation finalization
```
