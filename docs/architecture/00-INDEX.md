# NeuroBleed Alert — Architecture Documentation Index

> Professional Medical Software Prototype
> Architecture Index — Complete

---

## Document Structure

```
docs/
├── architecture/          # Overall system architecture
│   ├── 00-INDEX.md
│   ├── 01-system-overview.md
│   ├── 02-backend-architecture.md
│   └── 03-deployment-architecture.md
├── ai/                    # AI Architecture (document 1)
│   └── AI_ARCHITECTURE.md
├── device/                # Device Software Architecture (document 2)
│   └── DEVICE_ARCHITECTURE.md
├── flutter/               # Flutter Architecture (document 3)
│   └── FLUTTER_ARCHITECTURE.md
├── design-system/         # Design System (document 4)
│   └── DESIGN_SYSTEM.md
├── offline-first/         # Offline First Architecture (document 5)
│   └── OFFLINE_FIRST.md
├── telemetry/             # Telemetry Pipeline (document 6)
│   └── TELEMETRY_PIPELINE.md
├── message-queue/         # Message Queue (document 7)
│   └── MESSAGE_QUEUE.md
├── observability/         # Observability (document 8)
│   └── OBSERVABILITY.md
├── backup/                # Backup & Disaster Recovery (document 9)
│   └── BACKUP_DR.md
├── standards/             # Medical Data Standards (document 10)
│   └── MEDICAL_STANDARDS.md
├── ai/                    # AI Validation (document 11)
│   └── AI_VALIDATION.md
├── telemetry/             # Data Processing Pipeline (document 12)
│   └── DATA_PIPELINE.md
├── manuals/               # Professional Documentation (document 13)
│   └── DOCUMENTATION_INDEX.md
├── quality/               # Quality & Regulatory References (document 14)
│   └── REGULATORY.md
├── approval/              # Architecture Approval (document 15)
│   └── ARCHITECTURE_APPROVAL.md
└── diagrams/              # Architecture diagrams (text-based)
    └── DIAGRAMS.md
```

---

## Quick Navigation

| Document | Description |
|----------|-------------|
| [AI Architecture](../ai/AI_ARCHITECTURE.md) | AI Gateway, Risk Engine, RAG, LLM, TinyML, PubMed |
| [Device Architecture](../device/DEVICE_ARCHITECTURE.md) | HAL, Drivers, BLE, Cellular, OTA, TinyML Runtime |
| [Flutter Architecture](../flutter/FLUTTER_ARCHITECTURE.md) | Feature-First Clean Architecture with Riverpod |
| [Design System](../design-system/DESIGN_SYSTEM.md) | Medical UI/UX, Colors, Typography, Components |
| [Offline First](../offline-first/OFFLINE_FIRST.md) | Isar, Sync Engine, Conflict Resolution |
| [Telemetry Pipeline](../telemetry/TELEMETRY_PIPELINE.md) | Sensor → ESP32 → Cloud → App |
| [Message Queue](../message-queue/MESSAGE_QUEUE.md) | Redis Streams for async messaging |
| [Observability](../observability/OBSERVABILITY.md) | Prometheus, Grafana, Sentry, Tracing |
| [Backup & DR](../backup/BACKUP_DR.md) | Recovery strategy, replication |
| [Medical Standards](../standards/MEDICAL_STANDARDS.md) | HL7, FHIR, LOINC, SNOMED, ICD-10 |
| [AI Validation](../ai/AI_VALIDATION.md) | Metrics, ROC, Explainability |
| [Data Pipeline](../telemetry/DATA_PIPELINE.md) | Signal processing, feature extraction |
| [Documentation](../manuals/DOCUMENTATION_INDEX.md) | SRS, SDD, User Manuals |
| [Regulatory](../quality/REGULATORY.md) | ISO 13485, IEC 62304, HIPAA, GDPR |
| [Architecture Approval](../approval/ARCHITECTURE_APPROVAL.md) | Final review & sign-off |

---

**Status**: Architecture Complete
**Next**: Ready to begin Milestone 1
