import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../core/responsive/screen_fit.dart';
import '../../../../core/services/notification_service.dart';
import '../../../component4_control_center/presentation/controllers/responder_controller.dart';
import '../../services/citizen_firestore_service.dart';
import '../../services/safe_zone_service.dart';
import 'citizen_dashboard_screen.dart';

enum _CheckInStatus { idle, loading, confirmed }

class SafeArrivalCheckInScreen extends StatefulWidget {
  const SafeArrivalCheckInScreen({super.key});

  @override
  State<SafeArrivalCheckInScreen> createState() =>
      _SafeArrivalCheckInScreenState();
}

class _SafeArrivalCheckInScreenState extends State<SafeArrivalCheckInScreen>
    with TickerProviderStateMixin {
  _CheckInStatus _status = _CheckInStatus.idle;
  String? _checkInTime;
  String? _currentSafeZoneName;
  String? _currentSafeZoneDistance;
  LatLng? _userLocation;
  List<SafeZone> _safeZones = const [];
  StreamSubscription<List<SafeZone>>? _safeZonesSub;
  StreamSubscription<DocumentSnapshot>? _profileSub;
  bool _isLoadingLocation = false;
  final CitizenFirestoreService _firestoreService = CitizenFirestoreService();

  // Sri Lanka emergency relief centers fallback if Firestore has no camps yet
  static const List<SafeZone> _fallbackSafeZones = [
    SafeZone(
      id: 'camp_kolonnawa',
      name: 'Kolonnawa Central Relief Shelter',
      lat: 6.9298,
      lng: 79.8860,
      capacity: 500,
      occupied: 120,
      closed: false,
    ),
    SafeZone(
      id: 'camp_kelani',
      name: 'Kelani Ganga Safe Evacuation Center',
      lat: 6.9553,
      lng: 79.9142,
      capacity: 600,
      occupied: 245,
      closed: false,
    ),
    SafeZone(
      id: 'camp_ratnapura',
      name: 'Ratnapura District Disaster Shelter',
      lat: 6.6828,
      lng: 80.3992,
      capacity: 450,
      occupied: 180,
      closed: false,
    ),
    SafeZone(
      id: 'camp_kaduwela',
      name: 'Kaduwela Community Safe Haven',
      lat: 6.9344,
      lng: 79.9839,
      capacity: 400,
      occupied: 90,
      closed: false,
    ),
    SafeZone(
      id: 'camp_galle',
      name: 'Galle Municipal Evacuation Camp',
      lat: 6.0535,
      lng: 80.2210,
      capacity: 350,
      occupied: 85,
      closed: false,
    ),
  ];

  // Animations
  late AnimationController _rippleController;
  late AnimationController _successController;
  late Animation<double> _successScale;
  late Animation<double> _successOpacity;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeIn),
    );

    _listenToProfile();
    _initLocationAndSafeZones();
  }

  @override
  void dispose() {
    _safeZonesSub?.cancel();
    _profileSub?.cancel();
    _rippleController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _listenToProfile() {
    _profileSub = _firestoreService.getCitizenProfile().listen((doc) {
      if (!mounted || !doc.exists) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final evacStatus = data['evacuationStatus'] as String?;
      final savedZone = data['currentSafeZone'] as String?;
      final timestamp = data['checkInTimestamp'] as Timestamp?;

      if (evacStatus == 'Safe') {
        String formatted = _checkInTime ?? '';
        if (formatted.isEmpty && timestamp != null) {
          formatted = '${DateFormat('HH:mm').format(timestamp.toDate())} LKT';
        } else if (formatted.isEmpty) {
          final now = TimeOfDay.now();
          formatted =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} LKT';
        }

        setState(() {
          _status = _CheckInStatus.confirmed;
          _checkInTime = formatted;
          if (savedZone != null && savedZone.isNotEmpty) {
            _currentSafeZoneName = savedZone;
          }
        });
        _rippleController.stop();
        _successController.value = 1.0;
      }
    });
  }

  Future<void> _initLocationAndSafeZones() async {
    setState(() => _isLoadingLocation = true);

    // 1. Listen to real Firestore Safe Zones
    _safeZonesSub = SafeZoneService.instance.watch().listen((zones) {
      if (!mounted) return;
      setState(() {
        _safeZones = zones;
      });
      _computeClosestSafeZone();
    }, onError: (e) {
      debugPrint('SafeZoneService watch error: $e');
    });

    // 2. Obtain GPS location
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          Position? pos;
          try {
            pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 4),
              ),
            );
          } catch (_) {
            pos = await Geolocator.getLastKnownPosition();
          }
          if (pos != null && mounted) {
            _userLocation = LatLng(pos.latitude, pos.longitude);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
    }

    // Fallback based on citizen's sector or default Sri Lanka coordinates
    if (_userLocation == null) {
      final user = ResponderController().currentUser;
      final district = (user?.district ?? '').toLowerCase();
      if (district.contains('ratnapura')) {
        _userLocation = const LatLng(6.6828, 80.3992);
      } else if (district.contains('galle')) {
        _userLocation = const LatLng(6.0535, 80.2210);
      } else if (district.contains('kalutara')) {
        _userLocation = const LatLng(6.5854, 79.9607);
      } else if (district.contains('gampaha')) {
        _userLocation = const LatLng(7.0840, 80.0098);
      } else {
        _userLocation = const LatLng(6.9271, 79.8612); // Colombo
      }
    }

    if (mounted) {
      setState(() => _isLoadingLocation = false);
      _computeClosestSafeZone();
    }
  }

  void _computeClosestSafeZone() {
    final candidateList =
        _safeZones.isNotEmpty ? _safeZones : _fallbackSafeZones;
    final withLocation = candidateList.where((z) => z.hasLocation).toList();
    if (withLocation.isEmpty) return;

    final loc = _userLocation ?? const LatLng(6.9271, 79.8612);

    final openList = withLocation.where((z) => z.isOpen).toList();
    final searchList = openList.isNotEmpty ? openList : withLocation;

    searchList.sort((a, b) {
      final da = SafeZoneService.distanceKm(loc, a.point);
      final db = SafeZoneService.distanceKm(loc, b.point);
      return da.compareTo(db);
    });

    final closest = searchList.first;
    final dist = SafeZoneService.distanceKm(loc, closest.point);

    if (_status != _CheckInStatus.confirmed || _currentSafeZoneName == null) {
      setState(() {
        _currentSafeZoneName = closest.name;
        _currentSafeZoneDistance = dist < 1.0
            ? '${(dist * 1000).round()} m away'
            : '${dist.toStringAsFixed(1)} km away';
      });
    }
  }

  // --- Check-In Action (Firestore write) ---
  Future<void> _markAsSafe() async {
    if (_status != _CheckInStatus.idle) return;

    setState(() => _status = _CheckInStatus.loading);

    final selectedZone = _currentSafeZoneName ?? 'Designated Relief Camp';
    final now = TimeOfDay.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} LKT';

    try {
      // Mark as safe with real closest safe zone name and coordinates
      await _firestoreService.markAsSafe(
        safeZoneName: selectedZone,
        latitude: _userLocation?.latitude,
        longitude: _userLocation?.longitude,
      );

      // Trigger notification confirmation
      NotificationService.instance.showDisasterWarningNotification(
        id: 88801,
        title: '✅ Check-In Confirmed',
        body:
            'You are safely checked in at $selectedZone. Emergency contacts notified.',
        severity: 'Safe',
      );
    } catch (e) {
      debugPrint('Error marking as safe: $e');
      if (mounted) {
        setState(() => _status = _CheckInStatus.idle);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _status = _CheckInStatus.confirmed;
        _checkInTime = formattedTime;
        _currentSafeZoneName = selectedZone;
      });

      _rippleController.stop();
      _successController.forward();
    }
  }

  Future<void> _resetCheckIn() async {
    setState(() {
      _status = _CheckInStatus.idle;
      _checkInTime = null;
    });
    _successController.reset();
    _rippleController.repeat();
    _computeClosestSafeZone();

    try {
      await _firestoreService.resetCheckInStatus();
    } catch (e) {
      debugPrint('Error resetting check-in: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: const Color(0xFF070B14).withValues(alpha: 0.7),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Safe Arrival Check-In',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [Color(0xFF112240), Color(0xFF070B14)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ScrollFill(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Status Area ────────────────────────────────────────────
                  _status == _CheckInStatus.confirmed
                      ? _PremiumSuccessState(
                          checkInTime: _checkInTime ?? 'Recently',
                          safeZoneName:
                              _currentSafeZoneName ?? 'Designated Relief Camp',
                          safeZoneDistance: _currentSafeZoneDistance,
                          scaleAnimation: _successScale,
                          opacityAnimation: _successOpacity,
                          onReset: _resetCheckIn,
                        )
                      : _PremiumIdleOrLoadingState(
                          status: _status,
                          rippleController: _rippleController,
                          closestZoneName: _currentSafeZoneName,
                          closestZoneDistance: _currentSafeZoneDistance,
                          isLoadingLocation: _isLoadingLocation,
                          onMarkAsSafe: _markAsSafe,
                        ),

                  const Spacer(flex: 3),

                  // ── Battery-save note ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.battery_saver_outlined,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Battery-save mode active',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium Sub-widgets
// ---------------------------------------------------------------------------

class _PremiumRippleRing extends AnimatedWidget {
  final double delay;
  final Color color;

  const _PremiumRippleRing({
    required super.listenable,
    required this.delay,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final adjustedValue = (animation.value + delay) % 1.0;
    final size = 120.0 + adjustedValue * 150.0;
    final opacity = (1.0 - adjustedValue).clamp(0.0, 0.5);

    return Positioned.fill(
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: opacity),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: opacity * 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumIdleOrLoadingState extends StatelessWidget {
  final _CheckInStatus status;
  final AnimationController rippleController;
  final String? closestZoneName;
  final String? closestZoneDistance;
  final bool isLoadingLocation;
  final VoidCallback onMarkAsSafe;

  const _PremiumIdleOrLoadingState({
    required this.status,
    required this.rippleController,
    this.closestZoneName,
    this.closestZoneDistance,
    this.isLoadingLocation = false,
    required this.onMarkAsSafe,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = status == _CheckInStatus.loading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Instruction text ─────────────────────────────────────────────
        const Text(
          'Have you reached safety?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Tap the button below to confirm your arrival\nand instantly notify emergency contacts.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        // ── Nearest Detected Safe Zone Preview ────────────────────────────
        if (closestZoneName != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.near_me_rounded,
                  color: Color(0xFF00E676),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Nearest Safe Shelter: $closestZoneName${closestZoneDistance != null ? " ($closestZoneDistance)" : ""}',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ] else if (isLoadingLocation) ...[
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00E676),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Locating nearest safe shelter...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 32),

        // ── Mark as Safe Button with Ripple ──────────────────────────────
        SizedBox(
          width: ScreenFit.square(context, 280, heightFraction: 0.36),
          height: ScreenFit.square(context, 280, heightFraction: 0.36),
          child: Stack(
            children: [
              // Ripple rings (only animate when idle)
              if (!isLoading) ...[
                _PremiumRippleRing(
                  listenable: rippleController,
                  delay: 0.0,
                  color: const Color(0xFF00E676),
                ),
                _PremiumRippleRing(
                  listenable: rippleController,
                  delay: 0.33,
                  color: const Color(0xFF00E676),
                ),
                _PremiumRippleRing(
                  listenable: rippleController,
                  delay: 0.66,
                  color: const Color(0xFF00E676),
                ),
              ],

              // The main button
              Positioned.fill(
                child: Center(
                  child: GestureDetector(
                    onTap: isLoading ? null : onMarkAsSafe,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: isLoading
                              ? [
                                  const Color(0xFF1A3A1A),
                                  const Color(0xFF0D1D0D)
                                ]
                              : [
                                  const Color(0xFF00E676),
                                  const Color(0xFF00B259)
                                ],
                        ),
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: isLoading ? 0.05 : 0.2),
                          width: 2,
                        ),
                        boxShadow: isLoading
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: const Color(0xFF00E676)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 4,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_rounded,
                                    color: Colors.black87,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'MARK\nAS SAFE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (isLoading) ...[
          const SizedBox(height: 36),
          Text(
            'Broadcasting status...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _PremiumSuccessState extends StatelessWidget {
  final String checkInTime;
  final String safeZoneName;
  final String? safeZoneDistance;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final VoidCallback onReset;

  const _PremiumSuccessState({
    required this.checkInTime,
    required this.safeZoneName,
    this.safeZoneDistance,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacityAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2B),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Success Icon ────────────────────────────────────────────
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Color(0xFF00E676),
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Success message ─────────────────────────────────────────
              const Text(
                'Safely Checked-In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Recorded at $checkInTime',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Your emergency contacts have been notified with your last known location.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ── Status card with dynamic safe zone location ─────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF00E676),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Safe Zone',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            safeZoneName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (safeZoneDistance != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              safeZoneDistance!,
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Action Buttons ──────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const CitizenDashboardScreen()),
                  (route) => false,
                ),
                icon: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.black,
                  size: 20,
                ),
                label: const Text(
                  'Return to Dashboard',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                key: const Key('checkin_reset_btn'),
                onPressed: onReset,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 18,
                ),
                label: Text(
                  'Update check-in status',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
