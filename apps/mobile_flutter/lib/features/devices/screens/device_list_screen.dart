import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../providers/device_list_provider.dart';

class DeviceListScreen extends ConsumerStatefulWidget {
  const DeviceListScreen({super.key});

  @override
  ConsumerState<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends ConsumerState<DeviceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceListProvider.notifier).loadDevices(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: deviceState.isLoading && deviceState.devices.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF42A5F5),
                      ),
                    )
                  : deviceState.error != null && deviceState.devices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFFF3B30), size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'خطأ في تحميل الأجهزة',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(deviceListProvider.notifier)
                                    .refresh(),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : deviceState.devices.isEmpty
                          ? _buildEmptyState()
                          : _buildDeviceList(deviceState),
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
            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
            onPressed: () {},
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context).t('device_title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.bluetooth_searching, color: Colors.white, size: 24),
            onPressed: () => context.push('/devices/pair'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
            onPressed: () =>
                ref.read(deviceListProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other,
              color: Colors.white.withValues(alpha: 0.3), size: 64),
          const SizedBox(height: 16),
          Text(
            'لا توجد أجهزة مسجلة',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بتركيب جهاز NeuroBleed للبدء',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/devices/pair'),
            icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
            label: const Text(
              'زوج جهاز جديد',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF42A5F5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(DeviceListState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(deviceListProvider.notifier).refresh(),
      color: const Color(0xFF42A5F5),
      backgroundColor: const Color(0xFF1A1F35),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.devices.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.devices.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFF42A5F5)),
              ),
            );
          }

          final device = state.devices[index];
          return _buildDeviceCard(device);
        },
      ),
    );
  }

  Widget _buildDeviceCard(dynamic device) {
    final deviceName = device.name ?? device.serialNumber;
    final serialNumber = device.serialNumber;
    final batteryLevel = device.batteryLevel.round();
    final status = device.status;
    final firmwareVersion = device.firmwareVersion;
    final lastSeen = device.lastHeartbeat;
    final signalStrength = device.signalStrength;
    final isActive = device.isConnected;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/device_headset.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.headset_mic,
                      color: Color(0xFF90CAF9),
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      serialNumber,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF34C759).withValues(alpha: 0.15)
                      : const Color(0xFFFF3B30).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: isActive
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF3B30),
                      size: 8,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'متصل' : 'غير متصل',
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF3B30),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('نوع الجهاز', _deviceTypeLabel(device.type)),
          const SizedBox(height: 8),
          _buildInfoRow('الإصدار', firmwareVersion),
          const SizedBox(height: 8),
          _buildInfoRow('البطارية', '$batteryLevel%'),
          if (lastSeen != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('آخر اتصال', _formatLastSeen(lastSeen)),
          ],
          if (signalStrength > 0) ...[
            const SizedBox(height: 8),
            _buildInfoRow('قوة الإشارة', '$signalStrength dBm'),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/device/detail/${device.id}'),
                  icon: const Icon(Icons.info_outline,
                      color: Color(0xFF42A5F5), size: 18),
                  label: const Text(
                    'تفاصيل',
                    style: TextStyle(color: Color(0xFF42A5F5)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF42A5F5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final api = ref.read(apiClientProvider);
                      await api.get('/v1/devices/${device.id}/diagnostics');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم فحص الجهاز بنجاح'),
                            backgroundColor: Color(0xFF34C759),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('خطأ في الفحص: $e'),
                            backgroundColor: const Color(0xFFFF3B30),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.build_outlined,
                      color: Color(0xFF9C27B0), size: 18),
                  label: const Text(
                    'فحص',
                    style: TextStyle(color: Color(0xFF9C27B0)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF9C27B0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 14,
          ),
        ),
        const Spacer(),
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

  String _deviceTypeLabel(dynamic type) {
    switch (type) {
      case DeviceType.headband:
        return 'Headband';
      case DeviceType.wearable:
        return 'Wearable';
      case DeviceType.bedside:
        return 'Bedside';
      default:
        return type?.toString() ?? '--';
    }
  }

  String _formatLastSeen(dynamic lastSeen) {
    try {
      final dt = lastSeen is DateTime
          ? lastSeen
          : DateTime.parse(lastSeen.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      return 'منذ ${diff.inDays} يوم';
    } catch (_) {
      return '--';
    }
  }
}
