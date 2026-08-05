import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'providers/patients_providers.dart';

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));

    return patientAsync.when(
      loading: () => const Scaffold(
        body: Center(child: AppLoading()),
      ),
      error: (error, stack) => Scaffold(
        body: AppErrorState(
          title: 'Error Loading Patient',
          message: error.toString(),
          onRetry: () => ref.invalidate(patientDetailProvider(patientId)),
        ),
      ),
      data: (patient) => _PatientDetailContent(patient: patient),
    );
  }
}

class _PatientDetailContent extends ConsumerStatefulWidget {
  final Patient patient;
  const _PatientDetailContent({required this.patient});

  @override
  ConsumerState<_PatientDetailContent> createState() =>
      _PatientDetailContentState();
}

class _PatientDetailContentState extends ConsumerState<_PatientDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      backgroundColor: NeuroColors.bgPrimary,
      body: Column(
        children: [
          // Patient header (reference IMG-0205: bg #011132)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [NeuroColors.primaryGlass, NeuroColors.primaryGlass],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: NeuroColors.textBody,
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Patient Details',
                          style: NeuroTypography.h3?.copyWith(
                            color: NeuroColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: NeuroColors.textBody,
                        ),
                        onPressed: () =>
                            context.push('/patients/${patient.id}/edit'),
                      ),
                    ],
                  ),
                  // Patient info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      NeuroSpacing.lg,
                      NeuroSpacing.xs,
                      NeuroSpacing.lg,
                      NeuroSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor:
                              NeuroColors.primary.withValues(alpha: 0.3),
                          child: Text(
                            '${patient.firstName[0]}${patient.lastName[0]}',
                            style: TextStyle(
                              color: NeuroColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: NeuroSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${patient.firstName} ${patient.lastName}',
                                style: NeuroTypography.h3?.copyWith(
                                  color: NeuroColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'MRN: ${patient.mrn}  •  ${patient.gender.name}',
                                style: NeuroTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: patient.status),
                      ],
                    ),
                  ),
                  // Tab bar (reference: bg #011030)
                  Container(
                    color: NeuroColors.primaryGlass,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: NeuroColors.primaryLight,
                      unselectedLabelColor: NeuroColors.textSecondary,
                      indicatorColor: NeuroColors.primaryLight,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: NeuroTypography.labelMedium,
                      tabs: const [
                        Tab(text: 'Profile'),
                        Tab(text: 'Medical'),
                        Tab(text: 'History'),
                        Tab(text: 'Documents'),
                        Tab(text: 'Vitals'),
                        Tab(text: 'Alerts'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ProfileTab(patient: patient),
                _MedicalTab(patient: patient),
                _HistoryTab(patientId: patient.id),
                _DocumentsTab(patientId: patient.id),
                _VitalsTab(patientId: patient.id),
                _AlertsTab(patientId: patient.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Profile Tab =====================

class _ProfileTab extends StatelessWidget {
  final Patient patient;
  const _ProfileTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(NeuroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${patient.firstName[0]}${patient.lastName[0]}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                SizedBox(width: NeuroSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${patient.firstName} ${patient.lastName}',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: NeuroSpacing.xxs),
                      Text(
                        'MRN: ${patient.mrn}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: NeuroSpacing.xs),
                      _StatusBadge(status: patient.status),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showPatientMenu(context),
                ),
              ],
            ),
          ),
          SizedBox(height: NeuroSpacing.md),
          _SectionTitle(title: 'Personal Information'),
          SizedBox(height: NeuroSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _InfoRow(label: 'Date of Birth', value: patient.dateOfBirth),
                _InfoRow(label: 'Gender', value: patient.gender.name),
                _InfoRow(
                    label: 'Nationality', value: patient.nationality ?? '-'),
                _InfoRow(
                    label: 'National ID', value: patient.nationalId ?? '-'),
                _InfoRow(
                    label: 'Marital Status', value: patient.maritalStatus.name),
                _InfoRow(label: 'Blood Type', value: patient.bloodType.name),
                _InfoRow(
                    label: 'Weight',
                    value:
                        patient.weight != null ? '${patient.weight} kg' : '-'),
                _InfoRow(
                    label: 'Height',
                    value:
                        patient.height != null ? '${patient.height} cm' : '-'),
              ],
            ),
          ),
          SizedBox(height: NeuroSpacing.md),
          _SectionTitle(title: 'Contact Information'),
          SizedBox(height: NeuroSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                    label: 'Phone',
                    value: patient.phone ?? '-',
                    icon: Icons.phone),
                _InfoRow(
                    label: 'Email',
                    value: patient.email ?? '-',
                    icon: Icons.email),
                _InfoRow(
                    label: 'Address',
                    value: patient.address ?? '-',
                    icon: Icons.location_on),
              ],
            ),
          ),
          SizedBox(height: NeuroSpacing.md),
          _SectionTitle(title: 'Insurance'),
          SizedBox(height: NeuroSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                    label: 'Provider', value: patient.insuranceProvider ?? '-'),
                _InfoRow(
                    label: 'Insurance ID', value: patient.insuranceId ?? '-'),
              ],
            ),
          ),
          SizedBox(height: NeuroSpacing.md),
          _SectionTitle(title: 'Assignment'),
          SizedBox(height: NeuroSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                    label: 'Hospital',
                    value: patient.hospitalName ?? patient.hospitalId ?? '-'),
                _InfoRow(
                    label: 'Department',
                    value:
                        patient.departmentName ?? patient.departmentId ?? '-'),
                _InfoRow(label: 'Ward', value: patient.ward ?? '-'),
                _InfoRow(label: 'Bed', value: patient.bedNumber ?? '-'),
              ],
            ),
          ),
          SizedBox(height: NeuroSpacing.md),
          _SectionTitle(title: 'Actions'),
          SizedBox(height: NeuroSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Admit',
                  icon: Icons.local_hospital,
                  variant: ButtonVariant.primary,
                  onPressed: () =>
                      context.push('/patients/${patient.id}/admit'),
                ),
              ),
              SizedBox(width: NeuroSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Add Note',
                  icon: Icons.note_add,
                  variant: ButtonVariant.secondary,
                  onPressed: () =>
                      context.push('/patients/${patient.id}/notes/add'),
                ),
              ),
            ],
          ),
          SizedBox(height: NeuroSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Add Document',
                  icon: Icons.upload_file,
                  variant: ButtonVariant.secondary,
                  onPressed: () =>
                      context.push('/patients/${patient.id}/documents/add'),
                ),
              ),
              SizedBox(width: NeuroSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Emergency Contact',
                  icon: Icons.emergency,
                  variant: ButtonVariant.danger,
                  onPressed: () => context
                      .push('/patients/${patient.id}/emergency-contacts'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPatientMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.transfer_within_a_station),
              title: const Text('Transfer Patient'),
              onTap: () {
                Navigator.pop(context);
                context.push('/patients/${patient.id}/transfer');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View History'),
              onTap: () {
                Navigator.pop(context);
                context.push('/patients/${patient.id}/history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Audit Log'),
              onTap: () {
                Navigator.pop(context);
                context.push('/patients/${patient.id}/audit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: NeuroColors.critical),
              title: const Text('Emergency SOS',
                  style: TextStyle(color: NeuroColors.critical)),
              onTap: () {
                Navigator.pop(context);
                context.push('/patients/${patient.id}/sos');
              },
            ),
            ListTile(
              leading: Icon(Icons.archive, color: NeuroColors.high),
              title: Text('Archive Patient',
                  style: TextStyle(color: NeuroColors.high)),
              onTap: () {
                Navigator.pop(context);
                _confirmArchive(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context) {
    AppDialog.confirm(
      context,
      title: 'Archive Patient',
      message: 'Are you sure you want to archive this patient?',
      confirmLabel: 'Archive',
      isDangerous: true,
    );
  }
}

// ===================== Medical Tab =====================

class _MedicalTab extends StatelessWidget {
  final Patient patient;
  const _MedicalTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(NeuroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (patient.primaryDiagnosis != null) ...[
            _SectionTitle(title: 'Primary Diagnosis'),
            SizedBox(height: NeuroSpacing.sm),
            AppCard(
              child: Padding(
                padding: EdgeInsets.all(NeuroSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.medical_services, color: NeuroColors.critical),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: Text(patient.primaryDiagnosis!)),
                  ],
                ),
              ),
            ),
            SizedBox(height: NeuroSpacing.md),
          ],
          _SectionTitle(title: 'Diagnoses'),
          SizedBox(height: NeuroSpacing.sm),
          AppCard(
            child: patient.diagnoses.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    child: Text('No data'),
                  )
                : Column(
                    children: patient.diagnoses
                        .map((d) => ListTile(
                              leading: Icon(Icons.check_circle_outline,
                                  color: NeuroColors.stable),
                              title: Text(d),
                            ))
                        .toList(),
                  ),
          ),
          SizedBox(height: NeuroSpacing.md),
          _SectionTitle(title: 'Allergies'),
          SizedBox(height: NeuroSpacing.sm),
          AppCard(
            child: Wrap(
              spacing: NeuroSpacing.xs,
              runSpacing: NeuroSpacing.xs,
              children: patient.allergies.isEmpty
                  ? [
                      Padding(
                        padding: EdgeInsets.all(NeuroSpacing.md),
                        child: Text('No known allergies'),
                      )
                    ]
                  : patient.allergies
                      .map((a) => Chip(
                            label: Text(a),
                            backgroundColor:
                                NeuroColors.high.withValues(alpha: 0.1),
                            avatar: const Icon(Icons.warning_amber,
                                size: 16, color: NeuroColors.high),
                          ))
                      .toList(),
            ),
          ),
          SizedBox(height: NeuroSpacing.md),
          _SectionTitle(title: 'Medications'),
          SizedBox(height: NeuroSpacing.sm),
          AppCard(
            child: patient.medications.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    child: Text('No data'),
                  )
                : Column(
                    children: patient.medications
                        .map((m) => ListTile(
                              leading: Icon(Icons.medication,
                                  color: NeuroColors.primary),
                              title: Text(m),
                            ))
                        .toList(),
                  ),
          ),
          SizedBox(height: NeuroSpacing.md),
          _SectionTitle(title: 'Comorbidities'),
          SizedBox(height: NeuroSpacing.sm),
          AppCard(
            child: Wrap(
              spacing: NeuroSpacing.xs,
              runSpacing: NeuroSpacing.xs,
              children: patient.comorbidities.isEmpty
                  ? [
                      Padding(
                        padding: EdgeInsets.all(NeuroSpacing.md),
                        child: Text('No data'),
                      )
                    ]
                  : patient.comorbidities
                      .map((c) => Chip(
                            label: Text(c),
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== History Tab =====================

class _HistoryTab extends ConsumerWidget {
  final String patientId;
  const _HistoryTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(patientHistoryProvider(patientId));

    return historyAsync.when(
      loading: () => const Center(child: AppLoading()),
      error: (e, _) => AppErrorState(
        title: 'Error Loading History',
        message: e.toString(),
      ),
      data: (data) {
        final timeline = <Widget>[];

        for (final admission in data.admissions) {
          timeline.add(_TimelineTile(
            icon: Icons.local_hospital,
            iconColor: NeuroColors.primary,
            title: 'Admission - ${admission.admissionType ?? "N/A"}',
            subtitle:
                admission.admissionDate.toLocal().toString().substring(0, 16),
            trailing: admission.status.name,
          ));
        }

        for (final note in data.notes) {
          timeline.add(_TimelineTile(
            icon: Icons.note,
            iconColor: NeuroColors.info,
            title: note.title,
            subtitle: note.createdAt.toLocal().toString().substring(0, 16),
            trailing: note.type.name,
          ));
        }

        for (final alert in data.alerts) {
          timeline.add(_TimelineTile(
            icon: Icons.warning,
            iconColor: alert.level == 'critical'
                ? NeuroColors.critical
                : NeuroColors.warning,
            title: alert.title,
            subtitle: alert.createdAt.toLocal().toString().substring(0, 16),
            trailing: alert.status.name,
          ));
        }

        if (timeline.isEmpty) {
          return AppEmptyState(
            icon: Icons.history,
            title: 'No History',
            message: 'No historical records found for this patient.',
          );
        }

        return ListView(
          padding: EdgeInsets.all(NeuroSpacing.md),
          children: timeline,
        );
      },
    );
  }
}

// ===================== Documents Tab =====================

class _DocumentsTab extends ConsumerWidget {
  final String patientId;
  const _DocumentsTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(patientDocumentsProvider(patientId));

    return documentsAsync.when(
      loading: () => const Center(child: AppLoading()),
      error: (e, _) => AppErrorState(
        title: 'Error Loading Documents',
        message: e.toString(),
      ),
      data: (documents) {
        if (documents.isEmpty) {
          return AppEmptyState(
            icon: Icons.description,
            title: 'No Documents',
            message: 'No medical documents uploaded yet.',
            actionLabel: 'Upload Document',
            onAction: () => context.push('/patients/$patientId/documents/add'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(NeuroSpacing.md),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            return Padding(
              padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
              child: AppCard(
                onTap: () {},
                child: ListTile(
                  leading:
                      Icon(_documentIcon(doc.type), color: NeuroColors.primary),
                  title: Text(doc.title),
                  subtitle:
                      Text('${doc.fileName}  ${_formatSize(doc.fileSize)}'),
                  trailing: Chip(
                    label: Text(doc.status.name,
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor: doc.status == DocumentStatus.verified
                        ? NeuroColors.success.withValues(alpha: 0.1)
                        : NeuroColors.high.withValues(alpha: 0.1),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _documentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.labReport:
        return Icons.science;
      case DocumentType.imaging:
        return Icons.image;
      case DocumentType.prescription:
        return Icons.medication;
      case DocumentType.consentForm:
        return Icons.description;
      case DocumentType.medicalReport:
        return Icons.article;
      case DocumentType.dischargeSummary:
        return Icons.summarize;
      case DocumentType.referral:
        return Icons.send;
      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ===================== Vitals Tab =====================

class _VitalsTab extends ConsumerWidget {
  final String patientId;
  const _VitalsTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsAsync = ref.watch(patientVitalsProvider(patientId));

    return vitalsAsync.when(
      loading: () => const Center(child: AppLoading()),
      error: (e, _) => AppErrorState(
        title: 'Error Loading Vitals',
        message: e.toString(),
      ),
      data: (vitals) {
        if (vitals.isEmpty) {
          return AppEmptyState(
            icon: Icons.monitor_heart,
            title: 'No Vitals',
            message: 'No vital signs recorded yet.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(NeuroSpacing.md),
          itemCount: vitals.length,
          itemBuilder: (context, index) {
            final v = vitals[index];
            return Padding(
              padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
              child: AppCard(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.timestamp.toLocal().toString().substring(0, 16),
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                      SizedBox(height: NeuroSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _VitalChip(
                              label: 'HR',
                              value: v.heartRate?.toStringAsFixed(0) ?? '-',
                              unit: 'bpm'),
                          _VitalChip(
                              label: 'SpO2',
                              value:
                                  v.oxygenSaturation?.toStringAsFixed(0) ?? '-',
                              unit: '%'),
                          _VitalChip(
                              label: 'BP',
                              value: v.systolicBP != null
                                  ? '${v.systolicBP!.toInt()}/${v.diastolicBP!.toInt()}'
                                  : '-',
                              unit: 'mmHg'),
                          _VitalChip(
                              label: 'Temp',
                              value: v.temperature?.toStringAsFixed(1) ?? '-',
                              unit: '\u00b0C'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ===================== Alerts Tab =====================

class _AlertsTab extends ConsumerWidget {
  final String patientId;
  const _AlertsTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(patientAlertsProvider(patientId));

    return alertsAsync.when(
      loading: () => const Center(child: AppLoading()),
      error: (e, _) => AppErrorState(
        title: 'Error Loading Alerts',
        message: e.toString(),
      ),
      data: (alerts) {
        if (alerts.isEmpty) {
          return AppEmptyState(
            icon: Icons.check_circle,
            title: 'No Alerts',
            message: 'No alerts recorded.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(NeuroSpacing.md),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return Padding(
              padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
              child: AlertBanner(
                severity: _mapAlertLevel(alert.level),
                title: alert.title,
                description: alert.description,
                onTap: alert.status == AlertStatus.active
                    ? () => _acknowledgeAlert(context)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  void _acknowledgeAlert(BuildContext context) {
    // Acknowledge action
  }

  AlertSeverity _mapAlertLevel(String level) {
    switch (level) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }
}

// ===================== Reusable Widgets =====================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _InfoRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: NeuroSpacing.xs),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(width: NeuroSpacing.xs),
          ],
          SizedBox(
            width: 120,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PatientStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == PatientStatus.active;
    final color = isActive ? NeuroColors.low : NeuroColors.high;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NeuroSpacing.sm,
        vertical: NeuroSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(NeuroRadius.badge),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: NeuroTypography.badge.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailing;

  const _TimelineTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(NeuroSpacing.xs),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: AppCard(
              child: Padding(
                padding: EdgeInsets.all(NeuroSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: NeuroSpacing.sm),
          Chip(
            label: Text(trailing, style: const TextStyle(fontSize: 10)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _VitalChip(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(unit,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
      ],
    );
  }
}
