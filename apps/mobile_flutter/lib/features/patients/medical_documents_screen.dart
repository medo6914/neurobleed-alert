import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'providers/patients_providers.dart';

class MedicalDocumentsScreen extends ConsumerWidget {
  final String patientId;
  const MedicalDocumentsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(patientDocumentsProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Documents'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.upload_file),
        onPressed: () => context.push('/patients/$patientId/documents/add'),
      ),
      body: docsAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
        data: (docs) {
          if (docs.isEmpty) {
            return AppEmptyState(
              icon: Icons.description,
              title: 'No Documents',
              message: 'No medical documents uploaded yet',
              actionLabel: 'Upload Document',
              onAction: () => context.push('/patients/$patientId/documents/add'),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(NeuroSpacing.md),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final statusColor = doc.status == DocumentStatus.verified
                  ? Colors.green
                  : doc.status == DocumentStatus.rejected
                      ? Colors.red
                      : Colors.orange;

              return Padding(
                padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
                child: AppCard(
                  child: ListTile(
                    leading: Icon(_documentIcon(doc.type), color: NeuroColors.primary, size: 32),
                    title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.fileName),
                        Text('${_formatSize(doc.fileSize)} • ${doc.createdAt.toLocal().toString().substring(0, 10)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(doc.status.name, style: const TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: statusColor,
                      visualDensity: VisualDensity.compact,
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _documentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.labReport: return Icons.science;
      case DocumentType.imaging: return Icons.image;
      case DocumentType.prescription: return Icons.medication;
      case DocumentType.consentForm: return Icons.description;
      case DocumentType.medicalReport: return Icons.article;
      case DocumentType.dischargeSummary: return Icons.summarize;
      case DocumentType.referral: return Icons.send;
      default: return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
