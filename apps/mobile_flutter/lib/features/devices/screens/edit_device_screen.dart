import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../providers/device_providers.dart';

class EditDeviceScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const EditDeviceScreen({super.key, required this.deviceId});

  @override
  ConsumerState<EditDeviceScreen> createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends ConsumerState<EditDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();
  final _firmwareVersionController = TextEditingController();
  final _hospitalIdController = TextEditingController();
  final _departmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    final deviceAsync = ref.read(deviceDetailProvider(widget.deviceId));
    deviceAsync.whenData((device) {
      _deviceNameController.text = device.name ?? '';
      _firmwareVersionController.text = device.firmwareVersion;
      _hospitalIdController.text = device.hospitalId ?? '';
      _departmentController.text = '';
    });
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _firmwareVersionController.dispose();
    _hospitalIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceAsync = ref.watch(deviceDetailProvider(widget.deviceId));
    final state = ref.watch(updateDeviceProvider);

    return deviceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit Device')),
        body: const Center(child: AppLoading()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit Device')),
        body: AppErrorState(
          title: 'Error Loading Device',
          message: e.toString(),
          onRetry: () => ref.invalidate(deviceDetailProvider(widget.deviceId)),
        ),
      ),
      data: (device) => Scaffold(
        appBar: AppBar(
          title: Text('Edit ${device.name ?? device.serialNumber}'),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(NeuroSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serial Number: ${device.serialNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: NeuroSpacing.sm),
                        Text(
                          'Type: ${device.type.name}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: NeuroSpacing.lg),

                _SectionTitle(title: 'Editable Fields'),
                SizedBox(height: NeuroSpacing.sm),
                AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppInput(
                          label: 'Device Name',
                          hint: 'Enter device name',
                          controller: _deviceNameController,
                        ),
                        SizedBox(height: NeuroSpacing.sm),
                        AppInput(
                          label: 'Firmware Version',
                          hint: 'e.g. 1.0.0',
                          controller: _firmwareVersionController,
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              final result = DeviceValidator.validateFirmwareVersion(v);
                              return result.fold((f) => f.message, (_) => null);
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: NeuroSpacing.sm),
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
                      title: 'Update Error',
                      description: state.error,
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: AppButton(
                    label: state.isSubmitting ? 'Saving...' : 'Save Changes',
                    icon: state.isSubmitting ? null : Icons.save,
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting ? null : () => _submitForm(device.id),
                  ),
                ),
                SizedBox(height: NeuroSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm(String deviceId) async {
    if (!_formKey.currentState!.validate()) return;

    final request = DeviceUpdateRequest(
      deviceName: _deviceNameController.text.trim().isEmpty ? null : _deviceNameController.text.trim(),
      firmwareVersion: _firmwareVersionController.text.trim().isEmpty ? null : _firmwareVersionController.text.trim(),
      hospitalId: _hospitalIdController.text.trim().isEmpty ? null : _hospitalIdController.text.trim(),
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
    );

    final notifier = ref.read(updateDeviceProvider.notifier);
    final result = await notifier.submitUpdate(deviceId, request);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: NeuroColors.critical),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device updated successfully')),
        );
        ref.invalidate(deviceDetailProvider(deviceId));
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
