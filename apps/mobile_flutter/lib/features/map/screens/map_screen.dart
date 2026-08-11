import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:core/core.dart';

final mapHospitalsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
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
  final MapController _mapController = MapController();
  LatLng _userLocation = const LatLng(_kDefaultLat, _kDefaultLng);
  bool _loading = true;
  bool _locating = false;
  List<Map<String, dynamic>> _hospitals = [];
  List<LatLng>? _route;
  double? _routeDistanceM;
  int? _routeDurationS;

  @override
  void initState() {
    super.initState();
    _load();
    _locateUser();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/v1/analytics/hospitals');
      final data = response.data;
      final hospitals = data is Map && data['hospitals'] is List
          ? (data['hospitals'] as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      final nearby = await _nearbyHospitals(api);
      setState(() {
        _hospitals = hospitals.isEmpty ? nearby : hospitals;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _hospitals = [];
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _nearbyHospitals(dynamic api) async {
    try {
      final response =
          await api.get('/v1/maps/hospitals/nearby', queryParameters: {
        'lat': _userLocation.latitude,
        'lng': _userLocation.longitude,
        'radius_m': 10000,
        'limit': 10,
      });
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
    } catch (_) {}
    return [];
  }

  Future<void> _locateUser() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final asked = await Geolocator.requestPermission();
        if (asked == LocationPermission.denied ||
            asked == LocationPermission.deniedForever) {
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _mapController.move(_userLocation, 14);
      });
    } catch (_) {
      // Offline/simulator: keep default Cairo location.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _routeToNearest() async {
    final hospital = _nearestHospital();
    if (hospital == null) return;
    final lat = (hospital['latitude'] as num?)?.toDouble() ??
        (hospital['lat'] as num?)?.toDouble();
    final lng = (hospital['longitude'] as num?)?.toDouble() ??
        (hospital['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/v1/maps/route', queryParameters: {
        'from_lat': _userLocation.latitude,
        'from_lng': _userLocation.longitude,
        'to_lat': lat,
        'to_lng': lng,
      });
      final data = response.data;
      if (data is Map && data['geometry'] is Map) {
        final coords = (data['geometry'] as Map)['coordinates'] as List;
        final points = coords
            .map((c) =>
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        setState(() {
          _route = points;
          _routeDistanceM = (data['distance_m'] as num?)?.toDouble();
          _routeDurationS = (data['duration_s'] as num?)?.toInt();
        });
      }
    } catch (_) {}
  }

  Map<String, dynamic>? _nearestHospital() {
    if (_hospitals.isEmpty) return null;
    double best = double.infinity;
    Map<String, dynamic>? nearest;
    for (final h in _hospitals) {
      final lat =
          (h['latitude'] as num?)?.toDouble() ?? (h['lat'] as num?)?.toDouble();
      final lng = (h['longitude'] as num?)?.toDouble() ??
          (h['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final d = const Distance().distance(_userLocation, LatLng(lat, lng));
      if (d < best) {
        best = d;
        nearest = h;
      }
    }
    return nearest;
  }

  LatLng? _hospitalLatLng(Map<String, dynamic> h) {
    final lat =
        (h['latitude'] as num?)?.toDouble() ?? (h['lat'] as num?)?.toDouble();
    final lng =
        (h['longitude'] as num?)?.toDouble() ?? (h['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, t),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF2196F3)))
                  : Stack(
                      children: [
                        _buildMap(),
                        _buildMapControls(),
                        if (_route != null) _buildRouteBanner(t),
                      ],
                    ),
            ),
            _buildHospitalInfoCard(t),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations t) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            t.t('nearest_hospitals'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation,
            initialZoom: 13,
            onTap: (_, __) => setState(() {
              _route = null;
              _routeDistanceM = null;
              _routeDurationS = null;
            }),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.neurobleed.alert',
            ),
            if (_route != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _route!,
                    strokeWidth: 5,
                    color: const Color(0xFF2196F3),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final h in _hospitals)
                  if (_hospitalLatLng(h) != null)
                    Marker(
                      point: _hospitalLatLng(h)!,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'H',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                Marker(
                  point: _userLocation,
                  width: 36,
                  height: 44,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'A',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      CustomPaint(
                        size: const Size(12, 8),
                        painter: _TrianglePainter(
                          color: const Color(0xFFFF3B30),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 24,
      top: 80,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.my_location,
            onTap: _locateUser,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.add,
            onTap: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(
                  _mapController.camera.center, currentZoom + 1);
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.remove,
            onTap: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(
                  _mapController.camera.center, currentZoom - 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F35),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildRouteBanner(AppLocalizations t) {
    final durationS = _routeDurationS;
    final distanceM = _routeDistanceM;
    final minutes = durationS != null ? (durationS / 60).ceil() : null;
    final distanceKm = distanceM != null
        ? distanceM >= 1000
            ? '${(distanceM / 1000).toStringAsFixed(1)} ${t.t('unit_km')}'
            : '${distanceM.round()} ${t.t('unit_m')}'
        : null;

    return Positioned(
      top: 8,
      left: 24,
      right: 70,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F35),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions, color: Color(0xFF2196F3), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.t('direction_to_nearest_hospital'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    minutes != null
                        ? minutes == 1
                            ? t.t('eta_one_minute')
                            : t.tWithParams('eta_minutes', {'minutes': '$minutes'})
                        : t.t('calculating_eta'),
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (distanceKm != null)
              Text(
                distanceKm,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalInfoCard(AppLocalizations t) {
    final hospital = _nearestHospital();
    if (hospital == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_hospital_outlined,
                  color: Colors.white.withValues(alpha: 0.3), size: 48),
              const SizedBox(height: 12),
              Text(
                t.t('no_hospitals_found'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final name = hospital['name'] as String? ?? t.t('hospital_fallback');
    final distance = (hospital['distance_km'] as num?)?.toDouble() ?? 2.3;
    final duration =
        _routeDurationS != null ? (_routeDurationS! / 60).ceil() : 8;
    final phone = hospital['phone'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFF2196F3),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Color(0xFF34C759), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} ${t.t('unit_km')}',
                          style: const TextStyle(
                            color: Color(0xFF34C759),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time,
                            color: Color(0xFF34C759), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$duration ${t.t('tab_month')}',
                          style: const TextStyle(
                            color: Color(0xFF34C759),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final phoneNum =
                      phone ?? hospital['phone_number'] as String?;
                  if (phoneNum != null) {
                    final uri = Uri.parse('tel:$phoneNum');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _routeToNearest(),
              icon: const Icon(Icons.info_outline, color: Colors.white),
              label: Text(
                t.t('more_details'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
