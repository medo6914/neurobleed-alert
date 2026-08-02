import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../error/failure.dart';
import '../error/error_handler.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';
import '../network/dtos/device/device_dtos.dart';
import '../network/endpoints/device_endpoints.dart';
import '../database/offline_cache.dart';
import '../database/collections/device_collection.dart';
import '../sync/sync_queue.dart';

class DeviceRepository {
  final ApiClient _apiClient;
  final DeviceApi _deviceApi;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final OfflineCache? _cache;
  final SyncQueue? _syncQueue;

  DeviceRepository({
    required ApiClient apiClient,
    required DeviceApi deviceApi,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    OfflineCache? cache,
    SyncQueue? syncQueue,
  })  : _apiClient = apiClient,
        _deviceApi = deviceApi,
        _errorHandler = errorHandler,
        _logger = logger,
        _cache = cache,
        _syncQueue = syncQueue;

  Future<Either<Failure, Device>> registerDevice(
      DeviceCreateRequest request) async {
    try {
      final response = await _deviceApi.registerDevice(request.toJson());
      final dto =
          DeviceDto.fromJson(response.data as Map<String, dynamic>);
      final device = DeviceMapper.toEntity(dto);
      await _cache?.put('device_${device.id}',
          DeviceCollection.fromEntity(device).toJson());
      return Right(device);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: request.serialNumber,
          entityType: 'device',
          operation: 'create',
          data: request.toJson(),
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Device>> getDevice(String id) async {
    try {
      final response = await _deviceApi.getDevice(id);
      final dto =
          DeviceDto.fromJson(response.data as Map<String, dynamic>);
      final device = DeviceMapper.toEntity(dto);
      await _cache?.put('device_$id',
          DeviceCollection.fromEntity(device).toJson());
      return Right(device);
    } catch (e) {
      try {
        final cached = await _cache?.get<Device>(
          'device_$id',
          fromJson: (json) =>
              DeviceCollection.fromJson(json).toEntity(),
        );
        if (cached != null) return Right(cached);
      } catch (_) {}
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Device>>> listDevices({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    String? status,
    String? deviceType,
    String? hospitalId,
    String? patientId,
    String? search,
  }) async {
    try {
      final response = await _deviceApi.listDevices(
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
        status: status,
        deviceType: deviceType,
        hospitalId: hospitalId,
        patientId: patientId,
        search: search,
      );
      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List)
          .map((e) => DeviceMapper.toEntity(
              DeviceDto.fromJson(e as Map<String, dynamic>)))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Device>> updateDevice(
      String id, DeviceUpdateRequest request) async {
    try {
      final response =
          await _deviceApi.updateDevice(id, request.toJson());
      final dto =
          DeviceDto.fromJson(response.data as Map<String, dynamic>);
      final device = DeviceMapper.toEntity(dto);
      await _cache?.put('device_$id',
          DeviceCollection.fromEntity(device).toJson());
      return Right(device);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: id,
          entityType: 'device',
          operation: 'update',
          data: request.toJson(),
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> deleteDevice(String id) async {
    try {
      await _deviceApi.deleteDevice(id);
      await _cache?.remove('device_$id');
      return const Right(true);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Device>> updateStatus(
      String id, DeviceStatusUpdate statusUpdate) async {
    try {
      final response =
          await _deviceApi.updateStatus(id, statusUpdate.toJson());
      final dto =
          DeviceDto.fromJson(response.data as Map<String, dynamic>);
      final device = DeviceMapper.toEntity(dto);
      await _cache?.put('device_$id',
          DeviceCollection.fromEntity(device).toJson());
      return Right(device);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Device>> assignDevice(
      String id, DeviceAssignRequest request) async {
    try {
      final response =
          await _deviceApi.assignDevice(id, request.toJson());
      final dto =
          DeviceDto.fromJson(response.data as Map<String, dynamic>);
      final device = DeviceMapper.toEntity(dto);
      await _cache?.put('device_$id',
          DeviceCollection.fromEntity(device).toJson());
      return Right(device);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Device>> unassignDevice(String id) async {
    try {
      final response = await _deviceApi.unassignDevice(id);
      final dto =
          DeviceDto.fromJson(response.data as Map<String, dynamic>);
      final device = DeviceMapper.toEntity(dto);
      await _cache?.put('device_$id',
          DeviceCollection.fromEntity(device).toJson());
      return Right(device);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Device>> heartbeat(
      String id, DeviceHeartbeatRequest request) async {
    try {
      final response =
          await _deviceApi.heartbeat(id, request.toJson());
      final dto =
          DeviceDto.fromJson(response.data as Map<String, dynamic>);
      final device = DeviceMapper.toEntity(dto);
      await _cache?.put('device_$id',
          DeviceCollection.fromEntity(device).toJson());
      return Right(device);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, DeviceDiagnostics>> getDiagnostics(
      String id) async {
    try {
      final response = await _deviceApi.getDiagnostics(id);
      return Right(DeviceDiagnostics.fromJson(
          response.data as Map<String, dynamic>));
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, int>> getTotalCount({String? hospitalId}) async {
    try {
      final params = <String, dynamic>{'page': 1, 'limit': 1};
      if (hospitalId != null) params['hospital_id'] = hospitalId;
      final response =
          await _apiClient.get('/v1/devices', queryParameters: params);
      final total = response.data['total'] as int? ?? 0;
      return Right(total);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Device>>> searchDevices(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _deviceApi.listDevices(
        search: query,
        page: page,
        limit: limit,
      );
      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List)
          .map((e) => DeviceMapper.toEntity(
              DeviceDto.fromJson(e as Map<String, dynamic>)))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> bulkOperation(
      BulkOperationRequest request) async {
    try {
      final response = await _deviceApi.bulkOperation(request.toJson());
      final result = (response.data['results'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      return Right(result);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<dynamic>>> getHistory(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _deviceApi.getHistory(id, page: page, limit: limit);
      final data = response.data['data'] as List<dynamic>? ?? [];
      return Right(data);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, ProvisioningClaimResponse>> claimDevice(
    ProvisioningClaimRequest request,
  ) async {
    try {
      final response = await _deviceApi.claimDevice(request.toJson());
      return Right(ProvisioningClaimResponse.fromJson(
          response.data as Map<String, dynamic>));
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }
}
