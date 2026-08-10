import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../../../core/auth/auth_provider.dart' show authStateProvider;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildUserInfo(user),
                    const SizedBox(height: 16),
                    _buildPersonalInfo(),
                    const SizedBox(height: 16),
                    _buildSettingsSection(context),
                    const SizedBox(height: 16),
                    _buildLogoutButton(context),
                    const SizedBox(height: 100),
                  ],
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
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
            onPressed: () => context.go('/settings'),
          ),
          const Spacer(),
          const Text(
            'الملف الشخصي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(dynamic user) {
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
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.3),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Color(0xFF2196F3),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0A0E1A),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'زيا احمد صفوت',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'ziad.ahmed@example.com',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF34C759), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'مستخدم نشط',
                        style: TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 12,
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
    );
  }

  Widget _buildPersonalInfo() {
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
            'معلومات شخصية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person_outline, 'العمر', '18 سنة'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.monitor_weight_outlined, 'الوزن', '63 kg'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.bloodtype_outlined, 'فصيلة الدم', 'O+'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.medical_information_outlined, 'الحالات الطبية', 'لا توجد'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today_outlined, 'تاريخ الانضمام', '10 ماي 2026'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8E8E93), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
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
            'الإعدادات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsItem(Icons.notifications_outlined, 'الإشعارات', () {}),
          const SizedBox(height: 12),
          _buildSettingsItem(Icons.lock_outlined, 'الأمان والخصوصية', () {}),
          const SizedBox(height: 12),
          _buildSettingsItem(Icons.bluetooth_outlined, 'الجهاز المرتبط', () {}),
          const SizedBox(height: 12),
          _buildSettingsItem(Icons.tune, 'تفضيلات التطبيق', () {}),
          const SizedBox(height: 12),
          _buildSettingsItem(Icons.help_outline, 'الدعم والمساعدة', () {}),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8E8E93), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF8E8E93),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          await ref.read(authStateProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        },
        icon: const Icon(Icons.logout, color: Color(0xFFFF3B30)),
        label: const Text(
          'تسجيل الخروج',
          style: TextStyle(
            color: Color(0xFFFF3B30),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFF3B30)),
          ),
        ),
      ),
    );
  }
}
