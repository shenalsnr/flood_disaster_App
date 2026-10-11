import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

// ============================================================================
// Visual Card 1: Get Early Warning Alerts
// ============================================================================

class EarlyWarningVisual extends StatefulWidget {
  const EarlyWarningVisual({super.key});

  @override
  State<EarlyWarningVisual> createState() => _EarlyWarningVisualState();
}

class _EarlyWarningVisualState extends State<EarlyWarningVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final floatOffset = math.sin(_controller.value * math.pi) * 6;
        final pulseScale = 1.0 + (_controller.value * 0.04);

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF131B2B),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 1. Map Road Grid in Background
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapRoadsPainter(
                      roadColor: const Color(0xFF1E293B),
                      highlightColor: AppColors.primaryLight.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ),

                // 2. Rising Flood Waves at Bottom Half
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 140,
                  child: CustomPaint(
                    painter: _FloodWavesPainter(animValue: _controller.value),
                  ),
                ),

                // 3. Central Hazard Pin in the Water / Map
                Positioned(
                  top: 70,
                  right: 90,
                  child: Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),

                // 4. Floating Badge 1 (Left - Orange Hazard Warning)
                Positioned(
                  left: 20,
                  bottom: 50 + floatOffset,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB020), Color(0xFFFF6B2C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B2C)
                              .withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.warning_rounded,
                        color: Color(0xFF131B2B),
                        size: 44,
                      ),
                    ),
                  ),
                ),

                // 5. Floating Badge 2 (Right - Red Emergency Pill)
                Positioned(
                  right: 20,
                  bottom: 34 - floatOffset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5252), Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5252)
                              .withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Emergency',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 10,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Visual Card 2: Report Hazards Instantly
// ============================================================================

// ============================================================================
// Visual Card 2: Report Hazards Instantly (High-Fidelity)
// ============================================================================

class ReportHazardsVisual extends StatefulWidget {
  const ReportHazardsVisual({super.key});

  @override
  State<ReportHazardsVisual> createState() => _ReportHazardsVisualState();
}

class _ReportHazardsVisualState extends State<ReportHazardsVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final anim = _controller.value;
        final floatOffset = math.sin(anim * math.pi * 2) * 4;

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF131B2B),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 1. Subtle background grid
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapRoadsPainter(
                      roadColor: const Color(0xFF172033),
                      highlightColor: Colors.transparent,
                    ),
                  ),
                ),

                // 2. Central Floating Smartphone Mockup (Behind person's hand)
                Positioned(
                  right: 14,
                  top: 14 + floatOffset,
                  bottom: 14 - floatOffset,
                  width: 195,
                  child: _IPhoneMockup(pulseAnim: anim),
                ),

                // 3. Citizen Character Illustration on the Left (Overlapping phone)
                Positioned(
                  left: 6,
                  bottom: 0,
                  width: 155,
                  height: 250,
                  child: _DetailedCitizenGraphic(signalAnim: anim),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailedCitizenGraphic extends StatelessWidget {
  final double signalAnim;

  const _DetailedCitizenGraphic({required this.signalAnim});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Broadcast signal waves from hand
        Positioned(
          top: 32,
          right: 4,
          child: CustomPaint(
            size: const Size(48, 48),
            painter: _SignalWavesPainter(progress: signalAnim),
          ),
        ),

        // Citizen high-fidelity vector illustration
        Positioned.fill(child: CustomPaint(painter: _RealisticPersonPainter())),
      ],
    );
  }
}

class _IPhoneMockup extends StatelessWidget {
  final double pulseAnim;

  const _IPhoneMockup({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131B2B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // iPhone Status Bar & Dynamic Island
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFF131B2B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '9:41',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 8.5,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 12,
                        height: 6,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Header: < Report a Hazard
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF131B2B),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Report a Hazard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Mini Map with Pin Markers & Flood Water
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Road map background
                  CustomPaint(
                    painter: _MapRoadsPainter(
                      roadColor: const Color(0xFF1E293B),
                      highlightColor: Colors.transparent,
                    ),
                  ),

                  // Flood Water at bottom of map
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 62,
                    child: CustomPaint(
                      painter: _FloodWavesPainter(animValue: pulseAnim),
                    ),
                  ),

                  // 1. Red Hazard Triangle Marker in the Water (Right)
                  Positioned(
                    bottom: 14,
                    right: 22,
                    child: CustomPaint(
                      size: const Size(20, 20),
                      painter: _SubmergedHazardTrianglePainter(),
                    ),
                  ),

                  // 2. Teardrop Stop Hand Map Pin anchored in the Water (Center-Left)
                  Positioned(
                    left: 48,
                    bottom: 12,
                    child: CustomPaint(
                      size: const Size(36, 48),
                      painter: _StopHandPinPainter(pulse: pulseAnim),
                    ),
                  ),
                ],
              ),
            ),

            // Form Fields Placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            // Orange Report Button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                width: double.infinity,
                height: 26,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A22), Color(0xFFFF4D00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5200).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Visual Card 3: Find Safe Routes & Shelter
// ============================================================================

class SafeRoutesVisual extends StatefulWidget {
  const SafeRoutesVisual({super.key});

  @override
  State<SafeRoutesVisual> createState() => _SafeRoutesVisualState();
}

class _SafeRoutesVisualState extends State<SafeRoutesVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final floatOffset = math.sin(_controller.value * math.pi) * 5;

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF131B2B),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 1. Street Map Grid
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapRoadsPainter(
                      roadColor: const Color(0xFF1E293B),
                      highlightColor: Colors.transparent,
                    ),
                  ),
                ),

                // 2. Neon Green Evacuation Route
                Positioned.fill(
                  child: CustomPaint(
                    painter: _NeonRoutePainter(progress: _controller.value),
                  ),
                ),

                // 3. Waypoint Pins along the Route
                // Pin 1 (Bottom Left origin)
                Positioned(
                  left: 45,
                  bottom: 75,
                  child: _ShelterWaypointPin(pulse: _controller.value),
                ),
                // Pin 2 (Middle Left)
                Positioned(
                  left: 65,
                  top: 110,
                  child: _ShelterWaypointPin(pulse: _controller.value),
                ),
                // Pin 3 (Middle Right)
                Positioned(
                  right: 50,
                  bottom: 120,
                  child: _ShelterWaypointPin(pulse: _controller.value),
                ),
                // Destination Pin (Top Right destination with checkmark)
                Positioned(
                  right: 48,
                  top: 48,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF16A34A),
                      border: Border.all(
                        color: const Color(0xFF4ADE80),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // 4. Floating Badge 1 (Top Left - Evacuation Check-Ins)
                Positioned(
                  left: 20,
                  top: 35 + floatOffset,
                  child: _ShelterBadge(
                    icon: Icons.shield_outlined,
                    title: 'Evacuation',
                    subtitle: 'Check-Ins',
                    trailing: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF22C55E),
                      size: 18,
                    ),
                  ),
                ),

                // 5. Floating Badge 2 (Bottom Right - Shelter Ins Check-ins)
                Positioned(
                  right: 25,
                  bottom: 35 - floatOffset,
                  child: _ShelterBadge(
                    icon: Icons.roofing_rounded,
                    title: 'Shelter Ins',
                    subtitle: 'Check-ins',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShelterWaypointPin extends StatelessWidget {
  final double pulse;

  const _ShelterWaypointPin({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0F2E1E),
        border: Border.all(color: const Color(0xFF22C55E), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Icon(Icons.home_rounded, color: Color(0xFF4ADE80), size: 15),
    );
  }
}

class _ShelterBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _ShelterBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B291A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF16A34A).withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4ADE80), size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.9),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

// ============================================================================
// Custom Painters for Vector Quality Graphics
// ============================================================================

/// Road network painter for backgrounds
class _MapRoadsPainter extends CustomPainter {
  final Color roadColor;
  final Color highlightColor;

  _MapRoadsPainter({required this.roadColor, required this.highlightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = roadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final secondaryPaint = Paint()
      ..color = roadColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Horizontal road blocks
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.55),
      Offset(size.width, size.height * 0.55),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.8),
      paint,
    );

    // Vertical streets
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, 0),
      Offset(size.width * 0.65, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.85, 0),
      Offset(size.width * 0.85, size.height),
      secondaryPaint,
    );

    // Diagonal arterial roads
    canvas.drawLine(
      Offset(0, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.9),
      secondaryPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width, size.height * 0.7),
      secondaryPaint,
    );

    // Highlight road (e.g. orange route in visual 1)
    if (highlightColor != Colors.transparent) {
      final highPaint = Paint()
        ..color = highlightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(size.width * 0.65, size.height * 0.7)
        ..lineTo(size.width * 0.72, size.height * 0.25)
        ..lineTo(size.width * 0.85, 0);

      canvas.drawPath(path, highPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapRoadsPainter oldDelegate) => false;
}

/// Dynamic stylized flood waves
class _FloodWavesPainter extends CustomPainter {
  final double animValue;

  _FloodWavesPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Deep water back wave
    final backWavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0369A1).withValues(alpha: 0.85),
          const Color(0xFF0284C7).withValues(alpha: 0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final backWave = Path()
      ..moveTo(0, h * 0.45 + math.sin(animValue * math.pi * 2) * 6)
      ..quadraticBezierTo(
        w * 0.3,
        h * 0.25 - math.cos(animValue * math.pi * 2) * 8,
        w * 0.6,
        h * 0.45 + math.sin(animValue * math.pi * 2) * 6,
      )
      ..quadraticBezierTo(w * 0.85, h * 0.65, w, h * 0.4)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(backWave, backWavePaint);

    // Front crest wave (light cyan)
    final frontWavePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF40C4FF), Color(0xFF0284C7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final frontWave = Path()
      ..moveTo(0, h * 0.6 - math.cos(animValue * math.pi * 2) * 6)
      ..quadraticBezierTo(
        w * 0.35,
        h * 0.42 + math.sin(animValue * math.pi * 2) * 7,
        w * 0.7,
        h * 0.55 - math.cos(animValue * math.pi * 2) * 5,
      )
      ..quadraticBezierTo(w * 0.9, h * 0.65, w, h * 0.5)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(frontWave, frontWavePaint);

    // White ripple line highlight
    final ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final ripple = Path()
      ..moveTo(w * 0.15, h * 0.62)
      ..quadraticBezierTo(w * 0.4, h * 0.48, w * 0.65, h * 0.6);

    canvas.drawPath(ripple, ripplePaint);
  }

  @override
  bool shouldRepaint(covariant _FloodWavesPainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}

/// High-fidelity realistic citizen reporter vector painter
class _RealisticPersonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skinPaint = Paint()
      ..color = const Color(0xFFFDBA74)
      ..style = PaintingStyle.fill;

    final skinShadowPaint = Paint()
      ..color = const Color(0xFFEA580C).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final hairPaint = Paint()
      ..color = const Color(0xFF0D131F)
      ..style = PaintingStyle.fill;

    final shirtPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFA024), Color(0xFFEA580C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(10, 80, 110, 130))
      ..style = PaintingStyle.fill;

    final pantsPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    // 1. Trousers (Bottom)
    final pants = Path()
      ..moveTo(20, 180)
      ..lineTo(98, 180)
      ..lineTo(102, size.height)
      ..lineTo(16, size.height)
      ..close();
    canvas.drawPath(pants, pantsPaint);

    // 2. Torso (Golden Orange T-shirt)
    final shirt = Path()
      ..moveTo(24, 115)
      // Left shoulder slope
      ..quadraticBezierTo(35, 96, 50, 95)
      // Neckline
      ..quadraticBezierTo(62, 98, 74, 95)
      // Right shoulder
      ..quadraticBezierTo(86, 98, 96, 112)
      // Right armpit / side seam
      ..lineTo(98, 180)
      // Waist
      ..lineTo(20, 180)
      // Left side seam
      ..quadraticBezierTo(18, 145, 24, 115)
      ..close();
    canvas.drawPath(shirt, shirtPaint);

    // Left short sleeve
    final leftSleeve = Path()
      ..moveTo(24, 115)
      ..lineTo(14, 142)
      ..lineTo(28, 146)
      ..lineTo(32, 128)
      ..close();
    canvas.drawPath(leftSleeve, shirtPaint);

    // 3. Neck & Throat
    final neck = Path()
      ..moveTo(52, 75)
      ..lineTo(70, 75)
      ..lineTo(72, 97)
      ..lineTo(50, 97)
      ..close();
    canvas.drawPath(neck, skinPaint);

    // Neck shadow under chin
    final neckShadow = Path()
      ..moveTo(58, 75)
      ..lineTo(70, 75)
      ..lineTo(72, 92)
      ..lineTo(60, 92)
      ..close();
    canvas.drawPath(neckShadow, skinShadowPaint);

    // 4. Head Base & Profile Face (Facing Right towards Phone)
    // Head oval base
    canvas.drawOval(const Rect.fromLTWH(38, 42, 34, 38), skinPaint);

    // Facial profile features (forehead, nose, lips, chin)
    final faceProfile = Path()
      ..moveTo(64, 46)
      // Forehead
      ..lineTo(70, 52)
      // Nose bridge & tip
      ..lineTo(75, 56)
      ..lineTo(70, 58)
      // Upper lip & mouth
      ..lineTo(71, 62)
      // Lower lip & chin
      ..lineTo(72, 66)
      ..quadraticBezierTo(68, 74, 58, 76)
      ..lineTo(56, 68)
      ..close();
    canvas.drawPath(faceProfile, skinPaint);

    // Ear
    canvas.drawOval(const Rect.fromLTWH(42, 54, 8, 13), skinPaint);
    // Inner ear curve
    final earInner = Paint()
      ..color = const Color(0xFFEA580C).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
      const Rect.fromLTWH(44, 57, 4, 7),
      -1.5,
      3.0,
      false,
      earInner,
    );

    // 5. Stylized Voluminous Wavy Black Hair
    final hair = Path()
      ..moveTo(36, 68) // Nape of neck
      // Back curve of hair
      ..quadraticBezierTo(28, 55, 30, 42)
      // Top wavy locks
      ..cubicTo(32, 28, 48, 25, 58, 32)
      ..cubicTo(62, 26, 70, 32, 72, 38)
      // Front forehead lock
      ..quadraticBezierTo(74, 44, 66, 46)
      // Hairline in front of ear
      ..quadraticBezierTo(54, 48, 50, 52)
      // Sideburn
      ..lineTo(48, 56)
      ..quadraticBezierTo(44, 54, 42, 58)
      ..quadraticBezierTo(38, 62, 36, 68)
      ..close();
    canvas.drawPath(hair, hairPaint);

    // 6. Right Arm (Raised towards the phone, short-sleeve to bare arm)
    // Right short sleeve on shoulder
    final rightSleeve = Path()
      ..moveTo(88, 102)
      ..lineTo(104, 114)
      ..lineTo(98, 128)
      ..lineTo(82, 116)
      ..close();
    canvas.drawPath(rightSleeve, shirtPaint);

    // Bare Arm extending upwards at 45 degrees
    final bareArm = Path()
      ..moveTo(96, 114)
      // Upper arm to elbow
      ..quadraticBezierTo(108, 98, 115, 82)
      // Forearm to wrist
      ..quadraticBezierTo(122, 66, 128, 50)
      // Wrist width
      ..lineTo(138, 55)
      // Inner arm back to armpit
      ..quadraticBezierTo(130, 75, 122, 94)
      ..quadraticBezierTo(112, 110, 94, 124)
      ..close();
    canvas.drawPath(bareArm, skinPaint);

    // Arm shading
    final armShade = Path()
      ..moveTo(128, 50)
      ..lineTo(138, 55)
      ..quadraticBezierTo(130, 75, 124, 94)
      ..lineTo(118, 90)
      ..close();
    canvas.drawPath(armShade, skinShadowPaint);

    // 7. Articulated Open Hand (Palm + 5 Fingers facing outward `✋`)
    final palmCenter = const Offset(136, 42);
    canvas.drawOval(
      Rect.fromCenter(center: palmCenter, width: 15, height: 18),
      skinPaint,
    );

    final fingerPaint = Paint()
      ..color = const Color(0xFFFDBA74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    // Thumb pointing left
    canvas.drawLine(const Offset(130, 44), const Offset(120, 42), fingerPaint);
    // Index finger
    canvas.drawLine(const Offset(132, 36), const Offset(134, 18), fingerPaint);
    // Middle finger
    canvas.drawLine(const Offset(136, 34), const Offset(139, 14), fingerPaint);
    // Ring finger
    canvas.drawLine(const Offset(140, 36), const Offset(144, 17), fingerPaint);
    // Pinky finger
    canvas.drawLine(const Offset(143, 40), const Offset(148, 24), fingerPaint);

    // 8. Megaphone / Radio Beacon Icon near hand
    final beaconPaint = Paint()
      ..color = const Color(0xFFFF9500)
      ..style = PaintingStyle.fill;

    final beacon = Path()
      ..moveTo(116, 26)
      ..lineTo(124, 20)
      ..lineTo(124, 32)
      ..close();
    canvas.drawPath(beacon, beaconPaint);
    canvas.drawRect(const Rect.fromLTWH(113, 24, 4, 3), beaconPaint);
  }

  @override
  bool shouldRepaint(covariant _RealisticPersonPainter oldDelegate) => false;
}

/// Stop Hand Teardrop Pin anchored in the Flood Water
class _StopHandPinPainter extends CustomPainter {
  final double pulse;

  _StopHandPinPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.38;
    final r = size.width * 0.42;

    // Outer glow pulse
    final glowPaint = Paint()
      ..color = const Color(0xFFFF4500).withValues(alpha: 0.35 + (pulse * 0.15))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy), r + 4, glowPaint);

    // Teardrop Pin Path
    final pinPath = Path()
      ..moveTo(cx, size.height * 0.96) // Bottom sharp point in water
      ..quadraticBezierTo(cx - r * 0.95, cy + r * 0.65, cx - r, cy)
      ..arcToPoint(
        Offset(cx + r, cy),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..quadraticBezierTo(cx + r * 0.95, cy + r * 0.65, cx, size.height * 0.96)
      ..close();

    // Pin Gradient Fill
    final pinPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF5722), Color(0xFFDC2626)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, pinPaint);

    // White outline
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(pinPath, outlinePaint);

    // Water ripple ring at the base of pin
    final ripplePaint = Paint()
      ..color = const Color(0xFF40C4FF).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.96),
        width: 16,
        height: 5,
      ),
      ripplePaint,
    );

    // White Stop Hand Symbol inside Pin Head
    final handPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Hand palm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 2), width: 11, height: 11),
        const Radius.circular(3),
      ),
      handPaint,
    );

    // 4 Fingers + thumb
    final fingerStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Thumb
    canvas.drawLine(
      Offset(cx - 5, cy + 3),
      Offset(cx - 8, cy + 1),
      fingerStroke,
    );
    // Index
    canvas.drawLine(
      Offset(cx - 3.5, cy),
      Offset(cx - 3.5, cy - 6),
      fingerStroke,
    );
    // Middle
    canvas.drawLine(Offset(cx - 1, cy), Offset(cx - 1, cy - 7.5), fingerStroke);
    // Ring
    canvas.drawLine(
      Offset(cx + 1.5, cy),
      Offset(cx + 1.5, cy - 6.5),
      fingerStroke,
    );
    // Pinky
    canvas.drawLine(
      Offset(cx + 4, cy + 1),
      Offset(cx + 4, cy - 4.5),
      fingerStroke,
    );
  }

  @override
  bool shouldRepaint(covariant _StopHandPinPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

/// Submerged Hazard Triangle Marker sticking out of the water
class _SubmergedHazardTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Triangle path
    final triangle = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.88)
      ..lineTo(0, h * 0.88)
      ..close();

    // Red fill with glow
    final redPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.fill;
    canvas.drawPath(triangle, redPaint);

    final whiteBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(triangle, whiteBorder);

    // White Exclamation mark '!'
    final markPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.28),
      Offset(w * 0.5, h * 0.58),
      markPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.72),
      1.2,
      Paint()..color = Colors.white,
    );

    // Water ripple at base
    final ripple = Paint()
      ..color = const Color(0xFF40C4FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(-2, h * 0.9), Offset(w + 2, h * 0.9), ripple);
  }

  @override
  bool shouldRepaint(covariant _SubmergedHazardTrianglePainter oldDelegate) =>
      false;
}

/// Broadcasting signal ripples from hand
class _SignalWavesPainter extends CustomPainter {
  final double progress;

  _SignalWavesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final t = (progress + (i * 0.33)) % 1.0;
      final radius = 6.0 + (t * 18.0);
      final alpha = (1.0 - t).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = const Color(0xFFFF8F5A).withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width * 0.2, size.height * 0.5),
          radius: radius,
        ),
        -math.pi / 2.5,
        math.pi * 0.8,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignalWavesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Glowing neon route for Safe Routes card
class _NeonRoutePainter extends CustomPainter {
  final double progress;

  _NeonRoutePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final route = Path()
      ..moveTo(size.width * 0.2, size.height * 0.75)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.5,
        size.width * 0.4,
        size.height * 0.55,
        size.width * 0.55,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.7,
        size.height * 0.35,
        size.width * 0.75,
        size.height * 0.28,
        size.width * 0.82,
        size.height * 0.16,
      );

    // 1. Wide ambient green glow
    final glowPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawPath(route, glowPaint);

    // 2. Medium vibrant green line
    final midPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(route, midPaint);

    // 3. Crisp bright core
    final corePaint = Paint()
      ..color = const Color(0xFF86EFAC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(route, corePaint);
  }

  @override
  bool shouldRepaint(covariant _NeonRoutePainter oldDelegate) => false;
}
