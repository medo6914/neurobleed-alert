# Business Model Canvas — NeuroBleed Alert

---

## Value Proposition

| Component | Description |
|-----------|-------------|
| **Core Product** | Continuous, AI-powered intracranial hemorrhage monitoring system combining a wearable NIRS sensor with cloud-based risk assessment and real-time clinician alerts |
| **Primary Value** | Early ICH detection — before clinical symptoms manifest — reducing time-to-intervention from hours to seconds |
| **Secondary Value** | Objective cerebral oxygenation data replaces subjective clinical assessment; reduces unnecessary CT scans; enables remote monitoring |
| **Differentiator** | End-to-end system (hardware + software + AI) optimized specifically for ICH — not a generic vital signs monitor |

### Value for Each Segment

| Segment | Value |
|---------|-------|
| **Neurosurgeons** | Continuous rSO2 + ICP monitoring post-surgery. AI alerts for silent ICH. SHAP explanations for every risk score. |
| **ICU Doctors** | Monitor 4+ patients from mobile device. Severity-coded alerts. Trend analysis for early intervention. |
| **ER Physicians** | 60-second ICH risk assessment on admission. Objective data for CT decision. Reduces medicolegal uncertainty. |
| **Hospital Administrators** | Reduced CT costs. Improved patient outcomes (reduced mortality/LOS). Compliance with quality metrics. Competitive differentiation. |
| **Paramedics** | Field-deployable monitoring. Real-time data relay to receiving hospital. Better triage decisions. |

---

## Customer Segments

| Segment | Sub-Segments | Size (KSA/UAE/EGY) | Priority |
|---------|--------------|--------------------|----------|
| **Tier 1 Hospitals** | Government tertiary (200+ beds) | ~150 hospitals | Primary |
| **Tier 2 Hospitals** | Private secondary (50-200 beds) | ~400 hospitals | Secondary |
| **Academic Medical Centers** | University hospitals + research | ~50 centers | Primary |
| **Defense / Military** | Military hospitals + field units | ~30 facilities | Secondary |
| **Ambulance Services** | Private + government EMS | ~20 providers | Tertiary |

**Initial Beachhead**: Government tertiary hospitals in Saudi Arabia (Ministry of Health) — 50+ hospitals with neurosurgery capacity.

---

## Channels

| Channel | Type | Purpose | Cost |
|---------|------|---------|------|
| **Direct Sales** | B2B field sales team | Hospital procurement cycles | High (but necessary) |
| **Clinical Conferences** | Medical conferences (Neurosurgery, ICU) | Thought leadership, demos | Medium |
| **Distributors (Medical Devices)** | Partner channel | Reach smaller hospitals | Commission-based |
| **Ministry of Health Tenders** | Government procurement | Large-scale deployments | Low acquisition cost |
| **Telemedicine Platforms** | Integration partner | Bundle with existing telehealth | Revenue share |
| **App Stores** | Digital (iOS/Android) | Direct user acquisition | Low (brand awareness) |

**Primary Channel (v1.0)**: Direct B2B sales + Ministry of Health tender participation.

---

## Revenue Streams

| Stream | Model | Price Point | Target | Timeline |
|--------|-------|-------------|--------|----------|
| **Hospital Subscription (SaaS)** | Per-bed/month subscription | $200–500/bed/month | 500 beds in Year 1 | v1.0 |
| **Device Hardware** | One-time device purchase | $2,000–5,000/device | 200 devices in Year 1 | v1.0 |
| **Enterprise License** | Annual site license for hospital group | $50K–$200K/year | 10 enterprise deals Year 2 | v1.1 |
| **AI-as-a-Service** | Per-assessment fee | $0.50–$1.00/assessment | > 1M assessments/year | v1.2 |
| **Data Insights (Anonymized)** | Aggregated population health reports | Custom pricing | Research institutions | v2.0 |
| **Training & Certification** | Per-person certification program | $500–$2,000/person | 1,000 clinicians/year | v1.1 |

**Expected Revenue Mix Year 1**: 60% hardware + 30% subscription + 10% training.

---

## Cost Structure

| Category | Items | Annual Cost (Est.) |
|----------|-------|---------------------|
| **R&D (Engineering)** | 4 Flutter + 4 Backend + 2 AI + 2 Hardware + 1 DevOps | $600K |
| **Hardware BOM** | ESP32-S3, MAX30102, NIRS sensor, PCB, enclosure, battery | $150–300/unit |
| **Cloud Infrastructure** | 3× servers, PostgreSQL, Redis, object storage | $60K |
| **Regulatory** | FDA 510(k) consultant, testing labs | $200K (one-time) |
| **Sales & Marketing** | Conferences, demos, sales team | $150K |
| **Legal & Compliance** | HIPAA/GDPR/PDPL, contracts, IP | $80K |
| **Clinical Validation** | IRB-approved study costs | $100K |
| **Office & Admin** | Tools, licenses, rent | $50K |

**Estimated Year 1 Burn Rate**: ~$1.2M + hardware COGS.

---

## Key Activities

| Activity | Description | Phase |
|----------|-------------|-------|
| **Software Development** | Flutter apps + FastAPI backend + AI engine | Milestones 1–9 |
| **Hardware Engineering** | ESP32 firmware, sensor drivers, PCB design | Milestones 10–13 |
| **Clinical Validation** | IRB study, accuracy benchmarking, usability testing | v1.0–v1.1 |
| **Regulatory Clearance** | FDA 510(k), SFDA, CE marking | v1.0–v1.2 |
| **Hospital Pilots** | Beta deployment at 3 hospitals | v1.0 |
| **IP Protection** | Patents for AI algorithm + device design | v1.0 |

---

## Key Resources

| Resource | Description | Status |
|----------|-------------|--------|
| **Engineering Team** | Current team with full-stack + AI + hardware capability | ✅ Active |
| **Medical Advisory Board** | Neurosurgeons + intensivists for clinical guidance | ⬜ Needed |
| **Software Platform** | Flutter + FastAPI + PostgreSQL + Redis | ✅ Built |
| **Hardware Design** | ESP32-S3 + sensor selection | ⬜ To build |
| **AI Models** | XGBoost risk engine | ⬜ To train |
| **Regulatory Expertise** | FDA/SFDA/CE consultant | ⬜ Needed |
| **IP Portfolio** | Algorithms, device design | ⬜ To file |
| **Clinical Data** | Training and validation datasets | ⬜ To collect |

---

## Key Partners

| Partner | Role | Strategic Value |
|---------|------|-----------------|
| **Ministry of Health (KSA)** | First customer, regulatory pathway | Market access, credibility |
| **University Hospitals** | Clinical validation sites | Research publications, IRB |
| **Sensor Manufacturers** | NIRS sensor supply chain | Critical component sourcing |
| **AWS / Oracle Cloud** | Cloud infrastructure | HIPAA-compliant hosting |
| **Twilio** | SMS/Voice notifications | Communication infrastructure |
| **Medical Distributors** | Sales channel in UAE, Egypt | Regional expansion |
| **EMR Vendors** | Integration partners (Epic, Cerner, Seha) | Hospital workflow integration |
| **AI Research Labs** | Model improvement, validation | Technical credibility |
