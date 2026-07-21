# Quality & Regulatory References

> Regulatory Framework Reference
> **Important**: This is a reference for design — NOT a certification claim.
> Full regulatory compliance requires certification by accredited bodies.

---

## Regulatory Standards Map

```
┌────────────────────────────────────────────────────────────────────────┐
│                   MEDICAL SOFTWARE REGULATORY FRAMEWORK                 │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                  QUALITY MANAGEMENT SYSTEM                        │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐   │   │
│  │  │ ISO 13485:2016│  │ ISO 9001:2015│  │ 21 CFR Part 820 (QSR)│   │   │
│  │  │ Medical QMS  │  │ General QMS  │  │ US FDA Quality System│   │   │
│  │  └──────────────┘  └──────────────┘  └───────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                RISK MANAGEMENT                                    │   │
│  │  ┌────────────────────────────────────────────────────────────┐   │   │
│  │  │  ISO 14971:2019 — Medical Devices — Risk Management        │   │   │
│  │  │  ├── Risk Analysis                                         │   │   │
│  │  │  ├── Risk Evaluation                                       │   │   │
│  │  │  ├── Risk Control                                          │   │   │
│  │  │  └── Residual Risk Evaluation                              │   │   │
│  │  └────────────────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │              SOFTWARE LIFE CYCLE                                  │   │
│  │  ┌────────────────────────────────────────────────────────────┐   │   │
│  │  │  IEC 62304:2023 — Medical Software Life Cycle Processes   │   │   │
│  │  │  ├── Software Development Planning                         │   │   │
│  │  │  ├── Software Requirements Analysis                        │   │   │
│  │  │  ├── Software Architectural Design                         │   │   │
│  │  │  ├── Software Detailed Design                              │   │   │
│  │  │  ├── Software Unit Implementation                          │   │   │
│  │  │  ├── Software Integration Testing                          │   │   │
│  │  │  ├── Software System Testing                               │   │   │
│  │  │  └── Software Release                                      │   │   │
│  │  └────────────────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │              SAFETY & PERFORMANCE                                 │   │
│  │  ┌────────────────────────────────────────────────────────────┐   │   │
│  │  │  IEC 60601 Series — Medical Electrical Equipment           │   │   │
│  │  │  ├── 60601-1: General Safety Requirements                  │   │   │
│  │  │  ├── 60601-1-2: EMC Requirements                           │   │   │
│  │  │  ├── 60601-1-6: Usability                                  │   │   │
│  │  │  ├── 60601-1-8: Alarm Systems                              │   │   │
│  │  │  ├── 60601-1-11: Home Healthcare                           │   │   │
│  │  │  └── 60601-2-xx: Particular Standards (if applicable)     │   │   │
│  │  └────────────────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │              DATA PRIVACY & SECURITY                              │   │
│  │  ┌────────────────────┐  ┌────────────────────┐  ┌────────────┐   │   │
│  │  │  HIPAA (US)        │  │  GDPR (EU)         │  │  PDPL      │   │   │
│  │  │  ┌──────────────┐  │  │  ┌──────────────┐  │  │  (KSA)     │   │   │
│  │  │  │Privacy Rule  │  │  │  │Data           │  │  │            │   │   │
│  │  │  │Security Rule │  │  │  │Protection     │  │  │            │   │   │
│  │  │  │Breach        │  │  │  │GDPR Articles  │  │  │            │   │   │
│  │  │  │Notification  │  │  │  │DSAR, DPIA     │  │  │            │   │   │
│  │  │  └──────────────┘  │  │  └──────────────┘  │  │            │   │   │
│  │  └────────────────────┘  └────────────────────┘  └────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 1. ISO 13485:2016 — Medical Devices Quality Management System

### Scope
Requirements for a quality management system for medical device design and production.

### Relevance to NeuroBleed Alert

| Clause | Requirement | Our Implementation |
|--------|-------------|-------------------|
| 4.1 | Quality Management System | Documentation structure, controlled processes |
| 7.1 | Product Realization Planning | Milestones, phase-gate process |
| 7.3 | Design and Development | Architecture-first approach, design reviews |
| 7.3.3 | Design Inputs | SRS document — functional + non-functional requirements |
| 7.3.4 | Design Outputs | SDD, architecture diagrams, specifications |
| 7.3.5 | Design Review | Architecture Approval document, code reviews |
| 7.3.6 | Design Verification | Unit tests, integration tests, API tests |
| 7.3.7 | Design Validation | Clinical validation, user acceptance testing |
| 7.5 | Production and Service Provision | Docker deployment, CI/CD pipeline |
| 8.2 | Monitoring and Measurement | Observability stack, metrics, alerts |
| 8.3 | Nonconforming Product | Error tracking (Sentry), bug reports |
| 8.5 | Improvement | Iterative development, post-release monitoring |

### Current Status
- **Design Controls**: Partially implemented (architecture docs, design reviews)
- **QMS Documentation**: Document structure established
- **Risk Management**: ISO 14971 architecture designed
- **Full Certification**: Requires external audit — not in current scope

---

## 2. ISO 14971:2019 — Risk Management for Medical Devices

### Risk Management Process

```
┌──────────────┐
│ Risk Analysis │
│               │
│ ┌─────────┐   │
│ │ Intended │   │
│ │ Use      │   │
│ └────┬────┘   │
│      │        │
│ ┌────┴────┐   │
│ │ Hazard   │   │
│ │ Identify │   │
│ └────┬────┘   │
│      │        │
│ ┌────┴────┐   │
│ │ Risk    │   │
│ │ Estimate│   │
│ └────┬────┘   │
└──────┼────────┘
       │
┌──────┴────────┐
│ Risk Evaluation│
│ Acceptable?    │
│ YES → Proceed  │
│ NO  → Control  │
└──────┬────────┘
       │
┌──────┴────────┐
│ Risk Control   │
│ ┌─────────┐   │
│ │ Option 1│   │
│ │ Option 2│   │
│ │ Option 3│   │
│ └────┬────┘   │
│      │        │
│ ┌────┴────┐   │
│ │Residual │   │
│ │Risk Eval│   │
│ └────┬────┘   │
└──────┼────────┘
       │
┌──────┴────────┐
│ Risk Mgmt     │
│ Report        │
└───────────────┘
```

### Key Hazards Identified

| Hazard ID | Hazard | Cause | Severity | Probability | Risk Level | Control |
|-----------|--------|-------|----------|-------------|------------|---------|
| H-001 | Missed ICH detection | AI model failure | Critical | Low | Medium | Dual-engine (Edge + Cloud), Clinical rules override |
| H-002 | False alarm causing alert fatigue | AI over-sensitivity | Moderate | Medium | Medium | Calibration, tunable thresholds, severity levels |
| H-003 | Data loss during transmission | Network failure | Moderate | Medium | Medium | Offline queue, retry, data integrity checks |
| H-004 | Battery failure during monitoring | Hardware failure | Moderate | Low | Low | Battery monitoring, low-battery alert, reserve mode |
| H-005 | Unauthorized patient data access | Security breach | Critical | Low | Medium | JWT, TLS, audit logs, access control, encryption |
| H-006 | Incorrect sensor placement | User error | Moderate | Medium | Medium | Signal quality monitoring, placement guide in app |
| H-007 | Delayed alert delivery | System overload | Critical | Low | Medium | Message queue, priority queuing, redundancy |
| H-008 | Firmware update failure | OTA corruption | Moderate | Low | Low | Dual-slot bootloader, signature verification, rollback |

---

## 3. IEC 62304:2023 — Medical Software Life Cycle Processes

### Software Safety Classification

```
Class A: No injury or damage to health
  - Feature examples: Settings, user profile, reports

Class B: Non-serious injury possible
  - Feature examples: Patient list, historical data display

Class C: Death or serious injury possible
  - Feature examples: Risk assessment, alert generation, 
    real-time monitoring, decision support

NeuroBleed Alert primary classification: CLASS C
(Because a missed ICH detection can lead to death or serious injury)
```

### IEC 62304 Requirements for Class C Software

| Requirement | Our Implementation | Evidence |
|-------------|-------------------|----------|
| Software Development Plan | SRS + SDD + Milestone plan | docs/manuals/ |
| Software Requirements | SRS document | docs/manuals/SRS.md |
| Software Architecture | Architecture Book | docs/architecture/ |
| Software Detailed Design | All architecture docs | docs/ |
| Unit Verification | Unit tests | test/ |
| Integration Testing | API + Integration tests | tests/ |
| System Testing | E2E tests | tests/ |
| Software Release | CI/CD pipeline | .github/workflows/ |
| Problem Resolution | Sentry + Bug tracker | Sentry |
| Software Maintenance | Maintenance guide | docs/manuals/ |
| Risk Management | ISO 14971 plan | docs/quality/REGULATORY.md |
| Software Change | Version control + changelog | CHANGELOG.md |

---

## 4. IEC 60601 Series — Medical Electrical Equipment

### Applicable Standards for the Wearable Device

| Standard | Title | Status |
|----------|-------|--------|
| IEC 60601-1 | General safety requirements for ME equipment | Design reference |
| IEC 60601-1-2 | Electromagnetic compatibility (EMC) | Design reference |
| IEC 60601-1-6 | Usability engineering | Design reference |
| IEC 60601-1-8 | Alarm systems | Design reference |
| IEC 60601-1-11 | Requirements for home healthcare | Design reference |
| IEC 60601-2-xx | Particular standards (if classified as monitor) | TBD |

### Design Implications
- **Isolation**: Patient-accessible parts must meet 2MOPP (2 Means of Patient Protection)
- **Leakage Current**: < 10 microamps for patient-connected parts
- **EMC**: Radiated emissions, immunity to medical environment interference
- **Alarm Priority**: High/Medium/Low with distinct audio/visual indicators

---

## 5. HIPAA (Health Insurance Portability and Accountability Act)

### HIPAA Rules Applied

| HIPAA Rule | Requirement | Implementation |
|-----------|-------------|----------------|
| **Privacy Rule** | Protected Health Information (PHI) protection | Encryption at rest + transit, access control, audit logs |
| **Security Rule** | Administrative, physical, technical safeguards | RBAC, authentication, encryption, logging |
| **Breach Notification Rule** | Notification of PHI breaches | Monitoring, alerting, incident response plan |
| **Enforcement Rule** | Penalties for non-compliance | Compliance documentation, regular audits |

### HIPAA Technical Safeguards (45 CFR § 164.312)

| Safeguard | Implementation |
|-----------|---------------|
| Access Control | JWT + RBAC |
| Unique User Identification | Email + UUID + Role |
| Emergency Access | Break-glass procedure for critical alerts |
| Automatic Logoff | Token expiration (1 hour), app auto-lock |
| Encryption (at rest) | AES-256 for all PHI fields |
| Encryption (in transit) | TLS 1.2+ for all communications |
| Integrity Controls | Checksums, audit trails, version tracking |
| Person/Entity Authentication | Multi-factor (password + OTP/Google) |
| Audit Controls | Comprehensive audit logs (7-year retention) |

---

## 6. GDPR (General Data Protection Regulation)

### GDPR Principles Applied

| GDPR Article | Principle | Implementation |
|-------------|-----------|----------------|
| Art. 5 | Lawfulness, fairness, transparency | Privacy policy, consent management |
| Art. 5(1)(c) | Data minimization | Only essential medical data collected |
| Art. 5(1)(e) | Storage limitation | Data retention policies (see Backup & DR) |
| Art. 7 | Consent | Explicit consent for data processing |
| Art. 17 | Right to erasure | Patient data deletion workflow |
| Art. 20 | Data portability | FHIR export, JSON/CSV download |
| Art. 25 | Data protection by design | Architecture-level privacy controls |
| Art. 32 | Security of processing | Encryption, access control, audit |
| Art. 33 | Data breach notification | Automated alerting, incident response |
| Art. 35 | Data Protection Impact Assessment | DPIA documented |

### Data Processing Register (Art. 30)

| Processing Activity | Purpose | Legal Basis | Data Categories | Retention |
|-------------------|---------|-------------|-----------------|-----------|
| Patient Monitoring | Clinical decision support | Vital interest (Art. 9(2)(c)) | Health data, vital signs | 10 years |
| AI Risk Assessment | Risk prediction | Explicit consent | Health data | 2 years |
| Device Pairing | Device management | Contract (Art. 6(1)(b)) | Device identifiers | Device lifetime |
| User Account | Access control | Contract (Art. 6(1)(b)) | Name, email, role | Account lifetime |
| Audit Logs | Security, compliance | Legal obligation (Art. 6(1)(c)) | User actions, IP | 7 years |

---

## 7. Regulatory Strategy Roadmap

```
Phase 1: Academic Prototype (Current)
  - Design reference to ISO 13485, IEC 62304, ISO 14971
  - Architecture documents reference standards
  - No regulatory submission

Phase 2: Clinical Pilot (Post-MVP)
  - ISO 14971 Risk Management File (preliminary)
  - IEC 62304 Software Classification
  - Institutional ethics approval for pilot study
  - HIPAA/GDPR compliance audit

Phase 3: Regulatory Submission (Future)
  - Full ISO 13485 QMS implementation
  - IEC 62304 certification (Class C)
  - ISO 14971 Risk Management Report
  - FDA 510(k) clearance (US) or
  - CE Marking under MDR (EU) or
  - SFDA approval (KSA)
  - IEC 60601 testing for wearable device

Phase 4: Post-Market (Future)
  - PMS (Post-Market Surveillance)
  - PMCF (Post-Market Clinical Follow-up)
  - CAPA (Corrective and Preventive Actions)
  - Periodic Safety Update Reports
```

---

## Disclaimer

> This document serves as an **architectural reference and design framework** for the NeuroBleed Alert academic prototype. It identifies relevant regulatory standards and their design implications to ensure the architecture supports future certification pathways.
>
> **The NeuroBleed Alert project has NOT obtained any of the following certifications:**
> - ISO 13485:2016 certification
> - ISO 14971:2019 compliance verification
> - IEC 62304:2023 software certification
> - IEC 60601 series testing
> - FDA 510(k) clearance
> - CE marking
> - HIPAA compliance audit
>
> These standards are used as **design references only** to ensure the architecture can support future regulatory pathways.
>
> Clinical deployment requires formal certification by accredited bodies, which is outside the scope of this academic prototype.
