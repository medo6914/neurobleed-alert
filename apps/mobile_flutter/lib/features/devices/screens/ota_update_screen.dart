import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../providers/device_providers.dart';

class OtaUpdateScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const OtaUpdateScreen({super.key, required this.deviceId});

  @override
  ConsumerState<OtaUpdateScreen> createState() => _OtaUpdateScreenState();
}

class _OtaUpdateScreenState extends ConsumerState<OtaUpdateScreen> {
  final _firmwareController = TextEditingController();

  @override
  void dispose() {
    _firmwareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceAsync = ref.watch(deviceDetailProvider(widget.deviceId));
    final otaState = ref.watch(deviceOtaProvider);
    final theme = Theme.of(context);

    return deviceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('OTA Update')),
        body: const Center(child: AppLoading()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('OTA Update')),
        body: AppErrorState(
          title: 'Error',
          message: e.toString(),
          onRetry: () => ref.invalidate(deviceDetailProvider(widget.deviceId)),
        ),
      ),
      data: (device) => Scaffold(
        appBar: AppBar(
          title: const Text('OTA Update'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
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
                        device.name ?? device.serialNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: NeuroSpacing.xs),
                      Text(
                        'SN: ${device.serialNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: NeuroSpacing.lg),

              AppCard(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, size: 20, color: theme.colorScheme.primary),
                          SizedBox(width: NeuroSpacing.sm),
                          Text(
                            'Current Firmware',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: NeuroSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: NeuroSpacing.md, vertical: NeuroSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(NeuroRadius.md),
                        ),
                        child: Text(
                          device.firmwareVersion,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: NeuroSpacing.lg),

              AppCard(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.system_update, size: 20, color: theme.colorScheme.primary),
                          SizedBox(width: NeuroSpacing.sm),
                          Text(
                            'New Firmware Version',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: NeuroSpacing.md),
                      AppInput(
                        label: 'Firmware Version *',
                        hint: 'e.g. 2.0.0',
                        controller: _firmwareController,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Firmware version is required';
                          final result = DeviceValidator.validateFirmwareVersion(v);
                          return result.fold((f) => f.message, (_) => null);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: NeuroSpacing.lg),

              if (otaState.isUpdating) ...[
                AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: otaState.progress > 0 ? otaState.progress / 100 : null,
                            strokeWidth: 4,
                          ),
                        ),
                        SizedBox(height: NeuroSpacing.md),
                        Text(
                          otaState.progress > 0
                              ? 'Updating... ${otaState.progress.toStringAsFixed(0)}%'
                              : 'Starting OTA update...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: NeuroSpacing.md),
              ],

              if (otaState.error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: NeuroSpacing.md),
                  child: AlertBanner(
                    severity: AlertSeverity.critical,
                    title: 'Update Failed',
                    description: otaState.error,
                  ),
                ),

              if (otaState.result != null)
                Padding(
                  padding: EdgeInsets.only(bottom: NeuroSpacing.md),
                  child: AlertBanner(
                    severity: AlertSeverity.stable,
                    title: 'Update Initiated',
                    description: 'OTA firmware update has been triggered successfully.',
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: AppButton(
                  label: otaState.isUpdating ? 'Updating...' : 'Trigger OTA Update',
                  icon: otaState.isUpdating ? null : Icons.system_update_alt,
                  isLoading: otaState.isUpdating,
                  onPressed: otaState.isUpdating ? null : _triggerOta,
                ),
              ),
              SizedBox(height: NeuroSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _triggerOta() async {
    if (_firmwareController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a firmware version')),
      );
      return;
    }

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Confirm OTA Update',
      message: 'Are you sure you want to update the firmware to ${_firmwareController.text.trim()}?',
      confirmLabel: 'Update',
      isDangerous: true,
    );

    if (confirmed != true) return;

    final notifier = ref.read(deviceOtaProvider.notifier);
    final result = await notifier.triggerOta(
      widget.deviceId,
      _firmwareController.text.trim(),
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTA update triggered successfully')),
        );
      },
    );
  }
}
