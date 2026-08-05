import 'package:equatable/equatable.dart';

enum NoteType { general, medical, nursing, progress, consult, discharge, other }

enum NoteStatus { draft, final_, amended }

class PatientNote extends Equatable {
  final String id;
  final String patientId;
  final String? encounterId;
  final NoteType type;
  final NoteStatus status;
  final String title;
  final String content;
  final String? authorId;
  final String? authorName;
  final String? authorRole;
  final List<String> tags;
  final bool isConfidential;
  final bool isSticky;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? amendedAt;
  final String? amendedBy;

  const PatientNote({
    required this.id,
    required this.patientId,
    this.encounterId,
    this.type = NoteType.general,
    this.status = NoteStatus.draft,
    required this.title,
    required this.content,
    this.authorId,
    this.authorName,
    this.authorRole,
    this.tags = const [],
    this.isConfidential = false,
    this.isSticky = false,
    required this.createdAt,
    required this.updatedAt,
    this.amendedAt,
    this.amendedBy,
  });

  PatientNote copyWith({
    String? id,
    String? patientId,
    String? encounterId,
    NoteType? type,
    NoteStatus? status,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? authorRole,
    List<String>? tags,
    bool? isConfidential,
    bool? isSticky,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? amendedAt,
    String? amendedBy,
  }) {
    return PatientNote(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      encounterId: encounterId ?? this.encounterId,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      tags: tags ?? this.tags,
      isConfidential: isConfidential ?? this.isConfidential,
      isSticky: isSticky ?? this.isSticky,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      amendedAt: amendedAt ?? this.amendedAt,
      amendedBy: amendedBy ?? this.amendedBy,
    );
  }

  factory PatientNote.fromJson(Map<String, dynamic> json) {
    return PatientNote(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      encounterId: json['encounterId'] as String?,
      type: json['type'] != null
          ? NoteType.values.firstWhere((e) => e.name == json['type'])
          : NoteType.general,
      status: json['status'] != null
          ? NoteStatus.values.firstWhere((e) => e.name == json['status'])
          : NoteStatus.draft,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      authorRole: json['authorRole'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      isConfidential: json['isConfidential'] as bool? ?? false,
      isSticky: json['isSticky'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      amendedAt: json['amendedAt'] != null
          ? DateTime.parse(json['amendedAt'] as String)
          : null,
      amendedBy: json['amendedBy'] as String?,
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
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'tags': tags,
      'isConfidential': isConfidential,
      'isSticky': isSticky,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'amendedAt': amendedAt?.toIso8601String(),
      'amendedBy': amendedBy,
    };
  }

  @override
  List<Object?> get props => [id, patientId, type, status, title, createdAt];
}
