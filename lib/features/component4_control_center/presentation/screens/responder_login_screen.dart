import 'package:flutter/material.dart';
import '../../data/models/responder_models.dart';
import 'alert_dashboard_screen.dart';
import 'responder_register_screen.dart';
import '../../../component1_evacuation/presentation/screens/citizen_dashboard_screen.dart';
import '../../../component2_reporting/presentation/screens/quick_hazard_screen.dart';
import '../../../component3_relief_tracking/presentation/screens/camp_dashboard_screen.dart';

class ResponderLoginScreen extends StatefulWidget {
  final UserRole initialRole;

  const ResponderLoginScreen({
    super.key,
    this.initialRole = UserRole.responder,
  });

  @override
  State<ResponderLoginScreen> createState() => _ResponderLoginScreenState();
}

class _ResponderLoginScreenState extends State<ResponderLoginScreen> {
  late UserRole _currentRole;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
    _populateDemoCredentials();
  }

  void _populateDemoCredentials() {
    switch (_currentRole) {
      case UserRole.responder:
        _emailController.text = 'n.perera@dispatched.gov.lk';
        _passwordController.text = 'Disaster@2026';
        break;
      case UserRole.citizen:
        _emailController.text = 'citizen.somapala@gmail.com';
        _passwordController.text = 'Safe@2026';
        break;
      case UserRole.volunteer:
        _emailController.text = 'volunteer.kapila@dmc.org';
        _passwordController.text = 'Report@2026';
        break;
      case UserRole.campLeader:
        _emailController.text = 'leader.rohan@relief.gov.lk';
        _passwordController.text = 'Camp@2026';
        break;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      switch (_currentRole) {
        case UserRole.responder:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const AlertDashboardScreen(),
            ),
          );
          break;
        case UserRole.citizen:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const CitizenDashboardScreen(),
            ),
          );
          break;
        case UserRole.volunteer:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const QuickHazardScreen(),
            ),
          );
          break;
        case UserRole.campLeader:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const CampDashboardScreen(),
            ),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Role-Based Login',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header icon & title
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF6D00).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Color(0xFFFF6D00), size: 34),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'RESPONDER CONTROL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'MUNICIPAL DISPATCH SYSTEM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),

              const SizedBox(height: 24),

              // ROLE SELECTION SWITCHER CHIPS
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 4, bottom: 6),
                      child: Text(
                        'ACCESS ROLE PERMISSION',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: UserRole.values.map((role) {
                        final isSelected = _currentRole == role;
                        return ChoiceChip(
                          label: Text(
                            role == UserRole.responder
                                ? '👨‍🚒 Responder / Dispatcher'
                                : role == UserRole.citizen
                                    ? '🙋‍♂️ Citizen'
                                    : role == UserRole.volunteer
                                        ? '🤝 Volunteer'
                                        : '🏕️ Camp Leader',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF6D00),
                          backgroundColor: const Color(0xFF1E293B),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _currentRole = role;
                                _populateDemoCredentials();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Input: Dispatcher ID / Email
              _buildFieldLabel(
                _currentRole == UserRole.responder
                    ? 'DISPATCHER ID / OFFICIAL EMAIL'
                    : 'ACCOUNT EMAIL / USERNAME',
              ),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(
                  hint: 'Enter your ID or Email',
                  icon: Icons.badge_outlined,
                ),
              ),

              const SizedBox(height: 16),

              // Input: Password
              _buildFieldLabel('PASSWORD'),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(
                  hint: 'Enter password',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Remember me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: const Color(0xFFFF6D00),
                          onChanged: (v) {
                            setState(() => _rememberMe = v ?? true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember session',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Password recovery OTP sent to authorized DMC phone.'),
                          backgroundColor: Color(0xFF1E293B),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFFFF6D00),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SECURE LOGIN BUTTON
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
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_open_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _currentRole == UserRole.responder
                                ? 'SECURE DISPATCHER LOGIN'
                                : 'ENTER AS ${_currentRole.displayName.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // Operator Mode Banner (from wireframe 1)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111C33),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified,
                        color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AUTHORIZED OPERATOR PERSPECTIVE',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            _currentRole == UserRole.responder
                                ? 'Nadeeka Perera (Dispatcher Mode — Unit #04)'
                                : 'Role set to ${_currentRole.displayName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Link to Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Need official responder access? ',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ResponderRegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Register here',
                      style: TextStyle(
                        color: Color(0xFFFF6D00),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF0F172A),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFFFF6D00), size: 20),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
      ),
    );
  }
}
