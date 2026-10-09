import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../models/warning_alert.dart';

import 'evacuation_checklist_screen.dart';
import 'emergency_contacts_screen.dart';
import 'safe_routing_map_screen.dart';
import 'safe_arrival_checkin_screen.dart';
import 'citizen_drawer.dart';
import '../../../component4_control_center/presentation/controllers/responder_controller.dart';

// ---------------------------------------------------------------------------
// Citizen Dashboard Screen — Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// Premium, high-contrast, state-of-the-art UI with glassmorphism.
// ---------------------------------------------------------------------------

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const _severityRank = {'Watch': 0, 'Warning': 1, 'Critical': 2};

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(ResponderController().currentUser?.email ?? 'unknown')
          .snapshots(),
      builder: (context, userSnap) {
        final bool isLoading =
            userSnap.connectionState == ConnectionState.waiting;
        final userData =
            userSnap.hasData && userSnap.data != null && userSnap.data!.exists
            ? (userSnap.data!.data() as Map<String, dynamic>)
            : <String, dynamic>{};

        final district = userData['district'] as String? ?? 'Colombo';
        final city = userData['city'] as String? ?? 'Colombo';
        String? firestoreName = userData['name'] as String? ?? userData['fullName'] as String?;
        if (firestoreName == 'Citizen User' || firestoreName == null || firestoreName.isEmpty) {
          firestoreName = null;
        }
        final citizenName = firestoreName ?? ResponderController().currentUser?.fullName ?? 'Citizen User';
        final citizenZone =
            userData['floodZone'] as String? ??
            userData['district'] as String? ??
            userData['zone'] as String? ??
            userData['alertZone'] as String? ??
            ResponderController().currentUser?.floodZone ??
            'Colombo Low-Lying Area';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('warnings')
              .where('district', isEqualTo: district)
              .where('city', isEqualTo: city)
              .snapshots(),
          builder: (context, warningsSnap) {
            WarningAlert? topAlert;
            List<WarningAlert> allAlerts = [];

            if (warningsSnap.hasData && warningsSnap.data!.docs.isNotEmpty) {
              allAlerts = warningsSnap.data!.docs
                  .map((d) => WarningAlert.fromDoc(d))
                  .toList();

              // Only run reduce if list is not empty, which we know it isn't
              topAlert = allAlerts.reduce(
                (a, b) =>
                    (_severityRank[b.severity] ?? 0) >
                        (_severityRank[a.severity] ?? 0)
                    ? b
                    : a,
              );
            }

            final alertLevel = topAlert?.severity.toUpperCase() ?? 'SAFE';
            final isPulse = topAlert != null;

            return Scaffold(
              backgroundColor: const Color(0xFF070B14),
              drawer: const CitizenDrawer(),
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                leading: Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    tooltip: 'Open Menu',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF00E676),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'We',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'Safe',
                            style: TextStyle(color: Color(0xFF00E676)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(child: _AlertLevelBadge(level: alertLevel)),
                  ),
                ],
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Logged in Citizen Profile Banner ────────────────────────────
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF00E676),
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E676)
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF00E676)
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: Color(0xFF00E676),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            citizenName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Sector: $citizenZone',
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E676)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        if (topAlert != null)
                          ScaleTransition(
                            scale: isPulse
                                ? _pulseAnimation
                                : const AlwaysStoppedAnimation(1.0),
                            child: _PremiumCriticalAlertCard(
                              title:
                                  '${topAlert.severity} ${topAlert.hazardType} — ${topAlert.locationZone}',
                              body: topAlert.description,
                              time:
                                  'Issued: ${DateFormat('dd MMM, HH:mm').format(topAlert.issuedTimestamp)}',
                              waterLevel: topAlert.waterLevelMeters,
                              rainfall: topAlert.rainfallMm,
                              windSpeed: topAlert.windSpeedKmh,
                              severity: topAlert.severity,
                            ),
                          )
                        else
                          _AllClearCard(district: district),

                        // ── Multiple active warnings list ────────────────────
                        if (allAlerts.length > 1) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6D00),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${allAlerts.length} Active Warnings',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...allAlerts
                              .skip(1)
                              .map((a) => _MiniAlertTile(alert: a)),
                        ],

                        const SizedBox(height: 36),

                        // ── Section Header ───────────────────────────────────────────────
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x6600E676),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Emergency Actions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Primary Action: Safe Route ──────────────────────────────────
                        _PremiumActionCard(
                          onTap: () => _push(const SafeRoutingMapScreen()),
                          icon: Icons.alt_route_rounded,
                          title: 'Safe Route',
                          subtitle: 'Fastest path to high ground',
                          color: const Color(0xFFFFD740),
                          isPrimary: true,
                        ),

                        const SizedBox(height: 16),

                        // ── Secondary Actions (Row 1) ───────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _PremiumGridCard(
                                onTap: () =>
                                    _push(const EvacuationChecklistScreen()),
                                icon: Icons.checklist_rounded,
                                label: 'Go-Bag\nChecklist',
                                color: const Color(0xFF00E676),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _PremiumGridCard(
                                onTap: () =>
                                    _push(const EmergencyContactsScreen()),
                                icon: Icons.contact_phone_rounded,
                                label: 'Emergency\nContacts',
                                color: const Color(0xFF40C4FF),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Secondary Action (Full Width) ───────────────────────────────
                        _PremiumActionCard(
                          onTap: () => _push(const SafeArrivalCheckInScreen()),
                          icon: Icons.verified_user_rounded,
                          title: 'Safe Arrival Check-In',
                          subtitle: 'Mark yourself and family as safe',
                          color: const Color(0xFFFF6D00),
                          isPrimary: false,
                        ),

                        const SizedBox(height: 36),

                        // ── Status Footer ────────────────────────────────────────────────
                        const _PremiumStatusFooter(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Premium Sub-widgets
// ---------------------------------------------------------------------------

class _PremiumActionCard extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final bool isPrimary;

  const _PremiumActionCard({
    required this.onTap,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    this.isPrimary = false,
  });

  @override
  State<_PremiumActionCard> createState() => _PremiumActionCardState();
}

class _PremiumActionCardState extends State<_PremiumActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _scaleCtrl.reverse();
  void _onTapUp(_) => _scaleCtrl.forward();
  void _onTapCancel() => _scaleCtrl.forward();

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2B), // Very dark slate/blue
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isPrimary
                  ? widget.color.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isPrimary
                    ? widget.color.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.2),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumGridCard extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;

  const _PremiumGridCard({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<_PremiumGridCard> createState() => _PremiumGridCardState();
}

class _PremiumGridCardState extends State<_PremiumGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _scaleCtrl.reverse();
  void _onTapUp(_) => _scaleCtrl.forward();
  void _onTapCancel() => _scaleCtrl.forward();

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumCriticalAlertCard extends StatefulWidget {
  final String title;
  final String body;
  final String time;
  final double waterLevel;
  final double rainfall;
  final double windSpeed;
  final String severity;

  const _PremiumCriticalAlertCard({
    required this.title,
    required this.body,
    required this.time,
    required this.waterLevel,
    required this.rainfall,
    required this.windSpeed,
    required this.severity,
  });

  @override
  State<_PremiumCriticalAlertCard> createState() => _PremiumCriticalAlertCardState();
}

class _PremiumCriticalAlertCardState extends State<_PremiumCriticalAlertCard> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  static const _gradients = {
    'Watch': [Color(0xFFFFB300), Color(0xFFFF8F00)],
    'Warning': [Color(0xFFFF6D00), Color(0xFFE65100)],
    'Critical': [Color(0xFFFF1744), Color(0xFFD50000)], // More vibrant reds
  };

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradColors = _gradients[widget.severity] ?? [const Color(0xFFFF1744), const Color(0xFFD50000)];
    final isCritical = widget.severity == 'Critical';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gradColors[1].withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Bottom layer: Vibrant Gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradColors[0], gradColors[1]],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            
            // Middle layer: Animated Rain & Water
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _WeatherBackgroundPainter(
                      _bgController.value,
                      isCritical,
                    ),
                  );
                },
              ),
            ),
            
            // Top layer: Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'EMERGENCY ALERT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      _BlinkingDot(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Live metrics row
                  Row(
                    children: [
                      _MetricPill(
                        icon: Icons.water_rounded,
                        label: '${widget.waterLevel.toStringAsFixed(2)} m',
                        hint: 'Water Level',
                      ),
                      const SizedBox(width: 6),
                      _MetricPill(
                        icon: Icons.grain_rounded,
                        label: '${widget.rainfall.toStringAsFixed(1)} mm',
                        hint: 'Rainfall',
                      ),
                      const SizedBox(width: 6),
                      _MetricPill(
                        icon: Icons.air_rounded,
                        label: '${widget.windSpeed.toStringAsFixed(1)} kph',
                        hint: 'Wind Speed',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.time,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _WeatherBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isCritical;

  _WeatherBackgroundPainter(this.animationValue, this.isCritical);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Rain
    final paintRain = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final int dropCount = isCritical ? 40 : 20;
    for (int i = 0; i < dropCount; i++) {
      final double x = (i * 27.0) % size.width;
      final double y = ((i * 53.0) + (animationValue * size.height * 2)) % size.height;
      final double length = 10.0 + (i % 15);
      canvas.drawLine(Offset(x, y), Offset(x - 2, y + length), paintRain); // slightly angled rain
    }

    // 2. Draw Back Water Wave (Slower)
    final paintWaterBack = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
      
    final pathBack = Path();
    final double baseHeightBack = size.height * 0.75;
    pathBack.moveTo(0, size.height);
    pathBack.lineTo(0, baseHeightBack);

    for (double i = 0; i <= size.width; i++) {
      final waveOffset = math.cos((i / 40) - (animationValue * math.pi * 2)) * 6;
      pathBack.lineTo(i, baseHeightBack + waveOffset);
    }
    pathBack.lineTo(size.width, size.height);
    pathBack.close();
    canvas.drawPath(pathBack, paintWaterBack);

    // 3. Draw Front Water Wave (Faster)
    final paintWaterFront = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final pathFront = Path();
    final double baseHeightFront = size.height * 0.78;
    pathFront.moveTo(0, size.height);
    pathFront.lineTo(0, baseHeightFront);

    for (double i = 0; i <= size.width; i++) {
      final waveOffset = math.sin((i / 30) + (animationValue * math.pi * 4)) * 8;
      pathFront.lineTo(i, baseHeightFront + waveOffset);
    }
    pathFront.lineTo(size.width, size.height);
    pathFront.close();
    canvas.drawPath(pathFront, paintWaterFront);
  }

  @override
  bool shouldRepaint(covariant _WeatherBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hint,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllClearCard extends StatelessWidget {
  final String district;
  const _AllClearCard({required this.district});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003822), Color(0xFF001F13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF00E676),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Clear',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No active warnings in $district.',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAlertTile extends StatelessWidget {
  final WarningAlert alert;
  const _MiniAlertTile({required this.alert});

  static const _colors = {
    'Watch': Color(0xFFFFC107),
    'Warning': Color(0xFFFF6D00),
    'Critical': Color(0xFFFF1744),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[alert.severity] ?? const Color(0xFFFFC107);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning_amber_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.hazardType} — ${alert.locationZone}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${alert.waterLevelMeters.toStringAsFixed(2)} m  •  ${alert.rainfallMm.toStringAsFixed(1)} mm  •  ${alert.windSpeedKmh.toStringAsFixed(1)} kph',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              alert.severity,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
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
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.white, blurRadius: 6)],
        ),
      ),
    );
  }
}

class _AlertLevelBadge extends StatelessWidget {
  final String level;

  const _AlertLevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final isSafe = level == 'SAFE';
    final bgColor = isSafe
        ? const Color(0xFF00E676).withValues(alpha: 0.15)
        : const Color(0xFFB71C1C).withValues(alpha: 0.8);
    final borderColor = isSafe
        ? const Color(0xFF00E676).withValues(alpha: 0.4)
        : Colors.redAccent.shade100.withValues(alpha: 0.5);
    final shadowColor = isSafe
        ? const Color(0x3300E676)
        : const Color(0x4DB71C1C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 8)],
      ),
      child: Text(
        level,
        style: TextStyle(
          color: isSafe ? const Color(0xFF00E676) : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _PremiumStatusFooter extends StatelessWidget {
  const _PremiumStatusFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.display_settings_rounded,
                color: Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'SYSTEM STATUS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            Icons.cell_tower,
            'Network: Online',
            const Color(0xFF00E676),
          ),
          const SizedBox(height: 14),
          _buildStatusRow(
            Icons.offline_pin_rounded,
            'Map cached (10km)',
            const Color(0xFF40C4FF),
          ),
          const SizedBox(height: 14),
          _buildStatusRow(
            Icons.battery_4_bar_rounded,
            'Battery-save ON',
            const Color(0xFFFFD740),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}
