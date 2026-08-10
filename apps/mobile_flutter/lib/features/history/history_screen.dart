import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabs(),
            Expanded(
              child: historyState.isLoading && historyState.activityFeed.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF42A5F5),
                      ),
                    )
                  : historyState.error != null &&
                          historyState.activityFeed.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFFF3B30), size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'خطأ في تحميل السجل',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(historyProvider.notifier)
                                    .loadAll(),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : _buildTimeline(historyState),
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
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 24),
            onPressed: () => context.go('/dashboard'),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context).t('history_title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.filter_list,
                color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      AppLocalizations.of(context).t('tab_all'),
      AppLocalizations.of(context).t('tab_alerts'),
      AppLocalizations.of(context).t('tab_reports'),
      AppLocalizations.of(context).t('tab_events'),
    ];
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
                  color: isSelected
                      ? const Color(0xFF1A237E)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF42A5F5))
                      : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : const Color(0xFF8E8E93),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeline(HistoryState state) {
    final List<_TimelineItem> items = [];

    if (_selectedTab == 0 || _selectedTab == 1) {
      for (final alert in state.alerts) {
        final severity = alert['severity'] ?? 'low';
        final createdAt = alert['created_at'] ?? '';
        final message = alert['message'] ?? '';
        final alertType = alert['alert_type'] ?? '';
        final isAck = alert['is_acknowledged'] ?? false;

        items.add(_TimelineItem(
          timestamp: createdAt,
          title: _alertTypeLabel(alertType),
          subtitle: message,
          icon: _alertIcon(severity),
          color: _alertColor(severity),
          date: createdAt.substring(0, 10),
          time: createdAt.length > 11 ? createdAt.substring(11, 16) : '',
          metadata: isAck ? 'تم التأكيد' : 'في الانتظار',
        ));
      }
    }

    if (_selectedTab == 0 || _selectedTab == 2) {
      for (final report in state.reports) {
        final createdAt = report['created_at'] ?? '';
        final title = report['title'] ?? 'تقرير';
        final status = report['status'] ?? '';

        items.add(_TimelineItem(
          timestamp: createdAt,
          title: title,
          subtitle: 'الحالة: $status',
          icon: Icons.description,
          color: const Color(0xFF2196F3),
          date: createdAt.substring(0, 10),
          time: createdAt.length > 11 ? createdAt.substring(11, 16) : '',
          metadata: report['report_type'] ?? '',
        ));
      }
    }

    if (_selectedTab == 0 || _selectedTab == 3) {
      for (final event in state.activityFeed) {
        final timestamp = event['timestamp'] ?? '';
        final description = event['description'] ?? '';
        final eventType = event['event_type'] ?? '';

        items.add(_TimelineItem(
          timestamp: timestamp,
          title: eventType,
          subtitle: description,
          icon: _eventIcon(eventType),
          color: _eventColor(eventType),
          date: timestamp.substring(0, 10),
          time: timestamp.length > 11 ? timestamp.substring(11, 16) : '',
          metadata: event['entity_type'] ?? '',
        ));
      }
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history,
                color: Colors.white.withValues(alpha: 0.3), size: 64),
            const SizedBox(height: 16),
            Text(
              'لا يوجد سجل حالياً',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<_TimelineItem>>{};
    for (final item in items) {
      final dateKey = item.date;
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final date in sortedDates) ...[
            _buildDateSeparator(_formatDate(date)),
            const SizedBox(height: 12),
            for (final item in grouped[date]!) ...[
              _buildTimelineItem(item),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 100),
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

  Widget _buildTimelineItem(_TimelineItem item) {
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
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.metadata.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.metadata,
                      style: TextStyle(
                        color: item.color,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      if (diff == 0) return AppLocalizations.of(context).t('date_today');
      if (diff == 1) return 'أمس';
      return '${date.day} ${_arabicMonth(date.month)} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _arabicMonth(int month) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month];
  }

  String _alertTypeLabel(String type) {
    switch (type) {
      case 'critical_bleed':
        return 'نزيف حاد';
      case 'risk_increase':
        return 'ارتفاع المخاطر';
      case 'device_offline':
        return 'الجهاز غير متصل';
      case 'low_spo2':
        return 'انخفاض الأكسجين';
      default:
        return type.isNotEmpty ? type : 'تنبيه';
    }
  }

  IconData _alertIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.notifications;
      default:
        return Icons.circle;
    }
  }

  Color _alertColor(String severity) {
    switch (severity) {
      case 'critical':
        return const Color(0xFFFF3B30);
      case 'high':
        return const Color(0xFFFF9500);
      case 'medium':
        return const Color(0xFFFFCC00);
      case 'low':
        return const Color(0xFF34C759);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  IconData _eventIcon(String eventType) {
    if (eventType.contains('alert')) return Icons.warning;
    if (eventType.contains('report')) return Icons.description;
    if (eventType.contains('device')) return Icons.devices;
    if (eventType.contains('patient')) return Icons.person;
    if (eventType.contains('emergency')) return Icons.phone;
    return Icons.circle;
  }

  Color _eventColor(String eventType) {
    if (eventType.contains('alert')) return const Color(0xFFFF3B30);
    if (eventType.contains('report')) return const Color(0xFF2196F3);
    if (eventType.contains('device')) return const Color(0xFF00BCD4);
    if (eventType.contains('patient')) return const Color(0xFF9C27B0);
    if (eventType.contains('emergency')) return const Color(0xFFFF3B30);
    return const Color(0xFF8E8E93);
  }
}

class _TimelineItem {
  final String timestamp;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String date;
  final String time;
  final String metadata;

  const _TimelineItem({
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.date,
    required this.time,
    this.metadata = '',
  });
}
