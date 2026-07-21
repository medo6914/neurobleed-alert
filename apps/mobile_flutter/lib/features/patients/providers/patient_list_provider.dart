import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

class PatientListState {
  final List<Patient> patients;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final String? searchQuery;
  final String? statusFilter;

  const PatientListState({
    this.patients = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.searchQuery,
    this.statusFilter,
  });

  PatientListState copyWith({
    List<Patient>? patients,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
    String? searchQuery,
    String? statusFilter,
  }) {
    return PatientListState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class PatientListNotifier extends StateNotifier<PatientListState> {
  final PatientRepository _repository;

  PatientListNotifier(this._repository) : super(const PatientListState());

  Future<void> loadPatients({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    if (!refresh && !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.listPatients(
      page: page,
      limit: 20,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (patients) {
        state = state.copyWith(
          patients: refresh ? patients : [...state.patients, ...patients],
          isLoading: false,
          currentPage: page + 1,
          hasMore: patients.length >= 20,
          error: null,
        );
      },
    );
  }

  Future<void> searchPatients(String query) async {
    if (query.length < 2) {
      if (state.searchQuery != null) {
        state = state.copyWith(searchQuery: null);
        loadPatients(refresh: true);
      }
      return;
    }

    state = state.copyWith(isLoading: true, error: null, searchQuery: query);

    final result = await _repository.searchPatients(query: query);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (patients) {
        state = state.copyWith(
          patients: patients,
          isLoading: false,
          currentPage: 1,
          hasMore: false,
          error: null,
        );
      },
    );
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status, currentPage: 1);
    loadPatients(refresh: true);
  }
}

final patientListProvider = StateNotifierProvider<PatientListNotifier, PatientListState>((ref) {
  final repository = ref.watch(patientRepositoryProvider);
  return PatientListNotifier(repository);
});
