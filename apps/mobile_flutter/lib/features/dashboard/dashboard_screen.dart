import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../../core/auth/auth_provider.dart';
import '../devices/services/ble_service.dart';

final dashboardDevicesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response =
      await api.get('/v1/devices/', queryParameters: {'per_page': 50});
  final data = response.data;
  if (data is Map && data['items'] is List) return data['items'] as List;
  if (data is List) return data;
  return [];
});

final recentAlertsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/alerts/',
      queryParameters: {'acknowledged': false, 'per_page': 5});
  final data = response.data;
  if (data is Map && data['items'] is List) return data['items'] as List;
  if (data is List) return data;
  return [];
});

class BleVitalsState {
  final bool isConnected;
  final int heartRate;
  final int spo2;
  final double temperature;
  final int brainFlow;
  final bool isMonitoring;

  const BleVitalsState({
    this.isConnected = false,
    this.heartRate = 0,
    this.spo2 = 0,
    this.temperature = 0.0,
    this.brainFlow = 0,
    this.isMonitoring = false,
  });

  BleVitalsState copyWith({
    bool? isConnected,
    int? heartRate,
    int? spo2,
    double? temperature,
    int? brainFlow,
    bool? isMonitoring,
  }) {
    return BleVitalsState(
      isConnected: isConnected ?? this.isConnected,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      temperature: temperature ?? this.temperature,
      brainFlow: brainFlow ?? this.brainFlow,
      isMonitoring: isMonitoring ?? this.isMonitoring,
    );
  }
}

class BleVitalsNotifier extends StateNotifier<BleVitalsState> {
  final BleService _bleService;
  StreamSubscription<bool>? _connectionSub;

  BleVitalsNotifier(this._bleService) : super(const BleVitalsState()) {
    _init();
  }

  void _init() {
    _connectionSub = _bleService.connectionStream.listen((connected) {
      state = state.copyWith(
        isConnected: connected,
        isMonitoring: connected,
        heartRate: connected ? 0 : state.heartRate,
        spo2: connected ? 0 : state.spo2,
        temperature: connected ? 0.0 : state.temperature,
        brainFlow: connected ? 0 : state.brainFlow,
      );
    });
  }

  void updateVitals(Map<String, dynamic> data) {
    state = state.copyWith(
      heartRate: data['heart_rate'] as int? ?? state.heartRate,
      spo2: data['spo2'] as int? ?? state.spo2,
      temperature:
          (data['temperature'] as num?)?.toDouble() ?? state.temperature,
      brainFlow: data['brain_flow'] as int? ?? state.brainFlow,
    );
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }
}

final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(() => service.dispose());
  return service;
});

final bleVitalsProvider =
    StateNotifierProvider<BleVitalsNotifier, BleVitalsState>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return BleVitalsNotifier(bleService);
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(dashboardDevicesProvider);
    final alertsAsync = ref.watch(recentAlertsProvider);
    final vitals = ref.watch(bleVitalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(dashboardDevicesProvider);
                  ref.invalidate(recentAlertsProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildDeviceCard(context, devicesAsync),
                      const SizedBox(height: 16),
                      _buildBrainStateCard(context, alertsAsync, vitals),
                      const SizedBox(height: 16),
                      _buildVitalSignsCard(context, vitals),
                      const SizedBox(height: 16),
                      _buildEmergencyCard(context),
                      const SizedBox(height: 16),
                      _buildQuickActions(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          const Spacer(),
          Column(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Neuro',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'Bleed',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF3B30),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'دكاء اصطناعي لحماية دماغك',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 28),
                onPressed: () => context.go('/alerts'),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
      BuildContext context, AsyncValue<List<dynamic>> devicesAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF42A5F5).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bluetooth,
              color: Color(0xFF2196F3),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'متصل بالجهاز',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NBA-HEADBAND-01',
                  style: TextStyle(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Device headset image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/device_headset.png',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.headset_mic,
                  color: Color(0xFF90CAF9),
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrainStateCard(BuildContext context,
      AsyncValue<List<dynamic>> alertsAsync, BleVitalsState vitals) {
    final hasCriticalAlert = alertsAsync.valueOrNull?.any((a) =>
            (a['severity'] as String?)?.toLowerCase() == 'critical') ??
        false;
    final riskPercent = hasCriticalAlert ? 78 : 18;
    final riskColor =
        hasCriticalAlert ? const Color(0xFFFF3B30) : const Color(0xFF34C759);
    final statusText = hasCriticalAlert ? 'حالة طارئة' : 'الحالة مستقرة';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'حالة الدماغ الآن',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.show_chart, color: const Color(0xFF2196F3), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1A237E).withValues(alpha: 0.3),
                        const Color(0xFF0A0E1A),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.psychology,
                      size: 80,
                      color: Color(0xFF42A5F5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: riskPercent / 100,
                              strokeWidth: 8,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              valueColor:
                                  AlwaysStoppedAnimation(riskColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$riskPercent%',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'احتمال النزيف',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: riskColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasCriticalAlert
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle,
                            color: riskColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: riskColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time,
                  color: Color(0xFF8E8E93), size: 14),
              const SizedBox(width: 4),
              Text(
                'آخر تحديث: منذ 30 ثانية',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsCard(BuildContext context, BleVitalsState vitals) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المؤشرات الحيوية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _VitalSignTile(
                  icon: Icons.water_drop_outlined,
                  label: 'تنشيع الأكسجين',
                  value: vitals.isConnected ? '${vitals.spo2}%' : '96%',
                  color: const Color(0xFF2196F3),
                  isActive: vitals.isConnected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalSignTile(
                  icon: Icons.psychology_outlined,
                  label: 'تدفق الدم للدماغ',
                  value: vitals.isConnected ? '${vitals.brainFlow}%' : '75%',
                  color: const Color(0xFF9C27B0),
                  isActive: vitals.isConnected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalSignTile(
                  icon: Icons.favorite_outline,
                  label: 'معدل النبض',
                  value:
                      vitals.isConnected ? '${vitals.heartRate} BPM' : '78 BPM',
                  color: const Color(0xFFFF3B30),
                  isActive: vitals.isConnected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalSignTile(
                  icon: Icons.thermostat,
                  label: 'درجة الحرارة',
                  value: vitals.isConnected
                      ? '${vitals.temperature.toStringAsFixed(1)}°C'
                      : '36.6°C',
                  color: const Color(0xFF2196F3),
                  isActive: vitals.isConnected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEmergencyDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF3B30).withValues(alpha: 0.2),
              const Color(0xFFFF3B30).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF3B30),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حالة طارئة',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'اضغط إذا شعرت بأي أعراض خطرة',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFFF3B30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.phone,
                label: 'اتصال طوارئ',
                color: const Color(0xFFFF3B30),
                onTap: () => _showEmergencyDialog(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.local_hospital_outlined,
                label: 'أقرب مستشفى',
                color: const Color(0xFF2196F3),
                onTap: () => context.go('/map'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.share_location_outlined,
                label: 'مشاركة الموقع',
                color: const Color(0xFF00BCD4),
                onTap: () => _shareLocation(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.description_outlined,
                label: 'سجل التقارير',
                color: const Color(0xFF9C27B0),
                onTap: () => context.go('/reports'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF3B30)),
            const SizedBox(width: 8),
            const Text('اتصال طوارئ',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'هل تريد الاتصال برقم الطوارئ (123)؟',
          style: TextStyle(color: Color(0xFF8E8E93)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse('tel:123');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
            ),
            child: const Text('اتصال'),
          ),
        ],
      ),
    );
  }

  void _shareLocation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري مشاركة الموقع...'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }
}

class _VitalSignTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isActive;

  const _VitalSignTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.08)
            : const Color(0xFF1A1F35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? color : const Color(0xFF8E8E93),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.white : const Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? color : const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
