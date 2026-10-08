import 'package:flutter/material.dart';
import '../../data/models/responder_models.dart';
import 'responder_login_screen.dart';
import 'responder_register_screen.dart';
import '../../../component1_evacuation/presentation/screens/citizen_dashboard_screen.dart';
import '../../../component2_reporting/presentation/screens/quick_hazard_screen.dart';
import '../../../component3_relief_tracking/presentation/screens/camp_dashboard_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  UserRole _selectedRole = UserRole.responder;

  void _proceedToLogin() {
    switch (_selectedRole) {
      case UserRole.responder:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResponderLoginScreen(initialRole: _selectedRole),
          ),
        );
        break;
      case UserRole.citizen:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CitizenDashboardScreen()),
        );
        break;
      case UserRole.volunteer:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const QuickHazardScreen()),
        );
        break;
      case UserRole.campLeader:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CampDashboardScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Top Agency Badge
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'NATIONAL DISASTER MANAGEMENT PLATFORM',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App Logo & Shield Header
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFF6D00).withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_outlined,
                      size: 44,
                      color: Color(0xFFFF6D00),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'FloodGuard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Stay safe with one-tap alerts and verified routes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Role Selection Header
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
                  const SizedBox(width: 8),
                  const Text(
                    'SELECT SYSTEM ROLE TO ENTER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Role Option Cards
              _buildRoleCard(
                role: UserRole.responder,
                title: 'Emergency Dispatcher / Responder',
                subtitle:
                    'Component 4 • Triage incident queue, dispatch units & live tracking',
                icon: Icons.cell_tower,
                color: const Color(0xFFFF6D00),
                isHighlight: true,
              ),

              const SizedBox(height: 10),

              _buildRoleCard(
                role: UserRole.citizen,
                title: 'Affected Citizen',
                subtitle:
                    'Component 1 • Evacuation route, weather alerts & battery save mode',
                icon: Icons.person_pin_circle_outlined,
                color: const Color(0xFF00E676),
              ),

              const SizedBox(height: 10),

              _buildRoleCard(
                role: UserRole.volunteer,
                title: 'Community Volunteer Reporter',
                subtitle:
                    'Component 2 • Icon-driven hazard reporting with auto-tagged GPS',
                icon: Icons.add_location_alt_outlined,
                color: const Color(0xFF38BDF8),
              ),

              const SizedBox(height: 10),

              _buildRoleCard(
                role: UserRole.campLeader,
                title: 'Relief Camp Triage Leader',
                subtitle:
                    'Component 3 • Manage shelter beds, supplies & food logistics',
                icon: Icons.night_shelter_outlined,
                color: const Color(0xFFA855F7),
              ),

              const SizedBox(height: 28),

              // Primary Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  shadowColor:
                      const Color(0xFFFF6D00).withValues(alpha: 0.4),
                ),
                onPressed: _proceedToLogin,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedRole == UserRole.responder
                          ? 'ENTER RESPONDER PORTAL'
                          : 'LAUNCH ${_selectedRole.displayName.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Create Account Link (for official responders & users)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0xFF334155)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ResponderRegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  'CREATE NEW RESPONDER ACCOUNT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Emergency Hotline Footer
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_in_talk, color: Colors.redAccent, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Emergency Hotlines: 117 (DMC) • 119 (Police) • 110 (Fire)',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E293B)
              : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF1E293B),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isHighlight) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6D00)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PART 4',
                            style: TextStyle(
                              color: Color(0xFFFF6D00),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : const Color(0xFF475569),
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
