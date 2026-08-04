import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';
import '../providers/device_providers.dart';

class RegisterDeviceScreen extends ConsumerStatefulWidget {
  const RegisterDeviceScreen({super.key});

  @override
  ConsumerState<RegisterDeviceScreen> createState() => _RegisterDeviceScreenState();
}

class _RegisterDeviceScreenState extends ConsumerState<RegisterDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialNumberController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _macAddressController = TextEditingController();
  final _firmwareVersionController = TextEditingController();
  final _hardwareVersionController = TextEditingController();
  final _hospitalIdController = TextEditingController();
  final _departmentController = TextEditingController();

  DeviceType? _selectedDeviceType;

  @override
  void dispose() {
    _serialNumberController.dispose();
    _deviceNameController.dispose();
    _macAddressController.dispose();
    _firmwareVersionController.dispose();
    _hardwareVersionController.dispose();
    _hospitalIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Device'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(NeuroSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context: context,
                title: 'Device Information',
                icon: Icons.devices,
                children: [
                  AppInput(
                    label: 'Serial Number *',
                    hint: 'Enter serial number',
                    controller: _serialNumberController,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Serial number is required';
                      final result = DeviceValidator.validateSerialNumber(v);
                      return result.fold((f) => f.message, (_) => null);
                    },
                  ),
                  SizedBox(height: NeuroSpacing.sm),
                  AppInput(
                    label: 'Device Name',
                    hint: 'Optional device name',
                    controller: _deviceNameController,
                  ),
                  SizedBox(height: NeuroSpacing.sm),
                  _buildDeviceTypeDropdown(),
                  SizedBox(height: NeuroSpacing.sm),
                  AppInput(
                    label: 'MAC Address',
                    hint: 'e.g. AA:BB:CC:DD:EE:FF',
                    controller: _macAddressController,
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final result = DeviceValidator.validateMacAddress(v);
                        return result.fold((f) => f.message, (_) => null);
                      }
                      return null;
                    },
                  ),
                ],
              ),
              SizedBox(height: NeuroSpacing.lg),

              _buildSection(
                context: context,
                title: 'Version Info',
                icon: Icons.info,
                children: [
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
                    label: 'Hardware Version',
                    hint: 'Optional',
                    controller: _hardwareVersionController,
                  ),
                ],
              ),
              SizedBox(height: NeuroSpacing.lg),

              _buildSection(
                context: context,
                title: 'Assignment',
                icon: Icons.assignment,
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
              SizedBox(height: NeuroSpacing.xxl),

              if (state.error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: NeuroSpacing.md),
                  child: AlertBanner(
                    severity: AlertSeverity.critical,
                    title: 'Registration Error',
                    description: state.error,
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: AppButton(
                  label: state.isSubmitting ? 'Registering...' : 'Register Device',
                  icon: state.isSubmitting ? null : Icons.add_circle,
                  isLoading: state.isSubmitting,
                  onPressed: state.isSubmitting ? null : _submitForm,
                ),
              ),
              SizedBox(height: NeuroSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: NeuroSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: NeuroSpacing.sm),
        AppCard(
          child: Padding(
            padding: EdgeInsets.all(NeuroSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceTypeDropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: DropdownButtonFormField<DeviceType>(
        initialValue: _selectedDeviceType,
        decoration: InputDecoration(
          labelText: 'Device Type *',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: NeuroSpacing.md,
            vertical: NeuroSpacing.sm,
          ),
        ),
        items: DeviceType.values.map((t) => DropdownMenuItem(
          value: t,
          child: Text(t.name),
        )).toList(),
        onChanged: (v) => setState(() => _selectedDeviceType = v),
        validator: (v) => v == null ? 'Device type is required' : null,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeviceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select device type')),
      );
      return;
    }

    final request = DeviceCreateRequest(
      serialNumber: _serialNumberController.text.trim(),
      deviceName: _deviceNameController.text.trim().isEmpty ? null : _deviceNameController.text.trim(),
      deviceType: _selectedDeviceType!.name,
      macAddress: _macAddressController.text.trim().isEmpty ? null : _macAddressController.text.trim(),
      firmwareVersion: _firmwareVersionController.text.trim().isEmpty ? null : _firmwareVersionController.text.trim(),
      hardwareVersion: _hardwareVersionController.text.trim().isEmpty ? null : _hardwareVersionController.text.trim(),
      hospitalId: _hospitalIdController.text.trim().isEmpty ? null : _hospitalIdController.text.trim(),
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
    );

    final notifier = ref.read(registerDeviceProvider.notifier);
    final result = await notifier.submitRegister(request);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: NeuroColors.critical),
        );
      },
      (device) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device registered successfully. SN: ${device.serialNumber}')),
        );
        context.pushReplacement('/devices/${device.id}');
      },
    );
  }
}
