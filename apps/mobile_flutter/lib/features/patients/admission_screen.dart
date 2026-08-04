import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';
import 'providers/patients_providers.dart';

class AdmissionScreen extends ConsumerStatefulWidget {
  final String patientId;
  const AdmissionScreen({super.key, required this.patientId});

  @override
  ConsumerState<AdmissionScreen> createState() => _AdmissionScreenState();
}

class _AdmissionScreenState extends ConsumerState<AdmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _admissionType = 'emergency';
  final _admittingPhysicianController = TextEditingController();
  final _wardController = TextEditingController();
  final _bedNumberController = TextEditingController();
  final _primaryDiagnosisController = TextEditingController();
  final _admissionNotesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _admittingPhysicianController.dispose();
    _wardController.dispose();
    _bedNumberController.dispose();
    _primaryDiagnosisController.dispose();
    _admissionNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientDetailProvider(widget.patientId));
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.t('admitPatient')),
        centerTitle: true,
      ),
      body: patientAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: localizations.t('error'),
          message: e.toString(),
        ),
        data: (patient) {
          if (_primaryDiagnosisController.text.isEmpty && patient.primaryDiagnosis != null) {
            _primaryDiagnosisController.text = patient.primaryDiagnosis!;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(NeuroSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          child: Text('${patient.firstName[0]}${patient.lastName[0]}'),
                        ),
                        SizedBox(width: NeuroSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${patient.firstName} ${patient.lastName}', style: Theme.of(context).textTheme.titleMedium),
                            Text('MRN: ${patient.mrn}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: NeuroSpacing.lg),

                  Text(localizations.t('admissionDetails'), style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary,
                  )),
                  SizedBox(height: NeuroSpacing.sm),

                  DropdownButtonFormField<String>(
                    value: _admissionType,
                    decoration: InputDecoration(
                      labelText: localizations.t('admissionType'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(NeuroRadius.md)),
                    ),
                    items: ['emergency', 'elective', 'urgent'].map((t) => DropdownMenuItem(
                      value: t, child: Text(t),
                    )).toList(),
                    onChanged: (v) => setState(() => _admissionType = v!),
                  ),
                  SizedBox(height: NeuroSpacing.sm),

                  AppInput(
                    controller: _admittingPhysicianController,
                    label: localizations.t('admittingPhysician'),
                  ),
                  SizedBox(height: NeuroSpacing.sm),

                  Row(
                    children: [
                      Expanded(child: AppInput(controller: _wardController, label: localizations.t('ward'))),
                      SizedBox(width: NeuroSpacing.sm),
                      Expanded(child: AppInput(controller: _bedNumberController, label: localizations.t('bedNumber'))),
                    ],
                  ),
                  SizedBox(height: NeuroSpacing.sm),

                  AppInput(
                    controller: _primaryDiagnosisController,
                    label: localizations.t('primaryDiagnosis'),
                  ),
                  SizedBox(height: NeuroSpacing.sm),

                  TextField(
                    controller: _admissionNotesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: localizations.t('notes'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(NeuroRadius.md)),
                      alignLabelWithHint: true,
                    ),
                  ),
                  SizedBox(height: NeuroSpacing.xxl),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: AppButton(
                      label: _isSubmitting ? localizations.t('admitting') : localizations.t('admitPatient'),
                      icon: _isSubmitting ? null : Icons.local_hospital,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : () => _submit(patient),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(Patient patient) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final admission = Admission(
      id: '',
      patientId: widget.patientId,
      patientName: '${patient.firstName} ${patient.lastName}',
      patientMrn: patient.mrn,
      status: AdmissionStatus.active,
      admissionType: _admissionType,
      admittingPhysician: _admittingPhysicianController.text.trim(),
      ward: _wardController.text.trim().isEmpty ? null : _wardController.text.trim(),
      bedNumber: _bedNumberController.text.trim().isEmpty ? null : _bedNumberController.text.trim(),
      primaryDiagnosis: _primaryDiagnosisController.text.trim().isEmpty ? null : _primaryDiagnosisController.text.trim(),
      admissionNotes: _admissionNotesController.text.trim().isEmpty ? null : _admissionNotesController.text.trim(),
      admissionDate: now,
      createdAt: now,
      updatedAt: now,
    );

    final useCase = ref.read(admitPatientProvider);
    final result = await useCase(admission);

    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: NeuroColors.critical),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient admitted successfully')),
        );
        context.pop();
      },
    );
  }
}
