import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/overview');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminStatsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('System Overview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            statsAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 8),
                      Text('Unable to load stats', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('$err', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              data: (stats) => SizedBox(
                height: 120,
                child: Row(
                  children: [
                    _StatCard(
                      icon: Icons.people,
                      label: 'Users',
                      value: '${stats['total_users'] ?? '-'}',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.devices,
                      label: 'Devices',
                      value: '${stats['total_devices'] ?? '-'}',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.local_hospital,
                      label: 'Patients',
                      value: '${stats['total_patients'] ?? '-'}',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Management', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _AdminMenuItem(
              icon: Icons.people_outline,
              title: 'User Management',
              subtitle: 'Manage system users and roles',
              onTap: () => context.push('/settings'),
            ),
            _AdminMenuItem(
              icon: Icons.security,
              title: 'Audit Logs',
              subtitle: 'View system audit trail',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Audit logs available in backend')),
                );
              },
            ),
            _AdminMenuItem(
              icon: Icons.analytics_outlined,
              title: 'System Health',
              subtitle: 'Server status and performance',
              onTap: () => context.push('/analytics'),
            ),
            _AdminMenuItem(
              icon: Icons.cloud_sync,
              title: 'Data Sync',
              subtitle: 'Offline sync status and queues',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync status available in backend dashboard')),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Configuration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _AdminMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notification Settings',
              subtitle: 'Push notification configuration',
              onTap: () => context.push('/settings'),
            ),
            _AdminMenuItem(
              icon: Icons.palette_outlined,
              title: 'Theme & Appearance',
              subtitle: 'Customize application theme',
              onTap: () => context.push('/settings'),
            ),
            const SizedBox(height: 24),
            Text('System Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Application', value: 'NeuroBleed Alert'),
                    _InfoRow(label: 'Version', value: '1.0.0'),
                    _InfoRow(label: 'Environment', value: 'Production'),
                    _InfoRow(label: 'API Version', value: 'v1'),
                    _InfoRow(label: 'BLE Status', value: 'Real (flutter_blue_plus)'),
                    _InfoRow(label: 'Authentication', value: 'JWT + OTP + OAuth2'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
