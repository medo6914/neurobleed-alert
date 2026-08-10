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
const _kDarkTileUrl =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

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
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, t),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        _buildMap(),
                        if (_route != null) _buildEtaBanner(t),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: _buildHospitalCard(t),
                        ),
                      ],
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
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            t.t('nearest_hospitals'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.navigation_outlined, color: Colors.white, size: 24),
            onPressed: _locateUser,
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
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
          urlTemplate: _kDarkTileUrl,
          subdomains: const ['a', 'b', 'c'],
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
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'H',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
            Marker(
              point: _userLocation,
              width: 32,
              height: 32,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEtaBanner(AppLocalizations t) {
    final durationS = _routeDurationS;
    final distanceM = _routeDistanceM;
    final minutes = durationS != null ? (durationS / 60).ceil() : null;
    final distanceKm = distanceM != null
        ? distanceM >= 1000
            ? '${(distanceM / 1000).toStringAsFixed(1)} ${t.t('unit_km')}'
            : '${distanceM.round()} ${t.t('unit_m')}'
        : null;

    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions, color: Color(0xFF2196F3), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.t('direction_to_nearest_hospital'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
                      fontSize: 12,
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
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCard(AppLocalizations t) {
    final hospital = _nearestHospital();
    if (hospital == null) return const SizedBox.shrink();

    final name = hospital['name'] as String? ?? t.t('hospital_fallback');
    final distance = (hospital['distance_km'] as num?)?.toDouble() ?? 2.3;
    final duration = _routeDurationS != null ? (_routeDurationS! / 60).ceil() : 8;
    final phone = hospital['phone'] as String?;

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFF2196F3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
              if (phone != null)
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _routeToNearest(),
              icon: const Icon(Icons.info_outline, color: Color(0xFF2196F3)),
              label: Text(
                t.t('more_details'),
                style: const TextStyle(
                  color: Color(0xFF2196F3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF2196F3)),
                ),
              ),
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
}
