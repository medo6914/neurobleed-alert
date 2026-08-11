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
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, t),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildUserInfo(user, t),
                    const SizedBox(height: 16),
                    _buildPersonalInfo(t),
                    const SizedBox(height: 16),
                    _buildSettingsSection(context, t),
                    const SizedBox(height: 16),
                    _buildLogoutButton(context, t),
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

  Widget _buildHeader(BuildContext context, AppLocalizations t) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, MediaQuery.of(context).padding.top + 8, 16, 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
            onPressed: () => context.go('/settings'),
          ),
          const Spacer(),
          Text(
            t.t('profile'),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
            onPressed: () => _showEditProfileDialog(context, t),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(dynamic user, AppLocalizations t) {
    final displayName = user?.displayName ?? user?.full_name ?? '';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl ?? user?.profile_image_url;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showChangeImageDialog(context, t),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.3),
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Color(0xFF2196F3))
                      : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0E1A), width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isNotEmpty ? displayName : 'مستخدم جديد',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isNotEmpty ? email : '',
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
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
                      Text('مستخدم نشط', style: TextStyle(color: Color(0xFF34C759), fontSize: 12)),
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

  Widget _buildPersonalInfo(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.t('personal_info'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person_outline, t.t('age'), '18 سنة'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.monitor_weight_outlined, t.t('weight'), '63 kg'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.bloodtype_outlined, t.t('blood_type'), 'O+'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.medical_information_outlined, t.t('medical_conditions'), 'لا توجد'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today_outlined, t.t('join_date'), '10 ماي 2026'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8E8E93), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14))),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.t('settings'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _buildSettingsItem(Icons.notifications_outlined, t.t('section_notifications'), () => context.go('/settings')),
          const SizedBox(height: 12),
          _buildSettingsItem(Icons.lock_outlined, t.t('section_security'), () => context.go('/settings')),
          const SizedBox(height: 12),
          _buildSettingsItem(Icons.bluetooth_outlined, t.t('connected_devices'), () => context.go('/devices')),
          const SizedBox(height: 12),
          _buildSettingsItem(Icons.tune, t.t('section_appearance'), () => context.go('/settings')),
          const SizedBox(height: 12),
          _buildSettingsItem(Icons.help_outline, t.t('help_support'), () {}),
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
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14))),
          const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations t) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          await ref.read(authStateProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
        icon: const Icon(Icons.logout, color: Color(0xFFFF3B30)),
        label: Text(t.t('logout'), style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 16, fontWeight: FontWeight.w600)),
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

  void _showChangeImageDialog(BuildContext context, AppLocalizations t) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: Text(t.t('profile_image'), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'رابط الصورة (URL)',
            hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF42A5F5)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.t('cancel'), style: const TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                await _updateProfileImage(context, controller.text, t);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
            child: Text(t.t('save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfileImage(BuildContext context, String imageUrl, AppLocalizations t) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/v1/auth/me', data: {'profile_image_url': imageUrl});
      ref.invalidate(authStateProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الصورة بنجاح'), backgroundColor: Color(0xFF34C759)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: const Color(0xFFFF3B30)),
        );
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, AppLocalizations t) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: Text(t.t('edit_profile'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: t.t('full_name'),
                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF42A5F5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: t.t('phone'),
                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF42A5F5)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.t('cancel'), style: const TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final api = ref.read(apiClientProvider);
                final data = <String, dynamic>{};
                if (nameController.text.isNotEmpty) data['full_name'] = nameController.text;
                if (phoneController.text.isNotEmpty) data['phone'] = phoneController.text;
                if (data.isNotEmpty) {
                  await api.put('/v1/auth/me', data: data);
                  ref.invalidate(authStateProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث الملف الشخصي'), backgroundColor: Color(0xFF34C759)),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: const Color(0xFFFF3B30)),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
            child: Text(t.t('save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
