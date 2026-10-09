import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import 'incident_details_screen.dart';
import 'live_tracking_screen.dart';
import 'assign_responder_screen.dart';
import 'responder_profile_screen.dart';

class AlertDashboardScreen extends StatefulWidget {
  const AlertDashboardScreen({super.key});

  @override
  State<AlertDashboardScreen> createState() => _AlertDashboardScreenState();
}

class _AlertDashboardScreenState extends State<AlertDashboardScreen>
    with TickerProviderStateMixin {
  final ResponderController _controller = ResponderController();
  int _bottomNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeInController;
  late Animation<double> _fadeInAnimation;
  late AnimationController _statusBarController;
  late Animation<double> _statusBarSlide;

  // Live clock
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChange);

    // Pulse animation for live indicators
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade in for initial load
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );
    _fadeInController.forward();

    // Status bar slide in
    _statusBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _statusBarSlide = CurvedAnimation(
      parent: _statusBarController,
      curve: Curves.easeOutCubic,
    );
    _statusBarController.forward();

    // Start live clock
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  void _updateClock() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    if (mounted) setState(() => _currentTime = '$h:$m:$s');
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    _searchController.dispose();
    _pulseController.dispose();
    _fadeInController.dispose();
    _statusBarController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _showBroadcastDialog() {
    final titleController = TextEditingController(text: 'IMMEDIATE EVACUATION ORDER');
    final zoneController = TextEditingController(text: 'Sector 4 Low-Lying Area');
    final messageController = TextEditingController(
      text:
          'Water level in Kalu Ganga / Kelani Basin critical. Flash flood imminent. Evacuate to Central College immediately.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cell_tower, color: Colors.redAccent, size: 26),
            SizedBox(width: 10),
            Text(
              'BROADCAST ZONE ALERT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Broadcast emergency alarm directly to all citizen mobile devices in target perimeter.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text(
                'TARGET ZONE',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: zoneController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ALERT TITLE',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'CITIZEN WARNING INSTRUCTION',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('TRANSMIT ALERT'),
            onPressed: () {
              _controller.broadcastZoneAlert(
                zone: zoneController.text,
                title: titleController.text,
                message: messageController.text,
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Targeted zone alert transmitted via Cellular Emergency Broadcast!'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == _bottomNavIndex) return;

    if (index == 0) {
      setState(() => _bottomNavIndex = 0);
    } else if (index == 1) {
      // Live Tracking Map
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveTrackingScreen(
            incident: _controller.activeIncident ?? _controller.incidents.first,
          ),
        ),
      );
    } else if (index == 2) {
      // Assign Responder
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AssignResponderScreen(
            incident: _controller.activeIncident ?? _controller.incidents.first,
          ),
        ),
      );
    } else if (index == 3) {
      // Profile
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ResponderProfileScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _controller.filteredIncidents.where((i) {
      if (_searchQuery.isEmpty) return true;
      return i.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.id.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        title: Row(
          children: [
            // Animated shield icon with glow
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6D00).withValues(alpha: _pulseAnimation.value * 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.shield, color: Color(0xFFFF6D00), size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _controller.currentUser?.fullName ?? 'Nadeeka Perera',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _controller.currentUser?.roleTitle ??
                      'DISPATCHER #04 • DMC CONTROL',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.cell_tower, size: 16),
              label: const Text(
                'BROADCAST',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: _showBroadcastDialog,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ResponderProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Column(
            children: [
              // Animated Status & Quick Summary Bar
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_statusBarSlide),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0F172A),
                        const Color(0xFF0F172A).withValues(alpha: 0.95),
                      ],
                    ),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFF1E293B), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Animated live pulse dot
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E676).withValues(alpha: _pulseAnimation.value),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'DISPATCH STATION: ON DUTY',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      // Live clock
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _currentTime,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Icon(
                          Icons.sync,
                          color: Color.lerp(
                            const Color(0xFF38BDF8).withValues(alpha: 0.5),
                            const Color(0xFF38BDF8),
                            _pulseAnimation.value,
                          ),
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Mini Spatial Overview Banner with hover effect
              _buildMapBanner(),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    hintText: 'Search by Sector, ID (#FLD-089) or Hazard...',
                    hintStyle:
                        const TextStyle(color: Color(0xFF475569), fontSize: 12),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1E293B)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1E293B)),
                    ),
                  ),
                ),
              ),

              // SEVERITY FILTER TABS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSeverityFilterChip(
                          'ALL', _controller.countFor('ALL'), const Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      _buildSeverityFilterChip('CRITICAL',
                          _controller.countFor('CRITICAL'), const Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      _buildSeverityFilterChip(
                          'HIGH', _controller.countFor('HIGH'), const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _buildSeverityFilterChip(
                          'MED', _controller.countFor('MED'), const Color(0xFFFFB020)),
                      const SizedBox(width: 8),
                      _buildSeverityFilterChip(
                          'LOW', _controller.countFor('LOW'), const Color(0xFF10B981)),
                    ],
                  ),
                ),
              ),

              // Triage Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'INCOMING REPORTS • SORTED BY SEVERITY',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '${filteredList.length} items',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Incident List with staggered animations
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Color(0xFF00E676), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No incidents in $_searchQuery ${_controller.selectedSeverityFilter} filter',
                              style: const TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final incident = filteredList[index];
                          return _AnimatedIncidentCard(
                            index: index,
                            child: _buildIncidentTriageCard(incident),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF1E293B), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: _onBottomNavTap,
          backgroundColor: const Color(0xFF0B132B),
          selectedItemColor: const Color(0xFFFF6D00),
          unselectedItemColor: const Color(0xFF64748B),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alt_route_rounded),
              label: 'Live Track',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              label: 'Teams',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LiveTrackingScreen(
              incident: _controller.activeIncident ??
                  _controller.incidents.first,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.map_outlined,
                  color: Color(0xFFFF6D00), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Multi-Agency Map & Coordinates Feed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.open_in_new,
                          color: Colors.white54, size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_controller.incidents.length} active incidents • ${_controller.teams.where((t) => t.isAvailable).length} available rescue units',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
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

  Widget _buildSeverityFilterChip(String label, int count, Color color) {
    final isSelected = _controller.selectedSeverityFilter == label;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ChoiceChip(
        selected: isSelected,
        label: Text('$label ($count)'),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
        selectedColor: color,
        backgroundColor: const Color(0xFF1E293B),
        side: BorderSide(
          color: isSelected ? color : const Color(0xFF334155),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (val) {
          if (val) _controller.setFilter(label);
        },
      ),
    );
  }

  Widget _buildIncidentTriageCard(IncidentReport incident) {
    Color severityColor;
    switch (incident.severity) {
      case IncidentSeverity.critical:
        severityColor = const Color(0xFFEF4444);
        break;
      case IncidentSeverity.high:
        severityColor = const Color(0xFFF59E0B);
        break;
      case IncidentSeverity.medium:
        severityColor = const Color(0xFFFFB020);
        break;
      case IncidentSeverity.low:
        severityColor = const Color(0xFF10B981);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111E36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: incident.severity == IncidentSeverity.critical
              ? severityColor.withValues(alpha: 0.5)
              : const Color(0xFF1E293B),
          width: incident.severity == IncidentSeverity.critical ? 1.5 : 1,
        ),
        boxShadow: incident.severity == IncidentSeverity.critical
            ? [
                BoxShadow(
                  color: severityColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _controller.setActiveIncident(incident);
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    IncidentDetailsScreen(incident: incident),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Badges & Time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: severityColor, width: 1),
                      ),
                      child: Text(
                        incident.severityLabel,
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (incident.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified,
                                color: Color(0xFF38BDF8), size: 12),
                            SizedBox(width: 4),
                            Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    // Animated time badge for critical
                    if (incident.severity == IncidentSeverity.critical)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: _pulseAnimation.value * 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            incident.timeAgo,
                            style: TextStyle(
                              color: severityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        incident.timeAgo,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Incident Title & Hazard Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        incident.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${incident.id}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Location with pin icon
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFFFF6D00), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incident.location,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Divider
                const Divider(color: Color(0xFF1E293B), height: 1),

                const SizedBox(height: 8),

                // Bottom row: Corroboration & Status button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_outline,
                            color: Color(0xFF94A3B8), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${incident.corroboratingCount} Reports',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: incident.status == IncidentStatus.incoming
                            ? const Color(0xFFFF6D00)
                            : incident.status == IncidentStatus.dispatched
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: (incident.status == IncidentStatus.incoming
                                    ? const Color(0xFFFF6D00)
                                    : incident.status == IncidentStatus.dispatched
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFF10B981))
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            incident.statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Staggered entrance animation for incident cards
class _AnimatedIncidentCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedIncidentCard({required this.index, required this.child});

  @override
  State<_AnimatedIncidentCard> createState() => _AnimatedIncidentCardState();
}

class _AnimatedIncidentCardState extends State<_AnimatedIncidentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger based on index
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
