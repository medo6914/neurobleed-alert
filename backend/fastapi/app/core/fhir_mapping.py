import uuid
from datetime import datetime, timezone

from app.models.patient import Patient
from app.models.alert import Alert
from app.models.sensor_reading import SensorReading
from app.models.ai_report import AIReport
from app.models.enums import Gender, BloodType
from app.config import settings


class FHIRMapper:

    FHIR_SYSTEMS = {
        "mrn": "http://hospital.smarthealthit.org/identifier/mrn",
        "national_id": "urn:oid:1.2.3.4.5.6.7",
        "phone": "http://hl7.org/fhir/contact-point-system/phone",
        "email": "http://hl7.org/fhir/contact-point-system/email",
    }

    @staticmethod
    def patient_to_fhir(patient: Patient) -> dict:
        resource = {
            "resourceType": "Patient",
            "id": str(patient.id),
            "identifier": FHIRMapper._build_identifiers(patient),
            "active": patient.is_active,
            "name": FHIRMapper._build_names(patient),
            "telecom": FHIRMapper._build_telecom(patient),
            "gender": FHIRMapper._map_gender(patient.gender),
            "birthDate": str(patient.date_of_birth) if patient.date_of_birth else None,
            "address": FHIRMapper._build_address(patient),
            "maritalStatus": {"coding": [{"system": "http://hl7.org/fhir/marital-status", "code": "U"}]},
            "communication": [
                {
                    "language": {
                        "coding": [
                            {"system": "urn:ietf:bcp:47", "code": "en"}
                        ]
                    },
                    "preferred": True,
                }
            ],
            "managingOrganization": FHIRMapper._build_organization(patient),
            "extension": FHIRMapper._build_extensions(patient),
            "meta": {
                "versionId": str(patient.version) if hasattr(patient, 'version') and patient.version else "1",
                "lastUpdated": patient.updated_at.isoformat() if patient.updated_at else datetime.now(timezone.utc).isoformat(),
                "profile": ["http://hl7.org/fhir/StructureDefinition/Patient"],
            },
        }

        resource = {k: v for k, v in resource.items() if v is not None}
        return resource

    @staticmethod
    def _build_identifiers(patient: Patient) -> list:
        identifiers = []
        if patient.mrn:
            identifiers.append({
                "system": FHIRMapper.FHIR_SYSTEMS["mrn"],
                "value": patient.mrn,
                "type": {"coding": [{"system": "http://hl7.org/fhir/identifier-type", "code": "MR"}]},
            })
        if patient.national_id:
            identifiers.append({
                "system": FHIRMapper.FHIR_SYSTEMS["national_id"],
                "value": patient.national_id,
                "type": {"coding": [{"system": "http://hl7.org/fhir/identifier-type", "code": "NI"}]},
            })
        return identifiers

    @staticmethod
    def _build_names(patient: Patient) -> list:
        name_parts = patient.full_name.split(" ", 1)
        given = name_parts[0] if name_parts else patient.full_name
        family = name_parts[1] if len(name_parts) > 1 else ""
        return [{"use": "official", "family": family, "given": [given]}]

    @staticmethod
    def _build_telecom(patient: Patient) -> list:
        telecom = []
        if patient.phone:
            telecom.append({"system": "phone", "value": patient.phone, "use": "mobile"})
        if patient.email:
            telecom.append({"system": "email", "value": patient.email})
        return telecom

    @staticmethod
    def _build_address(patient: Patient) -> list:
        return [{"text": f"Bed: {patient.bed_number}" if patient.bed_number else ""}]

    @staticmethod
    def _build_organization(patient: Patient) -> dict | None:
        if patient.hospital_id:
            return {"reference": f"Organization/{patient.hospital_id}"}
        return None

    @staticmethod
    def _build_extensions(patient: Patient) -> list:
        extensions = []
        if patient.blood_type:
            extensions.append({
                "url": "http://hl7.org/fhir/StructureDefinition/patient-bloodType",
                "valueCodeableConcept": {
                    "coding": [{
                        "system": "http://hl7.org/fhir/ValueSet/blood-type",
                        "code": patient.blood_type.value if hasattr(patient.blood_type, 'value') else str(patient.blood_type),
                    }]
                },
            })
        if patient.height_cm:
            extensions.append({
                "url": "http://hl7.org/fhir/StructureDefinition/body-height",
                "valueQuantity": {"value": patient.height_cm, "unit": "cm", "system": "http://unitsofmeasure.org", "code": "cm"},
            })
        if patient.weight_kg:
            extensions.append({
                "url": "http://hl7.org/fhir/StructureDefinition/body-weight",
                "valueQuantity": {"value": patient.weight_kg, "unit": "kg", "system": "http://unitsofmeasure.org", "code": "kg"},
            })
        return extensions

    @staticmethod
    def _map_gender(gender) -> str:
        if isinstance(gender, Gender):
            return gender.value
        return str(gender) if gender else "unknown"

    @staticmethod
    def observation_to_fhir(
        reading: SensorReading,
        patient_id: str,
    ) -> list[dict]:
        resources = []
        base = {
            "resourceType": "Observation",
            "status": "final",
            "subject": {"reference": f"Patient/{patient_id}"},
            "meta": {
                "profile": ["http://hl7.org/fhir/StructureDefinition/vitalsigns"],
                "lastUpdated": reading.created_at.isoformat() if reading.created_at else datetime.now(timezone.utc).isoformat(),
            },
            "effectiveDateTime": reading.created_at.isoformat() if reading.created_at else None,
        }

        if reading.heart_rate is not None:
            resources.append({
                **base,
                "id": f"hr-{reading.id}",
                "code": {
                    "coding": [
                        {"system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"},
                        {"system": "http://snomed.info/sct", "code": "364075005", "display": "Heart rate"}
                    ],
                    "text": "Heart Rate",
                },
                "valueQuantity": {"value": reading.heart_rate, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"},
                "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
            })

        if reading.oxygen_saturation is not None:
            resources.append({
                **base,
                "id": f"spo2-{reading.id}",
                "code": {
                    "coding": [
                        {"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"},
                        {"system": "http://snomed.info/sct", "code": "442705005", "display": "Oxygen saturation"}
                    ],
                    "text": "SpO2",
                },
                "valueQuantity": {"value": reading.oxygen_saturation, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"},
                "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
            })

        if reading.systolic_bp is not None and reading.diastolic_bp is not None:
            resources.append({
                **base,
                "id": f"bp-{reading.id}",
                "code": {
                    "coding": [
                        {"system": "http://loinc.org", "code": "85354-9", "display": "Blood pressure panel"},
                    ],
                    "text": "Blood Pressure",
                },
                "component": [
                    {
                        "code": {"coding": [{"system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"}]},
                        "valueQuantity": {"value": reading.systolic_bp, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"},
                    },
                    {
                        "code": {"coding": [{"system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"}]},
                        "valueQuantity": {"value": reading.diastolic_bp, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"},
                    },
                ],
                "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
            })

        if reading.temperature is not None:
            resources.append({
                **base,
                "id": f"temp-{reading.id}",
                "code": {
                    "coding": [
                        {"system": "http://loinc.org", "code": "8310-5", "display": "Body temperature"},
                    ],
                    "text": "Temperature",
                },
                "valueQuantity": {"value": reading.temperature, "unit": "degC", "system": "http://unitsofmeasure.org", "code": "Cel"},
                "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
            })

        return resources

    @staticmethod
    def condition_to_fhir(ai_report: AIReport, patient_id: str) -> dict | None:
        if not ai_report.risk_score:
            return None

        severity = "active"
        if (ai_report.risk_score or 0) >= 0.8:
            severity = "active"
        elif (ai_report.risk_score or 0) >= 0.6:
            severity = "active"
        else:
            severity = "active"

        return {
            "resourceType": "Condition",
            "id": f"condition-{ai_report.id}",
            "subject": {"reference": f"Patient/{patient_id}"},
            "clinicalStatus": {
                "coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": severity}]
            },
            "code": {
                "coding": [
                    {"system": "http://snomed.info/sct", "code": "230690007", "display": "Intracranial hemorrhage"}
                ],
                "text": ai_report.summary or "Intracranial hemorrhage risk detected",
            },
            "severity": {
                "coding": [{
                    "system": "http://snomed.info/sct",
                    "code": "24484000" if (ai_report.risk_score or 0) >= 0.8 else "6736007",
                    "display": "Severe" if (ai_report.risk_score or 0) >= 0.8 else "Moderate",
                }]
            },
            "meta": {
                "profile": ["http://hl7.org/fhir/StructureDefinition/Condition"],
                "lastUpdated": ai_report.created_at.isoformat() if ai_report.created_at else None,
            },
        }


fhir_mapper = FHIRMapper()
