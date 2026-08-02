import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import 'providers/emergency_provider.dart';

class SosScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const SosScreen({
    super.key,
    required this.patientId,
    this.patientName = '',
  });

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _countdown = 5;
  Timer? _countdownTimer;
  bool _isCounting = false;

  final _latController =
      TextEditingController(text: '30.0444');
  final _lngController =
      TextEditingController(text: '31.2357');
  final _notesController = TextEditingController();
  Map<String, dynamic>? _latestVitals;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.microtask(() {
      ref
          .read(emergencyProvider.notifier)
          .loadContacts(patientId: widget.patientId);
      _loadLatestVitals();
    });
  }

  Future<void> _loadLatestVitals() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api
          .get('/v1/vitals/patient/${widget.patientId}/latest');
      final data = response.data;
      if (data is Map) {
        setState(() {
          _latestVitals = data.cast<String, dynamic>();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _latController.dispose();
    _lngController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _vitalsSummary() {
    final v = _latestVitals;
    if (v == null) return '';
    final parts = <String>[];
    final hr = v['heart_rate'];
    final spo2 = v['oxygen_saturation'];
    final sys = v['systolic_bp'];
    final dia = v['diastolic_bp'];
    if (hr != null) parts.add('النبض: $hr');
    if (spo2 != null) parts.add('الأكسجين: $spo2%');
    if (sys != null && dia != null) parts.add('الضغط: $sys/$dia');
    return parts.join('، ');
  }

  void _startCountdown() {
    if (_isCounting) return;
    setState(() {
      _isCounting = true;
      _countdown = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _isCounting = false);
        _triggerSos();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCounting = false;
      _countdown = 5;
    });
  }

  Future<void> _triggerSos() async {
    final vitals = _vitalsSummary();
    final notes = [
      if (_notesController.text.trim().isNotEmpty) _notesController.text.trim(),
      if (vitals.isNotEmpty) 'آخر القياسات: $vitals',
    ].join(' | ');

    await ref.read(emergencyProvider.notifier).triggerSos(
          patientId: widget.patientId,
          sosType: 'manual',
          lat: double.tryParse(_latController.text.trim()),
          lng: double.tryParse(_lngController.text.trim()),
          notes: notes.isEmpty ? null : notes,
        );
  }

  Future<void> _callNumber(String? phone) async {
    final number = phone?.replaceAll(RegExp(r'[^\d+]'), '');
    if (number == null || number.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendSms(String? phone) async {
    final number = phone?.replaceAll(RegExp(r'[^\d+]'), '');
    if (number == null || number.isEmpty) return;
    final body =
        'طوارئ NeuroBleed Alert: تم تفعيل زر الطوارئ للمريض '
        '(${widget.patientName}) — الموقع: ${_latController.text.trim()}, ${_lngController.text.trim()} '
        'https://maps.google.com/?q=${_latController.text.trim()},${_lngController.text.trim()}';
    final uri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: {'body': body},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_latController.text.trim()},${_lngController.text.trim()}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName.isNotEmpty
              ? 'Emergency - $widget.patientName'
              : 'Emergency SOS',
        ),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: state.isSending || state.sent
          ? _SosResultView(
              state: state,
              patientName: widget.patientName,
              lat: _latController.text.trim(),
              lng: _lngController.text.trim(),
              onCall: () => _callNumber('122'),
              onSms: () async {
                final contacts = state.contacts;
                final primary = contacts.isNotEmpty
                    ? (contacts.first['phone'] as String? ?? '')
                    : '';
                await _sendSms(primary.isEmpty ? '122' : primary);
              },
              onMaps: _openMaps,
              onResolve: () => ref.read(emergencyProvider.notifier).resolveEvent(
                    (state.sosResult?['id'] as String?) ?? '',
                  ),
              onReset: () => ref.read(emergencyProvider.notifier).reset(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SosTriggerCard(
                  isCounting: _isCounting,
                  countdown: _countdown,
                  pulseAnimation: _pulseAnimation,
                  onTrigger: _startCountdown,
                  onCancel: _cancelCountdown,
                ),
                const SizedBox(height: 16),
                _LocationCard(
                  latController: _latController,
                  lngController: _lngController,
                  notesController: _notesController,
                  vitalsSummary: _vitalsSummary(),
                  onOpenMaps: _openMaps,
                ),
                const SizedBox(height: 16),
                _ContactsCard(
                  contacts: state.contacts,
                  isLoading: state.isLoading,
                  onCall: _callNumber,
                  onSms: _sendSms,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.phone_in_talk, size: 18),
                        label: const Text('اتصال 122 (شرطة)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                        onPressed: () => _callNumber('122'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.local_hospital, size: 18),
                        label: const Text('اتصال 123 (إسعاف)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                        onPressed: () => _callNumber('123'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SosTriggerCard extends StatelessWidget {
  final bool isCounting;
  final int countdown;
  final Animation<double> pulseAnimation;
  final VoidCallback onTrigger;
  final VoidCallback onCancel;

  const _SosTriggerCard({
    required this.isCounting,
    required this.countdown,
    required this.pulseAnimation,
    required this.onTrigger,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.red.shade50,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.warning_amber, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'EMERGENCY SOS',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم تنبيه جميع جهات الاتصال فوراً مع إرسال الموقع والقياسات الحيوية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 24),
            if (isCounting) ...[
              Text(
                'جارٍ الإرسال خلال...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: pulseAnimation.value,
                  child: child,
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$countdown',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'إلغاء',
                variant: ButtonVariant.secondary,
                onPressed: onCancel,
              ),
            ] else ...[
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: pulseAnimation.value,
                  child: child,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    minimumSize: const Size(120, 120),
                    elevation: 8,
                  ),
                  onPressed: onTrigger,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sos, size: 40),
                      SizedBox(height: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final TextEditingController latController;
  final TextEditingController lngController;
  final TextEditingController notesController;
  final String vitalsSummary;
  final VoidCallback onOpenMaps;

  const _LocationCard({
    required this.latController,
    required this.lngController,
    required this.notesController,
    required this.vitalsSummary,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الموقع والإحداثيات',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.map_outlined, color: Colors.blue),
                  tooltip: 'فتح في خرائط Google',
                  onPressed: onOpenMaps,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'خط العرض (Lat)',
                      prefixIcon: Icon(Icons.explore_outlined),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: lngController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'خط الطول (Lng)',
                      prefixIcon: Icon(Icons.explore_outlined),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات إضافية (اختياري)',
                hintText: 'مثال: حالة المريض تفاقمت...',
                isDense: true,
              ),
            ),
            if (vitalsSummary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monitor_heart_outlined,
                      color: Colors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم إرفاق آخر القياسات: $vitalsSummary',
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;
  final bool isLoading;
  final Future<void> Function(String?) onCall;
  final Future<void> Function(String?) onSms;

  const _ContactsCard({
    required this.contacts,
    required this.isLoading,
    required this.onCall,
    required this.onSms,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'جهات الاتصال الطارئة',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${contacts.length} جهة',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: AppLoading())
            else if (contacts.isEmpty)
              const AppEmptyState(
                icon: Icons.contact_emergency,
                title: 'لا توجد جهات اتصال',
                message: 'لم يتم إعداد جهات اتصال طارئة بعد.',
              )
            else
              ...contacts.map((contact) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Text(
                        (contact['full_name'] as String? ?? '?')[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(contact['full_name'] as String? ?? ''),
                    subtitle: Text(contact['phone'] as String? ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          tooltip: 'اتصال',
                          onPressed: () =>
                              onCall(contact['phone'] as String?),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.sms_outlined,
                            color: Colors.blue,
                          ),
                          tooltip: 'إرسال موقعي SMS',
                          onPressed: () => onSms(contact['phone'] as String?),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _SosResultView extends StatelessWidget {
  final EmergencySosState state;
  final String patientName;
  final String lat;
  final String lng;
  final Future<void> Function() onCall;
  final Future<void> Function() onSms;
  final Future<void> Function() onMaps;
  final VoidCallback onResolve;
  final VoidCallback onReset;

  const _SosResultView({
    required this.state,
    required this.patientName,
    required this.lat,
    required this.lng,
    required this.onCall,
    required this.onSms,
    required this.onMaps,
    required this.onResolve,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contactedCount = state.sosResult?['contacted_count'] as int? ?? 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isSending ? Icons.hourglass_top : Icons.check_circle,
              size: 80,
              color: state.isSending ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              state.isSending ? 'جارٍ إرسال SOS...' : 'تم إرسال SOS!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!state.isSending) ...[
              Text(
                'تم إخطار $contactedCount جهة اتصال طارئة.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (state.sosResult?['status'] != null)
                Text(
                  'الحالة: ${state.sosResult!['status']}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$lat, $lng',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('اتصال 122'),
                            onPressed: onCall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.sms, size: 18),
                            label: const Text('SMS'),
                            onPressed: onSms,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.map, size: 18),
                            label: const Text('الخريطة'),
                            onPressed: onMaps,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'وضع علامة كتم التعامل',
                icon: Icons.check,
                variant: ButtonVariant.primary,
                onPressed: onResolve,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onReset,
                child: const Text('إرسال مرة أخرى'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
