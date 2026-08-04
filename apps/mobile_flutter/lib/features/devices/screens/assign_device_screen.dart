import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import '../providers/device_providers.dart';
import '../widgets/device_status_indicator.dart';
import '../widgets/device_battery_indicator.dart';

class AssignDeviceScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const AssignDeviceScreen({super.key, required this.deviceId});

  @override
  ConsumerState<AssignDeviceScreen> createState() => _AssignDeviceScreenState();
}

class _AssignDeviceScreenState extends ConsumerState<AssignDeviceScreen> {
  final _patientSearchController = TextEditingController();
  final _hospitalIdController = TextEditingController();
  final _departmentController = TextEditingController();

  List<Map<String, String>> _searchResults = [];
  String? _selectedPatientId;
  String? _selectedPatientName;
  bool _isSearching = false;

  @override
  void dispose() {
    _patientSearchController.dispose();
    _hospitalIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceAsync = ref.watch(deviceDetailProvider(widget.deviceId));
    final state = ref.watch(deviceAssignProvider);

    return deviceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Assign Device')),
        body: const Center(child: AppLoading()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Assign Device')),
        body: AppErrorState(title: 'Error', message: e.toString()),
      ),
      data: (device) => Scaffold(
        appBar: AppBar(
          title: const Text('Assign Device'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(NeuroSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Row(
                  children: [
                    Icon(
                      device.type == DeviceType.headband
                          ? Icons.headphones
                          : device.type == DeviceType.wearable
                              ? Icons.watch
                              : Icons.monitor,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: NeuroSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name ?? device.serialNumber,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'SN: ${device.serialNumber}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        DeviceStatusIndicator(status: device.status),
                        SizedBox(height: 4),
                        DeviceBatteryIndicator(batteryLevel: device.batteryLevel),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: NeuroSpacing.xl),

              _SectionTitle(title: 'Select Patient'),
              SizedBox(height: NeuroSpacing.sm),
              AppCard(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppInput(
                        label: 'Search Patient',
                        hint: 'Search by MRN or name...',
                        controller: _patientSearchController,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _selectedPatientId != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _selectedPatientId = null;
                                    _selectedPatientName = null;
                                    _patientSearchController.clear();
                                    _searchResults = [];
                                  });
                                },
                              )
                            : null,
                      ),
                      if (_selectedPatientId != null) ...[
                        SizedBox(height: NeuroSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: NeuroSpacing.sm, vertical: NeuroSpacing.xs),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(NeuroRadius.sm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 16, color: NeuroColors.success),
                              SizedBox(width: 4),
                              Text(
                                'Selected: $_selectedPatientName',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: NeuroColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_searchResults.isNotEmpty) ...[
                        SizedBox(height: NeuroSpacing.sm),
                        Divider(height: 1),
                        ..._searchResults.map((r) => ListTile(
                          dense: true,
                          title: Text(r['name'] ?? ''),
                          subtitle: Text('MRN: ${r['mrn'] ?? ''}'),
                          selected: _selectedPatientId == r['id'],
                          trailing: _selectedPatientId == r['id']
                              ? Icon(Icons.check_circle, color: NeuroColors.success, size: 20)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedPatientId = r['id'];
                              _selectedPatientName = r['name'];
                              _patientSearchController.text = r['name'] ?? '';
                              _searchResults = [];
                            });
                          },
                        )),
                      ],
                      if (_isSearching)
                        Padding(
                          padding: EdgeInsets.all(NeuroSpacing.md),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: NeuroSpacing.lg),

              _SectionTitle(title: 'Assignment Details'),
              SizedBox(height: NeuroSpacing.sm),
              AppCard(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppInput(
                        label: 'Hospital ID',
                        hint: 'Optional',
                        controller: _hospitalIdController,
                      ),
                      SizedBox(height: NeuroSpacing.sm),
                      AppInput(
                        label: 'Department',
                        hint: 'Optional',
                        controller: _departmentController,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: NeuroSpacing.xxl),

              if (state.error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: NeuroSpacing.md),
                  child: AlertBanner(
                    severity: AlertSeverity.critical,
                    title: 'Assignment Error',
                    description: state.error,
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: AppButton(
                  label: state.isSubmitting ? 'Assigning...' : 'Assign Device',
                  icon: state.isSubmitting ? null : Icons.link,
                  isLoading: state.isSubmitting,
                  onPressed: state.isSubmitting ? null : _submitAssign,
                ),
              ),
              SizedBox(height: NeuroSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAssign() async {
    final notifier = ref.read(deviceAssignProvider.notifier);
    final result = await notifier.assignDevice(
      deviceId: widget.deviceId,
      patientId: _selectedPatientId,
      hospitalId: _hospitalIdController.text.trim().isEmpty ? null : _hospitalIdController.text.trim(),
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: NeuroColors.critical),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device assigned successfully')),
        );
        ref.invalidate(deviceDetailProvider(widget.deviceId));
        context.pop();
      },
    );
  }
}

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
