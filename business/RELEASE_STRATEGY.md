# Release Strategy — NeuroBleed Alert

---

## Version Philosophy

**Semantic Versioning** (MAJOR.MINOR.PATCH):
- **MAJOR**: Architecture change, regulatory milestone, breaking API changes
- **MINOR**: New features, non-breaking additions
- **PATCH**: Bug fixes, security patches, performance improvements

**Release Cadence**: Minor releases every 6–8 weeks during active development. Patches as needed (hotfix).

---

## Version 1.0 — "Foundation" (Target: Q1 2027)

**Theme**: Core platform operational — first hospital pilots.

### Includes
- ✅ Flutter Mobile (Android + iOS) — Patient monitoring, alerts, device management
- ✅ Flutter Web Dashboard — Admin panel, patient overview
- ✅ FastAPI Backend — All CRUD APIs, WebSocket, Redis Streams
- ✅ PostgreSQL Database — Multi-tenant schema, migrations
- ✅ Authentication — JWT, RBAC, refresh tokens, audit logs
- ✅ Localization — Arabic + English, RTL/LTR, dynamic switching
- ✅ Design System — Full token system + 7 components
- ✅ Offline-First — Isar local DB, sync engine
- ✅ Enterprise Architecture — Multi-tenant, organizations, hospitals
- ✅ API — Versioning, OpenAPI docs, health checks
- ✅ DevOps — Docker Compose, CI/CD, environment management
- ✅ AI Engine (Beta) — XGBoost risk scoring deployed
- ✅ Technical Debt — All P0 items fixed

### Not Included (v1.0 Explicit Scope)
- ❌ Hardware/Firmware — Frozen until "ابدأ جزء الجهاز"
- ❌ FDA/SFDA clearance — Application started but not completed
- ❌ FHIR/HL7 integration — Adapter built but not deployed
- ❌ MFA — Designed but not implemented
- ❌ Performance/load testing — Basic checks only
- ❌ Grafana dashboards — Docker config ready, dashboards created

### v1.0 Release Criteria
| Criteria | Target | Status |
|----------|--------|--------|
| All P0 technical debt resolved | 3 items | ⬜ |
| All Must-Have MoSCoW tasks complete | 45 tasks | ⬜ |
| Backend test coverage > 85% | pytest | ⬜ |
| Flutter test coverage > 75% | flutter_test | ⬜ |
| 3 hospital pilot agreements signed | MOUs | ⬜ |
| AI model AUC > 0.90 on validation set | Internal | ⬜ |
| Security audit passes | OWASP scan | ⬜ |

---

## Version 1.1 — "Clinical" (Target: Q2 2027)

**Theme**: Clinical validation + regulatory progress + first paid customers.

### New Features
- Clinical Reports Generator (PDF)
- Emergency Workflow (SOS button)
- FHIR R4 API Adapter (production-ready)
- HL7 v2 Message Parser
- Knowledge Center (RAG-based)
- AI Monitoring Dashboard
- Performance / Load Testing
- Grafana Dashboards operational

### Improvements
- All P1 technical debt resolved (84h)
- Rate limiting on all endpoints
- Full audit logging
- Service layer refactoring in backend
- Legacy Flutter screens migration complete
- Multi-tenancy data migration
- Sentry error tracking configured

### Release Criteria
- 3 pilot hospitals live for 3+ months
- Clinical validation data published
- SFDA registration application submitted
- NPS score > 40 from pilot users
- SaaS revenue > $10K MRR

---

## Version 1.2 — "Scale" (Target: Q3–Q4 2027)

**Theme**: Scale to 25+ hospitals + regulatory clearance.

### New Features
- Enterprise License tier
- Advanced analytics dashboard
- Population health reports (anonymized)
- Custom alert rules per hospital
- Third-party device integration API
- Billing/invoicing system
- On-premise deployment option

### Improvements
- All P2 technical debt resolved (20h)
- Isar code generation automated
- Docker health checks operational
- CI covers Flutter packages individually
- Flutter Web build tested in CI
- Connection pooling tuned for production

### Regulatory
- SFDA registration received
- FDA 510(k) application submitted
- CE marking application submitted

### Release Criteria
- 25 hospitals live
- $100K MRR
- 99.9% platform uptime (3 months)
- FDA submission accepted for review

---

## Version 2.0 — "Global" (Target: 2028)

**Theme**: US market entry + hardware integration + platform maturity.

### New Features
- **Hardware Platform** — ESP32 firmware, sensors, BLE pairing (unfrozen)
- **Hardware Validation** — Accuracy, battery life, reliability testing
- **MFA** — TOTP/WebAuthn multi-factor authentication
- **Global Deployment** — US + EU cloud regions
- **HIPAA/FDA Compliance** — Full regulatory clearance
- **Advanced AI** — Ensemble of XGBoost + Deep Learning
- **Multi-language** — Add French, German, Turkish
- **Mobile SDK** — Third-party integration SDK for hospitals
- **Offline Edge AI** — Risk inference on device (no cloud needed)

### Improvements
- All P3 technical debt resolved (20h)
- Golden test suite comprehensive
- API docs versioned and published
- Performance benchmark published
- Full disaster recovery tested

### Release Criteria
- FDA 510(k) clearance
- CE marking (EU MDR)
- 75+ hospitals live
- $500K MRR
- Hardware integrated and validated
- Publication in peer-reviewed journal

---

## Release Timeline

```
v1.0 ──────────────── Q1 2027
  Foundation + Pilots
     │
v1.1 ──────────────── Q2 2027
  Clinical + Regulatory
     │
v1.2 ──────────────── Q3–Q4 2027
  Scale + SFDA Clearance
     │
v2.0 ──────────────── 2028
  Global + Hardware + FDA
```

---

## Version Support Policy

| Version | Active Support | Security Patches | End of Life |
|---------|---------------|------------------|-------------|
| v1.0 | Until v1.1 release | 6 months after v1.1 | v1.2 release |
| v1.1 | Until v1.2 release | 12 months after v1.2 | v2.0 release |
| v1.2 | Until v2.0 release | 18 months after v2.0 | v2.1 release |
| v2.0 | Ongoing | 24 months after next major | TBD |

**Hotfix Policy**: P0 (security, data loss) issues patched within 24 hours for all supported versions.
