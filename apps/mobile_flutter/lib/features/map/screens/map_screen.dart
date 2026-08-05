import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:design_system/design_system.dart';
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
const _kTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

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
  String _searchQuery = '';
  LatLng? _searchResult;

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
    setState(() {
      _loading = true;
    });
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

  Future<void> _search() async {
    final q = _searchQuery.trim();
    if (q.isEmpty) return;
    try {
      final api = ref.read(apiClientProvider);
      final response = await api
          .get('/v1/maps/geocode', queryParameters: {'q': q, 'limit': 1});
      final data = response.data;
      if (data is List && data.isNotEmpty) {
        final place = data.first as Map<String, dynamic>;
        final result = LatLng(
          (place['lat'] as num).toDouble(),
          (place['lng'] as num).toDouble(),
        );
        setState(() {
          _searchResult = result;
          _mapController.move(result, 15);
        });
      }
    } catch (_) {}
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

  Future<void> _openOSM() async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${_userLocation.latitude}&mlon=${_userLocation.longitude}#map=15/${_userLocation.latitude}/${_userLocation.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخريطة - أقرب المستشفيات'),
        actions: [
          IconButton(
            icon:
                Icon(_locating ? Icons.my_location : Icons.location_searching),
            tooltip: 'موقعي',
            onPressed: _locateUser,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: AppLoading())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => _searchQuery = v,
                          onSubmitted: (_) => _search(),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن مستشفى أو مكان...',
                            isDense: true,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.directions,
                            color: NeuroColors.success),
                        tooltip: 'الاتجاه إلى أقرب مستشفى',
                        onPressed: _routeToNearest,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _userLocation,
                          initialZoom: 13,
                          onTap: (_, __) => setState(() {
                            _route = null;
                            _routeDistanceM = null;
                            _routeDurationS = null;
                            _searchResult = null;
                          }),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: _kTileUrl,
                            userAgentPackageName: 'com.neurobleed.alert',
                          ),
                          if (_route != null)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _route!,
                                  strokeWidth: 5,
                                  color: NeuroColors.success,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              for (final h in _hospitals)
                                if (_hospitalLatLng(h) != null)
                                  Marker(
                                    point: _hospitalLatLng(h)!,
                                    width: 34,
                                    height: 34,
                                    child: GestureDetector(
                                      onTap: () => _showHospitalSheet(h),
                                      child: const Icon(
                                        Icons.local_hospital,
                                        color: NeuroColors.success,
                                        size: 32,
                                        shadows: [
                                          Shadow(
                                            color: NeuroColors.bgPrimary,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              if (_searchResult != null)
                                Marker(
                                  point: _searchResult!,
                                  width: 30,
                                  height: 30,
                                  child: const Icon(
                                    Icons.place,
                                    color: NeuroColors.info,
                                    size: 30,
                                  ),
                                ),
                              Marker(
                                point: _userLocation,
                                width: 32,
                                height: 32,
                                child: const Icon(
                                  Icons.navigation,
                                  color: NeuroColors.critical,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_locating)
                        const Positioned(
                          top: 12,
                          left: 12,
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('جاري تحديد الموقع...',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_route != null)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: _buildEtaBanner(),
                        ),
                    ],
                  ),
                ),
                _buildBottomCards(),
              ],
            ),
    );
  }

  Widget _buildEtaBanner() {
    final durationS = _routeDurationS;
    final distanceM = _routeDistanceM;
    final minutes = durationS != null ? (durationS / 60).ceil() : null;
    final distanceKm = distanceM != null
        ? distanceM >= 1000
            ? '${(distanceM / 1000).toStringAsFixed(1)} كم'
            : '${distanceM.round()} م'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NeuroColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeuroColors.success.withValues(alpha: 0.4)),
        boxShadow: const [NeuroShadows.elevated],
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency, color: NeuroColors.critical, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الوصول المتوقع للمستشفى',
                  style: NeuroTypography.caption?.copyWith(
                    color: NeuroColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  minutes != null
                      ? 'خلال ${minutes == 1 ? 'دقيقة واحدة' : '$minutes دقائق'}'
                      : 'جاري حساب وقت الوصول...',
                  style: NeuroTypography.h3?.copyWith(
                    color: NeuroColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (distanceKm != null)
            Text(
              distanceKm,
              style: NeuroTypography.caption?.copyWith(
                color: NeuroColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  LatLng? _hospitalLatLng(Map<String, dynamic> h) {
    final lat =
        (h['latitude'] as num?)?.toDouble() ?? (h['lat'] as num?)?.toDouble();
    final lng =
        (h['longitude'] as num?)?.toDouble() ?? (h['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  void _showHospitalSheet(Map<String, dynamic> h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeuroColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital, color: NeuroColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    h['name'] as String? ?? 'مستشفى',
                    style: const TextStyle(
                      color: NeuroColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (h['address'] != null) ...[
              const SizedBox(height: 8),
              Text(
                h['address'] as String,
                style:
                    const TextStyle(color: NeuroColors.textBody, fontSize: 13),
              ),
            ],
            if (h['phone'] != null) ...[
              const SizedBox(height: 4),
              Text(
                h['phone'] as String,
                style: const TextStyle(
                    color: NeuroColors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _routeToHospital(h),
                icon: const Icon(Icons.directions),
                label: const Text('الاتجاه'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _routeToHospital(Map<String, dynamic> h) async {
    final lat =
        (h['latitude'] as num?)?.toDouble() ?? (h['lat'] as num?)?.toDouble();
    final lng =
        (h['longitude'] as num?)?.toDouble() ?? (h['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    Navigator.of(context).pop();
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
        setState(() {
          _route = coords
              .map((c) =>
                  LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          _routeDistanceM = (data['distance_m'] as num?)?.toDouble();
          _routeDurationS = (data['duration_s'] as num?)?.toInt();
          _mapController.move(LatLng(lat, lng), 14);
        });
      }
    } catch (_) {}
  }

  Widget _buildBottomCards() {
    final hospitals = _hospitals;
    final display = hospitals.isEmpty
        ? const [
            {
              'name': 'مستشفى جامعة القاهرة',
              'latitude': 30.0286,
              'longitude': 31.2278
            },
            {
              'name': 'مستشفى المنيل التخصصي',
              'latitude': 30.0339,
              'longitude': 31.2304
            },
            {
              'name': 'مستشفى الدمرداش',
              'latitude': 30.0827,
              'longitude': 31.2904
            },
          ]
        : hospitals;

    final nearest = display.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: NeuroColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'أقرب المستشفيات',
                style: TextStyle(
                  color: NeuroColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined,
                    color: NeuroColors.textPrimary),
                tooltip: 'فتح OpenStreetMap',
                onPressed: _openOSM,
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
    final lat = (hospital['latitude'] as num?)?.toDouble() ??
        (hospital['lat'] as num?)?.toDouble();
    final lng = (hospital['longitude'] as num?)?.toDouble() ??
        (hospital['lng'] as num?)?.toDouble();
    final distance = (hospital['distance_km'] as num?)?.toDouble() ?? 2.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: NeuroColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital, color: NeuroColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: NeuroColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (lat != null && lng != null)
            Text(
              '${distance.toStringAsFixed(1)} كم',
              style: const TextStyle(
                color: NeuroColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
