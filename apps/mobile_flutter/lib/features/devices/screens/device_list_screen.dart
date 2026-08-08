import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import '../providers/device_providers.dart';
import '../widgets/device_widgets.dart';

class DeviceListScreen extends ConsumerStatefulWidget {
  const DeviceListScreen({super.key});

  @override
  ConsumerState<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends ConsumerState<DeviceListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(deviceListProvider.notifier).loadDevices());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(deviceListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأجهزة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(deviceListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderActions(context),
          Padding(
            padding: EdgeInsets.fromLTRB(
                NeuroSpacing.md, NeuroSpacing.md, NeuroSpacing.md, 0),
            child: AppInput(
              label: '',
              hint: 'بحث بالرقم التسلسلي أو الاسم...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(deviceListProvider.notifier).search('');
                      },
                    )
                  : null,
            ),
          ),
          SizedBox(height: NeuroSpacing.sm),
          _buildFilterChips(state),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/devices/register'),
        icon: const Icon(Icons.add),
        label: const Text('تسجيل جهاز'),
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(NeuroSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.bluetooth_searching,
              title: 'إزواج جهاز',
              subtitle: 'البحث عن أجهزة BLE',
              color: NeuroColors.primary,
              onTap: () => context.push('/devices/pair'),
            ),
          ),
          SizedBox(width: NeuroSpacing.sm),
          Expanded(
            child: _ActionCard(
              icon: Icons.app_registration,
              title: 'تسجيل جهاز',
              subtitle: 'إدخال الرقم التسلسلي',
              color: NeuroColors.info,
              onTap: () => context.push('/devices/register'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(DeviceListState state) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: NeuroSpacing.md),
        children: [
          _FilterChip(
            label: 'الكل',
            selected: state.statusFilter == null && state.typeFilter == null,
            onSelected: () {
              ref.read(deviceListProvider.notifier).filterByStatus(null);
              ref.read(deviceListProvider.notifier).filterByType(null);
            },
          ),
          SizedBox(width: NeuroSpacing.xs),
          _FilterChip(
            label: 'متصل',
            selected: state.statusFilter == DeviceStatus.online,
            onSelected: () =>
                ref.read(deviceListProvider.notifier).filterByStatus(
                      state.statusFilter == DeviceStatus.online
                          ? null
                          : DeviceStatus.online,
                    ),
          ),
          SizedBox(width: NeuroSpacing.xs),
          _FilterChip(
            label: 'غير متصل',
            selected: state.statusFilter == DeviceStatus.offline,
            onSelected: () =>
                ref.read(deviceListProvider.notifier).filterByStatus(
                      state.statusFilter == DeviceStatus.offline
                          ? null
                          : DeviceStatus.offline,
                    ),
          ),
          SizedBox(width: NeuroSpacing.xs),
          _FilterChip(
            label: 'خطأ',
            selected: state.statusFilter == DeviceStatus.error,
            onSelected: () =>
                ref.read(deviceListProvider.notifier).filterByStatus(
                      state.statusFilter == DeviceStatus.error
                          ? null
                          : DeviceStatus.error,
                    ),
          ),
          SizedBox(width: NeuroSpacing.xs),
          _FilterChip(
            label: 'صيانة',
            selected: state.statusFilter == DeviceStatus.maintenance,
            onSelected: () =>
                ref.read(deviceListProvider.notifier).filterByStatus(
                      state.statusFilter == DeviceStatus.maintenance
                          ? null
                          : DeviceStatus.maintenance,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DeviceListState state) {
    if (state.isLoading && state.devices.isEmpty) {
      return const AppLoading(message: 'جاري تحميل الأجهزة...');
    }

    if (state.error != null && state.devices.isEmpty) {
      return AppErrorState(
        title: 'خطأ في تحميل الأجهزة',
        message: state.error!,
        onRetry: () => ref.read(deviceListProvider.notifier).refresh(),
      );
    }

    if (state.devices.isEmpty) {
      if (state.searchQuery.isNotEmpty) {
        return AppEmptyState(
          icon: Icons.search_off,
          title: 'لا توجد نتائج',
          message: 'لم يتم العثور على أجهزة مطابقة لبحثك.',
        );
      }
      return AppEmptyState(
        icon: Icons.devices_other,
        title: 'لا توجد أجهزة',
        message: 'لم يتم تسجيل أي أجهزة بعد.\nيمكنك تسجيل جهاز جديد أو إزواج جهاز BLE.',
        actionLabel: 'تسجيل جهاز',
        onAction: () => context.push('/devices/register'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(deviceListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(NeuroSpacing.md),
        itemCount: state.devices.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.devices.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final device = state.devices[index];
          return DeviceCard(
            device: device,
            onTap: () => context.push('/devices/${device.id}'),
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(NeuroSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(NeuroRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: NeuroSpacing.sm),
            Text(
              title,
              style: NeuroTypography.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: NeuroTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        checkmarkColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
