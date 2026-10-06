import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'safe_arrival_checkin_screen.dart';

// ---------------------------------------------------------------------------
// BatterySavingNavScreen — Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// Activates when the citizen is actively walking to the shelter.
// TRUE BLACK background — no map tiles = maximum battery saving.
//
// Firebase / geolocator hook-up points:
//   • Replace the mock _distanceKm countdown with a StreamSubscription on
//     Geolocator.getPositionStream() and compute distance with latlong2's
//     Distance class: Distance().as(LengthUnit.Meter, currentPos, destination)
//   • Replace _bearing with Geolocator.bearingBetween(lat1,lng1,lat2,lng2)
//     to rotate the directional arrow to the real bearing
// ---------------------------------------------------------------------------

class BatterySavingNavScreen extends StatefulWidget {
  final String safeZoneName;

  // GEOLOCATOR HOOK: receive live coords from parent/provider
  final LatLng userLocation;
  final LatLng destination;

  const BatterySavingNavScreen({
    super.key,
    required this.safeZoneName,
    required this.userLocation,
    required this.destination,
  });

  @override
  State<BatterySavingNavScreen> createState() => _BatterySavingNavScreenState();
}

class _BatterySavingNavScreenState extends State<BatterySavingNavScreen>
    with TickerProviderStateMixin {
  // ── Mock navigation state ───────────────────────────────────────────────
  // GEOLOCATOR HOOK: replace with computed distance from live GPS stream
  double _distanceKm = 1.4;

  // GEOLOCATOR HOOK: replace with Geolocator.bearingBetween(...)
  // 0° = North, 90° = East, 180° = South, 270° = West
  final double _bearing = 42.0; // mock bearing — northeast toward high ground

  // Mock countdown timer — remove when live GPS is wired
  Timer? _mockTimer;
  int _etaSeconds = 18 * 60; // 18 minutes

  // Animations
  late AnimationController _arrowPulseCtrl;
  late Animation<double> _arrowPulse;
  late AnimationController _arrowRotateCtrl;
  late Animation<double> _arrowRotate;

  @override
  void initState() {
    super.initState();

    // Force black status bar to blend with the true-black screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

    // Arrow pulse animation
    _arrowPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _arrowPulse = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _arrowPulseCtrl, curve: Curves.easeInOut),
    );

    // Arrow rotation entry animation (spins in from 0 to target bearing)
    _arrowRotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _arrowRotate = Tween<double>(
      begin: 0.0,
      end: _bearing * (3.14159265 / 180.0), // degrees → radians
    ).animate(
      CurvedAnimation(parent: _arrowRotateCtrl, curve: Curves.elasticOut),
    );
    _arrowRotateCtrl.forward();

    // Mock countdown — REMOVE THIS BLOCK when geolocator provides live updates
    _startMockCountdown();
  }

  void _startMockCountdown() {
    _mockTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _distanceKm = (_distanceKm - 0.01).clamp(0.0, 10.0);
        _etaSeconds = (_etaSeconds - 3).clamp(0, 99999);
        if (_distanceKm <= 0.01) timer.cancel();
      });
    });
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _arrowPulseCtrl.dispose();
    _arrowRotateCtrl.dispose();
    // Restore status bar style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    super.dispose();
  }

  String get _formattedDistance => '${_distanceKm.toStringAsFixed(1)} km';

  String get _formattedEta {
    final min = _etaSeconds ~/ 60;
    final sec = _etaSeconds % 60;
    if (min > 0) return '~${min}m ${sec.toString().padLeft(2, '0')}s';
    return '${sec}s';
  }

  void _onArrived() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SafeArrivalCheckInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TRUE BLACK — no map tile rendering = significant battery saving
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────────
            _TopBar(safeZoneName: widget.safeZoneName),

            // ── Distance display ───────────────────────────────────────────
            _DistanceDisplay(
              distanceText: _formattedDistance,
              etaText: _formattedEta,
            ),

            // ── Directional Arrow ──────────────────────────────────────────
            Expanded(
              child: Center(
                child: ScaleTransition(
                  scale: _arrowPulse,
                  child: AnimatedBuilder(
                    animation: _arrowRotate,
                    builder: (_, _) => _DirectionalArrow(
                      bearingRadians: _arrowRotate.value,
                    ),
                  ),
                ),
              ),
            ),

            // ── Waypoint breadcrumbs ────────────────────────────────────────
            _WaypointRow(distanceKm: _distanceKm),

            const SizedBox(height: 16),

            // ── I've Arrived button ────────────────────────────────────────
            _ArrivedButton(onPressed: _onArrived),

            const SizedBox(height: 16),

            // ── Battery save notice ────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.battery_saver_outlined,
                      color: Colors.white24, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'Map hidden — Battery-save mode active',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final String safeZoneName;

  const _TopBar({required this.safeZoneName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white54, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Navigating to',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                Text(
                  safeZoneName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // ── Map Toggle Button ──────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.map_outlined, color: Colors.white70, size: 20),
            ),
          ),
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                _PulsingDot(),
                SizedBox(width: 5),
                Text('LIVE',
                    style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
            color: Color(0xFF00E676), shape: BoxShape.circle),
      ),
    );
  }
}

class _DistanceDisplay extends StatelessWidget {
  final String distanceText;
  final String etaText;

  const _DistanceDisplay(
      {required this.distanceText, required this.etaText});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Distance
          Expanded(
            child: Column(
              children: [
                Text(
                  distanceText,
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'to Safe Zone',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 48, color: Colors.white12),

          // ETA
          Expanded(
            child: Column(
              children: [
                Text(
                  etaText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'estimated',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionalArrow extends StatelessWidget {
  /// Bearing in radians. 0 = North (up), π/2 = East (right).
  /// GEOLOCATOR HOOK: set this to Geolocator.bearingBetween(...) converted
  /// to radians.
  final double bearingRadians;

  const _DirectionalArrow({required this.bearingRadians});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'HEAD THIS WAY',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 24),
        Transform.rotate(
          angle: bearingRadians,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E676).withValues(alpha: 0.07),
              border: Border.all(
                  color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  width: 2),
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Color(0xFF00E676),
              size: 110,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Compass rose labels
        const SizedBox(
          width: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('W', style: TextStyle(color: Colors.white24, fontSize: 13)),
              Text('N',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              Text('E', style: TextStyle(color: Colors.white24, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: const Text(
            '↑ Proceed to higher ground',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _WaypointRow extends StatelessWidget {
  final double distanceKm;

  const _WaypointRow({required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    // Simulate 3 waypoints: first completed if < 1.0km, second if < 0.5km
    final step1Done = distanceKm < 1.2;
    final step2Done = distanceKm < 0.7;
    final step3Done = distanceKm < 0.2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _WaypointDot(label: 'Main St', done: step1Done),
          _WaypointLine(done: step1Done),
          _WaypointDot(label: 'Bridge', done: step2Done),
          _WaypointLine(done: step2Done),
          _WaypointDot(label: 'Shelter', done: step3Done, isLast: true),
        ],
      ),
    );
  }
}

class _WaypointDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool isLast;

  const _WaypointDot(
      {required this.label, required this.done, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? const Color(0xFF00E676) : const Color(0xFF222222),
            border: Border.all(
              color: done
                  ? const Color(0xFF00E676)
                  : (isLast
                      ? const Color(0xFF00E676).withValues(alpha: 0.4)
                      : Colors.white24),
              width: 2,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.black)
              : isLast
                  ? const Icon(Icons.shield_rounded,
                      size: 10, color: Color(0xFF00E676))
                  : null,
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: done ? const Color(0xFF00E676) : Colors.white38,
                fontSize: 10,
                fontWeight:
                    done ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _WaypointLine extends StatelessWidget {
  final bool done;

  const _WaypointLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: done
            ? const Color(0xFF00E676)
            : Colors.white12,
      ),
    );
  }
}

class _ArrivedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ArrivedButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 68,
        child: ElevatedButton.icon(
          key: const Key('arrived_btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E676),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: onPressed,
          icon: const Icon(Icons.verified_user_rounded, size: 30),
          label: const Text(
            "I'VE ARRIVED",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
