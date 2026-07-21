# Milestone Execution Plan

> NeuroBleed Alert — Professional Medical Software Prototype

---

## MoSCoW Priority Summary

| Priority | Total Tasks | Estimated Hours | Duration |
|----------|-------------|----------------|----------|
| **Must Have** | 42 | 184h | ~23 days |
| **Should Have** | 18 | 72h | ~9 days |
| **Could Have** | 10 | 40h | ~5 days |
| **Won't Have (This Phase)** | 6 | N/A | Future |
| **Total** | **76** | **296h** | **~37 days** |

---

## Phase 1: Foundation
**Priority**: Must Have  
**Goal**: Establish project structure, tooling, CI/CD, and configuration for all development  
**Estimated Time**: 24 hours  
**Dependencies**: None  
**Risks**: Low

### Tasks
| ID | Task | Priority | Hours | Dependencies |
|----|------|----------|-------|-------------|
| 1.1 | Create monorepo directory structure | Must Have | 2 | None |
| 1.2 | Initialize Flutter workspace (`apps/mobile_flutter`) | Must Have | 2 | 1.1 |
| 1.3 | Initialize Flutter Web workspace (`apps/web_flutter`) | Must Have | 2 | 1.1 |
| 1.4 | Create `packages/design_system/` (Flutter package) | Must Have | 3 | 1.2 |
| 1.5 | Create `packages/shared/` (Flutter package) | Must Have | 2 | 1.2 |
| 1.6 | Create `packages/core/` (Flutter package) | Must Have | 3 | 1.2 |
| 1.7 | Initialize FastAPI project (`backend/fastapi/`) | Must Have | 3 | 1.1 |
| 1.8 | Create `.env.example` with all environment variables | Must Have | 1 | 1.7 |
| 1.9 | Set up Docker Compose for development (`deployment/docker/docker-compose.yml`) | Must Have | 2 | 1.7 |
| 1.10 | Set up GitHub Actions CI (`ci.yml`) | Should Have | 2 | 1.1 |
| 1.11 | Set up GitHub Actions CD (`cd.yml`) | Should Have | 2 | 1.10 |

### Deliverables
- ✅ Monorepo directory structure
- ✅ Flutter workspace (mobile + web)
- ✅ 3 Flutter packages (design_system, shared, core)
- ✅ FastAPI project scaffold
- ✅ Docker Compose for development
- ✅ CI/CD pipeline (basic)

---

## Phase 2: Authentication
**Priority**: Must Have  
**Goal**: Complete authentication system (email/password, Google Sign-In, OTP) for all platforms  
**Estimated Time**: 32 hours  
**Dependencies**: Phase 1  
**Risks**: Medium (Twilio OTP requires external account)

### Tasks
| ID | Task | Priority | Hours | Dependencies |
|----|------|----------|-------|-------------|
| 2.1 | Configure Twilio for OTP | Must Have | 1 | None |
| 2.2 | Implement JWT auth with refresh tokens | Must Have | 3 | 1.7 |
| 2.3 | Implement Twilio OTP (`backend/fastapi/app/core/twilio.py`) | Must Have | 2 | 1.7 |
| 2.4 | Implement JWT + bcrypt security (`backend/fastapi/app/core/security.py`) | Must Have | 2 | 1.7 |
| 2.5 | Implement auth routes (register, login, google, otp) | Must Have | 4 | 2.2, 2.3, 2.4 |
| 2.6 | Implement JWT middleware + RBAC (`backend/fastapi/app/core/dependencies.py`) | Must Have | 2 | 2.4 |
| 2.7 | Implement rate limiting on auth endpoints | Should Have | 2 | 2.5 |
| 2.8 | Create auth feature in Flutter (login screen) | Must Have | 4 | 1.2, 1.4 |
| 2.9 | Create register screen (Flutter) | Must Have | 3 | 1.2 |
| 2.10 | Create Google Sign-In button (Flutter) | Must Have | 3 | 2.8 |
| 2.11 | Create OTP input screen (Flutter) | Must Have | 3 | 2.8 |
| 2.12 | Implement auth state management (Riverpod providers) | Must Have | 3 | 2.8 |

---

## Phase 3: Database
**Priority**: Must Have  
**Goal**: Complete database schema, migrations, and seed data  
**Estimated Time**: 16 hours  
**Dependencies**: Phase 1  
**Risks**: Low

### Tasks
| ID | Task | Priority | Hours | Dependencies |
|----|------|----------|-------|-------------|
| 3.1 | Implement all SQLAlchemy models (10+ tables) | Must Have | 6 | 1.7 |
| 3.2 | Create Alembic migrations for all models | Must Have | 3 | 3.1 |
| 3.3 | Implement Pydantic schemas for all models | Must Have | 4 | 3.1 |
| 3.4 | Create database seed script (test data) | Should Have | 2 | 3.2 |
| 3.5 | Add PostgreSQL partition for sensor_readings | Could Have | 1 | 3.1 |

---

## Phase 4: Flutter Core
**Priority**: Must Have  
**Goal**: Build all shared infrastructure (network, routing, theming, localization)  
**Estimated Time**: 20 hours  
**Dependencies**: Phase 1, Phase 2  
**Risks**: Low

---

## Phase 5: Patient Management
**Priority**: Must Have  
**Goal**: Full CRUD for patients with search, filtering, and detail views  
**Estimated Time**: 28 hours  
**Dependencies**: Phase 3, Phase 4  
**Risks**: Low

---

## Phase 6: Device Management
**Priority**: Must Have  
**Goal**: Device registration, pairing, status monitoring, and OTA management  
**Estimated Time**: 24 hours  
**Dependencies**: Phase 3, Phase 4  
**Risks**: Medium (BLE requires physical device)

---

## Phase 7: Live Monitoring
**Priority**: Must Have  
**Goal**: Real-time vital sign display and alerts via WebSocket  
**Estimated Time**: 24 hours  
**Dependencies**: Phase 4, Phase 5  
**Risks**: Medium (WebSocket + Redis required)

---

## Phase 8: AI Integration
**Priority**: Should Have  
**Goal**: Integrate AI risk engine with the backend and display results in Flutter  
**Estimated Time**: 24 hours  
**Dependencies**: Phase 3, Phase 4, Phases 5-7  
**Risks**: Medium (AI model accuracy depends on training data)

---

## Phase 9: Notifications
**Priority**: Should Have  
**Goal**: Push notifications (WebSocket + Twilio) for alerts and system events  
**Estimated Time**: 16 hours  
**Dependencies**: Phase 2, Phase 4, Phase 5  
**Risks**: Low

---

## Phase 10: Dashboard
**Priority**: Must Have  
**Goal**: Professional medical dashboard (Flutter Web) with analytics and system overview  
**Estimated Time**: 32 hours  
**Dependencies**: Phase 4, Phase 5, Phase 6, Phase 7, Phase 8  
**Risks**: Low

---

## Phase 11: Testing
**Priority**: Must Have  
**Goal**: Comprehensive testing across all layers and platforms  
**Estimated Time**: 32 hours  
**Dependencies**: Phases 1-10  
**Risks**: Medium (may reveal integration issues)

---

## Phase 12: Deployment
**Priority**: Should Have  
**Goal**: Production-ready deployment configuration  
**Estimated Time**: 24 hours  
**Dependencies**: All phases  
**Risks**: Medium (requires cloud infrastructure)

---

## Timeline Summary (Optimistic)

```
Week 1:  Phase 1 (Foundation) + Phase 2 (Auth)
Week 2:  Phase 3 (Database) + Phase 4 (Flutter Core)
Week 3:  Phase 5 (Patient Management)
Week 4:  Phase 6 (Device Management) + Phase 7 (Live Monitoring)
Week 5:  Phase 8 (AI) + Phase 9 (Notifications)
Week 6:  Phase 10 (Dashboard) + Phase 11 (Testing)
Week 7:  Phase 11 (Testing) + Phase 12 (Deployment)
Week 8:  Buffer / Polish / Documentation
```

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Twilio OTP setup delays | Medium | High | Document all steps, use debug mode first |
| BLE testing without device | High | Medium | Simulate BLE data in development |
| AI model accuracy low | Medium | High | Iterative training, fallback rules engine |
| WebSocket performance issues | Low | Medium | Redis Pub/Sub handled, horizontal scaling |
| Team availability | Medium | High | Clear task ownership, async communication |
| Scope creep | Medium | Medium | MoSCoW prioritization, feature freeze per phase |

---

**Next Step**: Awaiting Milestone 1 to begin Phase 1: Foundation.
