import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

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

class _SafeRoutingMapScreenState extends State<SafeRoutingMapScreen>
    with TickerProviderStateMixin {
  // ── Mock GPS data ──────────────────────────────────────────────────────────
  // GEOLOCATOR HOOK: replace _userLocation with Geolocator.getPositionStream()
  final LatLng _userLocation = const LatLng(6.6828, 80.3992); // Ratnapura town

  // FIREBASE HOOK: load nearest shelter from Firestore (Component 3 provides
  // shelter data; query by proximity to _userLocation)
  final LatLng _safeZoneLocation = const LatLng(
    6.6950,
    80.4050,
  ); // Mock shelter

  final String _safeZoneName = 'Rathnapura Central College';

  // Safe walking route polyline — replace with decoded directions API points
  late final List<LatLng> _routePoints;

  final MapController _mapController = MapController();
  bool _isNavigating = false;

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

  void _animatedMapMove(
    LatLng destLocation,
    double destZoom, {
    double destRotation = 0.0,
  }) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );
    final rotationTween = Tween<double>(
      begin: _mapController.camera.rotation,
      end: destRotation,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
      if (rotationTween.begin != rotationTween.end) {
        _mapController.rotate(rotationTween.evaluate(animation));
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _navigateToBatterySaver() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BatterySavingNavScreen(
              safeZoneName: _safeZoneName,
              // Pass live coords here when geolocator is integrated
              userLocation: _userLocation,
              destination: _safeZoneLocation,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safe Evacuation Route',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              'OpenStreetMap — Offline Ready',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        // Re-center action removed from AppBar, replaced by floating FAB below
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
                userAgentPackageName: 'dev.lasha.flood_disaster',
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
                    width: 80,
                    height: 80,
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
          Positioned(top: 105, left: 16, child: _MapLegend()),

          // ── Battery Saver Action Button ───────────────────────────────────
          Positioned(
            top: 105,
            right: 16,
            child: GestureDetector(
              onTap: _navigateToBatterySaver,
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

          // ── My Location FAB (Google Maps Style) ───────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isNavigating ? 180 : 280,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location_fab',
              backgroundColor: Colors.white,
              elevation: 4,
              mini: true,
              onPressed: () {
                _animatedMapMove(
                  _userLocation,
                  _isNavigating ? 18.0 : 15.0,
                  destRotation: _isNavigating ? 45.0 : 0.0,
                );
              },
              child: const Icon(
                Icons.my_location_rounded,
                color: Colors.blueAccent,
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
              isNavigating: _isNavigating,
              onStartNavigation: () {
                setState(() {
                  _isNavigating = true;
                });
                // Fluid animation zoom & rotate for tracking mode
                _animatedMapMove(_userLocation, 18.0, destRotation: 45.0);
              },
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
    _anim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Directional cone (subtle gradient) pointing "up"
            Transform.translate(
              offset: const Offset(0, -20),
              child: ClipPath(
                clipper: _ConeClipper(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.blueAccent.withValues(alpha: 0.4),
                        Colors.blueAccent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Pulsing blue radius
            Container(
              width: 24 + (_anim.value * 24),
              height: 24 + (_anim.value * 24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(
                  alpha: 0.2 - (_anim.value * 0.2),
                ),
              ),
            ),
            // Solid blue dot with white border
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent,
                border: Border.all(color: Colors.white, width: 3.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(
      size.width / 2,
      size.height,
    ); // bottom center (origin of the dot)
    path.lineTo(0, 0); // top left
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.2,
      size.width,
      0,
    ); // curve across top
    path.lineTo(size.width / 2, size.height); // back to origin
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
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
          Text(
            'Safe Zone',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
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
  final bool isNavigating;
  final VoidCallback onStartNavigation;

  const _BottomActionCard({
    required this.safeZoneName,
    required this.isNavigating,
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
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
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
                child: const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFF00E676),
                  size: 24,
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  children: [
                    Text(
                      '~18 min',
                      style: TextStyle(
                        color: Color(0xFFFFD740),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'walk',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Route stats row
          const Row(
            children: [
              _RouteStat(
                icon: Icons.straighten,
                label: '1.4 km',
                sub: 'distance',
              ),
              SizedBox(width: 12),
              _RouteStat(
                icon: Icons.water_drop_outlined,
                label: 'Flood-free',
                sub: 'path status',
              ),
              SizedBox(width: 12),
              _RouteStat(
                icon: Icons.people_alt_outlined,
                label: '65% full',
                sub: 'shelter cap.',
              ),
            ],
          ),

          if (!isNavigating) ...[
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: onStartNavigation,
                icon: const Icon(Icons.directions_walk_rounded, size: 28),
                label: const Text(
                  'START NAVIGATING',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const _RouteStat({
    required this.icon,
    required this.label,
    required this.sub,
  });

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
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
