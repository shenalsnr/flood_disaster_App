import 'package:flutter/material.dart';
import '../../data/models/responder_models.dart';
import 'responder_login_screen.dart';
import 'alert_dashboard_screen.dart';

class ResponderRegisterScreen extends StatefulWidget {
  const ResponderRegisterScreen({super.key});

  @override
  State<ResponderRegisterScreen> createState() =>
      _ResponderRegisterScreenState();
}

class _ResponderRegisterScreenState extends State<ResponderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Nadeeka Perera');
  final _emailController =
      TextEditingController(text: 'n.perera@dispatched.gov.lk');
  final _phoneController = TextEditingController(text: '+94 77 482 1029');
  final _badgeController = TextEditingController(text: 'DMC-DISP-04');
  final _passwordController = TextEditingController(text: 'Disaster@2026');
  final _confirmPasswordController =
      TextEditingController(text: 'Disaster@2026');

  String _selectedSector = 'Colombo Sector 4 (Low-Lying Area)';
  String _selectedRoleType = 'Emergency Dispatcher';
  bool _agreedToProtocol = true;
  bool _obscurePassword = true;

  final List<String> _sectors = [
    'Colombo Sector 4 (Low-Lying Area)',
    'Kelani River Basin — Sector 2 Bund',
    'Ratnapura Central — Kalu Ganga Basin',
    'Gampaha District — Ja-Ela Flood Corridor',
    'Kalutara Coastal Lowlands',
  ];

  final List<String> _roles = [
    'Emergency Dispatcher',
    'First Responder Squad Lead',
    'Disaster Triage Officer',
    'Auxiliary EMT Coordinator',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _badgeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToProtocol) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please accept the National Disaster Management Protocol to proceed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00E676), size: 28),
            SizedBox(width: 10),
            Text('Account Created',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Responder account registered for ${_nameController.text}.\nBadge: ${_badgeController.text}\nSector: $_selectedSector',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Color(0xFFFF6D00), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Authorized credentials granted with Dispatcher Level 4 access.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const AlertDashboardScreen(),
                ),
              );
            },
            child: const Text('GO TO ALERT DASHBOARD',
                style: TextStyle(
                    color: Color(0xFFFF6D00), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          'Register Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Info Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFFFF6D00).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.badge_outlined,
                          color: Color(0xFFFF6D00), size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Your Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Component 4 • Municipal Dispatch Authorization',
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

                const SizedBox(height: 24),

                // Name
                _buildFieldLabel('OFFICER / FULL NAME'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    hint: 'e.g. Nadeeka Perera',
                    icon: Icons.person_outline,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter your name' : null,
                ),

                const SizedBox(height: 16),

                // Email
                _buildFieldLabel('OFFICIAL WORK EMAIL'),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    hint: 'e.g. n.perera@dispatched.gov.lk',
                    icon: Icons.email_outlined,
                  ),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Please enter valid official email'
                      : null,
                ),

                const SizedBox(height: 16),

                // Phone & Badge ID row
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('PHONE NUMBER'),
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            decoration: _buildInputDecoration(
                              hint: '+94 77 ...',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('OFFICER BADGE ID'),
                          TextFormField(
                            controller: _badgeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration(
                              hint: 'DMC-04',
                              icon: Icons.verified_user_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Assigned Sector
                _buildFieldLabel('ASSIGNED DISASTER SECTOR'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSector,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFFFF6D00)),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      items: _sectors.map((sector) {
                        return DropdownMenuItem(
                          value: sector,
                          child: Text(sector),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSector = val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Role Type
                _buildFieldLabel('RESPONDER ROLE TYPE'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRoleType,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFFFF6D00)),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedRoleType = val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Password
                _buildFieldLabel('PASSWORD'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    hint: '••••••••',
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
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Password too short' : null,
                ),

                const SizedBox(height: 20),

                // Protocol Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToProtocol,
                        activeColor: const Color(0xFFFF6D00),
                        checkColor: Colors.white,
                        onChanged: (val) {
                          setState(() => _agreedToProtocol = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'I accept the Emergency Disaster Response Operating Protocol and consent to real-time dispatch coordinate tracking.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submitRegistration,
                  child: const Text(
                    'COMPLETE REGISTRATION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back to login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already registered? ',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ResponderLoginScreen(
                              initialRole: UserRole.responder,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Log In here',
                        style: TextStyle(
                          color: Color(0xFFFF6D00),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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
