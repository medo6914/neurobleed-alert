import 'package:dartz/dartz.dart';
import '../error/failure.dart';

class DeviceValidator {
  static Either<Failure, String> validateSerialNumber(String serialNumber) {
    if (serialNumber.isEmpty) {
      return Left(ValidationFailure(
        message: 'Serial number is required',
        code: 'VALIDATION_ERROR',
        errors: {
          'serialNumber': ['Serial number is required']
        },
      ));
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(serialNumber)) {
      return Left(ValidationFailure(
        message: 'Serial number must be alphanumeric',
        code: 'VALIDATION_ERROR',
        errors: {
          'serialNumber': ['Serial number must be alphanumeric']
        },
      ));
    }
    return Right(serialNumber);
  }

  static Either<Failure, String?> validateDeviceName(String? name) {
    if (name != null && name.isEmpty) {
      return Left(ValidationFailure(
        message: 'Device name cannot be empty',
        code: 'VALIDATION_ERROR',
        errors: {
          'deviceName': ['Device name cannot be empty']
        },
      ));
    }
    return Right(name);
  }

  static Either<Failure, String> validateFirmwareVersion(
      String firmwareVersion) {
    if (firmwareVersion.isEmpty) {
      return Left(ValidationFailure(
        message: 'Firmware version is required',
        code: 'VALIDATION_ERROR',
        errors: {
          'firmwareVersion': ['Firmware version is required']
        },
      ));
    }
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(firmwareVersion)) {
      return Left(ValidationFailure(
        message: 'Firmware version must be semantic (e.g. 1.0.0)',
        code: 'VALIDATION_ERROR',
        errors: {
          'firmwareVersion': ['Firmware version must be semantic (e.g. 1.0.0)']
        },
      ));
    }
    return Right(firmwareVersion);
  }

  static Either<Failure, String?> validateMacAddress(String? macAddress) {
    if (macAddress != null && macAddress.isNotEmpty) {
      if (!RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$')
          .hasMatch(macAddress)) {
        return Left(ValidationFailure(
          message: 'Invalid MAC address format',
          code: 'VALIDATION_ERROR',
          errors: {
            'macAddress': ['Invalid MAC address format']
          },
        ));
      }
    }
    return Right(macAddress);
  }

  static Either<Failure, double> validateBatteryLevel(double level) {
    if (level < 0 || level > 100) {
      return Left(ValidationFailure(
        message: 'Battery level must be between 0 and 100',
        code: 'VALIDATION_ERROR',
        errors: {
          'batteryLevel': ['Battery level must be between 0 and 100']
        },
      ));
    }
    return Right(level);
  }

  static Either<Failure, int> validateSignalStrength(int strength) {
    if (strength < -100 || strength > 0) {
      return Left(ValidationFailure(
        message: 'Signal strength must be between -100 and 0 dBm',
        code: 'VALIDATION_ERROR',
        errors: {
          'signalStrength': ['Signal strength must be between -100 and 0 dBm']
        },
      ));
    }
    return Right(strength);
  }
}
