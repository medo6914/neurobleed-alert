import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabs(),
            Expanded(
              child: _buildTimeline(),
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
            onPressed: () => context.go('/dashboard'),
          ),
          const Spacer(),
          const Text(
            'السجل',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['الكل', 'تنبيهات', 'تقارير', 'أحداث'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1A237E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF42A5F5))
                      : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeline() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSeparator('اليوم'),
          const SizedBox(height: 12),
          _buildTimelineItem(
            time: '10:30 AM',
            title: 'حالة مستقرة',
            subtitle: 'جميع المؤشرات طبيعية',
            icon: Icons.check_circle,
            color: const Color(0xFF34C759),
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            time: '09:15 AM',
            title: 'تقرير دوري',
            subtitle: 'تم إنشاء تقرير صحي',
            icon: Icons.description,
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            time: '08:45 AM',
            title: 'اتصال طوارئ',
            subtitle: 'تم الاتصال بخدمة الطوارئ',
            icon: Icons.phone,
            color: const Color(0xFFFF3B30),
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            time: '07:30 AM',
            title: 'تحديث بيانات',
            subtitle: 'تم مزامنة البيانات',
            icon: Icons.cloud_upload,
            color: const Color(0xFF00BCD4),
          ),
          const SizedBox(height: 24),
          _buildDateSeparator('17 يوليو 2026'),
          const SizedBox(height: 12),
          _buildTimelineItem(
            time: '11:20 PM',
            title: 'حالة مستقرة',
            subtitle: 'جميع المؤشرات طبيعية',
            icon: Icons.check_circle,
            color: const Color(0xFF34C759),
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            time: '09:00 PM',
            title: 'تقرير دوري',
            subtitle: 'تم إنشاء تقرير صحي',
            icon: Icons.description,
            color: const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String date) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          date,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
              ],
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
}
