import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/warning_alert.dart';
import '../../../../core/services/notification_service.dart';

import 'evacuation_checklist_screen.dart';
import 'emergency_contacts_screen.dart';
import 'safe_routing_map_screen.dart';
import 'safe_arrival_checkin_screen.dart';
import 'citizen_drawer.dart';
import 'citizen_settings_screen.dart';
import '../../../component4_control_center/presentation/controllers/responder_controller.dart';
import '../../../../core/theme/appearance.dart';

import '../../../../core/localization/app_strings.dart';
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

  bool? _pushNotificationsEnabled = true;
  final Set<String> _notifiedWarningIds = {};

  @override
  void initState() {
    super.initState();
    NotificationService.instance.registerChannels();
    _loadNotificationSetting();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pushNotificationsEnabled =
            prefs.getBool('c1_push_notifications') ?? true;
      });
    }
  }

  void _onWarningsReceived(List<WarningAlert> alerts) {
    if (!(_pushNotificationsEnabled ?? true)) return;

    for (final alert in alerts) {
      if (!_notifiedWarningIds.contains(alert.id)) {
        _notifiedWarningIds.add(alert.id);
        NotificationService.instance.showDisasterWarningNotification(
          id: alert.id.hashCode & 0x7FFFFFFF,
          title: '🚨 ${alert.severity.toUpperCase()} ALERT: ${alert.hazardType}',
          body:
              '${alert.locationZone.isNotEmpty ? "${alert.locationZone} — " : ""}${alert.description}',
          severity: alert.severity,
        );
      }
    }
  }

  void _showNotificationCenter(
      BuildContext context, List<WarningAlert>? alerts, String district) {
    final alertList = alerts ?? <WarningAlert>[];
    final bool isPushActive = _pushNotificationsEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationCenterSheet(
        alerts: alertList,
        district: district,
        pushNotificationsEnabled: isPushActive,
        onManageSettings: () async {
          Navigator.pop(ctx);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CitizenSettingsScreen()),
          );
          _loadNotificationSetting();
        },
        onViewRoute: () {
          Navigator.pop(ctx);
          _push(const SafeRoutingMapScreen());
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Alert targeting ────────────────────────────────────────────────────────
  static String _norm(String v) => v
      .toLowerCase()
      .replaceAll('district', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _isAll(String v) {
    final n = _norm(v);
    return n.isEmpty || n == 'all';
  }

  /// A warning reaches a citizen when its district is "All" or equals the
  /// citizen's district, AND its city is "All" or equals the citizen's city.
  static bool _alertMatches(WarningAlert w, String district, String city) {
    final districtOk = _isAll(w.district) || _norm(w.district) == _norm(district);
    if (!districtOk) return false;
    return _isAll(w.city) || _norm(w.city) == _norm(city);
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

        // Blank profile values fall back to the logged-in account, then Colombo.
        String pickText(Object? fromDoc, String? fromAccount) {
          final d = (fromDoc as String?)?.trim() ?? '';
          if (d.isNotEmpty) return d;
          final a = fromAccount?.trim() ?? '';
          return a.isNotEmpty ? a : 'Colombo';
        }
        final String currentCitizenDistrict = pickText(
            userData['district'], ResponderController().currentUser?.district);
        final String currentCitizenCity = pickText(
            userData['city'], ResponderController().currentUser?.city);
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
        final photoUrl = userData['photoUrl'] as String?;

        print("CITIZEN LOC: $currentCitizenDistrict, $currentCitizenCity");

        return StreamBuilder<QuerySnapshot>(
          // All warnings are read and matched below, so spelling / letter-case
          // differences in district or city never hide an alert.
          stream: FirebaseFirestore.instance
              .collection('warnings')
              .snapshots(),
          builder: (context, snapshot) {
            WarningAlert? topAlert;
            List<WarningAlert> matchingAlerts = [];

            if (snapshot.hasData && snapshot.data != null) {
              // Strict Safety Net: iterate through docs and manually verify district & city
              for (final doc in snapshot.data!.docs) {
                try {
                  final alert = WarningAlert.fromDoc(doc);
                  if (_alertMatches(alert, currentCitizenDistrict, currentCitizenCity)) {
                    matchingAlerts.add(alert);
                  }
                } catch (e) {
                  debugPrint('Warning doc safety net validation error: $e');
                }
              }
              matchingAlerts.sort((a, b) => b.issuedTimestamp.compareTo(a.issuedTimestamp));

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _onWarningsReceived(matchingAlerts);
              });
            }

            if (matchingAlerts.isNotEmpty) {
              // Only run reduce if matching list is not empty
              topAlert = matchingAlerts.reduce(
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
              backgroundColor: const Color(0xFF0B1220),
              drawer: const CitizenDrawer(),
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                leading: Builder(
                  builder: (ctx) => IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    tooltip: tr('Open Menu'),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                titleSpacing: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: Color(0xFF34D399),
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                          children: [
                            TextSpan(
                              text: tr('We'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: tr('Safe'),
                              style: const TextStyle(color: Color(0xFF34D399)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: const EdgeInsets.all(6),
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: 'Disaster Warnings',
                        onPressed: () =>
                            _showNotificationCenter(context, matchingAlerts, currentCitizenDistrict),
                      ),
                      if (matchingAlerts.isNotEmpty)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF1744),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 15,
                              minHeight: 15,
                            ),
                            child: Center(
                              child: Text(
                                '${matchingAlerts.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 21,
                    ),
                    tooltip: 'Settings & Preferences',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CitizenSettingsScreen(),
                        ),
                      );
                      _loadNotificationSetting();
                    },
                  ),
                  const ThemeToggleButton(
                    visualDensity: VisualDensity.compact,
                    constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.all(6),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 8),
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
                    colors: [Color(0xFF112240), Color(0xFF0B1220)],
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
                            border: Border.all(color: const Color(0xFF1C2740)),
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
                                        color: Color(0xFF34D399),
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
                                        color: const Color(0xFF34D399)
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF34D399)
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: photoUrl != null && photoUrl.isNotEmpty
                                          ? (photoUrl.startsWith('http')
                                              ? Unfiltered(child: Image.network(
                                                  photoUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.person_rounded, color: Color(0xFF34D399), size: 22),
                                                ))
                                              : Unfiltered(child: Image.memory(
                                                  base64Decode(photoUrl),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.person_rounded, color: Color(0xFF34D399), size: 22),
                                                )))
                                          : const Icon(
                                              Icons.person_rounded,
                                              color: Color(0xFF34D399),
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
                                            tr(citizenName),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            tr('Sector: {p0}', {'p0': (citizenZone).toString()}),
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34D399)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tr('ACTIVE'),
                                        style: TextStyle(
                                          color: Color(0xFF34D399),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )),
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
                          _AllClearCard(district: currentCitizenDistrict),

                        // ── Multiple active warnings list ────────────────────
                        if (matchingAlerts.length > 1) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(child: Text(
                                tr('{p0} Active Warnings', {'p0': (matchingAlerts.length).toString()}),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              )),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...matchingAlerts
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
                                color: const Color(0xFF34D399),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x6634D399),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(child: Text(
                              tr('Emergency Actions'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            )),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Primary Action: Safe Route ──────────────────────────────────
                        _PremiumActionCard(
                          onTap: () => _push(const SafeRoutingMapScreen()),
                          icon: Icons.alt_route_rounded,
                          title: tr('Safe Route'),
                          subtitle: tr('Fastest path to high ground'),
                          color: const Color(0xFFFBBF24),
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
                                label: tr('Go Bag\nChecklist'),
                                color: const Color(0xFF34D399),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _PremiumGridCard(
                                onTap: () =>
                                    _push(const EmergencyContactsScreen()),
                                icon: Icons.contact_phone_rounded,
                                label: tr('Emergency\nContacts'),
                                color: const Color(0xFF38BDF8),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Secondary Action (Full Width) ───────────────────────────────
                        _PremiumActionCard(
                          onTap: () => _push(const SafeArrivalCheckInScreen()),
                          icon: Icons.verified_user_rounded,
                          title: tr('Safe Arrival Check-In'),
                          subtitle: tr('Mark yourself and family as safe'),
                          color: const Color(0xFF38BDF8),
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
            color: const Color(0xFF131C2E), // Very dark slate/blue
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
                      tr(widget.title),
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
                        tr(widget.subtitle!),
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
            color: const Color(0xFF131C2E),
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
                tr(widget.label),
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
    'Watch': [Color(0xFFFBBF24), Color(0xFFFF8F00)],
    'Warning': [Color(0xFF38BDF8), Color(0xFFE65100)],
    'Critical': [Color(0xFFF87171), Color(0xFFD50000)], // More vibrant reds
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
    final gradColors = _gradients[widget.severity] ?? [const Color(0xFFF87171), const Color(0xFFD50000)];
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
                      Expanded(
                        child: Text(
                          tr('EMERGENCY ALERT'),
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
                    tr(widget.title),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(widget.body),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 20),
                  // Live metrics row — use Wrap so pills wrap on small screens
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetricPill(
                        icon: Icons.water_rounded,
                        label: '${widget.waterLevel.toStringAsFixed(2)} m',
                        hint: tr('Water Level'),
                      ),
                      _MetricPill(
                        icon: Icons.grain_rounded,
                        label: tr('{p0} mm', {'p0': (widget.rainfall.toStringAsFixed(1)).toString()}),
                        hint: tr('Rainfall'),
                      ),
                      _MetricPill(
                        icon: Icons.air_rounded,
                        label: tr('{p0} kph', {'p0': (widget.windSpeed.toStringAsFixed(1)).toString()}),
                        hint: tr('Wind Speed'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                      const SizedBox(width: 6),
                      Flexible(child: Text(
                        tr(widget.time),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
          Flexible(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(hint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                tr(label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )),
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
          color: const Color(0xFF34D399).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34D399).withValues(alpha: 0.08),
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
              color: const Color(0xFF34D399).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF34D399),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('All Clear'),
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('No active warnings in {p0}.', {'p0': (district).toString()}),
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
    'Watch': Color(0xFFFBBF24),
    'Warning': Color(0xFF38BDF8),
    'Critical': Color(0xFFF87171),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[alert.severity] ?? const Color(0xFFFBBF24);
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tr('{p0} m  •  {p1} mm  •  {p2} kph', {'p0': (alert.waterLevelMeters.toStringAsFixed(2)).toString(), 'p1': (alert.rainfallMm.toStringAsFixed(1)).toString(), 'p2': (alert.windSpeedKmh.toStringAsFixed(1)).toString()}),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tr(alert.severity),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          )),
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
        ? const Color(0xFF34D399).withValues(alpha: 0.15)
        : const Color(0xFFB71C1C).withValues(alpha: 0.85);
    final borderColor = isSafe
        ? const Color(0xFF34D399).withValues(alpha: 0.4)
        : Colors.redAccent.shade100.withValues(alpha: 0.5);
    final shadowColor = isSafe
        ? const Color(0x3334D399)
        : const Color(0x4DB71C1C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 6)],
      ),
      child: Text(
        tr(level),
        style: TextStyle(
          color: isSafe ? const Color(0xFF34D399) : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
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
              Flexible(child: Text(
                tr('SYSTEM STATUS'),
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              )),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            Icons.cell_tower,
            'Network: Online',
            const Color(0xFF34D399),
          ),
          const SizedBox(height: 14),
          _buildStatusRow(
            Icons.offline_pin_rounded,
            'Map cached (10km)',
            const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 14),
          _buildStatusRow(
            Icons.battery_4_bar_rounded,
            'Battery-save ON',
            const Color(0xFFFBBF24),
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
        Flexible(child: Text(
          tr(label),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        )),
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

// ---------------------------------------------------------------------------
// Notification Center Bottom Sheet Modal
// ---------------------------------------------------------------------------
class _NotificationCenterSheet extends StatelessWidget {
  final List<WarningAlert>? alerts;
  final String district;
  final bool? pushNotificationsEnabled;
  final VoidCallback onManageSettings;
  final VoidCallback onViewRoute;

  const _NotificationCenterSheet({
    this.alerts,
    this.district = 'Galle',
    this.pushNotificationsEnabled,
    required this.onManageSettings,
    required this.onViewRoute,
  });

  @override
  Widget build(BuildContext context) {
    final alertList = alerts ?? <WarningAlert>[];
    final bool isPushActive = pushNotificationsEnabled ?? true;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1.5),
          left: BorderSide(color: Color(0xFF1E293B), width: 1.5),
          right: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF00E676),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Disaster Alerts & Warnings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alertList.isEmpty
                              ? 'All clear in your registered area ($district)'
                              : '${alertList.length} active emergency alert${alertList.length > 1 ? "s" : ""}',
                          style: TextStyle(
                            color: alertList.isEmpty
                                ? const Color(0xFF00E676)
                                : const Color(0xFFFF9F0A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Settings status banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(
                    isPushActive
                        ? Icons.check_circle_rounded
                        : Icons.notifications_off_rounded,
                    color: isPushActive
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF9F0A),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isPushActive
                          ? 'Status bar & push alerts active for $district'
                          : 'Push notifications are currently muted',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onManageSettings,
                    child: const Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 6),

            // Alerts Content List
            if (alertList.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 14, 32, 28),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Color(0xFF00E676),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Zone Status: All Clear ($district)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No active flood or disaster warnings in $district. Broadcast warnings will automatically pop into your phone notification bar.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: alertList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final a = alertList[i];
                        final isCrit =
                            a.severity.toLowerCase() == 'critical';
                        final isWarn =
                            a.severity.toLowerCase() == 'warning';
                        final color = isCrit
                            ? const Color(0xFFFF1744)
                            : isWarn
                                ? const Color(0xFFFF9F0A)
                                : const Color(0xFF40C4FF);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131B2B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: color, width: 1),
                                    ),
                                    child: Text(
                                      a.severity.toUpperCase(),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      a.hazardType,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(a.issuedTimestamp),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (a.locationZone.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFF00E676),
                                        size: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Zone: ${a.locationZone}',
                                          style: const TextStyle(
                                            color: Color(0xFF00E676),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Text(
                                a.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                                softWrap: true,
                              ),
                              const SizedBox(height: 12),
                              // Live metrics chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (a.waterLevelMeters > 0)
                                    _metricChip(
                                      Icons.water_rounded,
                                      '${a.waterLevelMeters.toStringAsFixed(1)}m Water Level',
                                      color,
                                    ),
                                  if (a.rainfallMm > 0)
                                    _metricChip(
                                      Icons.cloud_rounded,
                                      '${a.rainfallMm.toStringAsFixed(0)}mm Rain',
                                      const Color(0xFF40C4FF),
                                    ),
                                  if (a.windSpeedKmh > 0)
                                    _metricChip(
                                      Icons.air_rounded,
                                      '${a.windSpeedKmh.toStringAsFixed(0)} km/h Wind',
                                      Colors.white70,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  onPressed: onViewRoute,
                                  icon: const Icon(
                                    Icons.navigation_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'EVACUATION ROUTE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
