import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../providers/device_providers.dart';

class RegisterDeviceScreen extends ConsumerStatefulWidget {
  const RegisterDeviceScreen({super.key});

  @override
  ConsumerState<RegisterDeviceScreen> createState() =>
      _RegisterDeviceScreenState();
}

class _RegisterDeviceScreenState extends ConsumerState<RegisterDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialNumberController = TextEditingController();
  final _deviceNameController = TextEditingController();

  @override
  void dispose() {
    _serialNumberController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل جهاز جديد'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(NeuroSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(NeuroSpacing.md),
                decoration: BoxDecoration(
                  color: NeuroColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(NeuroRadius.card),
                  border: Border.all(color: NeuroColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: NeuroColors.info),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(
                      child: Text(
                        'يمكنك العثور على الرقم التسلسلي على ملصق الجهاز أو في العلبة',
                        style: NeuroTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: NeuroSpacing.xl),
              Text(
                'معلومات الجهاز',
                style: NeuroTypography.h3,
              ),
              SizedBox(height: NeuroSpacing.md),
              AppInput(
                label: 'الرقم التسلسلي *',
                hint: 'أدخل الرقم التسلسلي للجهاز',
                controller: _serialNumberController,
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'الرقم التسلسلي مطلوب';
                  return null;
                },
              ),
              SizedBox(height: NeuroSpacing.md),
              AppInput(
                label: 'اسم الجهاز (اختياري)',
                hint: 'مثل: جهاز المخ 1',
                controller: _deviceNameController,
              ),
              SizedBox(height: NeuroSpacing.xxl),
              if (state.error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: NeuroSpacing.md),
                  child: Container(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    decoration: BoxDecoration(
                      color: NeuroColors.critical.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(NeuroRadius.card),
                      border: Border.all(color: NeuroColors.critical),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: NeuroColors.critical),
                        SizedBox(width: NeuroSpacing.sm),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: NeuroTypography.bodyMedium?.copyWith(
                              color: NeuroColors.critical,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: AppButton(
                  label: state.isSubmitting ? 'جاري التسجيل...' : 'تسجيل الجهاز',
                  icon: state.isSubmitting ? null : Icons.add_circle,
                  isLoading: state.isSubmitting,
                  onPressed: state.isSubmitting ? null : _submitForm,
                ),
              ),
              SizedBox(height: NeuroSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/devices/pair'),
                  child: Text(
                    'أو ابحث عن جهاز BLE',
                    style: NeuroTypography.bodyMedium?.copyWith(
                      color: NeuroColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final request = DeviceCreateRequest(
      serialNumber: _serialNumberController.text.trim(),
      deviceName: _deviceNameController.text.trim().isEmpty
          ? null
          : _deviceNameController.text.trim(),
      deviceType: 'headband',
      macAddress: null,
      firmwareVersion: null,
      hardwareVersion: null,
      hospitalId: null,
      department: null,
    );

    final notifier = ref.read(registerDeviceProvider.notifier);
    final result = await notifier.submitRegister(request);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(failure.message),
              backgroundColor: NeuroColors.critical),
        );
      },
      (device) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل الجهاز بنجاح: ${device.serialNumber}'),
            backgroundColor: NeuroColors.low,
          ),
        );
        context.pop();
      },
    );
  }
}
