# FHIR Mapping Guide

## Overview

This document maps NeuroBleed Alert database tables to FHIR R4 resources. Each table includes both clinical and administrative FHIR mappings, with column-level granularity.

---

## 1. User → FHIR PractitionerRole / Practitioner

| DB Column | FHIR Path | Mapping |
|-----------|-----------|---------|
| `users.id` | `Practitioner.identifier` | UUID as system identifier |
| `users.email` | `Practitioner.telecom.where(system=email)` | Contact point |
| `users.full_name` | `Practitioner.name.text` | Human name display |
| `users.phone` | `Practitioner.telecom.where(system=phone)` | Contact point |
| `users.role` | `PractitionerRole.code.coding` | Role as practitioner role code |
| `users.hospital_id` | `PractitionerRole.organization.reference` | Organization reference |
| `users.is_active` | `Practitioner.active` | Active status |
| `users.fhir_id` | `Practitioner.id` | FHIR server logical ID |

**FHIR Resource Type**: `PractitionerRole` (primary), `Practitioner` (identity)

---

## 2. Patient → FHIR Patient

| DB Column | FHIR Path | Mapping |
|-----------|-----------|---------|
| `patients.id` | `Patient.identifier` | Internal UUID |
| `patients.mrn` | `Patient.identifier.where(type=MR)` | Medical Record Number |
| `patients.full_name` | `Patient.name[0].text` | Human name |
| `patients.date_of_birth` | `Patient.birthDate` | Date of birth |
| `patients.gender` | `Patient.gender` | Administrative gender |
| `patients.phone` | `Patient.telecom.where(system=phone)` | Contact point |
| `patients.email` | `Patient.telecom.where(system=email)` | Contact point |
| `patients.blood_type` | `Patient.extension(bloodType)` | Blood type extension |
| `patients.allergies` | `AllergyIntolerance` | Separate resource query |
| `patients.medical_conditions` | `Condition` | Separate resource query |
| `patients.medications` | `MedicationRequest` | Separate resource query |
| `patients.emergency_contact_name` | `Patient.contact[0].name.text` | Emergency contact |
| `patients.emergency_contact_phone` | `Patient.contact[0].telecom` | Emergency contact point |
| `patients.hospital_id` | `Patient.managingOrganization.reference` | Organization reference |
| `patients.national_id` | `Patient.identifier.where(type=NI)` | National identifier |
| `patients.height_cm` | `Observation(code=loinc#8302-2)` | Body height |
| `patients.weight_kg` | `Observation(code=loinc#29463-7)` | Body weight |
| `patients.is_active` | `Patient.active` | Active status |
| `patients.fhir_resource_type` | `Patient.resourceType` | Fixed: "Patient" |
| `patients.fhir_id` | `Patient.id` | FHIR server logical ID |
| `patients.icd10_code` | `Condition.code.coding` | Primary diagnosis code |
| `patients.snomed_ct_code` | `Condition.code.coding` | SNOMED CT code |

**FHIR Resource Type**: `Patient`

---

## 3. Device → FHIR Device

| DB Column | FHIR Path | Mapping |
|-----------|-----------|---------|
| `devices.id` | `Device.identifier` | Internal UUID |
| `devices.serial_number` | `Device.serialNumber` | Manufacturer serial |
| `devices.device_type` | `Device.type.text` | Device model/type |
| `devices.device_name` | `Device.deviceName[0].name` | Human-readable name |
| `devices.status` | `Device.status` | Operational status |
| `devices.firmware_version` | `Device.version.value` | Software version |
| `devices.mac_address` | `Device.identifier.where(type=MAC)` | Network identifier |
| `devices.sim_iccid` | `Device.extension(simICCID)` | SIM card identifier |
| `devices.battery_level` | `Device.extension(batteryLevel)` | Battery extension |
| `devices.last_seen` | `Device.lastUpdated` | Last communication |
| `devices.patient_id` | `Device.patient.reference` | Assigned patient |
| `devices.fhir_id` | `Device.id` | FHIR server logical ID |

**FHIR Resource Type**: `Device`

---

## 4. SensorReading → FHIR Observation

| DB Column | FHIR Path | Mapping |
|-----------|-----------|---------|
| `sensor_readings.id` | `Observation.identifier` | Internal UUID |
| `sensor_readings.patient_id` | `Observation.subject.reference` | Patient reference |
| `sensor_readings.device_id` | `Observation.device.reference` | Device reference |
| `sensor_readings.timestamp` | `Observation.effectiveDateTime` | Clinical time |
| `sensor_readings.spo2` | `Observation.component[O2Sat].valueQuantity` | LOINC 2708-6 |
| `sensor_readings.heart_rate` | `Observation.component[HR].valueQuantity` | LOINC 8867-4 |
| `sensor_readings.rso2` | `Observation.component[regionalO2].valueQuantity` | Regional saturation |
| `sensor_readings.ir_value` | `Observation.component[infrared].valueQuantity` | Raw IR pleth |
| `sensor_readings.red_value` | `Observation.component[red].valueQuantity` | Raw red pleth |
| `sensor_readings.signal_quality` | `Observation.component[sigQual].valueQuantity` | Signal quality index |
| `sensor_readings.motion_artifact` | `Observation.component[motion].valueQuantity` | Motion artifact |
| `sensor_readings.risk_score` | `Observation.extension(riskScore)` | AI risk score |
| `sensor_readings.risk_level` | `Observation.extension(riskLevel)` | Risk level category |
| `sensor_readings.loinc_code` | `Observation.code.coding` | LOINC panel code |

**FHIR Resource Type**: `Observation` (Vital Signs Profile)

---

## 5. Alert → FHIR Communication / Observation

| DB Column | FHIR Path | Mapping |
|-----------|-----------|---------|
| `alerts.id` | `Communication.identifier` | Internal UUID |
| `alerts.patient_id` | `Communication.subject.reference` | Patient reference |
| `alerts.device_id` | `Communication.sender.reference` | Device reference |
| `alerts.alert_type` | `Communication.category.coding` | Alert category |
| `alerts.severity` | `Communication.priority` | Alert priority |
| `alerts.message` | `Communication.payload.contentString` | Alert message body |
| `alerts.is_acknowledged` | `Communication.sent` extended | Acknowledgment marker |
| `alerts.acknowledged_by` | `Communication.recipient.reference` | Acknowledging user |
| `alerts.acknowledged_at` | `Communication.sent` | Acknowledgement time |
| `alerts.created_at` | `Communication.sent` | Alert creation time |

**FHIR Resource Type**: `Communication` (primary), `Observation` (when based on vital sign threshold)

---

## 6. AIReport → FHIR DiagnosticReport

| DB Column | FHIR Path | Mapping |
|-----------|-----------|---------|
| `ai_reports.id` | `DiagnosticReport.identifier` | Internal UUID |
| `ai_reports.patient_id` | `DiagnosticReport.subject.reference` | Patient reference |
| `ai_reports.report_type` | `DiagnosticReport.category.coding` | Report category |
| `ai_reports.risk_score` | `DiagnosticReport.extension(riskScore)` | Risk assessment |
| `ai_reports.confidence` | `DiagnosticReport.extension(confidence)` | AI confidence |
| `ai_reports.summary` | `DiagnosticReport.conclusion` | Report conclusion |
| `ai_reports.detailed_analysis` | `DiagnosticReport.presentedForm` | Full analysis text |
| `ai_reports.recommendations` | `DiagnosticReport.extension(recommendations)` | Clinical recommendations |
| `ai_reports.model_version` | `DiagnosticReport.extension(modelVersion)` | AI model version |
| `ai_reports.features` | `DiagnosticReport.result` (referenced Observations) | Input features |
| `ai_reports.input_data` | `DiagnosticReport.extension(rawInput)` | Raw input snapshot |
| `ai_reports.raw_output` | `DiagnosticReport.extension(rawOutput)` | Raw model output |
| `ai_reports.icp_risk` | `Observation(code=loinc#?).valueCodeableConcept` | ICP risk assessment |
| `ai_reports.herniation_risk` | `Observation(code=loinc#?).valueCodeableConcept` | Herniation risk |

**FHIR Resource Type**: `DiagnosticReport`

---

## 7. Hospital → FHIR Organization

| DB Column | FHIR Path | Mapping |
|-----------|-----------|---------|
| `hospitals.id` | `Organization.identifier` | Internal UUID |
| `hospitals.name` | `Organization.name` | Organization name |
| `hospitals.address` | `Organization.address.text` | Physical address |
| `hospitals.phone` | `Organization.telecom.where(system=phone)` | Contact phone |
| `hospitals.email` | `Organization.telecom.where(system=email)` | Contact email |
| `hospitals.license_number` | `Organization.identifier.where(type=PRN)` | Provider number |
| `hospitals.hospital_type` | `Organization.type.coding` | Organization type |
| `hospitals.is_active` | `Organization.active` | Active status |

**FHIR Resource Type**: `Organization`

---

## 8. Department → FHIR Organization (sub-organization)

| DB Column | FHIR Path | Mapping |
|-----------|-----------|---------|
| `departments.id` | `Organization.identifier` | Internal UUID |
| `departments.name` | `Organization.name` | Department name |
| `departments.hospital_id` | `Organization.partOf.reference` | Parent organization |

**FHIR Resource Type**: `Organization` (partOf relationship)

---

## 9. Organization → FHIR Organization

| DB Column | FHIR Path | Mapping |
|-----------|-----------|---------|
| `organizations.id` | `Organization.identifier` | Internal UUID |
| `organizations.name` | `Organization.name` | Organization name |
| `organizations.org_type` | `Organization.type.coding` | Organization type |
| `organizations.address` | `Organization.address.text` | Physical address |
| `organizations.phone` | `Organization.telecom` | Contact phone |
| `organizations.email` | `Organization.telecom` | Contact email |

**FHIR Resource Type**: `Organization`

---

## 10. Role / Permission → No Direct FHIR Mapping

Roles and permissions map to IAM / security infrastructure, not clinical FHIR resources. They can be serialized as `Provenance.agent` for audit trails.

---

## FHIR Readiness Summary

| FHIR Resource | DB Table | Status |
|---------------|----------|--------|
| Patient | `patients` | Full mapping |
| Practitioner | `users` | Full mapping |
| PractitionerRole | `users` + `user_roles` | Partial (via role mapping) |
| Device | `devices` | Full mapping |
| Observation | `sensor_readings` | Full (Vital Signs Profile) |
| Communication | `alerts` | Full mapping |
| DiagnosticReport | `ai_reports` | Full mapping |
| Organization | `hospitals` | Full mapping |
| Organization | `organizations` | Full mapping |
| Organization | `departments` | Sub-organization pattern |

All medical models include `fhir_resource_type` and `fhir_id` columns for direct FHIR server synchronization.
