# PII Classification & Data Sensitivity

## Classification Levels

| Level | Color | Description | Examples |
|-------|-------|-------------|----------|
| **Public** | Green | No PII, safe to expose | Table IDs, role names |
| **Internal** | Blue | Business data, not sensitive | Device serials, department names |
| **Confidential** | Orange | PII, requires access control | Names, emails, phone numbers |
| **Sensitive Medical** | Red | PHI/Medical data, highest protection | Diagnoses, vitals, AI reports |

---

## Classification by Table

### Users
| Field | Classification | Notes |
|-------|---------------|-------|
| id | Public | UUID, no PII |
| email | Confidential | PII — encrypt at rest |
| hashed_password | Confidential | Already hashed |
| full_name | Confidential | PII |
| role | Internal | Role assignment |
| phone | Confidential | PII |
| firebase_uid | Confidential | Auth provider UID |
| profile_image_url | Internal | URL (image may contain PII) |
| is_active | Internal | Account status |
| is_email_verified | Internal | Verification status |
| is_phone_verified | Internal | Verification status |
| is_mfa_enabled | Internal | Security setting |
| mfa_secret | Confidential | TOTP secret — encrypt |
| hospital_id | Internal | Org reference |
| last_login_at | Internal | Activity log |
| last_password_change | Internal | Audit data |
| password_history | Confidential | Historical hashes |
| login_attempts | Internal | Security metric |
| locked_until | Internal | Account lock status |
| created_at / updated_at | Internal | Timestamps |

### Patients
| Field | Classification | Notes |
|-------|---------------|-------|
| id | Public | UUID |
| mrn | Confidential | Medical Record Number |
| full_name | Sensitive Medical | Patient identity |
| date_of_birth | Sensitive Medical | Age/DOB |
| gender | Sensitive Medical | Demographics |
| national_id | Confidential | Government ID |
| phone | Confidential | Contact PII |
| email | Confidential | Contact PII |
| emergency_contact_name | Confidential | Third-party PII |
| emergency_contact_phone | Confidential | Third-party PII |
| emergency_contact_relation | Internal | Relationship |
| blood_type | Sensitive Medical | Clinical data |
| allergies | Sensitive Medical | Clinical data |
| medical_conditions | Sensitive Medical | Clinical data |
| medications | Sensitive Medical | Clinical data |
| height_cm / weight_kg | Sensitive Medical | Clinical data |
| is_ihd_suspected | Sensitive Medical | Clinical data |
| admission_date | Sensitive Medical | Episode dates |
| discharge_date | Sensitive Medical | Episode dates |
| department_id | Internal | Department assignment |
| bed_number | Internal | Location |
| hospital_id | Internal | Hospital reference |
| fhir fields | Internal | FHIR metadata |
| medical codes | Sensitive Medical | ICD/SNOMED/LOINC |

### SensorReadings
| Field | Classification | Notes |
|-------|---------------|-------|
| All vital signs (spo2, hr, rso2, etc.) | Sensitive Medical | PHI — time-series medical data |
| risk_score / risk_level | Sensitive Medical | Derived clinical data |
| All other fields | Internal | Technical metadata |

### Alerts
| Field | Classification | Notes |
|-------|---------------|-------|
| message | Sensitive Medical | Alert content may contain PHI |
| alert_type / severity | Internal | Categorization |
| acknowledgment fields | Internal | Workflow data |
| All other fields | Internal | Technical metadata |

### AIReports
| Field | Classification | Notes |
|-------|---------------|-------|
| summary / detailed_analysis | Sensitive Medical | AI-generated diagnostic text |
| recommendations | Sensitive Medical | Clinical recommendations |
| features / input_data / raw_output | Sensitive Medical | ML data (may contain PHI) |
| risk fields | Sensitive Medical | Clinical risk assessment |
| All other fields | Internal | Metadata |

### Device
| Field | Classification | Notes |
|-------|---------------|-------|
| serial_number | Internal | Hardware serial |
| mac_address | Internal | Network identifier |
| sim_iccid | Internal | SIM identifier |
| All other fields | Internal | Technical data |

### Hospital / Organization
| Field | Classification | Notes |
|-------|---------------|-------|
| name | Public | Hospital name |
| address | Internal | Business address |
| phone | Internal | Business phone |
| email | Internal | Business email |
| license_number | Confidential | Regulatory license |
| tax_id | Confidential | Tax identifier |
| All other fields | Internal | Business data |

### AuditLog
| Field | Classification | Notes |
|-------|---------------|-------|
| user_id | Confidential | Who performed action |
| ip_address | Confidential | Network location |
| user_agent | Internal | Client info |
| details | Confidential | May contain PII in context |
| All other fields | Internal | Audit metadata |

### Session / RefreshToken
| Field | Classification | Notes |
|-------|---------------|-------|
| token_hash | Confidential | Auth token |
| refresh_token_hash | Confidential | Refresh token |
| ip_address | Confidential | Network location |
| user_agent | Internal | Client info |
| All other fields | Internal | Session metadata |

### Role / Permission
| Field | Classification | Notes |
|-------|---------------|-------|
| All fields | Public | RBAC configuration |

---

## Access Control Rules

| Classification | Storage | Encryption | Access | Audit |
|---------------|---------|------------|--------|-------|
| Public | Plaintext | No | All authenticated users | No |
| Internal | Plaintext | No | Authenticated + role-based | Yes |
| Confidential | Encrypted at rest | AES-256-GCM | Specific roles only | Yes |
| Sensitive Medical | Encrypted at rest + in transit | AES-256-GCM + TLS | Clinical roles only + break-glass | Yes, full trail |

## Encryption Requirements

- **At rest**: All Confidential and Sensitive Medical fields encrypted using PostgreSQL `pgcrypto` with AES-256-GCM
- **Column-level encryption**: For fields like `mfa_secret`, `password_history`
- **In transit**: TLS 1.3 required for all database connections
- **Key management**: AWS KMS / Azure Key Vault for encryption keys, rotated every 90 days
