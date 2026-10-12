import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/language_button.dart';
import '../widgets/c4_ui.dart';

import '../../data/models/responder_models.dart';
import '../../data/services/auth_firebase_service.dart';
import '../controllers/responder_controller.dart';
import '../../data/services/session_service.dart';
import 'role_router.dart';
import 'responder_register_screen.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberCredentials = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Only fill email if it was passed from the registration screen
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
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
        SnackBar(
          content: Text(tr('login_enter_email')),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('login_enter_password')),
          backgroundColor: Color(0xFFDC2626),
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
              const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('login_welcome', {'name': user.fullName}),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1C2740),
          duration: const Duration(seconds: 2),
        ),
      );

      // 4. Remember this sign-in (or forget it) for the next app start
      if (_rememberCredentials) {
        await SessionService.save(user.email);
      } else {
        await SessionService.clear();
      }
      if (!mounted) return;

      // 5. Role-based routing based on the role stored in Firestore
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => dashboardForRole(user.role)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFF87171)),
              const SizedBox(width: 10),
              Expanded(child: Text(tr(errorMsg))),
            ],
          ),
          backgroundColor: const Color(0xFF1C2740),
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
        SnackBar(
          content: Text(
            tr('otp_need_email'),
          ),
          backgroundColor: Color(0xFFDC2626),
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
            const Icon(Icons.mark_email_read, color: Color(0xFF34D399)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('otp_sent_snack', {'email': targetEmail, 'otp': randomOtp}),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C2740),
        duration: const Duration(seconds: 5),
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
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
                    color: const Color(0xFF2B3A55),
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
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Color(0xFF38BDF8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('reset_title'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          tr('otp_via_email'),
                          style: TextStyle(
                            color: Color(0xFFB6C2D6),
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
                  color: const Color(0xFF131C2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1C2740)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF38BDF8),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr('otp_sent_to', {'email': targetEmail, 'otp': randomOtp}),
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
              Text(
                tr('enter_otp'),
                style: TextStyle(
                  color: Color(0xFFB6C2D6),
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
                  fillColor: const Color(0xFF131C2E),
                  hintText: '••••••',
                  hintStyle: const TextStyle(
                    color: Color(0xFF475569),
                    letterSpacing: 6,
                  ),
                  prefixIcon: const Icon(
                    Icons.pin,
                    color: Color(0xFF38BDF8),
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1C2740)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1C2740)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF38BDF8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tr('new_pin'),
                style: TextStyle(
                  color: Color(0xFFB6C2D6),
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
                  fillColor: const Color(0xFF131C2E),
                  hintText: tr('new_pin_hint'),
                  hintStyle: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF38BDF8),
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewPin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFFB6C2D6),
                      size: 20,
                    ),
                    onPressed: () {
                      setModalState(() {
                        obscureNewPin = !obscureNewPin;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1C2740)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1C2740)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF38BDF8),
                      width: 1.5,
                    ),
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
                      SnackBar(
                        content: Text(
                          tr('otp_invalid'),
                        ),
                        backgroundColor: Color(0xFFDC2626),
                      ),
                    );
                    return;
                  }

                  if (newPin.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr('pin_invalid'),
                        ),
                        backgroundColor: Color(0xFFDC2626),
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
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF34D399)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr('pin_updated'),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Color(0xFF1C2740),
                    ),
                  );
                },
                child: Text(
                  tr('verify_update'),
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
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 520,
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Circular Back Button
              Row(
                children: [
                  if (Navigator.of(context).canPop())
                    GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF151E32),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1C2740),
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
                  if (Navigator.of(context).canPop()) const SizedBox(width: 14),
                  Flexible(child: Text(
                    tr('portal_title'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  )),
                  const SizedBox(width: 10),
                  const LanguageButton(),
                ],
              ),

              const SizedBox(height: 22),

              // Top Brand Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131C2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1C2740), width: 1),
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
                          color: Color(0xFF38BDF8),
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('disaster_system'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            tr('municipal'),
                            style: TextStyle(
                              color: Color(0xFFB6C2D6),
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

              // Field 1: EMAIL
              _buildFieldLabel(tr('work_email')),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration(
                  hint: tr('enter_email'),
                  icon: Icons.email,
                ),
              ),

              const SizedBox(height: 18),

              // Field 2: PASSWORD
              _buildFieldLabel(tr('password')),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _buildInputDecoration(
                  hint: tr('enter_password'),
                  icon: Icons.lock,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFFB6C2D6),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Remember credentials & Reset PIN? Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Row(mainAxisSize: MainAxisSize.min, 
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
                      Flexible(child: Text(
                        tr('remember'),
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 13,
                        ),
                      )),
                    ],
                  )),
                  GestureDetector(
                    onTap: _openResetPinDialog,
                    child: Text(
                      tr('reset_pin_q'),
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Primary Button: AUTHENTICATE & LOGIN
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(child: Text(
                              tr('login_btn'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            )),
                            SizedBox(width: 8),
                            Icon(
                              Icons.login_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 22),

              // Bottom Link: New officer? Registration
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(
                    tr('new_officer'),
                    style: TextStyle(color: Color(0xFFB6C2D6), fontSize: 13),
                  )),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const ResponderRegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      tr('registration'),
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
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
        )),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        tr(label),
        style: const TextStyle(
          color: Color(0xFFB6C2D6),
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
      fillColor: const Color(0xFF131C2E),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1C2740)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1C2740)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
      ),
    );
  }
}
