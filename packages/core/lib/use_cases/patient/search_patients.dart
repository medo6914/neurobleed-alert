import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/patient_repository.dart';
import '../../security/permissions.dart';

class SearchPatients {
  final PatientRepository _repository;

  SearchPatients(this._repository);

  Future<Either<Failure, List<Patient>>> call({
    String? query,
    String? status,
    String? hospitalId,
    String? departmentId,
    String? ward,
    String? gender,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    UserRole? userRole,
  }) async {
    if (query != null && query.length < 2) {
      return Left(ValidationFailure(
        message: 'Search query must be at least 2 characters',
        code: 'VALIDATION_ERROR',
      ));
    }

    if (userRole != null &&
        !RolePermissions.hasPermission(userRole, Permission.patientSearch)) {
      return Left(AuthFailure(
        message: 'You do not have permission to search patients',
        code: 'FORBIDDEN',
      ));
    }

    return _repository.searchPatients(
      query: query,
      status: status,
      hospitalId: hospitalId,
      departmentId: departmentId,
      page: page,
      limit: limit,
    );
  }
}
