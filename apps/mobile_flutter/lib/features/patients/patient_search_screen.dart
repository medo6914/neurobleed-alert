import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';

final patientListProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/patients/');
  return response.data as List;
});

class PatientSearchScreen extends ConsumerStatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  ConsumerState<PatientSearchScreen> createState() =>
      _PatientSearchScreenState();
}

class _PatientSearchScreenState extends ConsumerState<PatientSearchScreen> {
  final _searchController = TextEditingController();
  String _riskFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeRisk(String? level) {
    final l = level?.toLowerCase() ?? '';
    switch (l) {
      case 'critical':
        return 'critical';
      case 'high':
        return 'high';
      case 'medium':
        return 'medium';
      case 'low':
      case 'stable':
        return 'low';
      default:
        return 'low';
    }
  }

  List<dynamic> _applyFilters(List<dynamic> patients) {
    final query = _searchController.text.trim().toLowerCase();
    var result = patients.where((p) {
      if (query.isEmpty) return true;
      final name = (p['full_name'] as String? ?? '').toLowerCase();
      final mrn = (p['mrn'] as String? ?? '').toLowerCase();
      return name.contains(query) || mrn.contains(query);
    }).toList();

    if (_riskFilter != 'all') {
      result = result
          .where((p) => _normalizeRisk(p['risk_level'] as String?) == _riskFilter)
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientListProvider);

    return Scaffold(
      body: Column(
        children: [
          // Search bar (reference: bg #051229)
          Container(
            padding: EdgeInsets.fromLTRB(
              NeuroSpacing.lg,
              MediaQuery.of(context).padding.top + NeuroSpacing.md,
              NeuroSpacing.lg,
              NeuroSpacing.md,
            ),
            color: const Color(0xFF051229),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: NeuroTypography.bodyLarge?.copyWith(
                color: NeuroColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو رقم الملف الطبي...',
                hintStyle: NeuroTypography.bodyMedium?.copyWith(
                  color: NeuroColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: NeuroColors.textBody,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: NeuroColors.textBody),
                        onPressed: () => setState(_searchController.clear),
                      )
                    : null,
                filled: true,
                fillColor: NeuroColors.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NeuroRadius.input),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NeuroRadius.input),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NeuroRadius.input),
                  borderSide: const BorderSide(
                    color: NeuroColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: NeuroSpacing.lg,
                  vertical: NeuroSpacing.md,
                ),
              ),
            ),
          ),
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NeuroSpacing.lg,
              vertical: NeuroSpacing.sm,
            ),
            color: NeuroColors.bgPrimary,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'الكل',
                    selected: _riskFilter == 'all',
                    color: NeuroColors.textBody,
                    onTap: () => setState(() => _riskFilter = 'all'),
                  ),
                  _FilterChip(
                    label: 'حرج',
                    selected: _riskFilter == 'critical',
                    color: NeuroColors.criticalBright,
                    onTap: () => setState(() => _riskFilter = 'critical'),
                  ),
                  _FilterChip(
                    label: 'مرتفع',
                    selected: _riskFilter == 'high',
                    color: NeuroColors.high,
                    onTap: () => setState(() => _riskFilter = 'high'),
                  ),
                  _FilterChip(
                    label: 'متوسط',
                    selected: _riskFilter == 'medium',
                    color: NeuroColors.medium,
                    onTap: () => setState(() => _riskFilter = 'medium'),
                  ),
                  _FilterChip(
                    label: 'مستقر',
                    selected: _riskFilter == 'low',
                    color: NeuroColors.low,
                    onTap: () => setState(() => _riskFilter = 'low'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(patientListProvider),
              child: patientsAsync.when(
                loading: () => const Center(child: AppLoading()),
                error: (err, _) => AppErrorState(
                  title: 'تعذر تحميل المرضى',
                  message: '$err',
                  onRetry: () => ref.invalidate(patientListProvider),
                ),
                data: (patients) {
                  final filtered = _applyFilters(patients);
                  if (filtered.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.person_search,
                      title: 'لا توجد نتائج',
                      message: 'لم يتم العثور على مرضى مطابقين',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(NeuroSpacing.lg),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final patient = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: NeuroSpacing.md),
                        child: _PatientListCard(
                          patient: patient,
                          onTap: () => context.push('/patients/${patient['id']}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: NeuroSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.lg,
            vertical: NeuroSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.2)
                : NeuroColors.bgCard,
            borderRadius: BorderRadius.circular(NeuroRadius.chip),
            border: Border.all(
              color: selected ? color : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: NeuroTypography.labelMedium?.copyWith(
              color: selected ? color : NeuroColors.textBody,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientListCard extends StatelessWidget {
  final dynamic patient;
  final VoidCallback onTap;

  const _PatientListCard({required this.patient, required this.onTap});

  Color get _riskColor {
    final level = (patient['risk_level'] as String?)?.toLowerCase();
    switch (level) {
      case 'critical':
        return NeuroColors.criticalBright;
      case 'high':
        return NeuroColors.high;
      case 'medium':
        return NeuroColors.medium;
      default:
        return NeuroColors.low;
    }
  }

  String get _riskLabel {
    final level = (patient['risk_level'] as String?)?.toLowerCase();
    switch (level) {
      case 'critical':
        return 'حرج';
      case 'high':
        return 'مرتفع';
      case 'medium':
        return 'متوسط';
      default:
        return 'مستقر';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = patient['full_name'] ?? 'مريض';
    final mrn = patient['mrn'] ?? '—';
    final bed = patient['bed_number'];
    final isActive = patient['is_active'] != false;
    final riskScore = ((patient['risk_score'] as num?)?.toDouble() ?? 0)
        .clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        child: Container(
          padding: const EdgeInsets.all(NeuroSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [NeuroColors.cardGradTop, NeuroColors.cardGradBottom],
            ),
            borderRadius: BorderRadius.circular(NeuroRadius.card),
            boxShadow: const [NeuroShadows.card],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar with status dot
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            NeuroColors.primary.withValues(alpha: 0.3),
                        child: Text(
                          name.toString().isNotEmpty
                              ? name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: NeuroColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xFF1ACB58)
                                : NeuroColors.critical,
                            border: Border.all(
                              color: NeuroColors.bgCard,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: NeuroSpacing.md),
                  // Name + MRN + bed
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: NeuroTypography.h3?.copyWith(
                            color: NeuroColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MRN: $mrn${bed != null ? '  •  سرير: $bed' : ''}',
                          style: NeuroTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  // Risk badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: NeuroSpacing.sm,
                      vertical: NeuroSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _riskColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(NeuroRadius.badge),
                      border: Border.all(color: _riskColor),
                    ),
                    child: Text(
                      _riskLabel,
                      style: NeuroTypography.badge.copyWith(color: _riskColor),
                    ),
                  ),
                  const SizedBox(width: NeuroSpacing.xs),
                  const Icon(
                    Icons.chevron_right,
                    color: NeuroColors.navInactive,
                  ),
                ],
              ),
              const SizedBox(height: NeuroSpacing.md),
              // Risk score bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: riskScore,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(_riskColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
