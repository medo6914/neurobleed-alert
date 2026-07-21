import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../database/database_service.dart';
import '../database/collections/device_collection.dart';
import '../error/failure.dart';
import '../logging/logger.dart';
import '../sync/sync_engine.dart';
import 'device_repository.dart';

class DeviceSyncRepository {
  final DeviceRepository _repository;
  final DatabaseService _db;
  final SyncEngine _syncEngine;
  final AppLogger _logger;

  DeviceSyncRepository({
    required DeviceRepository repository,
    required DatabaseService db,
    required SyncEngine syncEngine,
    required AppLogger logger,
  })  : _repository = repository,
        _db = db,
        _syncEngine = syncEngine,
        _logger = logger;

  Future<void> syncPendingDeviceOperations() async {
    await _syncEngine.process();
  }

  Future<Either<Failure, Device>> getDeviceWithSync(String id) async {
    final result = await _repository.getDevice(id);
    return result.fold(
      (failure) async {
        final local = await _db.getDevice(id);
        if (local != null) return Right(local);
        return Left(failure);
      },
      (device) async {
        await _db.saveDevice(device);
        return Right(device);
      },
    );
  }

  Future<List<Device>> getLocalDevices() async {
    try {
      final all = await _db.getAllDevices();
      return all;
    } catch (e) {
      _logger.error('Failed to get local devices', error: e);
      return [];
    }
  }

  Future<void> cacheDeviceLocally(Device device) async {
    try {
      await _db.saveDevice(device);
    } catch (e) {
      _logger.error('Failed to cache device locally', error: e);
    }
  }
}
