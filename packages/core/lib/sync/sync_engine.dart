import 'dart:async';
import 'dart:math';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../logging/logger.dart';
import 'sync_queue.dart';

enum SyncStatus { idle, syncing, completed, error }

class SyncEngine {
  final NetworkInfo _networkInfo;
  final SyncQueue _syncQueue;
  final ApiClient _apiClient;
  final AppLogger _logger;

  static const int _maxRetries = 5;
  static const Duration _baseDelay = Duration(seconds: 2);
  static const Duration _maxDelay = Duration(minutes: 5);
  static const Duration _periodicInterval = Duration(seconds: 30);

  StreamSubscription<bool>? _connectivitySub;
  Timer? _periodicTimer;
  bool _isProcessing = false;
  SyncStatus _status = SyncStatus.idle;

  final _statusController = StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get status => _statusController.stream;
  SyncStatus get currentStatus => _status;

  SyncEngine(
    this._networkInfo,
    this._syncQueue,
    this._apiClient,
    this._logger,
  );

  void start() {
    _connectivitySub = _networkInfo.onConnectivityChanged.listen((connected) {
      if (connected) {
        process();
      }
    });
    _periodicTimer = Timer.periodic(_periodicInterval, (_) {
      _networkInfo.isConnected.then((connected) {
        if (connected) process();
      });
    });
    _logger.info('Sync engine started');
  }

  Future<void> enqueue(SyncQueueEntry entry) async {
    await _syncQueue.add(entry);
    _logger.debug(
      'Enqueued sync entry',
      extra: {
        'id': entry.id,
        'entityType': entry.entityType,
        'operation': entry.operation,
      },
    );
    if (await _networkInfo.isConnected) {
      process();
    }
  }

  Future<void> process() async {
    if (_isProcessing) return;

    _isProcessing = true;
    _updateStatus(SyncStatus.syncing);

    try {
      final entries = await _syncQueue.getPending();

      if (entries.isEmpty) {
        _updateStatus(SyncStatus.idle);
        _isProcessing = false;
        return;
      }

      for (final entry in entries) {
        try {
          await _syncEntry(entry);
          await _syncQueue.remove(entry.id);
          _logger.info(
            'Synced entry',
            extra: {
              'id': entry.id,
              'entityType': entry.entityType,
              'operation': entry.operation,
            },
          );
        } catch (e) {
          final errorMessage = e.toString();
          await _syncQueue.incrementRetry(entry.id, errorMessage);
          final nextRetry = entry.retryCount + 1;
          _logger.warning(
            'Sync failed for entry',
            error: e,
            extra: {
              'id': entry.id,
              'retryCount': nextRetry,
            },
          );

          if (nextRetry >= _maxRetries) {
            await _syncQueue.markFailed(entry.id);
            _logger.error(
              'Sync entry exceeded max retries',
              extra: {'id': entry.id, 'entityType': entry.entityType},
            );
          }
        }
      }

      final failedCount = await _syncQueue.getFailed().then((v) => v.length);
      _updateStatus(
          failedCount > 0 ? SyncStatus.completed : SyncStatus.completed);
    } catch (e) {
      _logger.error('Sync engine process error', error: e);
      _updateStatus(SyncStatus.error);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> retryFailed() async {
    final failed = await _syncQueue.getFailed();
    for (final entry in failed) {
      await _syncQueue.markPending(entry.id);
    }
    if (failed.isNotEmpty && await _networkInfo.isConnected) {
      process();
    }
  }

  Duration _backoffDelay(int retryCount) {
    final exponential = _baseDelay * pow(2, retryCount).toInt();
    return exponential > _maxDelay ? _maxDelay : exponential;
  }

  Future<void> _syncEntry(SyncQueueEntry entry) async {
    switch (entry.operation) {
      case 'create':
        await _apiClient.post(
          '/${entry.entityType}',
          data: entry.data,
        );
        break;
      case 'update':
        await _apiClient.put(
          '/${entry.entityType}/${entry.id}',
          data: entry.data,
        );
        break;
      case 'delete':
        await _apiClient.delete(
          '/${entry.entityType}/${entry.id}',
        );
        break;
      default:
        throw ArgumentError('Unknown operation: ${entry.operation}');
    }
  }

  Future<int> getPendingCount() => _syncQueue.getPendingCount();

  Future<void> clear() => _syncQueue.clear();

  Future<void> clearCompleted() => _syncQueue.clearCompleted();

  void _updateStatus(SyncStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    _statusController.close();
  }
}
