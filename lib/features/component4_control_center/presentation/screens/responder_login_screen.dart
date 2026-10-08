import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/responder_models.dart';
import '../../data/services/auth_firebase_service.dart';
import '../controllers/responder_controller.dart';
import 'alert_dashboard_screen.dart';
import 'responder_register_screen.dart';
import '../../../component1_evacuation/presentation/screens/citizen_dashboard_screen.dart';
import '../../../component2_reporting/presentation/screens/quick_hazard_screen.dart';
import '../../../component3_relief_tracking/presentation/screens/camp_dashboard_screen.dart';

class ResponderLoginScreen extends StatefulWidget {
  final UserRole initialRole;
  final String? initialEmail;

  const ResponderLoginScreen({
    super.key,
    this.initialRole = UserRole.responder,
    this.initialEmail,
  });

  @override
  State<ResponderLoginScreen> createState() => _ResponderLoginScreenState();
}

class _ResponderLoginScreenState extends State<ResponderLoginScreen> {
  late UserRole _currentRole;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberCredentials = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      _passwordController.text = 'Secure@1234';
    } else {
      _populateRoleCredentials();
    }
  }

  void _populateRoleCredentials() {
    switch (_currentRole) {
      case UserRole.responder:
        _emailController.text = 'n.perera@dispatched.gov.lk';
        _passwordController.text = 'Disaster@2026';
        break;
      case UserRole.citizen:
        _emailController.text = 'chamara.d@gmail.com';
        _passwordController.text = 'Secure@1234';
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

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address to log in.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate & fetch user from Cloud Firestore
      final user = await AuthFirebaseService().loginUser(
        email: email,
        password: password,
      );

      // 2. Set current active user in global controller
      ResponderController().setCurrentUser(user);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 3. Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Welcome, ${user.fullName}! Connected to Firebase.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 2),
        ),
      );

      // 4. Role-based routing based on authenticated user's role from Firestore
      final role = user.role.toLowerCase();
      if (role.contains('citizen')) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CitizenDashboardScreen()),
        );
      } else if (role.contains('volunteer')) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const QuickHazardScreen()),
        );
      } else if (role.contains('camp') || role.contains('leader')) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CampDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AlertDashboardScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // OTP Reset PIN Feature requested by user
  void _openResetPinDialog() {
    final targetEmail = _emailController.text.trim();
    if (targetEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first to receive the OTP code.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Generate simulated 6-digit OTP
    final randomOtp = (100000 + Random().nextInt(900000)).toString();
    final otpInputController = TextEditingController();
    final newPinController = TextEditingController();
    bool obscureNewPin = true;

    // Show simulated notification banner
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read, color: Color(0xFF00E676)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'OTP Code sent to $targetEmail: $randomOtp (Valid for 5 mins)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 5),
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B132B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6D00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Color(0xFFFF6D00),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reset PIN / Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'OTP Verification via Email',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        color: Color(0xFFFF6D00), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'OTP sent to: $targetEmail\nTest Code: $randomOtp',
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ENTER 6-DIGIT OTP CODE',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: otpInputController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  color: Colors.white,
                  letterSpacing: 6,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  hintText: '••••••',
                  hintStyle: const TextStyle(
                    color: Color(0xFF475569),
                    letterSpacing: 6,
                  ),
                  prefixIcon: const Icon(Icons.pin,
                      color: Color(0xFFFF6D00), size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'NEW PIN / PASSWORD',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: newPinController,
                obscureText: obscureNewPin,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  hintText: 'Enter new secure PIN or password',
                  hintStyle:
                      const TextStyle(color: Color(0xFF475569), fontSize: 13),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Color(0xFFFF6D00), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewPin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () {
                      setModalState(() {
                        obscureNewPin = !obscureNewPin;
                      });
                    },
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final enteredOtp = otpInputController.text.trim();
                  final newPin = newPinController.text.trim();

                  if (enteredOtp != randomOtp) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid OTP code. Please enter the code sent to your email.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (newPin.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid PIN or password (min 4 characters).'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  // 1. Update password in Cloud Firestore
                  AuthFirebaseService().updatePassword(
                    email: targetEmail,
                    newPassword: newPin,
                  );

                  setState(() {
                    _passwordController.text = newPin;
                  });

                  Navigator.of(ctx).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF00E676)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PIN successfully updated in Firebase! You can now log in.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Color(0xFF1E293B),
                    ),
                  );
                },
                child: const Text(
                  'VERIFY OTP & UPDATE PIN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Circular Back Button (Matching Image 1)
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ResponderRegisterScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF151E32),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1E293B),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Secure Portal Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Top Brand Card (Matching Image 1)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF451A03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF7C2D12),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.security,
                          color: Color(0xFFFF6D00),
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disaster Response System',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Municipal Dispatch Authorization v4.2',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Field 1: OFFICIAL WORK EMAIL
              _buildFieldLabel('OFFICIAL WORK EMAIL'),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration(
                  hint: 'n.perera@dispatched.gov.lk',
                  icon: Icons.email,
                ),
              ),

              const SizedBox(height: 18),

              // Field 2: PASSWORD
              _buildFieldLabel('PASSWORD'),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _buildInputDecoration(
                  hint: '••••••••••••',
                  icon: Icons.lock,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Remember credentials & Reset PIN? Row (Matching Image 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberCredentials,
                          activeColor: const Color(0xFF0284C7),
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) {
                            setState(() => _rememberCredentials = v ?? true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember credentials',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _openResetPinDialog,
                    child: const Text(
                      'Reset PIN?',
                      style: TextStyle(
                        color: Color(0xFFFF6D00),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Primary Button: AUTHENTICATE & LOGIN ➔ (Matching Image 1)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'AUTHENTICATE & LOGIN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.login_rounded,
                                size: 18, color: Colors.white),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 22),

              // Bottom Link: New officer? Registration (Matching Image 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'New officer? ',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const ResponderRegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Registration',
                      style: TextStyle(
                        color: Color(0xFFFF6D00),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
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
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
      ),
    );
  }
}
