import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core/core.dart';

final alertsProvider = FutureProvider<List>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/alerts/?acknowledged=false');
  return response.data as List;
});

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإنذارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(alertsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(alertsProvider),
        child: alertsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ: $err'),
              ],
            ),
          ),
          data: (alerts) {
            if (alerts.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('✅ لا توجد إنذارات غير مؤكدة'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final severity = alert['severity'] ?? 'low';
                final isCritical = severity == 'critical';

                return Card(
                  borderOnForeground: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCritical ? Colors.red : Colors.orange,
                      width: isCritical ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isCritical ? Icons.warning : Icons.info,
                      color: isCritical ? Colors.red : Colors.orange,
                      size: 32,
                    ),
                    title: Text(
                      alert['alert_type'] ?? 'إنذار',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCritical ? Colors.red : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(alert['message'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          alert['created_at'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        severity,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      backgroundColor:
                          isCritical ? Colors.red : Colors.orange,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
