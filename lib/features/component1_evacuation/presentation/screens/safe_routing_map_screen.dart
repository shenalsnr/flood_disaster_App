import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../services/safe_zone_service.dart';
import 'battery_saving_nav_screen.dart';

// ---------------------------------------------------------------------------
// SafeRoutingMapScreen — Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// Shows the citizen the NEAREST OPEN safe zone on an OSM map.
//
// Safe zones come live from Firestore:
//   camps/{id}       added by the administrator (name, location, capacity)
//   campStatus/{id}  kept up to date by the camp leader (headcount, closed)
// When the nearest shelter becomes full or is closed by its camp leader, the
// route switches to the next nearest open shelter automatically.
//
// The citizen's own position comes from GPS (geolocator). If GPS is off or
// permission is refused, a demo position in Ratnapura town is used instead.
// ---------------------------------------------------------------------------

enum _LocIssue { none, serviceOff, denied, deniedForever }

class SafeRoutingMapScreen extends StatefulWidget {
  const SafeRoutingMapScreen({super.key});

  @override
  State<SafeRoutingMapScreen> createState() => _SafeRoutingMapScreenState();
}

class _SafeRoutingMapScreenState extends State<SafeRoutingMapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const LatLng _demoLocation = LatLng(6.6828, 80.3992); // Ratnapura town

  LatLng _userLocation = _demoLocation;
  bool _usingDemoLocation = true;

  List<SafeZone> _zones = const [];
  bool _loaded = false;
  String? _loadError;
  String? _targetId; // the shelter the route currently points to

  StreamSubscription<List<SafeZone>>? _zonesSub;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<ServiceStatus>? _serviceSub;

  // Location alert: shown when GPS is off or permission is missing, and closed
  // automatically as soon as the citizen turns location on.
  _LocIssue _locIssue = _LocIssue.none;
  bool _locating = false;
  bool _dialogOpen = false;
  bool _dismissedAlert = false;

  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _isNavigating = false;
  bool _fittedOnce = false;

  @override
  void initState() {
    super.initState();
    _zonesSub = SafeZoneService.instance.watch().listen((zones) {
      if (!mounted) return;
      _zones = zones;
      _loaded = true;
      _loadError = null;
      _recompute();
    }, onError: (Object e) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _loadError = e.toString();
      });
    });
    WidgetsBinding.instance.addObserver(this);
    _startLocation();
    try {
      // Fires when the citizen switches the phone's location on or off.
      _serviceSub = Geolocator.getServiceStatusStream().listen((status) {
        if (status == ServiceStatus.enabled) {
          _startLocation();
        } else {
          _positionSub?.cancel();
          _positionSub = null;
          _setIssue(_LocIssue.serviceOff);
        }
      }, onError: (Object _) {});
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone's settings: check again (permission may be given).
    if (state == AppLifecycleState.resumed && _locIssue != _LocIssue.none) {
      _startLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceSub?.cancel();
    _zonesSub?.cancel();
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── GPS ────────────────────────────────────────────────────────────────────
  Future<void> _startLocation() async {
    if (_locating) return;
    _locating = true;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _setIssue(_LocIssue.serviceOff);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        _setIssue(_LocIssue.denied);
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        _setIssue(_LocIssue.deniedForever);
        return;
      }
      _setIssue(_LocIssue.none); // closes the alert if it is showing
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 20));
      _onPosition(pos);
      await _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 25,
        ),
      ).listen(_onPosition, onError: (Object _) {});
    } catch (_) {
      // No GPS fix yet: the demo location stays until one arrives.
    } finally {
      _locating = false;
    }
  }

  void _setIssue(_LocIssue issue) {
    if (!mounted) return;
    setState(() => _locIssue = issue);
    if (issue == _LocIssue.none) {
      _dismissedAlert = false;
      if (_dialogOpen) {
        _dialogOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    } else if (!_dialogOpen && !_dismissedAlert) {
      _showLocationAlert();
    }
  }

  Future<void> _showLocationAlert() async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;
    final issue = _locIssue;
    final String text;
    final String button;
    switch (issue) {
      case _LocIssue.serviceOff:
        text = 'Turn on your phone\'s location so we can find the nearest '
            'safe zone to you.';
        button = 'TURN ON LOCATION';
        break;
      case _LocIssue.denied:
        text = 'Allow this app to use your location so we can find the '
            'nearest safe zone to you.';
        button = 'ALLOW LOCATION';
        break;
      case _LocIssue.deniedForever:
        text = 'Location permission is blocked. Open the app settings and '
            'allow Location so we can find the nearest safe zone to you.';
        button = 'OPEN SETTINGS';
        break;
      case _LocIssue.none:
        _dialogOpen = false;
        return;
    }
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_off_outlined, color: Color(0xFFFF9F0A)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Location is off',
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(text, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'later'),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, 'go'),
            child: Text(button,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    // null = the alert was closed by itself because location came on.
    final closedByUser = action != null;
    _dialogOpen = false;
    if (!mounted || !closedByUser) return;
    _dismissedAlert = true; // do not nag again; the chip can reopen it
    if (action == 'go') {
      switch (issue) {
        case _LocIssue.serviceOff:
          await Geolocator.openLocationSettings();
          break;
        case _LocIssue.denied:
          _startLocation();
          break;
        case _LocIssue.deniedForever:
          await Geolocator.openAppSettings();
          break;
        case _LocIssue.none:
          break;
      }
    }
  }

  void _onPosition(Position p) {
    if (!mounted) return;
    _userLocation = LatLng(p.latitude, p.longitude);
    _usingDemoLocation = false;
    _recompute();
  }

  // ── Nearest open shelter ───────────────────────────────────────────────────
  SafeZone? _zoneById(String? id) {
    if (id == null) return null;
    for (final z in _zones) {
      if (z.id == id) return z;
    }
    return null;
  }

  double _distanceTo(SafeZone z) =>
      SafeZoneService.distanceKm(_userLocation, z.point);

  void _recompute() {
    final open = _zones.where((z) => z.hasLocation && z.isOpen).toList()
      ..sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    final next = open.isEmpty ? null : open.first;

    // Tell the citizen when the shelter they were heading to is no longer
    // available and the route has moved to another one.
    final previous = _zoneById(_targetId);
    String? notice;
    if (_targetId != null && next?.id != _targetId) {
      if (previous == null) {
        notice = 'The previous safe zone is no longer available.';
      } else if (!previous.isOpen) {
        notice = '${previous.name} is now ${previous.stateLabel.toLowerCase()}.';
      }
      if (notice != null) {
        notice = next == null
            ? '$notice No other open shelter right now.'
            : '$notice Rerouting to ${next.name}.';
      }
    }

    final changed = next?.id != _targetId;
    setState(() => _targetId = next?.id);

    if (notice != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(notice),
          backgroundColor: const Color(0xFFFF9F0A),
          duration: const Duration(seconds: 8),
          showCloseIcon: true,
        ));
    }
    if ((changed || !_fittedOnce) && next != null && !_isNavigating) {
      _fitRoute(next);
    }
  }

  void _fitRoute(SafeZone target) {
    if (!_mapReady) return;
    _fittedOnce = true;
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_userLocation, target.point]),
          padding: const EdgeInsets.fromLTRB(60, 170, 60, 360),
          maxZoom: 16.5,
        ),
      );
    } catch (_) {
      // Map not ready yet; the next update will fit it.
    }
  }

  Future<void> _callDmc() async {
    final uri = Uri(scheme: 'tel', path: '117');
    try {
      await launchUrl(uri);
    } catch (_) {}
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

  void _navigateToBatterySaver(SafeZone target) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BatterySavingNavScreen(
              safeZoneName: target.name,
              userLocation: _userLocation,
              destination: target.point,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Other shelters on the map (full / closed / farther open ones) ──────────
  List<Marker> _otherZoneMarkers(SafeZone? target) {
    final markers = <Marker>[];
    for (final z in _zones) {
      if (!z.hasLocation || z.id == target?.id) continue;
      final color = z.state == SafeZoneState.open
          ? const Color(0xFF00E676).withValues(alpha: 0.6)
          : z.state == SafeZoneState.full
              ? const Color(0xFFFF9F0A)
              : const Color(0xFFFF5252);
      markers.add(Marker(
        point: z.point,
        width: 44,
        height: 44,
        alignment: Alignment.topCenter,
        child: Tooltip(
          message: '${z.name} (${z.stateLabel})',
          child: Icon(Icons.location_pin, color: color, size: 30),
        ),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final target = _zoneById(_targetId);
    final distanceKm = target == null ? 0.0 : _distanceTo(target);
    // Walking pace about 4.5 km/h.
    final walkMinutes = (distanceKm / 4.5 * 60).ceil().clamp(1, 9999).toInt();
    final distanceText = distanceKm < 1
        ? '${(distanceKm * 1000).round()} m'
        : '${distanceKm.toStringAsFixed(1)} km';

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
              'OpenStreetMap — Live shelter status',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 14.5,
              minZoom: 10,
              maxZoom: 18,
              backgroundColor: const Color(0xFF1A1A2E),
              onMapReady: () {
                _mapReady = true;
                final t = _zoneById(_targetId);
                if (t != null) _fitRoute(t);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.lasha.flood_disaster',
              ),

              // Route to the nearest open shelter (straight line)
              if (target != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_userLocation, target.point],
                      color: const Color(0xFF00E676),
                      strokeWidth: 5.0,
                      borderColor: const Color(0xFF00E676),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  ..._otherZoneMarkers(target),

                  // User's current location
                  Marker(
                    point: _userLocation,
                    width: 80,
                    height: 80,
                    child: _UserLocationMarker(),
                  ),

                  // Nearest open safe zone
                  if (target != null)
                    Marker(
                      point: target.point,
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

          if (_usingDemoLocation || _locIssue != _LocIssue.none)
            Positioned(
              top: 150,
              left: 16,
              child: GestureDetector(
                onTap: _locIssue == _LocIssue.none
                    ? null
                    : () {
                        _dismissedAlert = false;
                        _showLocationAlert();
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF9F0A)),
                  ),
                  child: Text(
                    _locIssue == _LocIssue.none
                        ? 'Finding your location...'
                        : 'Location is off - tap to turn on (demo location shown)',
                    style:
                        const TextStyle(color: Color(0xFFFF9F0A), fontSize: 11),
                  ),
                ),
              ),
            ),

          // ── Battery Saver Action Button ───────────────────────────────────
          Positioned(
            top: 105,
            right: 16,
            child: GestureDetector(
              onTap: target == null ? null : () => _navigateToBatterySaver(target),
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
            bottom: _isNavigating ? 180 : 300,
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
              loading: !_loaded,
              errorText: _loadError,
              safeZoneName: target?.name,
              walkMinutes: walkMinutes,
              distanceText: distanceText,
              fillText: target == null ? '-' : '${target.fillPercent}% full',
              hasTarget: target != null,
              isNavigating: _isNavigating,
              onCallDmc: _callDmc,
              onStartNavigation: () {
                if (target == null) return;
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
  final bool loading;
  final String? errorText;
  final String? safeZoneName;
  final int walkMinutes;
  final String distanceText;
  final String fillText;
  final bool hasTarget;
  final bool isNavigating;
  final VoidCallback onStartNavigation;
  final VoidCallback onCallDmc;

  const _BottomActionCard({
    required this.loading,
    required this.errorText,
    required this.safeZoneName,
    required this.walkMinutes,
    required this.distanceText,
    required this.fillText,
    required this.hasTarget,
    required this.isNavigating,
    required this.onStartNavigation,
    required this.onCallDmc,
  });

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;
    if (loading) {
      title = 'Looking for safe zones...';
      subtitle = 'Nearest Safe Zone';
    } else if (errorText != null) {
      title = 'Could not load safe zones';
      subtitle = 'Check your internet connection';
    } else if (!hasTarget) {
      title = 'No open safe zone right now';
      subtitle = 'All shelters are full, closed or not set up yet';
    } else {
      title = safeZoneName ?? '';
      subtitle = 'Nearest Safe Zone';
    }

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
                  color: (hasTarget
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF9F0A))
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasTarget ? Icons.shield_rounded : Icons.warning_amber_rounded,
                  color: hasTarget
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFF9F0A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasTarget)
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
                  child: Column(
                    children: [
                      Text(
                        '~$walkMinutes min',
                        style: const TextStyle(
                          color: Color(0xFFFFD740),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'walk',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (hasTarget) ...[
            const SizedBox(height: 16),

            // Route stats row
            Row(
              children: [
                _RouteStat(
                  icon: Icons.straighten,
                  label: distanceText,
                  sub: 'distance',
                ),
                const SizedBox(width: 12),
                const _RouteStat(
                  icon: Icons.check_circle_outline,
                  label: 'Open',
                  sub: 'shelter status',
                ),
                const SizedBox(width: 12),
                _RouteStat(
                  icon: Icons.people_alt_outlined,
                  label: fillText,
                  sub: 'shelter cap.',
                ),
              ],
            ),
          ],

          if (!loading && errorText == null && !hasTarget) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF9F0A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onCallDmc,
                icon: const Icon(Icons.phone_in_talk_outlined,
                    color: Color(0xFFFF9F0A)),
                label: const Text(
                  'CALL DMC HOTLINE 117',
                  style: TextStyle(
                    color: Color(0xFFFF9F0A),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],

          if (!isNavigating && hasTarget) ...[
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
