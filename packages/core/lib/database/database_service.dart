import 'package:isar_community/isar.dart';
import 'package:shared/shared.dart';

import '../logging/logger.dart';
import '../storage/local_database_service.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_queue.dart';
import 'collections.dart';
import 'database_collections.dart';
import 'offline_cache.dart';
import 'persistent_sync_queue.dart';

/// Central offline-first data access layer.
///
/// Coordinates between three storage tiers:
/// 1. **Isar** – local embedded database (primary store).
/// 2. **OfflineCache** – file-based JSON fallback for reads.
/// 3. **PersistentSyncQueue** – write-behind queue for operations
///    created while offline.
class DatabaseService {
  final LocalDatabaseService _localDb;
  final PersistentSyncQueue _syncQueue;
  final SyncEngine _syncEngine;
  final OfflineCache _cache;
  final AppLogger _logger;

  DatabaseService({
    required LocalDatabaseService localDb,
    required PersistentSyncQueue syncQueue,
    required SyncEngine syncEngine,
    required OfflineCache cache,
    required AppLogger logger,
  })  : _localDb = localDb,
        _syncQueue = syncQueue,
        _syncEngine = syncEngine,
        _cache = cache,
        _logger = logger;

  /// Open Isar and bootstrap the cache & sync queue.
  Future<void> initialize({String? directory}) async {
    await _cache.init();
    await _syncQueue.init();

    _localDb.initialize(
      DatabaseCollections.allSchemas,
      directory: directory,
    );
    _logger.info('DatabaseService initialised');
  }

  // --------------------------------------------------------------------------
  // Internal helpers
  // --------------------------------------------------------------------------

  Isar get _db => _localDb.db;

  bool get _isarReady => _localDb.isInitialized;

  // --------------------------------------------------------------------------
  // PATIENTS
  // --------------------------------------------------------------------------

  Future<Patient?> getPatient(String id) async {
    final cached = await _cache.get<PatientCollection>(
      'patient_$id',
      fromJson: PatientCollection.fromJson,
    );
    if (cached != null) return cached.toEntity();

    if (_isarReady) {
      final col = _db.patientCollections;
      final found = await col.where().idEqualTo(id).findFirst();
      if (found != null) {
        await _cache.put('patient_$id', found.toJson());
        return found.toEntity();
      }
    }
    return null;
  }

  Future<List<Patient>> getAllPatients() async {
    if (!_isarReady) return [];
    return (await _db.patientCollections.where().findAll())
        .map((c) => c.toEntity())
        .toList();
  }

  Future<void> savePatient(Patient patient) async {
    final col = PatientCollection.fromEntity(patient);
    if (_isarReady) {
      await _db.patientCollections.put(col);
    }
    await _cache.put('patient_${patient.id}', col.toJson());
  }

  Future<void> deletePatient(String id) async {
    if (_isarReady) {
      await _db.patientCollections.where().idEqualTo(id).deleteAll();
    }
    await _cache.remove('patient_$id');
  }

  // --------------------------------------------------------------------------
  // ALERTS
  // --------------------------------------------------------------------------

  Future<Alert?> getAlert(String id) async {
    final cached = await _cache.get<AlertCollection>(
      'alert_$id',
      fromJson: AlertCollection.fromJson,
    );
    if (cached != null) return cached.toEntity();
    if (_isarReady) {
      final found =
          await _db.alertCollections.where().idEqualTo(id).findFirst();
      if (found != null) {
        await _cache.put('alert_$id', found.toJson());
        return found.toEntity();
      }
    }
    return null;
  }

  Future<List<Alert>> getAlertsForPatient(String patientId) async {
    if (!_isarReady) return [];
    return (await _db.alertCollections
            .where()
            .patientIdEqualTo(patientId)
            .findAll())
        .map((c) => c.toEntity())
        .toList();
  }

  Future<List<Alert>> getRecentAlerts({int limit = 50}) async {
    if (!_isarReady) return [];
    return (await _db.alertCollections
            .where()
            .sortByCreatedAtDesc()
            .limit(limit)
            .findAll())
        .map((c) => c.toEntity())
        .toList();
  }

  Future<void> saveAlert(Alert alert) async {
    final col = AlertCollection.fromEntity(alert);
    if (_isarReady) {
      await _db.alertCollections.put(col);
    }
    await _cache.put('alert_${alert.id}', col.toJson());
  }

  // --------------------------------------------------------------------------
  // DEVICES
  // --------------------------------------------------------------------------

  Future<Device?> getDevice(String id) async {
    final cached = await _cache.get<DeviceCollection>(
      'device_$id',
      fromJson: DeviceCollection.fromJson,
    );
    if (cached != null) return cached.toEntity();
    if (_isarReady) {
      final found =
          await _db.deviceCollections.where().idEqualTo(id).findFirst();
      if (found != null) {
        await _cache.put('device_$id', found.toJson());
        return found.toEntity();
      }
    }
    return null;
  }

  Future<List<Device>> getDevicesByPatient(String patientId) async {
    if (!_isarReady) return [];
    return (await _db.deviceCollections
            .where()
            .patientIdEqualTo(patientId)
            .findAll())
        .map((c) => c.toEntity())
        .toList();
  }

  Future<void> saveDevice(Device device) async {
    final col = DeviceCollection.fromEntity(device);
    if (_isarReady) {
      await _db.deviceCollections.put(col);
    }
    await _cache.put('device_${device.id}', col.toJson());
  }

  Future<List<Device>> getAllDevices() async {
    if (!_isarReady) return [];
    return (await _db.deviceCollections.where().findAll())
        .map((c) => c.toEntity())
        .toList();
  }

  // --------------------------------------------------------------------------
  // SENSOR READINGS
  // --------------------------------------------------------------------------

  Future<SensorReading?> getSensorReading(String id) async {
    final cached = await _cache.get<SensorReadingCollection>(
      'reading_$id',
      fromJson: SensorReadingCollection.fromJson,
    );
    if (cached != null) return cached.toEntity();
    if (_isarReady) {
      final found =
          await _db.sensorReadingCollections.where().idEqualTo(id).findFirst();
      if (found != null) {
        await _cache.put('reading_$id', found.toJson());
        return found.toEntity();
      }
    }
    return null;
  }

  Future<List<SensorReading>> getReadingsForPatient(
    String patientId, {
    DateTime? since,
    int limit = 100,
  }) async {
    if (!_isarReady) return [];
    if (since != null) {
      return (await _db.sensorReadingCollections
              .where()
              .patientIdEqualTo(patientId)
              .filter()
              .timestampGreaterThan(since)
              .sortByTimestampDesc()
              .limit(limit)
              .findAll())
          .map((c) => c.toEntity())
          .toList();
    }
    return (await _db.sensorReadingCollections
            .where()
            .patientIdEqualTo(patientId)
            .sortByTimestampDesc()
            .limit(limit)
            .findAll())
        .map((c) => c.toEntity())
        .toList();
  }

  Future<void> saveSensorReading(SensorReading reading) async {
    final col = SensorReadingCollection.fromEntity(reading);
    if (_isarReady) {
      await _db.sensorReadingCollections.put(col);
    }
    await _cache.put('reading_${reading.id}', col.toJson());
  }

  Future<void> deleteReadingsForPatient(String patientId) async {
    if (_isarReady) {
      await _db.sensorReadingCollections
          .where()
          .patientIdEqualTo(patientId)
          .deleteAll();
    }
    await _cache.clearByPrefix('reading_');
  }

  // --------------------------------------------------------------------------
  // HOSPITALS
  // --------------------------------------------------------------------------

  Future<Hospital?> getHospital(String id) async {
    final cached = await _cache.get<HospitalCollection>(
      'hospital_$id',
      fromJson: HospitalCollection.fromJson,
    );
    if (cached != null) return cached.toEntity();
    if (_isarReady) {
      final found =
          await _db.hospitalCollections.where().idEqualTo(id).findFirst();
      if (found != null) {
        await _cache.put('hospital_$id', found.toJson());
        return found.toEntity();
      }
    }
    return null;
  }

  Future<List<Hospital>> getAllHospitals() async {
    if (!_isarReady) return [];
    return (await _db.hospitalCollections.where().findAll())
        .map((c) => c.toEntity())
        .toList();
  }

  Future<void> saveHospital(Hospital hospital) async {
    final col = HospitalCollection.fromEntity(hospital);
    if (_isarReady) {
      await _db.hospitalCollections.put(col);
    }
    await _cache.put('hospital_${hospital.id}', col.toJson());
  }

  // --------------------------------------------------------------------------
  // USERS
  // --------------------------------------------------------------------------

  Future<User?> getUser(String id) async {
    final cached = await _cache.get<UserCollection>(
      'user_$id',
      fromJson: UserCollection.fromJson,
    );
    if (cached != null) return cached.toEntity();
    if (_isarReady) {
      final found = await _db.userCollections.where().idEqualTo(id).findFirst();
      if (found != null) {
        await _cache.put('user_$id', found.toJson());
        return found.toEntity();
      }
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    if (!_isarReady) return null;
    final found =
        await _db.userCollections.where().emailEqualTo(email).findFirst();
    if (found != null) {
      await _cache.put('user_${found.id}', found.toJson());
      return found.toEntity();
    }
    return null;
  }

  Future<void> saveUser(User user) async {
    final col = UserCollection.fromEntity(user);
    if (_isarReady) {
      await _db.userCollections.put(col);
    }
    await _cache.put('user_${user.id}', col.toJson());
  }

  // --------------------------------------------------------------------------
  // SYNC – write-through queuing
  // --------------------------------------------------------------------------

  /// Queue a write operation for the sync engine.
  ///
  /// The operation will be replayed against the backend once connectivity
  /// is restored.
  Future<void> enqueueSync({
    required String id,
    required String entityType,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final entry = SyncQueueEntry(
      id: id,
      entityType: entityType,
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
    );
    await _syncEngine.enqueue(entry);
  }

  /// Number of pending sync operations.
  Future<int> get pendingSyncCount => _syncQueue.getPendingCount();

  /// Number of permanently failed operations.
  Future<int> get failedSyncCount =>
      _syncQueue.getFailed().then((v) => v.length);

  // --------------------------------------------------------------------------
  // LIFE-CYCLE
  // --------------------------------------------------------------------------

  Future<void> close() async {
    await _localDb.close();
    _logger.info('DatabaseService closed');
  }
}
