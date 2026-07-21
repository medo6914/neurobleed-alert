# Product Requirements Document — NeuroBleed Alert v1.0

---

## Vision

To eliminate preventable deaths from intracranial hemorrhage by making continuous, AI-powered brain monitoring accessible to every hospital bed — from elite neurosurgery centers to remote field clinics.

## Mission

Build a production-ready, regulatory-compatible medical monitoring platform that detects ICH in real time using wearable sensors + edge AI, alerts clinicians within seconds, and integrates seamlessly into existing hospital workflows — across the Middle East and globally.

---

## Target Users

| Segment | Description | Priority |
|---------|-------------|----------|
| Neurosurgeons | Primary decision-makers for ICH intervention | Primary |
| Intensivists / ICU Doctors | Manage critical patients at risk of ICH | Primary |
| ER Physicians | First contact for head trauma patients | Primary |
| Nurses (ICU/ER) | Continuous patient monitoring | Secondary |
| Hospital Administrators | Procurement and deployment decisions | Secondary |
| Paramedics / EMTs | Pre-hospital monitoring during transport | Secondary |
| Biomedical Engineers | Device setup, calibration, maintenance | Tertiary |
| Patients (Conscious) | Wearable device wearer (ambulatory monitoring) | Tertiary |
| Ministry of Health / Regulators | Compliance, certification, population health | Secondary |

---

## User Personas

### Dr. Ahmed Al-Rashid — Neurosurgeon
- **Age**: 45 | **Location**: Riyadh, Saudi Arabia | **Hospital**: King Faisal Specialist Hospital
- **Goals**: Detect post-surgical ICH before clinical deterioration. Reduce time-to-CT by 80%.
- **Pain Points**: Current monitoring relies on nurse checks every 30min. No continuous cerebral oxygenation data. Alerts arrive too late.
- **Needs**: Real-time rSO2 + ICP trends on mobile. AI risk score with SHAP explanation. Configurable alert thresholds.

### Nurse Layla Hassan — ICU Nurse
- **Age**: 29 | **Location**: Dubai, UAE | **Hospital**: Rashid Hospital
- **Goals**: Monitor 4+ patients simultaneously. Escalate critical changes immediately.
- **Pain Points**: Alarm fatigue from false positives. Difficult to spot subtle trends across patients. Handoff communication gaps.
- **Needs**: Clear severity-coded alerts. At-a-glance dashboard. Offline access to patient data. Arabic interface.

### Dr. Omar Khalid — ER Physician
- **Age**: 38 | **Location**: Cairo, Egypt | **Hospital**: Cairo University Hospital
- **Goals**: Rapidly triage head trauma patients. Decide on CT need within minutes.
- **Pain Points**: No objective rSO2 data in ER. Relies on GCS alone. Decision uncertainty leads to unnecessary CTs.
- **Needs**: Quick穿戴 device application. 60-second risk assessment. Integration with hospital EMR.

---

## User Stories

### Epic: Patient Monitoring
| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|-------------------|
| US-01 | As a neurosurgeon, I want to see real-time vital signs (HR, SpO2, BP, rSO2, ICP, CPP) for my patients, so I can detect deterioration immediately. | Must Have | Vitals update within 1s via WebSocket. 8 parameters displayed. Historical trend visible on tap. |
| US-02 | As a nurse, I want to receive color-coded alerts (critical/warning/info) so I can prioritize my response. | Must Have | Critical = red, Warning = orange, Info = blue. Push notification + in-app banner. |
| US-03 | As a doctor, I want to view a patient's vital trends over 1h/6h/24h, so I can assess progression. | Must Have | Selectable time windows. Line chart with zoom. |
| US-04 | As a clinician, I want the system to work offline so I can access patient data when WiFi is unavailable. | Must Have | Full patient list + vitals cached locally. Sync when online. |
| US-05 | As a doctor, I want AI risk scores with explanations so I understand why an alert was triggered. | Should Have | Risk score 0–1. Top 3 contributing features shown. |

### Epic: Device Management
| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|-------------------|
| US-06 | As a biomedical engineer, I want to pair a device with a patient via BLE, so monitoring can begin. | Must Have | Scan, select, pair within 30s. Confirm signal quality. |
| US-07 | As a nurse, I want to see device battery level and signal quality so I know if the device is reliable. | Must Have | Battery % + signal bars visible on patient card. Alert if <20% battery. |
| US-08 | As a hospital admin, I want to register devices to my hospital, so I can track inventory. | Must Have | Serial number entry. Assign to patient/bed. |

### Epic: Authentication & Access
| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|-------------------|
| US-09 | As a doctor, I want to log in with email/password so I can access patient data securely. | Must Have | Login with validation. JWT stored securely. Auto-logout after 1h. |
| US-10 | As a hospital admin, I want to assign roles to staff, so they see only relevant data. | Must Have | Role selection during registration. Permissions enforced on all endpoints. |
| US-11 | As a user, I want to use the app in Arabic or English, so I can work in my preferred language. | Must Have | Switch at any time. Full RTL support for Arabic. |

### Epic: Emergency Response
| ID | Story | Priority | Acceptance Criteria |
|----|-------|----------|-------------------|
| US-12 | As a doctor, I want an SOS button that alerts all on-call staff, so emergencies aren't missed. | Should Have | One-tap alert. SMS + WebSocket notification to on-call team. Response tracking. |
| US-13 | As a paramedic, I want to apply the device in the field and transmit data to the receiving hospital, so they're prepared. | Should Have | Device pairing in ambulance. Data relay via cellular. Hospital dashboard updates automatically. |

---

## Business Goals

| Goal | Metric | Target | Timeline |
|------|--------|--------|----------|
| Clinical Accuracy | AUC of ICH detection | > 0.95 | v1.0 |
| Speed | Time from physiological change to clinician alert | < 5 seconds | v1.0 |
| Adoption | Hospitals deployed | 3 pilot hospitals | v1.0 launch |
| Patient Safety | False alert rate per patient per day | < 3 | v1.0 |
| Scalability | Concurrent patients per server | > 500 | v1.0 |
| Revenue | Annual recurring revenue from pilots | > $500K | Year 1 |
| Regulatory | Regulatory pathway identified | FDA 510(k) + SFDA + CE | v1.0 |
| Usability | System Usability Scale (SUS) score | > 80 | v1.1 |

---

## KPIs & Success Metrics

### Clinical KPIs
- **Time-to-alert**: Mean + P99 latency from physiological change to clinician notification
- **Detection rate**: True positive rate for ICH events during monitored period
- **False positive rate**: Non-actionable alerts per patient-day
- **CT utilization**: Change in CT scan rate with NeuroBleed monitoring vs without

### Operational KPIs
- **Device uptime**: Percentage of time device is actively monitoring
- **Data completeness**: Percentage of expected readings actually captured
- **Sync latency**: Time from offline action to cloud sync completion
- **User adoption**: DAU/MAU ratio among subscribed clinicians

### Business KPIs
- **MRR**: Monthly recurring revenue from subscriptions
- **CAC**: Customer acquisition cost per hospital
- **LTV**: Lifetime value per hospital account
- **Churn rate**: Percentage of hospitals not renewing
- **NPS**: Net Promoter Score among clinicians

### Technical KPIs
- **API P99 latency**: < 200ms for all CRUD endpoints
- **WebSocket uptime**: > 99.9%
- **Test coverage**: > 90% across all packages
- **Deployment frequency**: Weekly releases during active development
