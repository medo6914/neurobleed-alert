import 'package:isar_community/isar.dart';

class LocalDatabaseService {
  Isar? _isar;

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

    _isar = await Isar.open(
      schemas,
      directory: directory ?? '',
    );
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
