import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../providers/monitoring_providers.dart';
import '../widgets/patient_monitor_card.dart';

class LiveMonitoringScreen extends ConsumerStatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  ConsumerState<LiveMonitoringScreen> createState() =>
      _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends ConsumerState<LiveMonitoringScreen> {
  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getToken();
    if (token != null) {
      final client = ref.read(webSocketClientProvider);
      client.connect(token: token, path: '/v1/ws/devices/monitor');
    }
  }

  String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(webSocketConnectionProvider);
    final connection = connectionState.valueOrNull ?? false;
    final vitalsMap = ref.watch(liveVitalsStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Monitoring'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  connection ? Icons.wifi : Icons.wifi_off,
                  size: 18,
                  color: connection ? NeuroColors.success : NeuroColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  connection ? 'Live' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 12,
                    color: connection ? NeuroColors.success : NeuroColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: vitalsMap.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monitor_heart_outlined,
                      size: 64, color: NeuroColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No active monitoring sessions',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: NeuroColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subscribe to a patient from their detail screen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NeuroColors.textSecondary,
                        ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {},
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vitalsMap.length,
                itemBuilder: (context, index) {
                  final entry = vitalsMap.entries.elementAt(index);
                  final patientId = entry.key;
                  final vitals = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PatientMonitorCard(
                          patientId: patientId,
                          patientName: 'Patient ${patientId.substring(0, 8)}',
                          vitals: vitals,
                          onTap: () {
                            context.push('/monitoring/$patientId');
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 4,
                            left: 12,
                            right: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 12,
                                color: NeuroColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'آخر تحديث: ${_formatTimestamp(vitals['timestamp'] as String?)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: NeuroColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
