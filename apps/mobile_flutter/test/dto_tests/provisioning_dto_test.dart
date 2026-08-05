import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

void main() {
  group('ProvisioningKey', () {
    test('fromJson creates correct instance', () {
      final json = {
        'id': 'pk-1',
        'key': 'NB-ABCD-EFGH',
        'device_type': 'nb_01',
        'label': 'ICU Monitor',
        'status': 'active',
        'expires_at': null,
        'used_at': null,
        'max_uses': 1,
        'use_count': 0,
        'created_at': '2026-07-20T10:00:00Z',
      };
      final dto = ProvisioningKey.fromJson(json);
      expect(dto.id, 'pk-1');
      expect(dto.key, 'NB-ABCD-EFGH');
      expect(dto.deviceType, 'nb_01');
      expect(dto.label, 'ICU Monitor');
      expect(dto.status, 'active');
      expect(dto.maxUses, 1);
      expect(dto.useCount, 0);
    });

    test('fromJson handles null label', () {
      final json = {
        'id': 'pk-2',
        'key': 'NB-WXYZ-6789',
        'device_type': 'nb_02',
        'label': null,
        'status': 'used',
        'expires_at': null,
        'used_at': '2026-07-21T15:00:00Z',
        'max_uses': 1,
        'use_count': 1,
        'created_at': '2026-07-20T10:00:00Z',
      };
      final dto = ProvisioningKey.fromJson(json);
      expect(dto.label, isNull);
      expect(dto.status, 'used');
      expect(dto.useCount, 1);
      expect(dto.usedAt, isNotNull);
    });
  });

  group('ProvisioningClaimResponse', () {
    test('fromJson creates success response', () {
      final json = {
        'success': true,
        'device_id': 'dev-123',
        'serial_number': 'SN-001',
        'message': 'Device claimed successfully',
        'device': {'id': 'dev-123', 'status': 'online'},
      };
      final dto = ProvisioningClaimResponse.fromJson(json);
      expect(dto.success, isTrue);
      expect(dto.deviceId, 'dev-123');
      expect(dto.serialNumber, 'SN-001');
      expect(dto.device, isNotNull);
      expect(dto.device!['status'], 'online');
    });

    test('fromJson handles failure response', () {
      final json = {
        'success': false,
        'device_id': null,
        'serial_number': null,
        'message': 'Invalid provisioning key',
        'device': null,
      };
      final dto = ProvisioningClaimResponse.fromJson(json);
      expect(dto.success, isFalse);
      expect(dto.deviceId, isNull);
      expect(dto.device, isNull);
    });
  });

  group('ProvisioningKeyCreateRequest', () {
    test('toJson includes all non-null fields', () {
      final req = ProvisioningKeyCreateRequest(
        deviceType: 'nb_01',
        label: 'Test',
        hospitalId: 'hosp-1',
        expiresAt: '2026-12-31T23:59:59Z',
        maxUses: 5,
      );
      final json = req.toJson();
      expect(json['device_type'], 'nb_01');
      expect(json['label'], 'Test');
      expect(json['hospital_id'], 'hosp-1');
      expect(json['expires_at'], '2026-12-31T23:59:59Z');
      expect(json['max_uses'], 5);
    });

    test('toJson omits null fields', () {
      final req = ProvisioningKeyCreateRequest(deviceType: 'nb_01');
      final json = req.toJson();
      expect(json.containsKey('label'), isFalse);
      expect(json.containsKey('hospital_id'), isFalse);
      expect(json.containsKey('expires_at'), isFalse);
      expect(json['max_uses'], 1);
    });
  });

  group('ProvisioningClaimRequest', () {
    test('toJson includes all non-null fields', () {
      final req = ProvisioningClaimRequest(
        provisioningKey: 'NB-KEY-123',
        serialNumber: 'SN-001',
        deviceName: 'Monitor',
        deviceType: 'nb_01',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        firmwareVersion: '1.0.0',
        hardwareVersion: 'v2',
      );
      final json = req.toJson();
      expect(json['provisioning_key'], 'NB-KEY-123');
      expect(json['serial_number'], 'SN-001');
      expect(json['device_name'], 'Monitor');
      expect(json['device_type'], 'nb_01');
      expect(json['mac_address'], 'AA:BB:CC:DD:EE:FF');
      expect(json['firmware_version'], '1.0.0');
      expect(json['hardware_version'], 'v2');
    });

    test('toJson omits null fields', () {
      final req = ProvisioningClaimRequest(
        provisioningKey: 'NB-KEY-456',
        serialNumber: 'SN-002',
      );
      final json = req.toJson();
      expect(json.containsKey('device_name'), isFalse);
      expect(json.containsKey('device_type'), isFalse);
      expect(json.length, 2);
    });
  });
}
