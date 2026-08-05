import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

class AddPatientNote {
  final NotesRepository _repository;

  AddPatientNote(this._repository);

  Future<Either<Failure, PatientNote>> call(PatientNote note) async {
    return _repository.createNote(note);
  }
}

final patientNotesProvider =
    FutureProvider.family<List<PatientNote>, String>((ref, patientId) async {
  final repository = ref.watch(notesRepositoryProvider);
  final result = await repository.getPatientNotes(patientId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (notes) => notes,
  );
});

final addPatientNoteProvider = Provider<AddPatientNote>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return AddPatientNote(repository);
});
