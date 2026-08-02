import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';

final mapHospitalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/hospitals');
  final data = response.data;
  if (data is Map) {
    final hospitals = data['hospitals'];
    if (hospitals is List) return hospitals.cast<Map<String, dynamic>>();
  }
  return [];
});

const _kDefaultLat = 30.0444;
const _kDefaultLng = 31.2357;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _loading = true;
  bool _failed = false;
  List<Map<String, dynamic>> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/v1/analytics/hospitals');
      final data = response.data;
      final hospitals = data is Map && data['hospitals'] is List
          ? (data['hospitals'] as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      setState(() {
        _hospitals = hospitals;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _hospitals = [];
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخريطة - أقرب المستشفيات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: AppLoading())
          : Column(
              children: [
                Expanded(
                  child: _MapCanvas(
                    hospitals: _hospitals,
                    failed: _failed,
                    onOpenMaps: () => _openGoogleMaps(),
                  ),
                ),
                _buildBottomCards(),
              ],
            ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_kDefaultLat,$_kDefaultLng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildBottomCards() {
    final hospitals = _hospitals;
    final display = hospitals.isEmpty
        ? const [
            {'name': 'مستشفى جامعة القاهرة', 'distance_km': 2.4},
            {'name': 'مستشفى المنيل التخصصي', 'distance_km': 3.1},
            {'name': 'مستشفى الدمرداش', 'distance_km': 5.8},
          ]
        : hospitals;

    final nearest = display.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1427),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أقرب المستشفيات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined, color: Colors.white),
                tooltip: 'فتح خرائط Google',
                onPressed: _openGoogleMaps,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final h in nearest) _HospitalRow(hospital: h),
        ],
      ),
    );
  }
}

class _HospitalRow extends StatelessWidget {
  final Map<String, dynamic> hospital;
  const _HospitalRow({required this.hospital});

  @override
  Widget build(BuildContext context) {
    final name = hospital['name'] as String? ?? 'مستشفى';
    final distance = (hospital['distance_km'] as num?)?.toDouble() ??
        (hospital['patient_count'] != null
            ? (2.0 + (hospital['patient_count'] as num).toDouble() * 0.3)
            : 2.0);
    final beds = (hospital['bed_capacity'] as num?)?.toInt();
    final occupancy =
        (hospital['bed_occupancy'] as num?)?.toDouble()?.clamp(0, 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131E3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital, color: Color(0xFF1ACB58)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (beds != null && occupancy != null)
                  Text(
                    '$beds سرير • إشغال ${occupancy.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${distance.toStringAsFixed(1)} كم',
                style: const TextStyle(
                  color: Color(0xFF1ACB58),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${((distance / 0.8).clamp(1, 120)).round()} دقيقة',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  final List<Map<String, dynamic>> hospitals;
  final bool failed;
  final VoidCallback onOpenMaps;

  const _MapCanvas({
    required this.hospitals,
    required this.failed,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1B33), Color(0xFF04101F)],
        ),
      ),
      child: CustomPaint(
        painter: _MapPainter(
          hospitalCount: hospitals.isEmpty ? 3 : hospitals.length,
          failed: failed,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'موقع المريض $_kDefaultLat, $_kDefaultLng',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_taxi, color: Color(0xFFFFB74D)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أقرب سيارة إسعاف',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'متوقعة خلال ~4 دقائق',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.white),
                      tooltip: 'فتح الخريطة',
                      onPressed: onOpenMaps,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final int hospitalCount;
  final bool failed;

  _MapPainter({required this.hospitalCount, required this.failed});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final center = Offset(size.width / 2, size.height / 2);

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      roadPaint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      roadPaint,
    );

    final roadThin = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (int i = 1; i < 4; i++) {
      final o = Offset(size.width * 0.2 * i, size.height * 0.25 * i);
      canvas.drawLine(o, Offset(size.width - o.dx, size.height - o.dy), roadThin);
      canvas.drawLine(
        Offset(size.width - o.dx, o.dy),
        Offset(o.dx, size.height - o.dy),
        roadThin,
      );
    }

    final rng = math.Random(7);
    for (int i = 0; i < hospitalCount; i++) {
      final angle = (rng.nextDouble() * math.pi * 2);
      final radius = math.min(size.width, size.height) * (0.2 + rng.nextDouble() * 0.3);
      final pos = center +
          Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      _drawMarker(
        canvas,
        pos,
        color: failed ? const Color(0xFF5B7DB1) : const Color(0xFF1ACB58),
        kind: MarkerKind.hospital,
        size: 22,
      );
    }

    _drawMarker(
      canvas,
      center,
      color: const Color(0xFFE53935),
      kind: MarkerKind.patient,
      size: 30,
      pulse: true,
    );

    _drawMarker(
      canvas,
      center + const Offset(-60, -70),
      color: const Color(0xFFFFB74D),
      kind: MarkerKind.ambulance,
      size: 24,
    );
  }

  void _drawMarker(
    Canvas canvas,
    Offset center, {
    required Color color,
    required MarkerKind kind,
    required double size,
    bool pulse = false,
  }) {
    if (pulse) {
      final pulsePaint = Paint()..color = color.withValues(alpha: 0.15);
      canvas.drawCircle(center, size * 1.8, pulsePaint);
      canvas.drawCircle(center, size * 1.2, pulsePaint);
    }
    final halo = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 2), size / 2 + 1, halo);

    final bg = Paint()..color = color;
    canvas.drawCircle(center, size / 2, bg);

    final fg = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fgFill = Paint()..color = Colors.white;

    switch (kind) {
      case MarkerKind.hospital:
        final w = size * 0.35;
        final rect = Rect.fromCenter(
          center: center,
          width: w,
          height: w,
        );
        canvas.drawRect(rect, fgFill);
        canvas.drawRect(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      case MarkerKind.patient:
        canvas.drawCircle(center, size * 0.18, fgFill);
        canvas.drawCircle(center, size * 0.18, fg);
      case MarkerKind.ambulance:
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: size * 0.7,
            height: size * 0.3,
          ),
          fgFill,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: size * 0.7,
            height: size * 0.3,
          ),
          fg,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.hospitalCount != hospitalCount ||
      oldDelegate.failed != failed;
}

enum MarkerKind { hospital, patient, ambulance }
