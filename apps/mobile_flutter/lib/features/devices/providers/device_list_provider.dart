import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'device_repository_providers.dart';

class DeviceListState {
  final List<Device> devices;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;
  final String searchQuery;
  final DeviceStatus? statusFilter;
  final DeviceType? typeFilter;

  const DeviceListState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.searchQuery = '',
    this.statusFilter,
    this.typeFilter,
  });

  DeviceListState copyWith({
    List<Device>? devices,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    String? searchQuery,
    DeviceStatus? statusFilter,
    DeviceType? typeFilter,
    bool clearError = false,
  }) {
    return DeviceListState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }
}

class DeviceListNotifier extends StateNotifier<DeviceListState> {
  final DeviceRepository _repository;

  DeviceListNotifier(this._repository) : super(const DeviceListState());

  Future<void> loadDevices({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.page;
    if (!refresh && !state.hasMore) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.listDevices(
      page: page,
      limit: 20,
      search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      status: state.statusFilter?.name,
      deviceType: state.typeFilter?.name,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (devices) {
        state = state.copyWith(
          devices: refresh ? devices : [...state.devices, ...devices],
          isLoading: false,
          page: page + 1,
          hasMore: devices.length >= 20,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (!state.isLoading && state.hasMore) {
      await loadDevices();
    }
  }

  Future<void> refresh() async {
    await loadDevices(refresh: true);
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, page: 1, hasMore: true);
    await loadDevices(refresh: true);
  }

  void filterByStatus(DeviceStatus? status) {
    state = state.copyWith(statusFilter: status, page: 1, hasMore: true);
    loadDevices(refresh: true);
  }

  void filterByType(DeviceType? type) {
    state = state.copyWith(typeFilter: type, page: 1, hasMore: true);
    loadDevices(refresh: true);
  }
}

final deviceListProvider =
    StateNotifierProvider<DeviceListNotifier, DeviceListState>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return DeviceListNotifier(repository);
});

final deviceDetailProvider =
    FutureProvider.family<Device, String>((ref, id) async {
  final repository = ref.watch(deviceRepositoryProvider);
  final result = await repository.getDevice(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (device) => device,
  );
});

final deviceDiagnosticsProvider =
    FutureProvider.family<DeviceDiagnostics, String>((ref, id) async {
  final repository = ref.watch(deviceRepositoryProvider);
  final result = await repository.getDiagnostics(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (diagnostics) => diagnostics,
  );
});

final deviceHistoryProvider =
    FutureProvider.family<List<dynamic>, String>((ref, id) async {
  final repository = ref.watch(deviceRepositoryProvider);
  final result = await repository.getHistory(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (history) => history,
  );
});
