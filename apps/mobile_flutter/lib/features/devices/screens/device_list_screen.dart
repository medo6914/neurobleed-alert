import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeviceListScreen extends ConsumerStatefulWidget {
  const DeviceListScreen({super.key});

  @override
  ConsumerState<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends ConsumerState<DeviceListScreen> {
  @override
  Widget build(BuildContext context) {
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
                    _buildDeviceStatusCard(),
                    const SizedBox(height: 16),
                    _buildConnectionStatus(),
                    const SizedBox(height: 16),
                    _buildDeviceInfo(),
                    const SizedBox(height: 16),
                    _buildSensorStatus(),
                    const SizedBox(height: 16),
                    _buildDiagnoseButton(),
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
            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
            onPressed: () {},
          ),
          const Spacer(),
          const Text(
            'الجهاز',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard() {
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
              const Text(
                'حالة الجهاز',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF34C759), size: 8),
                    SizedBox(width: 6),
                    Text(
                      'متصل',
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
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/device_headset.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.headset_mic,
                      color: Color(0xFF90CAF9),
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NBA-HEADBAND-01',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '78%',
                      style: TextStyle(
                        color: const Color(0xFF34C759),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ConnectionItem(
            icon: Icons.bluetooth,
            label: 'BLE',
            isConnected: true,
          ),
          _ConnectionItem(
            icon: Icons.phone_android,
            label: 'الهاتف',
            isConnected: true,
          ),
          _ConnectionItem(
            icon: Icons.cloud_queue,
            label: 'السحابة',
            isConnected: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo() {
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
            'معلومات الجهاز',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('إصدار الجهاز', 'v1.2.3'),
          const SizedBox(height: 12),
          _buildInfoRow('رقم الجهاز', 'NBA-2026-001'),
          const SizedBox(height: 12),
          _buildInfoRow('آخر مرافقة', 'اليوم 10:30 AM'),
          const SizedBox(height: 12),
          _buildInfoRow('حالة البطارية', '78%'),
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

  Widget _buildSensorStatus() {
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
            'حالة الحساسات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSensorRow('NIRS Sensor', true),
          const SizedBox(height: 12),
          _buildSensorRow('Temperature Sensor', true),
          const SizedBox(height: 12),
          _buildSensorRow('Motion Sensor', true),
          const SizedBox(height: 12),
          _buildSensorRow('Battery', true),
        ],
      ),
    );
  }

  Widget _buildSensorRow(String name, bool isActive) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          color: isActive ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
          size: 8,
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF34C759).withValues(alpha: 0.15)
                : const Color(0xFFFF3B30).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isActive ? 'نشط' : 'غير نشط',
            style: TextStyle(
              color: isActive ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnoseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.build_outlined, color: Colors.white),
        label: const Text(
          'فحص الجهاز الآن',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF42A5F5)),
          ),
        ),
      ),
    );
  }
}

class _ConnectionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isConnected;

  const _ConnectionItem({
    required this.icon,
    required this.label,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isConnected
                ? const Color(0xFF2196F3).withValues(alpha: 0.15)
                : const Color(0xFF8E8E93).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isConnected ? const Color(0xFF2196F3) : const Color(0xFF8E8E93),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isConnected ? Colors.white : const Color(0xFF8E8E93),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
