import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';
import 'providers/patients_providers.dart';

class DischargeScreen extends ConsumerStatefulWidget {
  final String patientId;
  const DischargeScreen({super.key, required this.patientId});

  @override
  ConsumerState<DischargeScreen> createState() => _DischargeScreenState();
}

class _DischargeScreenState extends ConsumerState<DischargeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _physicianController = TextEditingController();
  String _disposition = 'home';
  String? _selectedAdmissionId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _physicianController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admissionsAsync =
        ref.watch(patientAdmissionsProvider(widget.patientId));
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.t('dischargePatient')),
        centerTitle: true,
      ),
      body: admissionsAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: localizations.t('error'),
          message: e.toString(),
        ),
        data: (admissions) {
          final activeAdmissions = admissions
              .where((a) => a.status == AdmissionStatus.active)
              .toList();

          if (activeAdmissions.isEmpty) {
            return AppEmptyState(
              icon: Icons.check_circle,
              title: localizations.t('noActiveAdmissions'),
              message: localizations.t('patientNotAdmitted'),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(NeuroSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localizations.t('selectAdmission'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          )),
                  SizedBox(height: NeuroSpacing.sm),
                  ...activeAdmissions.map((admission) => Padding(
                        padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
                        child: AppCard(
                          onTap: () => setState(
                              () => _selectedAdmissionId = admission.id),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: admission.id,
                                groupValue: _selectedAdmissionId,
                                onChanged: (v) =>
                                    setState(() => _selectedAdmissionId = v),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${admission.admissionType ?? "N/A"} - ${admission.admissionDate.toLocal().toString().substring(0, 10)}'),
                                    Text(
                                        '${admission.ward ?? "N/A"} / Bed ${admission.bedNumber ?? "N/A"}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  if (_selectedAdmissionId != null) ...[
                    SizedBox(height: NeuroSpacing.lg),
                    Text(localizations.t('dischargeDetails'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            )),
                    SizedBox(height: NeuroSpacing.sm),
                    AppInput(
                        controller: _physicianController,
                        label: localizations.t('dischargingPhysician')),
                    SizedBox(height: NeuroSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _disposition,
                      decoration: InputDecoration(
                        labelText: localizations.t('dischargeDisposition'),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(NeuroRadius.md)),
                      ),
                      items: [
                        'home',
                        'rehabilitation',
                        'nursing_home',
                        'transfer',
                        'against_medical_advice',
                        'deceased'
                      ]
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text(d.replaceAll('_', ' '))))
                          .toList(),
                      onChanged: (v) => setState(() => _disposition = v!),
                    ),
                    SizedBox(height: NeuroSpacing.sm),
                    TextField(
                      controller: _summaryController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: localizations.t('dischargeSummary'),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(NeuroRadius.md)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    SizedBox(height: NeuroSpacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: AppButton(
                        label: _isSubmitting
                            ? localizations.t('discharging')
                            : localizations.t('dischargePatient'),
                        icon: _isSubmitting ? null : Icons.exit_to_app,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedAdmissionId == null)
      return;
    setState(() => _isSubmitting = true);

    final useCase = ref.read(dischargePatientProvider);
    final result = await useCase(
      _selectedAdmissionId!,
      dischargeSummary: _summaryController.text.trim(),
      dischargeDisposition: _disposition,
      dischargingPhysician: _physicianController.text.trim().isEmpty
          ? null
          : _physicianController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(failure.message),
              backgroundColor: NeuroColors.critical),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient discharged successfully')),
        );
        context.pop();
      },
    );
  }
}
