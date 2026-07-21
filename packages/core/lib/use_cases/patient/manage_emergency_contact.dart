import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/patient_repository.dart';
import '../../network/endpoints/patient_endpoints.dart';
import '../../network/api_client.dart';
import '../../error/error_handler.dart';
import '../../security/audit_logger.dart';

class ManageEmergencyContact {
  final ApiClient _apiClient;
  final ErrorHandler _errorHandler;
  final PatientApi _patientApi;
  final AuditLogger? _auditLogger;

  ManageEmergencyContact(this._apiClient, this._errorHandler, this._patientApi,
      [this._auditLogger]);

  Future<Either<Failure, EmergencyContact>> addContact({
    required String patientId,
    required String name,
    required String relationship,
    String? phone,
    String? email,
    String? address,
    bool isPrimary = false,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    if (name.isEmpty) {
      return Left(ValidationFailure(
        message: 'Contact name is required',
        code: 'VALIDATION_ERROR',
      ));
    }
    if (relationship.isEmpty) {
      return Left(ValidationFailure(
        message: 'Relationship is required',
        code: 'VALIDATION_ERROR',
      ));
    }

    try {
      final response = await _patientApi.createEmergencyContact(patientId, {
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'email': email,
        'address': address,
        'isPrimary': isPrimary,
      });
      final contact =
          EmergencyContact.fromJson(response.data as Map<String, dynamic>);
      _auditLogger?.logCreate(
        patientId: patientId,
        resourceType: 'emergency_contact',
        resourceId: contact.id,
        userId: userId,
        userName: userName,
        userRole: userRole,
      );
      return Right(contact);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, EmergencyContact>> updateContact({
    required String patientId,
    required String contactId,
    String? name,
    String? relationship,
    String? phone,
    String? email,
    String? address,
    bool? isPrimary,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (relationship != null) updates['relationship'] = relationship;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (address != null) updates['address'] = address;
    if (isPrimary != null) updates['isPrimary'] = isPrimary;

    try {
      final response = await _patientApi.updateEmergencyContact(
          patientId, contactId, updates);
      final contact =
          EmergencyContact.fromJson(response.data as Map<String, dynamic>);
      _auditLogger?.logUpdate(
        patientId: patientId,
        resourceType: 'emergency_contact',
        resourceId: contactId,
        changes: updates,
        userId: userId,
        userName: userName,
        userRole: userRole,
      );
      return Right(contact);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> deleteContact({
    required String patientId,
    required String contactId,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    try {
      await _patientApi.deleteEmergencyContact(patientId, contactId);
      _auditLogger?.logDelete(
        patientId: patientId,
        resourceType: 'emergency_contact',
        resourceId: contactId,
        userId: userId,
        userName: userName,
        userRole: userRole,
      );
      return const Right(true);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<EmergencyContact>>> listContacts(
      String patientId) async {
    try {
      final response = await _patientApi.getEmergencyContacts(patientId);
      final list = (response.data as List)
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }
}
