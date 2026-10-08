import 'package:flutter/material.dart';
import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import 'sign_in_screen.dart';
import '../../../component1_evacuation/presentation/screens/citizen_dashboard_screen.dart';
import '../../../component2_reporting/presentation/screens/quick_hazard_screen.dart';
import '../../../component3_relief_tracking/presentation/screens/camp_dashboard_screen.dart';

class ResponderProfileScreen extends StatefulWidget {
  const ResponderProfileScreen({super.key});

  @override
  State<ResponderProfileScreen> createState() => _ResponderProfileScreenState();
}

class _ResponderProfileScreenState extends State<ResponderProfileScreen> {
  final ResponderController _controller = ResponderController();
  bool _audioSirenAlerts = true;
  bool _offlineCaching = true;

  @override
  Widget build(BuildContext context) {
    final isOnDuty = _controller.isOnDuty;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Dispatcher Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF6D00),
                              width: 2.5,
                            ),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.security,
                              size: 44,
                              color: Color(0xFFFF6D00),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isOnDuty
                                  ? const Color(0xFF00E676)
                                  : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF070B14), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nadeeka Perera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Senior Emergency Dispatcher • Unit #04',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Sri Lanka Disaster Management Centre (DMC)',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Duty Status Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnDuty
                        ? const Color(0xFF00E676).withValues(alpha: 0.5)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnDuty
                            ? const Color(0xFF00E676)
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnDuty
                                ? 'ON DUTY (DISPATCH ACTIVE)'
                                : 'OFF DUTY (STANDBY)',
                            style: TextStyle(
                              color: isOnDuty
                                  ? const Color(0xFF00E676)
                                  : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Text(
                            'Receiving active emergency incident stream',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOnDuty,
                      activeColor: const Color(0xFF00E676),
                      onChanged: (val) {
                        _controller.toggleDutyStatus(val);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Dispatch Performance Grid
              const Text(
                'MISSION PERFORMANCE ANALYTICS',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      label: 'Total Triage',
                      value: '128',
                      icon: Icons.assignment_outlined,
                      color: const Color(0xFFFF6D00),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatTile(
                      label: 'Units Deployed',
                      value: '94',
                      icon: Icons.local_shipping_outlined,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      label: 'Citizens Rescued',
                      value: '412',
                      icon: Icons.health_and_safety_outlined,
                      color: const Color(0xFF00E676),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatTile(
                      label: 'Avg Response',
                      value: '4.2m',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFFA855F7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Role Switching (Role-Based Access)
              const Text(
                'CROSS-ROLE ACCESS (PAIR TESTING)',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    _buildRoleSwitchTile(
                      title: 'Affected Citizen Portal (Component 1)',
                      subtitle: 'Evacuation routes, weather alerts & checklist',
                      icon: Icons.person_pin_circle_outlined,
                      color: const Color(0xFF00E676),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CitizenDashboardScreen()),
                        );
                      },
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    _buildRoleSwitchTile(
                      title: 'Volunteer Hazard Reporter (Component 2)',
                      subtitle: 'Ground truth photo & hazard submission',
                      icon: Icons.add_location_alt_outlined,
                      color: const Color(0xFF38BDF8),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const QuickHazardScreen()),
                        );
                      },
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    _buildRoleSwitchTile(
                      title: 'Relief Camp Triage Leader (Component 3)',
                      subtitle: 'Shelter capacity & supply logistics',
                      icon: Icons.night_shelter_outlined,
                      color: const Color(0xFFA855F7),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CampDashboardScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // System Settings
              const Text(
                'DISPATCH CONTROLS & TELEMETRY',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      dense: true,
                      title: const Text('Audible Emergency Siren',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Play critical frequency tone on Level 4 floods',
                          style: TextStyle(
                              color: Color(0xFF64748B), fontSize: 11)),
                      value: _audioSirenAlerts,
                      activeColor: const Color(0xFFFF6D00),
                      onChanged: (v) => setState(() => _audioSirenAlerts = v),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Offline GIS Tile Caching (10km)',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Pre-cached offline maps for cellular blackouts',
                          style: TextStyle(
                              color: Color(0xFF64748B), fontSize: 11)),
                      value: _offlineCaching,
                      activeColor: const Color(0xFF00E676),
                      onChanged: (v) => setState(() => _offlineCaching = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Sign Out Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'SIGN OUT FROM DISPATCHER TERMINAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
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

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
      onTap: onTap,
    );
  }
}
