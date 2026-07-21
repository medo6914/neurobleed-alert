import 'package:equatable/equatable.dart';

enum DocumentType { labReport, imaging, prescription, consentForm, medicalReport, dischargeSummary, referral, other }

enum DocumentStatus { pending, uploaded, verified, rejected }

class MedicalDocument extends Equatable {
  final String id;
  final String patientId;
  final String? encounterId;
  final DocumentType type;
  final DocumentStatus status;
  final String title;
  final String? description;
  final String fileName;
  final String fileUrl;
  final String? thumbnailUrl;
  final int fileSize;
  final String mimeType;
  final String? uploadedBy;
  final String? uploadedByName;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalDocument({
    required this.id,
    required this.patientId,
    this.encounterId,
    this.type = DocumentType.other,
    this.status = DocumentStatus.pending,
    required this.title,
    this.description,
    required this.fileName,
    required this.fileUrl,
    this.thumbnailUrl,
    this.fileSize = 0,
    this.mimeType = 'application/octet-stream',
    this.uploadedBy,
    this.uploadedByName,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  MedicalDocument copyWith({
    String? id,
    String? patientId,
    String? encounterId,
    DocumentType? type,
    DocumentStatus? status,
    String? title,
    String? description,
    String? fileName,
    String? fileUrl,
    String? thumbnailUrl,
    int? fileSize,
    String? mimeType,
    String? uploadedBy,
    String? uploadedByName,
    String? verifiedBy,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalDocument(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      encounterId: encounterId ?? this.encounterId,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      encounterId: json['encounterId'] as String?,
      type: json['type'] != null
          ? DocumentType.values.firstWhere((e) => e.name == json['type'])
          : DocumentType.other,
      status: json['status'] != null
          ? DocumentStatus.values.firstWhere((e) => e.name == json['status'])
          : DocumentStatus.pending,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileSize: json['fileSize'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      uploadedBy: json['uploadedBy'] as String?,
      uploadedByName: json['uploadedByName'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'encounterId': encounterId,
      'type': type.name,
      'status': status.name,
      'title': title,
      'description': description,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, patientId, type, title, fileName];
}
