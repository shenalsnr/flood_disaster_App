import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/volunteer_drawer.dart';
import '../widgets/hazard_report_details_sheet.dart';
import 'hazard_report_wizard_screen.dart';

/// Main Dashboard Screen for District Volunteer (Component 2: Ground Hazard Reporting).
/// Features the Top App Bar from Screenshot 2, the Drawer from Screenshot 3,
/// and the complete Main Dashboard from Screenshot 1 with full interactivity.
class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Default initial reports matching Screenshot 1 exactly
  final List<HazardReportItem> _defaultReports = const [
    HazardReportItem(
      id: 'rep-001',
      title: 'Flood (Severe)',
      location: 'Kolonnawa Road',
      timeAgo: '10 mins ago',
      status: 'VERIFIED',
      hazardType: 'Flash Flood',
      description:
          'Water level reached 1.2m over the culvert on Kolonnawa Road. High velocity flow towards low-lying settlements. Sandbags deployed.',
      reporter: 'Kapila Perera (Volunteer)',
      icon: Icons.waves_rounded,
      iconColor: Color(0xFFFF5252),
      waterLevel: 1.2,
    ),
    HazardReportItem(
      id: 'rep-002',
      title: 'Landslide Warning',
      location: 'Kandy Slope',
      timeAgo: '1 hour ago',
      status: 'PENDING',
      hazardType: 'Landslide',
      description:
          'Active slope slippage detected along the upper hill cut. Minor mudflow over the lower access path. Verification team en route.',
      reporter: 'Kapila Perera (Volunteer)',
      icon: Icons.landscape_rounded,
      iconColor: Color(0xFFFFB300),
      waterLevel: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openHazardWizard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const HazardReportWizardScreen(),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      drawer: VolunteerDrawer(
        onProfileTap: () => setState(() => _selectedTabIndex = 3),
        onReportsTap: () => setState(() => _selectedTabIndex = 1),
        onMapTap: () => setState(() => _selectedTabIndex = 2),
      ),
      // ── Top App Bar matching Screenshot 2 ──────────────────────────────────
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
            tooltip: 'Open Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        backgroundColor: const Color(0xFF070B14),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
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
          // Live Status Pill (ONLINE badge from Screenshot 1 & 2)
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00E676),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ONLINE',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Main Body with Tab Switching ───────────────────────────────────────
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildHomeDashboardTab(),
          _buildReportsListTab(),
          _buildLiveMapTab(),
          _buildProfileTab(),
        ],
      ),

      // ── Bottom Navigation Bar matching Screenshot 1 ────────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A111E),
          border: Border(
            top: BorderSide(color: Color(0xFF1E293B), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTabIndex,
          onTap: (index) => setState(() => _selectedTabIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFF6D00),
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Live Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 0: HOME DASHBOARD (Exact Match to Screenshot 1)
  // ===========================================================================
  Widget _buildHomeDashboardTab() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Kapila Perera';

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFFFF6D00),
        backgroundColor: const Color(0xFF0F172A),
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: District Volunteer & Hello, Kapila Perera ────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'District Volunteer',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Hello, $userName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Avatar thumbnail
                  GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 3),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF9800),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/volunteer_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const CircleAvatar(
                              backgroundColor: Color(0xFFFF6D00),
                              child: Text(
                                'KP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Kelani River Level Warning Card ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1117), // Deep dark reddish/black
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF3B3B).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B3B).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B3B).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF3B3B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelani River Level: WARNING',
                            style: TextStyle(
                              color: Color(0xFFFF3B3B),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Minor flooding reported upstream in Hanwella.',
                            style: TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Hero Action Card: "REPORT HAZARD" ────────────────────────
              _ReportHazardHeroCard(onTap: _openHazardWizard),

              const SizedBox(height: 28),

              // ── "My Recent Reports" Section Header ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'My Recent Reports',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFFFF8F5A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Stream of Reports with Fallback to Mock Items ─────────────
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('hazard_reports')
                    .orderBy('timestamp', descending: true)
                    .limit(6)
                    .snapshots(),
                builder: (context, snapshot) {
                  List<HazardReportItem> reportsToDisplay = [];

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final hazard = data['hazardType'] as String? ?? 'Hazard';
                      final isFlood = hazard.toLowerCase().contains('flood');
                      reportsToDisplay.add(
                        HazardReportItem(
                          id: doc.id,
                          title: data['severity'] != null
                              ? '$hazard (${data['severity']})'
                              : hazard,
                          location: data['location'] as String? ?? 'Field Sector',
                          timeAgo: 'Just now',
                          status: data['status'] as String? ?? 'VERIFIED',
                          hazardType: hazard,
                          description: data['description'] as String? ??
                              'Ground hazard verified by district volunteer.',
                          reporter: data['reporterName'] as String? ?? 'Kapila Perera',
                          icon: isFlood
                              ? Icons.waves_rounded
                              : Icons.landscape_rounded,
                          iconColor: isFlood
                              ? const Color(0xFFFF5252)
                              : const Color(0xFFFFB300),
                          waterLevel: (data['waterDepth'] as num?)?.toDouble(),
                        ),
                      );
                    }
                  }

                  // If Firestore is empty or still offline, merge default reports
                  if (reportsToDisplay.isEmpty) {
                    reportsToDisplay = _defaultReports;
                  }

                  return Column(
                    children: reportsToDisplay
                        .take(3)
                        .map((report) => _RecentReportCard(
                              report: report,
                              onTap: () =>
                                  HazardReportDetailsSheet.show(context, report),
                            ))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: REPORTS LIST VIEW
  // ===========================================================================
  Widget _buildReportsListTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Incident Reports',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Live reports submitted by you and the District Operations Unit.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ..._defaultReports.map(
                    (r) => _RecentReportCard(
                      report: r,
                      onTap: () => HazardReportDetailsSheet.show(context, r),
                    ),
                  ),
                  _RecentReportCard(
                    report: const HazardReportItem(
                      id: 'rep-003',
                      title: 'Fallen Tree - Power Line Down',
                      location: 'Avissawella Road, Km 22',
                      timeAgo: '3 hours ago',
                      status: 'VERIFIED',
                      hazardType: 'Obstruction',
                      description:
                          'Large Mara tree fell on high-tension power line. Road blocked. CEB notified.',
                      reporter: 'Kapila Perera',
                      icon: Icons.park_rounded,
                      iconColor: Color(0xFF4ADE80),
                    ),
                    onTap: () => HazardReportDetailsSheet.show(
                      context,
                      const HazardReportItem(
                        id: 'rep-003',
                        title: 'Fallen Tree - Power Line Down',
                        location: 'Avissawella Road, Km 22',
                        timeAgo: '3 hours ago',
                        status: 'VERIFIED',
                        hazardType: 'Obstruction',
                        description:
                            'Large Mara tree fell on high-tension power line. Road blocked. CEB notified.',
                        reporter: 'Kapila Perera',
                        icon: Icons.park_rounded,
                        iconColor: Color(0xFF4ADE80),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: LIVE MAP VIEW
  // ===========================================================================
  Widget _buildLiveMapTab() {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(6.9271, 79.8612),
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.wesafe.flooddisaster',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: const LatLng(6.9271, 79.8612),
                  width: 50,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 6),
                      ],
                    ),
                    child: const Icon(
                      Icons.waves_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                Marker(
                  point: const LatLng(6.9380, 79.8780),
                  width: 50,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 6),
                      ],
                    ),
                    child: const Icon(
                      Icons.landscape_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_searching_rounded, color: Color(0xFF00E676), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Active Volunteer Sector: Kelani Basin',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: VOLUNTEER PROFILE VIEW
  // ===========================================================================
  Widget _buildProfileTab() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Kapila Perera';
    final userEmail = user?.email ?? 'volunteer.kapila@dmc.org';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF9800), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/volunteer_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.person_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00E676).withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'OFFICIAL DISTRICT VOLUNTEER',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Metrics row
            Row(
              children: [
                _buildStatTile('24', 'Reports Sent', const Color(0xFFFF6D00)),
                const SizedBox(width: 12),
                _buildStatTile('19', 'Verified', const Color(0xFF00E676)),
                const SizedBox(width: 12),
                _buildStatTile('100%', 'Sync Rate', const Color(0xFF38BDF8)),
              ],
            ),

            const SizedBox(height: 28),
            // Profile details card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                children: [
                  _buildProfileRow('Badge ID', 'VOL-WP-2026-084'),
                  const Divider(color: Color(0xFF1E293B), height: 24),
                  _buildProfileRow('Division', 'Kolonnawa / Colombo East'),
                  const Divider(color: Color(0xFF1E293B), height: 24),
                  _buildProfileRow('Emergency Role', 'Flood Scout & Water Gauge'),
                  const Divider(color: Color(0xFF1E293B), height: 24),
                  _buildProfileRow('Affiliation', 'DMC Community Network'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
      ],
    );
  }
}

// =============================================================================
// SUB-WIDGET: HERO "REPORT HAZARD" CARD (Exact Match to Screenshot 1)
// =============================================================================
class _ReportHazardHeroCard extends StatefulWidget {
  final VoidCallback onTap;

  const _ReportHazardHeroCard({required this.onTap});

  @override
  State<_ReportHazardHeroCard> createState() => _ReportHazardHeroCardState();
}

class _ReportHazardHeroCardState extends State<_ReportHazardHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnimation = _pressController;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _pressController.reverse(),
        onTapUp: (_) {
          _pressController.forward();
          widget.onTap();
        },
        onTapCancel: () => _pressController.forward(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFB300), // Rich amber gold
                Color(0xFFFF8F00), // Vibrant amber
                Color(0xFFFF6D00), // Deep energetic orange
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.42),
                blurRadius: 30,
                offset: const Offset(0, 14),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular cloud hazard icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA000).withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFCC5500).withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_outlined,
                        size: 40,
                        color: Color(0xFF2E1700),
                      ),
                      Positioned(
                        top: 25,
                        child: Container(
                          width: 4,
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E1700),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 21,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E1700),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title: "REPORT HAZARD"
              const Text(
                'REPORT HAZARD',
                style: TextStyle(
                  color: Color(0xFF140D07), // Deep dark bold text
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle: "Tap to report in 3 simple steps"
              const Text(
                'Tap to report in 3 simple steps',
                style: TextStyle(
                  color: Color(0xFF3E230B),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SUB-WIDGET: RECENT REPORT CARD (Exact Match to Screenshot 1)
// =============================================================================
class _RecentReportCard extends StatelessWidget {
  final HazardReportItem report;
  final VoidCallback onTap;

  const _RecentReportCard({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = report.status.toUpperCase() == 'VERIFIED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111B2E), // Dark navy card
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Hazard Icon container (wave or landslide)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18253D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF263552),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    report.icon,
                    color: report.iconColor,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 16),

                // Report Title & Location Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.location} • ${report.timeAgo}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Status Chip: VERIFIED or PENDING
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFF00E676).withValues(alpha: 0.12)
                        : const Color(0xFFFFB300).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isVerified
                          ? const Color(0xFF00E676).withValues(alpha: 0.3)
                          : const Color(0xFFFFB300).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(
                      color: isVerified
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFFB300),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
