import 'dart:convert';

class SyncQueueEntry {
  final String id;
  final String entityType;
  final String operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  const SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  SyncQueueEntry copyWith({
    String? id,
    String? entityType,
    String? operation,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? lastError,
  }) {
    return SyncQueueEntry(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'operation': operation,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) => SyncQueueEntry(
        id: json['id'] as String,
        entityType: json['entityType'] as String,
        operation: json['operation'] as String,
        data: json['data'] as Map<String, dynamic>,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
        lastError: json['lastError'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());

  factory SyncQueueEntry.fromJsonString(String jsonString) =>
      SyncQueueEntry.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

class SyncQueue {
  final List<SyncQueueEntry> _entries = [];

  /// Internal access for [PersistentSyncQueue] in `database/`.
  List<SyncQueueEntry> get entriesInternal => _entries;

  List<SyncQueueEntry> get entries => List.unmodifiable(_entries);

  Future<void> add(SyncQueueEntry entry) async {
    _entries.add(entry);
  }

  Future<void> addAll(List<SyncQueueEntry> entries) async {
    _entries.addAll(entries);
  }

  Future<List<SyncQueueEntry>> getPending() async {
    return _entries.where((e) => e.retryCount < 5).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<List<SyncQueueEntry>> getFailed() async {
    return _entries.where((e) => e.retryCount >= 5).toList();
  }

  Future<int> getPendingCount() async {
    return _entries.where((e) => e.retryCount < 5).length;
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  Future<void> incrementRetry(String id, String error) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final entry = _entries[index];
      _entries[index] = entry.copyWith(
        retryCount: entry.retryCount + 1,
        lastError: error,
      );
    }
  }

  Future<void> markFailed(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final entry = _entries[index];
      _entries[index] = entry.copyWith(
        retryCount: 5,
        lastError: 'Max retries exceeded',
      );
    }
  }

  Future<void> markPending(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final entry = _entries[index];
      _entries[index] = entry.copyWith(
        retryCount: 0,
        lastError: null,
      );
    }
  }

  Future<void> clear() async {
    _entries.clear();
  }

  Future<void> clearCompleted() async {
    _entries.removeWhere((e) => e.retryCount < 5);
  }
}
