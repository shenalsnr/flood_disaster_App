import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'battery_saving_nav_screen.dart';

// ---------------------------------------------------------------------------
// SafeRoutingMapScreen — Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// Displays an OSM map centred on Ratnapura, Sri Lanka with:
//   • A marker for the user's mock current location
//   • A marker for the nearest safe zone shelter
//   • A polyline showing the safe walking route
//
// Firebase / geolocator hook-up points:
//   • Replace _userLocation with a stream from geolocator (watchPosition)
//   • Replace _routePoints with decoded route from a Directions API response
//   • Replace _mapController.move() with live location updates
// ---------------------------------------------------------------------------

class SafeRoutingMapScreen extends StatefulWidget {
  const SafeRoutingMapScreen({super.key});

  @override
  State<SafeRoutingMapScreen> createState() => _SafeRoutingMapScreenState();
}

class _SafeRoutingMapScreenState extends State<SafeRoutingMapScreen> {
  // ── Mock GPS data ──────────────────────────────────────────────────────────
  // GEOLOCATOR HOOK: replace _userLocation with Geolocator.getPositionStream()
  final LatLng _userLocation = const LatLng(6.6828, 80.3992); // Ratnapura town

  // FIREBASE HOOK: load nearest shelter from Firestore (Component 3 provides
  // shelter data; query by proximity to _userLocation)
  final LatLng _safeZoneLocation = const LatLng(6.6950, 80.4050); // Mock shelter

  final String _safeZoneName = 'Rathnapura Central College';

  // Safe walking route polyline — replace with decoded directions API points
  late final List<LatLng> _routePoints;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Mock route: a simplified 4-point path from user to shelter
    _routePoints = [
      _userLocation,
      const LatLng(6.6855, 80.4005),
      const LatLng(6.6900, 80.4030),
      const LatLng(6.6925, 80.4042),
      _safeZoneLocation,
    ];
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _startNavigation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BatterySavingNavScreen(
          safeZoneName: _safeZoneName,
          // Pass live coords here when geolocator is integrated
          userLocation: _userLocation,
          destination: _safeZoneLocation,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safe Evacuation Route',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'OpenStreetMap — Offline Ready',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              key: const Key('map_recenter_btn'),
              icon: const Icon(Icons.my_location_rounded,
                  color: Color(0xFF00E676)),
              tooltip: 'Re-center on my location',
              onPressed: () => _mapController.move(_userLocation, 15),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────────────
          // OFFLINE CACHE HOOK: wrap TileLayer with a CachedTileProvider
          // (e.g. flutter_map_cache or flutter_map_tile_caching package)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 14.5,
              minZoom: 10,
              maxZoom: 18,
              backgroundColor: const Color(0xFF1A1A2E),
            ),
            children: [
              // OSM tile layer — swap provider for offline cache later
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flood_disaster',
                // OFFLINE HOOK: tileProvider: CachedTileProvider(),
              ),

              // Safe route polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: const Color(0xFF00E676),
                    strokeWidth: 5.0,
                    borderColor: const Color(0xFF00E676),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

              // Markers layer
              MarkerLayer(
                markers: [
                  // User's current location
                  Marker(
                    point: _userLocation,
                    width: 56,
                    height: 56,
                    child: _UserLocationMarker(),
                  ),

                  // Safe zone destination
                  Marker(
                    point: _safeZoneLocation,
                    width: 80,
                    height: 80,
                    alignment: Alignment.topCenter,
                    child: const _SafeZoneMarker(),
                  ),
                ],
              ),
            ],
          ),

          // ── Gradient overlay at top for AppBar readability ────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ── Legend pill ───────────────────────────────────────────────────
          Positioned(
            top: 105,
            left: 16,
            child: _MapLegend(),
          ),

          // ── Battery Saver Action Button ───────────────────────────────────
          Positioned(
            top: 105,
            right: 16,
            child: GestureDetector(
              onTap: _startNavigation,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.6),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.battery_saver_rounded,
                  color: Color(0xFF00E676),
                  size: 28,
                ),
              ),
            ),
          ),

          // ── Bottom action card ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomActionCard(
              safeZoneName: _safeZoneName,
              onStartNavigation: _startNavigation,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _UserLocationMarker extends StatefulWidget {
  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF40C4FF).withValues(alpha: 0.25),
          border: Border.all(color: const Color(0xFF40C4FF), width: 2.5),
        ),
        child: const Center(
          child: Icon(Icons.navigation_rounded,
              color: Color(0xFF40C4FF), size: 26),
        ),
      ),
    );
  }
}

class _SafeZoneMarker extends StatelessWidget {
  const _SafeZoneMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'SAFE ZONE',
            style: TextStyle(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        const Icon(Icons.location_pin, color: Color(0xFF00E676), size: 32),
      ],
    );
  }
}

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.navigation_rounded, color: Color(0xFF40C4FF), size: 14),
          SizedBox(width: 4),
          Text('You', style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(width: 12),
          Icon(Icons.location_pin, color: Color(0xFF00E676), size: 14),
          SizedBox(width: 4),
          Text('Safe Zone',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(width: 12),
          Icon(Icons.remove, color: Color(0xFF00E676), size: 14),
          SizedBox(width: 4),
          Text('Route', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BottomActionCard extends StatelessWidget {
  final String safeZoneName;
  final VoidCallback onStartNavigation;

  const _BottomActionCard({
    required this.safeZoneName,
    required this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Color(0xFF00E676), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearest Safe Zone',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    Text(
                      safeZoneName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  children: [
                    Text('~18 min',
                        style: TextStyle(
                            color: Color(0xFFFFD740),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text('walk',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Route stats row
          const Row(
            children: [
              _RouteStat(icon: Icons.straighten, label: '1.4 km', sub: 'distance'),
              SizedBox(width: 12),
              _RouteStat(
                  icon: Icons.water_drop_outlined,
                  label: 'Flood-free',
                  sub: 'path status'),
              SizedBox(width: 12),
              _RouteStat(
                  icon: Icons.people_alt_outlined,
                  label: '65% full',
                  sub: 'shelter cap.'),
            ],
          ),

          const SizedBox(height: 20),

          // START NAVIGATING button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              key: const Key('start_navigating_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: onStartNavigation,
              icon: const Icon(Icons.directions_walk_rounded, size: 28),
              label: const Text(
                'START NAVIGATING',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const _RouteStat(
      {required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            Text(sub,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
