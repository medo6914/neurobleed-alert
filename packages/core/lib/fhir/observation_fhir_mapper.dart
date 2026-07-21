import 'package:shared/shared.dart';
import 'fhir_types.dart';

class ObservationFhirMapper {
  /// Converts vitals to FHIR Observation bundle
  static List<Map<String, dynamic>> vitalsToFhir(VitalsRecord vitals) {
    final observations = <Map<String, dynamic>>[];
    final baseId = vitals.id;

    void addObservation({
      required String code,
      required String display,
      required String loincCode,
      double? value,
      String? unit,
    }) {
      if (value == null) return;
      observations.add({
        'resourceType': 'Observation',
        'id': '${baseId}_$code',
        'status': 'final',
        'category': [
          {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/CodeSystem/observation-category',
                'code': 'vital-signs',
                'display': 'Vital Signs',
              }
            ]
          }
        ],
        'code': {
          'coding': [
            {
              'system': FhirSystems.loinc,
              'code': loincCode,
              'display': display,
            }
          ],
          'text': display,
        },
        'subject': {'reference': 'Patient/${vitals.patientId}'},
        'effectiveDateTime': vitals.timestamp.toIso8601String(),
        'valueQuantity': {
          'value': value,
          'unit': unit ?? '',
          'system': FhirSystems.unitOfMeasure,
          'code': unit ?? '',
        },
        'device': vitals.deviceId != null
            ? {'reference': 'Device/${vitals.deviceId}'}
            : null,
      });
    }

    addObservation(
        code: 'heart_rate',
        display: 'Heart Rate',
        loincCode: '8867-4',
        value: vitals.heartRate,
        unit: '/min');
    addObservation(
        code: 'oxygen_saturation',
        display: 'Oxygen Saturation',
        loincCode: '59408-5',
        value: vitals.oxygenSaturation,
        unit: '%');
    addObservation(
        code: 'systolic_bp',
        display: 'Systolic Blood Pressure',
        loincCode: '8480-6',
        value: vitals.systolicBP,
        unit: 'mmHg');
    addObservation(
        code: 'diastolic_bp',
        display: 'Diastolic Blood Pressure',
        loincCode: '8462-4',
        value: vitals.diastolicBP,
        unit: 'mmHg');
    addObservation(
        code: 'temperature',
        display: 'Body Temperature',
        loincCode: '8310-5',
        value: vitals.temperature,
        unit: '°C');
    addObservation(
        code: 'respiratory_rate',
        display: 'Respiratory Rate',
        loincCode: '9279-1',
        value: vitals.respiratoryRate,
        unit: '/min');

    return observations;
  }
}
