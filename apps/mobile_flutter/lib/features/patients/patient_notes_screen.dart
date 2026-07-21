import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';
import 'providers/patients_providers.dart';

class PatientNotesScreen extends ConsumerWidget {
  final String patientId;

  const PatientNotesScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(patientNotesProvider(patientId));
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.t('notes')),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddNoteDialog(context, ref),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: localizations.t('error'),
          message: e.toString(),
          onRetry: () => ref.invalidate(patientNotesProvider(patientId)),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return AppEmptyState(
              icon: Icons.note,
              title: localizations.t('noNotes'),
              message: localizations.t('noNotesFound'),
              actionLabel: localizations.t('addNote'),
              onAction: () => _showAddNoteDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(NeuroSpacing.md),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Padding(
                padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
                child: AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              label: Text(note.type.name, style: const TextStyle(fontSize: 10)),
                              visualDensity: VisualDensity.compact,
                            ),
                            SizedBox(width: NeuroSpacing.sm),
                            if (note.isConfidential)
                              const Icon(Icons.lock, size: 14),
                            const Spacer(),
                            Text(
                              note.createdAt.toLocal().toString().substring(0, 10),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: NeuroSpacing.sm),
                        Text(
                          note.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: NeuroSpacing.xs),
                        Text(
                          note.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (note.authorName != null) ...[
                          SizedBox(height: NeuroSpacing.sm),
                          Text(
                            'by ${note.authorName}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddNoteSheet(patientId: patientId),
    );
  }
}

class _AddNoteSheet extends ConsumerStatefulWidget {
  final String patientId;
  const _AddNoteSheet({required this.patientId});

  @override
  ConsumerState<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<_AddNoteSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  NoteType _type = NoteType.general;
  bool _isConfidential = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: NeuroSpacing.lg,
        right: NeuroSpacing.lg,
        top: NeuroSpacing.lg,
        bottom: bottomInset + NeuroSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: NeuroSpacing.md),
          Text(localizations.t('addNote'), style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: NeuroSpacing.md),
          DropdownButtonFormField<NoteType>(
            value: _type,
            decoration: InputDecoration(
              labelText: localizations.t('type'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(NeuroRadius.md)),
            ),
            items: NoteType.values.map((t) => DropdownMenuItem(
              value: t, child: Text(t.name),
            )).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          SizedBox(height: NeuroSpacing.sm),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: localizations.t('title'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(NeuroRadius.md)),
            ),
          ),
          SizedBox(height: NeuroSpacing.sm),
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: localizations.t('content'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(NeuroRadius.md)),
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: NeuroSpacing.sm),
          SwitchListTile(
            title: Text(localizations.t('confidential')),
            value: _isConfidential,
            onChanged: (v) => setState(() => _isConfidential = v),
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: NeuroSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: _isSubmitting ? localizations.t('saving') : localizations.t('save'),
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) return;
    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final note = PatientNote(
      id: '',
      patientId: widget.patientId,
      type: _type,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      isConfidential: _isConfidential,
      createdAt: now,
      updatedAt: now,
    );

    final useCase = ref.read(addPatientNoteProvider);
    final result = await useCase(note);

    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (_) {
        Navigator.pop(context);
        ref.invalidate(patientNotesProvider(widget.patientId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note added successfully')),
        );
      },
    );
  }
}
