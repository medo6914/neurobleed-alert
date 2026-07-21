import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'providers/patients_providers.dart';

class PatientSearchScreen extends ConsumerStatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  ConsumerState<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends ConsumerState<PatientSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(patientSearchProvider.notifier).search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(patientSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Patients'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(NeuroSpacing.md),
            child: AppInput(
              label: '',
              hint: 'Search by name or MRN...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(patientSearchProvider.notifier).clear();
                      },
                    )
                  : null,
            ),
          ),
          Expanded(
            child: _buildBody(context, searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PatientSearchState state) {
    if (state.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            SizedBox(height: NeuroSpacing.md),
            Text(
              'Search Patients',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: NeuroSpacing.xs),
            Text(
              'Search by name or MRN...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (state.isSearching) {
      return const AppLoading(message: 'Searching...');
    }

    if (state.error != null) {
      return AppErrorState(
        title: 'Search Error',
        message: state.error!,
        onRetry: () => ref.read(patientSearchProvider.notifier).search(state.query),
      );
    }

    if (state.results.isEmpty) {
      return AppEmptyState(
        icon: Icons.person_search,
        title: 'No Results',
        message: 'No patients found matching your search.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(patientSearchProvider.notifier).search(state.query),
      child: ListView.builder(
        padding: EdgeInsets.all(NeuroSpacing.md),
        itemCount: state.results.length,
        itemBuilder: (context, index) {
          final patient = state.results[index];
          return _PatientSearchCard(
            patient: patient,
            onTap: () => context.push('/patients/${patient.id}'),
          );
        },
      ),
    );
  }
}

class _PatientSearchCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const _PatientSearchCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${patient.firstName[0]}${patient.lastName[0]}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            SizedBox(width: NeuroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${patient.firstName} ${patient.lastName}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: NeuroSpacing.xxs),
                  Text(
                    'MRN: ${patient.mrn}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: NeuroSpacing.xxs),
                  Row(
                    children: [
                      _InfoChip(label: patient.gender.name),
                      SizedBox(width: NeuroSpacing.xs),
                      _InfoChip(label: patient.bloodType.name),
                      SizedBox(width: NeuroSpacing.xs),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: patient.status == PatientStatus.active
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(NeuroRadius.sm),
                        ),
                        child: Text(
                          patient.status.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: patient.status == PatientStatus.active ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(NeuroRadius.sm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
