import 'package:flutter/material.dart';

import 'evacuation_checklist_screen.dart';
import 'emergency_contacts_screen.dart';
import 'safe_routing_map_screen.dart';
import 'safe_arrival_checkin_screen.dart';

// ---------------------------------------------------------------------------
// Citizen Dashboard Screen — Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// This screen is the main hub for the citizen-facing evacuation flow.
// All data is mocked locally; replace with Firebase streams when ready.
// ---------------------------------------------------------------------------

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen>
    with SingleTickerProviderStateMixin {
  // --- Mock alert data (replace with Firestore stream later) ---
  final String _alertLevel = 'CRITICAL';
  final String _alertTitle = 'Critical Flood Warning — Sector 4';
  final String _alertBody =
      'River Kalu Ganga has exceeded danger level. Immediate evacuation required for low-lying areas.';
  final String _alertTime = 'Issued: 22:01 LKT';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // --- Navigation grid items (strictly Component 1 only) ---
  List<_DashboardTile> get _tiles => [
    _DashboardTile(
      id: 'tile_checklist',
      icon: Icons.checklist_rounded,
      label: 'Go-Bag\nChecklist',
      color: const Color(0xFF00E676),
      onTap: () => _push(const EvacuationChecklistScreen()),
    ),
    _DashboardTile(
      id: 'tile_contacts',
      icon: Icons.contact_phone_rounded,
      label: 'Emergency\nContacts',
      color: const Color(0xFF40C4FF),
      onTap: () => _push(const EmergencyContactsScreen()),
    ),
    _DashboardTile(
      id: 'tile_safe_route',
      icon: Icons.alt_route_rounded,
      label: 'Safe\nRoute',
      color: const Color(0xFFFFD740),
      onTap: () => _push(const SafeRoutingMapScreen()),
    ),
    _DashboardTile(
      id: 'tile_checkin',
      icon: Icons.verified_user_rounded,
      label: 'Safe Arrival\nCheck-In',
      color: const Color(0xFFFF6D00),
      onTap: () => _push(const SafeArrivalCheckInScreen()),
    ),
  ];

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F), // Dark Navy Blue
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF060F1E,
        ), // Slightly darker navy for AppBar
        elevation: 0,
        title: Row(
          children: [
            const Icon(
              Icons.shield_rounded,
              color: Color(0xFF00E676),
              size: 22,
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
            padding: const EdgeInsets.only(right: 12),
            child: _AlertLevelBadge(level: _alertLevel),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Critical Alert Card ──────────────────────────────────────────
            ScaleTransition(
              scale: _pulseAnimation,
              child: _CriticalAlertCard(
                title: _alertTitle,
                body: _alertBody,
                time: _alertTime,
              ),
            ),

            const SizedBox(height: 24),

            // ── Section Header ───────────────────────────────────────────────
            const Text(
              'Emergency Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a tile to access your tools',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // ── Navigation Grid ──────────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: _tiles
                  .map((tile) => _DashboardGridTile(tile: tile))
                  .toList(),
            ),

            const SizedBox(height: 24),

            // ── Status Footer ────────────────────────────────────────────────
            _StatusFooter(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _CriticalAlertCard extends StatelessWidget {
  final String title;
  final String body;
  final String time;

  const _CriticalAlertCard({
    required this.title,
    required this.body,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFF7F0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99B71C1C),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '⚠ EMERGENCY ALERT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              // Blinking dot
              _BlinkingDot(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.shade100, width: 1),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _DashboardTile {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _DashboardGridTile extends StatefulWidget {
  final _DashboardTile tile;

  const _DashboardGridTile({required this.tile});

  @override
  State<_DashboardGridTile> createState() => _DashboardGridTileState();
}

class _DashboardGridTileState extends State<_DashboardGridTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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
    final tile = widget.tile;
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: tile.onTap,
        child: Semantics(
          label: tile.label.replaceAll('\n', ' '),
          button: true,
          child: Container(
            key: ValueKey(tile.id),
            decoration: BoxDecoration(
              color: const Color(0xFF112240), // Sleek lighter navy for cards
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: tile.color.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: tile.color.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: tile.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tile.icon, color: tile.color, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  tile.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tile.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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

class _StatusFooter extends StatelessWidget {
  final List<Map<String, dynamic>> _statusItems = const [
    {
      'icon': Icons.cell_tower,
      'label': 'Network: Online',
      'color': Color(0xFF00E676),
    },
    {
      'icon': Icons.offline_pin,
      'label': 'Map cached (10km)',
      'color': Color(0xFF40C4FF),
    },
    {
      'icon': Icons.battery_4_bar,
      'label': 'Battery-save ON',
      'color': Color(0xFFFFD740),
    },
  ];

  const _StatusFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36), // Navy matching footer
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Status',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          ..._statusItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
