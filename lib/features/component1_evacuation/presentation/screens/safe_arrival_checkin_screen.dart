import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Safe Arrival Check-In Screen — Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// Minimalist, battery-saving screen. Majority black.
// A single massive "Mark as Safe" button updates local state.
// Replace state mutation with a Firestore document write when backend is ready.
// ---------------------------------------------------------------------------

import '../../services/citizen_firestore_service.dart';

enum _CheckInStatus { idle, loading, confirmed }

class SafeArrivalCheckInScreen extends StatefulWidget {
  const SafeArrivalCheckInScreen({super.key});

  @override
  State<SafeArrivalCheckInScreen> createState() =>
      _SafeArrivalCheckInScreenState();
}

class _SafeArrivalCheckInScreenState extends State<SafeArrivalCheckInScreen>
    with TickerProviderStateMixin {
  // --- Local state (replace with Firestore write later) ---
  _CheckInStatus _status = _CheckInStatus.idle;
  String? _checkInTime;
  final CitizenFirestoreService _firestoreService = CitizenFirestoreService();

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
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // --- Check-In Action (Firestore write) ---
  Future<void> _markAsSafe() async {
    if (_status != _CheckInStatus.idle) return;

    setState(() => _status = _CheckInStatus.loading);

    try {
      // Ensure profile exists (simulating registration)
      await _firestoreService.createCitizenProfile("Citizen User");
      // Mark as safe
      await _firestoreService.markAsSafe();
    } catch (e) {
      // Handle error gracefully in real app
      setState(() => _status = _CheckInStatus.idle);
      return;
    }

    final now = TimeOfDay.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} LKT';

    setState(() {
      _status = _CheckInStatus.confirmed;
      _checkInTime = formattedTime;
    });

    _rippleController.stop();
    _successController.forward();
  }

  void _resetCheckIn() {
    setState(() {
      _status = _CheckInStatus.idle;
      _checkInTime = null;
    });
    _successController.reset();
    _rippleController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Safe Arrival Check-In',
          style: TextStyle(
              color: Colors.white54, fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Status Area ────────────────────────────────────────────
              _status == _CheckInStatus.confirmed
                  ? _SuccessState(
                      checkInTime: _checkInTime!,
                      scaleAnimation: _successScale,
                      opacityAnimation: _successOpacity,
                      onReset: _resetCheckIn,
                    )
                  : _IdleOrLoadingState(
                      status: _status,
                      rippleController: _rippleController,
                      onMarkAsSafe: _markAsSafe,
                    ),

              const Spacer(flex: 3),

              // ── Battery-save note ──────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.battery_saver_outlined,
                        color: Colors.white24, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Battery-save mode active',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _RippleRing extends AnimatedWidget {
  final double delay;
  final Color color;

  const _RippleRing({
    required super.listenable,
    required this.delay,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final adjustedValue = (animation.value + delay) % 1.0;
    final size = 100.0 + adjustedValue * 120.0;
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
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _IdleOrLoadingState extends StatelessWidget {
  final _CheckInStatus status;
  final AnimationController rippleController;
  final VoidCallback onMarkAsSafe;

  const _IdleOrLoadingState({
    required this.status,
    required this.rippleController,
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
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Press the button below to confirm your safe arrival\nand notify your emergency contacts.',
          style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 56),

        // ── Mark as Safe Button with Ripple ──────────────────────────────
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            children: [
              // Ripple rings (only animate when idle)
              if (!isLoading) ...[
                _RippleRing(
                  listenable: rippleController,
                  delay: 0.0,
                  color: const Color(0xFF00E676),
                ),
                _RippleRing(
                  listenable: rippleController,
                  delay: 0.35,
                  color: const Color(0xFF00E676),
                ),
                _RippleRing(
                  listenable: rippleController,
                  delay: 0.7,
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
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLoading
                            ? const Color(0xFF1A3A1A)
                            : const Color(0xFF00E676),
                        boxShadow: isLoading
                            ? []
                            : [
                                const BoxShadow(
                                  color: Color(0x8000E676),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                      ),
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00E676),
                                strokeWidth: 3,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.black,
                                  size: 44,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'MARK\nAS SAFE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    height: 1.3,
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
          const SizedBox(height: 28),
          const Text(
            'Sending check-in...',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  final String checkInTime;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final VoidCallback onReset;

  const _SuccessState({
    required this.checkInTime,
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
                  color: const Color(0xFF00E676),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00E676),
                size: 64,
              ),
            ),
            const SizedBox(height: 28),

            // ── Success message ─────────────────────────────────────────
            const Text(
              'You are checked in safely ✅',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Check-in recorded at $checkInTime',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your emergency contacts have been notified.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // ── Status card ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF00E676).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_rounded,
                      color: Color(0xFF00E676), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Safe Zone: Rathnapura Central College',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Reset / Update button ───────────────────────────────────
            TextButton.icon(
              key: const Key('checkin_reset_btn'),
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white38, size: 18),
              label: const Text(
                'Update check-in status',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
