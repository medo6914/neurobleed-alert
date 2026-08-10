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
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, t),
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
                      _buildDeviceCard(context, devicesAsync, t),
                      const SizedBox(height: 16),
                      _buildBrainStateCard(context, alertsAsync, vitals, t),
                      const SizedBox(height: 16),
                      _buildVitalSignsCard(context, vitals, t),
                      const SizedBox(height: 16),
                      _buildEmergencyCard(context, t),
                      const SizedBox(height: 16),
                      _buildQuickActions(context, t),
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

  Widget _buildHeader(BuildContext context, AppLocalizations t) {
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_brain.png',
                    width: 36,
                    height: 36,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.psychology,
                            color: Color(0xFF2196F3), size: 36),
                  ),
                  const SizedBox(width: 8),
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
                        TextSpan(
                          text: ' Alert',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                t.t('app_tagline'),
                style: const TextStyle(
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

  Widget _buildDeviceCard(BuildContext context, AsyncValue<List<dynamic>> devicesAsync, AppLocalizations t) {
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
                Text(
                  t.t('device_connected'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.t('device_model_name'),
                  style: TextStyle(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/device_headset.png',
              width: 80,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 50,
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
      AsyncValue<List<dynamic>> alertsAsync, BleVitalsState vitals, AppLocalizations t) {
    final hasCriticalAlert = alertsAsync.valueOrNull?.any((a) =>
            (a['severity'] as String?)?.toLowerCase() == 'critical') ??
        false;
    final riskPercent = hasCriticalAlert ? 78 : 18;
    final riskColor =
        hasCriticalAlert ? const Color(0xFFFF3B30) : const Color(0xFF34C759);
    final statusText = hasCriticalAlert ? t.t('status_emergency') : t.t('status_stable');

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
              Text(
                t.t('brain_state_now'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.show_chart, color: Color(0xFF2196F3), size: 20),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo_brain.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.psychology,
                        size: 80,
                        color: Color(0xFF42A5F5),
                      ),
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
                              Text(
                                t.t('bleed_risk_percentage'),
                                style: const TextStyle(
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
                t.t('last_update_30_seconds'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsCard(BuildContext context, BleVitalsState vitals, AppLocalizations t) {
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
          Text(
            t.t('vital_signs'),
            style: const TextStyle(
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
                  label: t.t('vital_oxygen_saturation'),
                  value: vitals.isConnected ? '${vitals.spo2}%' : '96%',
                  color: const Color(0xFF2196F3),
                  isActive: vitals.isConnected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalSignTile(
                  icon: Icons.psychology_outlined,
                  label: t.t('vital_brain_blood_flow'),
                  value: vitals.isConnected ? '${vitals.brainFlow}%' : '75%',
                  color: const Color(0xFF9C27B0),
                  isActive: vitals.isConnected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalSignTile(
                  icon: Icons.favorite_outline,
                  label: t.t('vital_heart_rate'),
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
                  label: t.t('vital_temperature'),
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

  Widget _buildEmergencyCard(BuildContext context, AppLocalizations t) {
    return GestureDetector(
      onTap: () => _showEmergencyDialog(context, t),
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
                  Text(
                    t.t('emergency_status'),
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    t.t('emergency_press_if_symptoms'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
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

  Widget _buildQuickActions(BuildContext context, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.t('quick_actions'),
          style: const TextStyle(
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
                label: t.t('emergency_call'),
                color: const Color(0xFFFF3B30),
                onTap: () => _showEmergencyDialog(context, t),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.local_hospital_outlined,
                label: t.t('nearest_hospital'),
                color: const Color(0xFF2196F3),
                onTap: () => context.go('/map'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.share_location_outlined,
                label: t.t('share_location'),
                color: const Color(0xFF00BCD4),
                onTap: () => _shareLocation(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.description_outlined,
                label: t.t('reports_history'),
                color: const Color(0xFF9C27B0),
                onTap: () => context.go('/reports'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEmergencyDialog(BuildContext context, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF3B30)),
            const SizedBox(width: 8),
            Text(t.t('emergency_call'),
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          t.t('emergency_call_confirm'),
          style: const TextStyle(color: Color(0xFF8E8E93)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.t('cancel'),
                style: const TextStyle(color: Color(0xFF8E8E93))),
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
            child: Text(t.t('call')),
          ),
        ],
      ),
    );
  }

  void _shareLocation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('sharing_location')),
        backgroundColor: const Color(0xFF2196F3),
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
