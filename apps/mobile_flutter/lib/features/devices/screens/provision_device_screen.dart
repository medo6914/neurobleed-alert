import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../providers/device_repository_providers.dart';

final provisionFormProvider = StateNotifierProvider<ProvisionFormNotifier, ProvisionFormState>((ref) {
  return ProvisionFormNotifier(ref.read(deviceRepositoryProvider));
});

class ProvisionFormState {
  final bool isLoading;
  final String? error;
  final ProvisioningClaimResponse? response;

  const ProvisionFormState({
    this.isLoading = false,
    this.error,
    this.response,
  });

  ProvisionFormState copyWith({
    bool? isLoading,
    String? error,
    ProvisioningClaimResponse? response,
    bool clearError = false,
  }) {
    return ProvisionFormState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      response: response ?? this.response,
    );
  }
}

class ProvisionFormNotifier extends StateNotifier<ProvisionFormState> {
  final DeviceRepository _repository;

  ProvisionFormNotifier(this._repository) : super(const ProvisionFormState());

  Future<void> submitClaim({
    required String provisioningKey,
    required String serialNumber,
    String? deviceName,
  }) async {
    if (provisioningKey.length < 8 || serialNumber.length < 3) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final request = ProvisioningClaimRequest(
      provisioningKey: provisioningKey.trim(),
      serialNumber: serialNumber.trim(),
      deviceName: deviceName?.trim(),
    );

    final result = await _repository.claimDevice(request);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (response) {
        state = state.copyWith(isLoading: false, response: response);
      },
    );
  }

  void reset() {
    state = const ProvisionFormState();
  }
}

class ProvisionDeviceScreen extends ConsumerStatefulWidget {
  const ProvisionDeviceScreen({super.key});

  @override
  ConsumerState<ProvisionDeviceScreen> createState() => _ProvisionDeviceScreenState();
}

class _ProvisionDeviceScreenState extends ConsumerState<ProvisionDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _serialController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _serialController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provisionFormProvider);
    final theme = Theme.of(context);

    if (state.response != null) {
      return _buildSuccessScreen(context, state.response!, theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provision Device'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(NeuroSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.vpn_key, size: 20, color: theme.colorScheme.primary),
                          SizedBox(width: NeuroSpacing.sm),
                          Text(
                            'Provisioning Key',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: NeuroSpacing.md),
                      Text(
                        'Enter the provisioning key provided with your NeuroBleed device.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: NeuroSpacing.md),
                      AppInput(
                        label: 'Provisioning Key *',
                        hint: 'e.g. a1b2c3d4e5f6g7h8',
                        controller: _keyController,
                        validator: (v) {
                          if (v == null || v.length < 8) return 'Key must be at least 8 characters';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: NeuroSpacing.lg),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.devices, size: 20, color: theme.colorScheme.primary),
                          SizedBox(width: NeuroSpacing.sm),
                          Text(
                            'Device Information',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: NeuroSpacing.md),
                      AppInput(
                        label: 'Serial Number *',
                        hint: 'Enter device serial number',
                        controller: _serialController,
                        validator: (v) {
                          if (v == null || v.length < 3) return 'Serial number must be at least 3 characters';
                          return null;
                        },
                      ),
                      SizedBox(height: NeuroSpacing.sm),
                      AppInput(
                        label: 'Device Name',
                        hint: 'Optional friendly name',
                        controller: _nameController,
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
                    title: 'Provisioning Error',
                    description: state.error,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: AppButton(
                  label: state.isLoading ? 'Claiming Device...' : 'Claim Device',
                  icon: state.isLoading ? null : Icons.check_circle,
                  isLoading: state.isLoading,
                  onPressed: state.isLoading ? null : _submitClaim,
                ),
              ),
              SizedBox(height: NeuroSpacing.lg),
              Center(
                child: TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to Pairing'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitClaim() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(provisionFormProvider.notifier).submitClaim(
      provisioningKey: _keyController.text.trim(),
      serialNumber: _serialController.text.trim(),
      deviceName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
    );
  }

  Widget _buildSuccessScreen(BuildContext context, ProvisioningClaimResponse response, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Provisioned'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(NeuroSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.check_circle, size: 60, color: Colors.green),
              ),
              SizedBox(height: NeuroSpacing.xl),
              Text(
                'Device Claimed Successfully',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: NeuroSpacing.md),
              Text(
                response.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (response.device != null) ...[
                SizedBox(height: NeuroSpacing.lg),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    child: Column(
                      children: [
                        _infoRow(theme, 'Serial Number', response.device!['serial_number'] as String? ?? '-'),
                        SizedBox(height: NeuroSpacing.sm),
                        _infoRow(theme, 'Device Name', response.device!['device_name'] as String? ?? '-'),
                        SizedBox(height: NeuroSpacing.sm),
                        _infoRow(theme, 'Device ID', response.device!['id'] as String? ?? '-'),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: NeuroSpacing.xxl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: AppButton(
                  label: 'View Device',
                  icon: Icons.visibility,
                  onPressed: () {
                    if (response.deviceId != null) {
                      context.go('/devices/${response.deviceId}');
                    } else {
                      context.pop();
                    }
                  },
                ),
              ),
              SizedBox(height: NeuroSpacing.md),
              TextButton(
                onPressed: () {
                  ref.read(provisionFormProvider.notifier).reset();
                  _keyController.clear();
                  _serialController.clear();
                  _nameController.clear();
                },
                child: const Text('Provision Another Device'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          )),
        ),
      ],
    );
  }
}
