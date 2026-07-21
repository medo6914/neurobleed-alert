# Medical Data Standards

> Medical Data Standards — Complete

---

## Standards Overview

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         MEDICAL STANDARDS MAP                              │
│                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      DATA EXCHANGE LAYER                             │   │
│  │                                                                      │   │
│  │  ┌──────────┐    ┌──────────┐    ┌──────────┐                       │   │
│  │  │   HL7    │    │   FHIR   │    │   DICOM  │                       │   │
│  │  │ Version 2 │    │  R4/R5   │    │  (Images)│                       │   │
│  │  │ (Legacy) │    │ (Modern)  │    │          │                       │   │
│  │  └──────────┘    └──────────┘    └──────────┘                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    VOCABULARY & CODING LAYER                         │   │
│  │                                                                      │   │
│  │  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐       │   │
│  │  │  LOINC   │    │ SNOMED   │    │  ICD-10  │    │  RxNorm  │       │   │
│  │  │ (Labs)   │    │  CT      │    │ (Disease)│    │ (Drugs)  │       │   │
│  │  │          │    │ (Clinical)│   │          │    │          │       │   │
│  │  └──────────┘    └──────────┘    └──────────┘    └──────────┘       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    DEVICE DATA LAYER                                  │   │
│  │                                                                      │   │
│  │  ┌──────────┐    ┌──────────┐    ┌──────────┐                       │   │
│  │  │   IEEE   │    │  HL7     │    │  IHE     │                       │   │
│  │  │  11073   │    │ PCD      │    │ PCD/ACM  │                       │   │
│  │  │ (Device) │    │ (Device) │    │ (Alerts) │                       │   │
│  │  └──────────┘    └──────────┘    └──────────┘                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. HL7 (Health Level 7)

### What is HL7?
HL7 v2 is the most widely used healthcare data exchange standard globally.
It defines messages for patient administration, orders, results, and billing.

### Relevance to NeuroBleed Alert
- **ADT (Admission, Discharge, Transfer)**: Patient registration/demographics
- **OBR (Observation Request)**: Vital sign orders from doctors
- **OBX (Observation Result)**: Delivery of vital sign readings
- **ACK (Acknowledgement)**: Message receipt confirmation

### Example HL7 Message
```
MSH|^~\&|NeuroBleed|HospitalA|EMR|HospitalA|20260714163000||ADT^A01|MSG00001|P|2.5
EVN|A01|20260714163000
PID|1||123456^^^HospitalA^MR||Smith^John^^^||19800101|M|||123 Main St^^Metropolis^NY^10001^USA
OBR|1|||93000^Vital Signs Panel^LN|||20260714163000|||||||20260714163000
OBX|1|NM|8867-4^Heart rate^LN||72|bpm|60-100|N|||F
OBX|2|NM|2708-6^SpO2^LN||98|%|95-100|N|||F
```

### Integration Architecture
```
NeuroBleed ──→ HL7 Converter ──→ Mirth Connect / HAPI FHIR ──→ Hospital EMR
                    │
              ┌─────┴─────┐
              │ HL7 v2.x  │
              │ Messages  │
              └───────────┘
```

---

## 2. FHIR (Fast Healthcare Interoperability Resources)

### What is FHIR?
Modern RESTful healthcare API standard (HL7 FHIR R4/R5).
Resources represent clinical entities with JSON/XML serialization.

### FHIR Resources Used

| FHIR Resource | NeuroBleed Mapping | FHIR Endpoint |
|--------------|-------------------|---------------|
| `Patient` | Local Patient model | `/Patient/{id}` |
| `Observation` | Sensor readings | `/Observation?subject=Patient/{id}` |
| `Device` | Wearable device | `/Device/{id}` |
| `RiskAssessment` | AI risk scores | `/RiskAssessment/{id}` |
| `Alert` (via `Communication`) | Emergency alerts | `/Communication` |
| `CarePlan` | Treatment recommendations | `/CarePlan` |
| `Encounter` | Patient visit/monitoring period | `/Encounter` |
| `Provenance` | Audit trail, data source | `/Provenance` |

### Example FHIR Observation
```json
{
  "resourceType": "Observation",
  "id": "obs-hr-001",
  "status": "final",
  "category": [{
    "coding": [{
      "system": "http://terminology.hl7.org/CodeSystem/observation-category",
      "code": "vital-signs",
      "display": "Vital Signs"
    }]
  }],
  "code": {
    "coding": [{
      "system": "http://loinc.org",
      "code": "8867-4",
      "display": "Heart rate"
    }]
  },
  "subject": {
    "reference": "Patient/pat-123"
  },
  "effectiveDateTime": "2026-07-14T16:30:00Z",
  "valueQuantity": {
    "value": 72,
    "unit": "bpm",
    "system": "http://unitsofmeasure.org",
    "code": "/min"
  },
  "device": {
    "reference": "Device/dev-nb-001"
  }
}
```

### FHIR Operations Plan
```
Phase 1 (Current):
  - FHIR-like JSON structure in internal API
  - Store FHIR resource IDs in DB

Phase 2 (After MVP):
  - HAPI FHIR Server (self-hosted or cloud)
  - Bi-directional sync with hospital FHIR servers
  - SMART on FHIR for EHR integration

Phase 3 (Production):
  - Full FHIR R4 compliance
  - $everything operation for patient data export
  - FHIR subscriptions for real-time updates
```

---

## 3. LOINC (Logical Observation Identifiers Names and Codes)

### Purpose
Universal coding system for laboratory and clinical observations.

### Mapped Codes
| Measurement | LOINC Code | Long Name |
|------------|-----------|-----------|
| Heart Rate | 8867-4 | Heart rate |
| SpO2 | 2708-6 | Oxygen saturation in Arterial blood |
| Systolic BP | 8480-6 | Systolic blood pressure |
| Diastolic BP | 8462-4 | Diastolic blood pressure |
| Respiratory Rate | 9279-1 | Respiratory rate |
| Body Temperature | 8310-5 | Body temperature |
| Cerebral Oximetry (rSO2) | PGNOT.Y-1 (provisional) | Regional cerebral oxygenation |
| PPG IR Amplitude | Custom | PPG infrared signal amplitude |
| PPG Red Amplitude | Custom | PPG red signal amplitude |

### Implementation
```python
LOINC_MAP = {
    "heart_rate": "8867-4",
    "spo2": "2708-6",
    "systolic_bp": "8480-6",
    "diastolic_bp": "8462-4",
    "respiratory_rate": "9279-1",
    "temperature": "8310-5",
    "rso2": "8339-5",  # Tissue oxygenation (similar)
}

def to_loinc_observation(reading: SensorReading) -> dict:
    """Convert internal reading to LOINC-coded Observation."""
    observations = []
    for field, loinc_code in LOINC_MAP.items():
        value = getattr(reading, field, None)
        if value is not None:
            observations.append({
                "resourceType": "Observation",
                "code": {
                    "coding": [{
                        "system": "http://loinc.org",
                        "code": loinc_code
                    }]
                },
                "valueQuantity": {
                    "value": value,
                    "unit": UNITS_MAP.get(field, "")
                }
            })
    return observations
```

---

## 4. SNOMED CT (Systematized Nomenclature of Medicine — Clinical Terms)

### Purpose
Comprehensive clinical terminology for diseases, findings, procedures.

### Relevant Terms
| Concept | SNOMED CT Code | Description |
|---------|---------------|-------------|
| Intracranial hemorrhage | 13830010 | Intracranial hemorrhage (disorder) |
| Cerebral hemorrhage | 274100004 | Cerebral hemorrhage (disorder) |
| Subarachnoid hemorrhage | 396533000 | Subarachnoid hemorrhage (disorder) |
| Intracerebral hemorrhage | 274400007 | Intraparenchymal hemorrhage |
| Traumatic brain injury | 127295002 | Traumatic brain injury (disorder) |
| Cerebral hypoxia | 367370004 | Cerebral hypoxia (finding) |
| Risk assessment | 444861000124104 | Risk assessment (procedure) |
| Vital signs monitoring | 182736004 | Vital signs monitoring (regime/therapy) |

### Clinical Finding Classification
```python
RISK_TO_SNOMED = {
    "critical": {
        "code": "13830010",
        "display": "Intracranial hemorrhage (disorder)"
    },
    "high": {
        "code": "367370004",
        "display": "Cerebral hypoxia (finding)"
    },
    "medium": {
        "code": "444861000124104",
        "display": "Risk assessment (procedure)"
    }
}
```

---

## 5. ICD-10 (International Classification of Diseases, 10th Revision)

### Purpose
Disease diagnosis coding for billing, epidemiology, and statistics.

### Relevant ICH Codes
| Code | Description | Relevance |
|------|-------------|-----------|
| I61.0 | Nontraumatic intracerebral hemorrhage, subcortical | Most common ICH location |
| I61.1 | Nontraumatic intracerebral hemorrhage, cortical | Second most common |
| I61.2 | Nontraumatic intracerebral hemorrhage, unspecified | General ICH |
| I60 | Subarachnoid hemorrhage | Related condition |
| S06 | Intracranial injury | Traumatic causes |
| I67.5 | Moyamoya disease | Risk factor for ICH |
| I10 | Essential hypertension | Primary risk factor |

### Usage
```python
# ICD-10 codes stored with patient conditions
PATIENT_CONDITIONS = {
    "hypertension": "I10",
    "diabetes_type_2": "E11",
    "atrial_fibrillation": "I48",
    "ich_history": "I61.9",
    "cerebral_aneurysm": "I67.1",
}
```

---

## 6. DICOM (Digital Imaging and Communications in Medicine)

### Purpose
Medical imaging standard for CT, MRI, X-ray.

### Relevance
While NeuroBleed Alert is not an imaging system, DICOM is critical for:
1. **CT Report Integration**: View CT scan metadata alongside vital signs
2. **Image Sharing**: Share ICH diagnosis images with neurosurgeons
3. **AI Imaging**: Future integration with CT hemorrhage detection AI

### DICOM Fields Relevant to ICH
```json
{
  "PatientName": "Smith^John",
  "StudyDescription": "CT HEAD WITHOUT CONTRAST",
  "SeriesDescription": "AXIAL 5MM SOFT",
  "Modality": "CT",
  "BodyPartExamined": "HEAD",
  "Findings": "Acute intraparenchymal hemorrhage in left basal ganglia measuring 3.4 × 2.1 × 2.8 cm",
  "Impression": "Acute intraparenchymal hemorrhage, ICH score 2"
}
```

### Integration Plan
```yaml
Phase 2:
  - Store DICOM UID references in patient records
  - Link CT reports to AI risk assessments
  - Basic DICOM viewer via OHIF Viewer integration

Phase 3:
  - DICOM Structured Reports for AI findings
  - DICOM Segmentation of hemorrhage regions
  - Full PACS integration via DICOM C-FIND/C-MOVE
```

---

## 7. IEEE 11073 (Personal Health Device Communication)

### Purpose
Standard for medical device data exchange (Bluetooth medical devices).

### Device Specializations
| Specialization | Device Type | Data |
|---------------|-------------|------|
| 10406 | Pulse Oximeter | SpO2, heart rate |
| 10407 | Blood Pressure Monitor | Systolic, diastolic, MAP |
| 10408 | Thermometer | Temperature |
| 10415 | Weight Scale | Weight, BMI |
| 10417 | Glucose Monitor | Blood glucose |

### Implementation
```python
# IEEE 11073-20601 optimized exchange protocol
MEDICAL_DEVICE_SPECS = {
    "MAX30102": {
        "specialization": "10406",  # Pulse Oximeter
        "attributes": {
            "MDC_ATTR_ID_HR": {"code": 18908, "unit": "beats/min"},
            "MDC_ATTR_ID_SPO2": {"code": 19001, "unit": "%"},
        }
    }
}
```

---

## 8. Implementation Roadmap

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         MEDICAL STANDARDS ROADMAP                           │
├────────────┬──────────────────────┬──────────────────┬─────────────────────┤
│   Phase    │    What             │    Impact        │    Timeline         │
├────────────┼──────────────────────┼──────────────────┼─────────────────────┤
│ Phase 1   │ LOINC coding for     │ Interoperability │ Current (MVP)       │
│ (Current)  │ all measurements     │ with labs         │                      │
│            │ ICD-10 for conditions │ Diagnosis coding │                      │
├────────────┼──────────────────────┼──────────────────┼─────────────────────┤
│ Phase 2   │ FHIR-compatible API   │ EHR integration  │ Post-MVP (Month 2)  │
│ (Post-MVP) │ SNOMED CT for        │ Clinical          │                      │
│            │ clinical findings    │ terminology       │                      │
│            │ IEEE 11073 for       │ Medical device    │                      │
│            │ BLE devices          │ standards         │                      │
├────────────┼──────────────────────┼──────────────────┼─────────────────────┤
│ Phase 3   │ Full FHIR R4 server   │ Enterprise       │ Production (Month 4)│
│ (Production)│ HL7 v2 interface     │ Hospital          │                      │
│            │ DICOM integration    │ integration       │                      │
│            │ SMART on FHIR        │ EHR launchable    │                      │
│            │ IHE PCD profiles     │ Device-to-EMR    │                      │
└────────────┴──────────────────────┴──────────────────┴─────────────────────┘
```

---

## 9. Compliance Notes

> **Important**: This document provides architecture reference. Full compliance with these standards requires certification and validation beyond the scope of an academic prototype.

| Standard | Current Status | Production Target |
|----------|---------------|-------------------|
| LOINC | ✅ Codes mapped | Full validation |
| ICD-10 | ✅ Codes mapped | Billing-ready coding |
| FHIR R4 | ⚠️ JSON structure only | Full server + $export |
| SNOMED CT | 🟡 Codes identified | Full clinical terminology |
| HL7 v2 | 🟡 Architecture designed | Mirth Connect deployment |
| DICOM | 🟡 Integration planned | PACS connectivity |
| IEEE 11073 | 🟡 Device profile planned | BLE medical device cert |
| IHE PCD | ❌ Not planned | Post-production |
