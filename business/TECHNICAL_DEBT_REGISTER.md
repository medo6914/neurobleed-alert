# Technical Debt Register — NeuroBleed Alert

> Current state of known technical debt, prioritized for remediation.

---

## Priority Definitions

| Priority | Definition | Target Resolution |
|----------|-----------|-------------------|
| **P0-Critical** | Blocks development, causes data loss, security risk | Before v1.0 launch |
| **P1-High** | Significant architectural issue, will cause pain within 3 months | v1.1 |
| **P2-Medium** | Should be fixed but not blocking | v1.2 |
| **P3-Low** | Nice to have, cosmetic, or far-future concern | v2.0 |

---

## Debt Register

| ID | Debt | Description | Location | Priority | Impact | Fix |
|----|------|-------------|----------|----------|--------|-----|
| TD-01 | **No service layer in backend** | Backend routes call DB models directly. No service layer for business logic. | `backend/fastapi/app/api/v1/*.py` | **P1-High** | Business logic mixed with HTTP concerns; hard to unit test | Extract service classes in Milestone 1 |
| TD-02 | **Legacy Flutter screens in apps/mobile_flutter** | 12 files from pre-monorepo era with different patterns (no Riverpod, no design system) | `apps/mobile_flutter/lib/features/*` | **P1-High** | Inconsistent patterns, duplicate code | Migrate to packages/ during Milestone 1 |
| TD-03 | **local_database_service.dart is skeleton** | Isar DB init has `// TODO` only. Offline-first not functional. | `packages/core/lib/storage/local_database_service.dart` | **P0-Critical** | No offline support — core requirement | Complete Isar initialization in Milestone 1 |
| TD-04 | **firebase.py exists as legacy** | Firebase Admin SDK code present but unused. Confusing to new developers. | `backend/fastapi/app/core/firebase.py` | **P2-Medium** | Dead code, maintenance burden | Remove or clearly mark as deprecated |
| TD-05 | **No type validation on env vars** | `.env.example` has 55 vars but no schema validation at startup | `backend/fastapi/app/config.py` | **P1-High** | Misconfiguration can silently break production | Add Pydantic model validation for all env vars |
| TD-06 | **Sentry not configured** | Error tracking dependency declared but DSN not configured | Flutter + Backend | **P2-Medium** | Silently failing in production | Set up Sentry project + DSN |
| TD-07 | **No API rate limiting** | All endpoints currently unlimited. No protection against abuse. | `backend/fastapi/app/` | **P1-High** | DOS vulnerability, tenant abuse | Add Redis-backed rate limiter middleware |
| TD-08 | **No audit logging on all mutations** | Only basic audit log table exists. Not all endpoints log yet. | `backend/fastapi/app/` | **P1-High** | HIPAA requirement, cannot trace issues | Add audit decorator to all state-changing endpoints |
| TD-09 | **WebSocket no auth guard** | WebSocket connections not authenticated. Any client can connect. | `backend/fastapi/app/api/v1/` | **P0-Critical** | Unauthorized access to real-time patient data | Add JWT verification on WS upgrade |
| TD-10 | **No refresh token rotation** | Refresh tokens issued but not rotated. Replay risk. | `backend/fastapi/app/core/security.py` | **P0-Critical** | Compromised refresh token = permanent access | Implement rotation on each refresh |
| TD-11 | **Isar code generation not set up** | Isar declared in pubspec but `build_runner` not configured to generate code | `packages/core/` | **P2-Medium** | Cannot use Isar models without code-gen | Add build_runner config + run after schema defined |
| TD-12 | **No connection pooling config** | SQLAlchemy uses defaults. No pool tuning for production load. | `backend/fastapi/app/database.py` | **P2-Medium** | DB connection exhaustion under load | Configure pool_size, max_overflow, pool_pre_ping |
| TD-13 | **Docker Compose no health checks** | Services start in order but no health check dependency waiting | `deployment/docker/` | **P2-Medium** | Race conditions on startup | Add health check + depends_on condition |
| TD-14 | **No data migration for multi-tenancy** | Current schema is single-tenant. Adding tenant_id requires migration. | Database schema | **P1-High** | Blocks EPIC 1 Enterprise Architecture | Plan migration from single to multi-tenant |
| TD-15 | **No CI for Flutter packages** | CI pipeline runs but doesn't test Flutter packages separately | `.github/workflows/ci.yml` | **P2-Medium** | Package-level bugs reach integration | Add per-package test jobs in CI |
| TD-16 | **No golden tests** | Widget tests don't have visual regression testing | Flutter test suite | **P3-Low** | UI regressions may go unnoticed | Add alchemist/ goldens for key screens |
| TD-17 | **No Flutter Web build tested** | Web entry point exists but never built in CI | `apps/web_flutter/` | **P2-Medium** | Web version may have build errors | Add `flutter build web` to CI |
| TD-18 | **No API docs versioning** | OpenAPI auto-generated but not version-controlled or published | Backend | **P3-Low** | API consumers lack stable reference | Publish versioned OpenAPI spec |
| TD-19 | **Empty Python service layer** | `backend/fastapi/app/services/__init__.py` is empty | Backend | **P1-High** | No separation of concerns in backend | Implement service layer |
| TD-20 | **No CORS restriction for WebSocket** | CORS handled for HTTP but WS may have different configuration | `backend/fastapi/app/main.py` | **P0-Critical** | WebSocket hijacking risk | Add WS origin validation |

---

## Debt Closure Plan

### Pre-v1.0 (Must Fix)

| ID | Hours | Assigned To |
|----|-------|-------------|
| TD-03 | 4 | Flutter |
| TD-09 | 3 | Backend |
| TD-10 | 3 | Backend |
| TD-20 | 2 | Backend |
| **Total** | **12h** | |

### v1.1 (Should Fix)

| ID | Hours | Assigned To |
|----|-------|-------------|
| TD-01 | 20 | Backend |
| TD-02 | 16 | Flutter |
| TD-05 | 4 | Backend |
| TD-07 | 8 | Backend |
| TD-08 | 8 | Backend |
| TD-14 | 12 | Backend |
| TD-19 | 16 | Backend |
| **Total** | **84h** | |

### v1.2 (Could Fix)

| ID | Hours | Assigned To |
|----|-------|-------------|
| TD-04 | 2 | Backend |
| TD-06 | 2 | DevOps |
| TD-11 | 3 | Flutter |
| TD-12 | 3 | Backend |
| TD-13 | 3 | DevOps |
| TD-15 | 4 | DevOps |
| TD-17 | 3 | DevOps |
| **Total** | **20h** | |

### v2.0 (Won't Fix Now)

| ID | Hours |
|----|-------|
| TD-16 | 16 |
| TD-18 | 4 |
| **Total** | **20h** |

---

## Debt Summary

| Priority | Count | Estimated Hours |
|----------|-------|----------------|
| P0-Critical | 3 | 12h |
| P1-High | 7 | 84h |
| P2-Medium | 8 | 20h |
| P3-Low | 2 | 20h |
| **Total** | **20 items** | **136h** |
