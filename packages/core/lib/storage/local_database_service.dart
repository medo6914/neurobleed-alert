import 'package:isar_community/isar.dart';
import '../logging/logger.dart';

class LocalDatabaseService {
  Isar? _isar;
  final AppLogger? _logger;

  LocalDatabaseService({AppLogger? logger}) : _logger = logger;

  Isar get db {
    if (_isar == null) {
      throw StateError(
          'LocalDatabaseService not initialized. Call initialize() first.');
    }
    return _isar!;
  }

  bool get isInitialized => _isar != null;

  Future<void> initialize(List<CollectionSchema> schemas,
      {String? directory}) async {
    if (_isar != null) return;

    try {
      _isar = await Isar.open(
        schemas,
        directory: directory ?? '',
      );
    } catch (e) {
      _logger?.warning('Isar initialization failed (expected on web): $e');
    }
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
