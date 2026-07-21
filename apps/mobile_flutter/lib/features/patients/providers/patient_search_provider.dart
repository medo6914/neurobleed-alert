import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

class PatientSearchState {
  final String query;
  final List<Patient> results;
  final bool isSearching;
  final String? error;

  const PatientSearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.error,
  });

  PatientSearchState copyWith({
    String? query,
    List<Patient>? results,
    bool? isSearching,
    String? error,
  }) {
    return PatientSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

class PatientSearchNotifier extends StateNotifier<PatientSearchState> {
  final PatientRepository _repository;

  PatientSearchNotifier(this._repository) : super(const PatientSearchState());

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isSearching: query.length >= 2);

    if (query.length < 2) {
      state = state.copyWith(isSearching: false, results: []);
      return;
    }

    final result = await _repository.searchPatients(query: query);

    result.fold(
      (failure) {
        state = state.copyWith(isSearching: false, error: failure.message);
      },
      (patients) {
        state = state.copyWith(
          isSearching: false,
          results: patients,
          error: null,
        );
      },
    );
  }

  void clear() {
    state = const PatientSearchState();
  }
}

final patientSearchProvider = StateNotifierProvider<PatientSearchNotifier, PatientSearchState>((ref) {
  final repository = ref.watch(patientRepositoryProvider);
  return PatientSearchNotifier(repository);
});
