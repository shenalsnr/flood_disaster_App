import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/warning_alert.dart';

import 'evacuation_checklist_screen.dart';
import 'emergency_contacts_screen.dart';
import 'safe_routing_map_screen.dart';
import 'safe_arrival_checkin_screen.dart';
import 'citizen_drawer.dart';

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
          .doc(FirebaseAuth.instance.currentUser?.uid ?? 'unknown')
          .snapshots(),
      builder: (context, userSnap) {
        final district =
            userSnap.hasData && userSnap.data != null && userSnap.data!.exists
            ? (userSnap.data!.data() as Map<String, dynamic>)['district']
                      as String? ??
                  'Colombo'
            : 'Colombo';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('warnings')
              .where('district', isEqualTo: district)
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

class _PremiumCriticalAlertCard extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final double waterLevel;
  final double rainfall;
  final String severity;

  const _PremiumCriticalAlertCard({
    required this.title,
    required this.body,
    required this.time,
    required this.waterLevel,
    required this.rainfall,
    required this.severity,
  });

  static const _gradients = {
    'Watch': [Color(0xFF7B5800), Color(0xFF4A3500)],
    'Warning': [Color(0xFFBF3600), Color(0xFF7A2000)],
    'Critical': [Color(0xFFD32F2F), Color(0xFF9B0000)],
  };

  @override
  Widget build(BuildContext context) {
    final gradColors =
        _gradients[severity] ??
        [const Color(0xFFD32F2F), const Color(0xFF9B0000)];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradColors[0], gradColors[1].withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66B71C1C),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'EMERGENCY ALERT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              _BlinkingDot(),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Live metrics row
          Row(
            children: [
              _MetricPill(
                icon: Icons.water_rounded,
                label: '${waterLevel.toStringAsFixed(2)} m',
                hint: 'Water Level',
              ),
              const SizedBox(width: 10),
              _MetricPill(
                icon: Icons.grain_rounded,
                label: '${rainfall.toStringAsFixed(1)} mm',
                hint: 'Rainfall',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                  '${alert.waterLevelMeters.toStringAsFixed(2)} m  •  ${alert.rainfallMm.toStringAsFixed(1)} mm',
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
