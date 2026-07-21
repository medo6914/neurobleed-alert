class FhirTypes {
  static const String patient = 'Patient';
  static const String encounter = 'Encounter';
  static const String observation = 'Observation';
  static const String condition = 'Condition';
  static const String allergyIntolerance = 'AllergyIntolerance';
  static const String medicationDispense = 'MedicationDispense';
  static const String medicationRequest = 'MedicationRequest';
  static const String procedure = 'Procedure';
  static const String documentReference = 'DocumentReference';
  static const String clinicalImpression = 'ClinicalImpression';
  static const String carePlan = 'CarePlan';
  static const String riskAssessment = 'RiskAssessment';
  static const String auditEvent = 'AuditEvent';
  static const String organization = 'Organization';
  static const String location = 'Location';
  static const String practitioner = 'Practitioner';
  static const String relatedPerson = 'RelatedPerson';
}

class FhirSystems {
  static const String identifierMrn =
      'http://hospital.example.org/identifier/mrn';
  static const String identifierNationalId =
      'http://national-id.gov/identifier';
  static const String identifierInsurance =
      'http://insurance.example.org/identifier';
  static const String loinc = 'http://loinc.org';
  static const String snomed = 'http://snomed.info/sct';
  static const String rxnorm = 'http://www.nlm.nih.gov/research/umls/rxnorm';
  static const String icd10 = 'http://hl7.org/fhir/sid/icd-10';
  static const String adminGender = 'http://hl7.org/fhir/administrative-gender';
  static const String contactRole = 'http://hl7.org/fhir/contact-entity-type';
  static const String observationVitalSigns =
      'http://hl7.org/fhir/observation-vitalsigns';
  static const String unitOfMeasure = 'http://unitsofmeasure.org';
}
