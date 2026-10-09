import 'package:flutter/material.dart';
import '../../data/models/responder_models.dart';
import '../../data/services/auth_firebase_service.dart';
import '../controllers/responder_controller.dart';
import 'responder_login_screen.dart';

class ResponderRegisterScreen extends StatefulWidget {
  const ResponderRegisterScreen({super.key});

  @override
  State<ResponderRegisterScreen> createState() =>
      _ResponderRegisterScreenState();
}

class _ResponderRegisterScreenState extends State<ResponderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nicController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _customSectorController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedSector = 'Colombo Low-Lying Area (Kelani Bank Zone)';

  // CHANGED: every new registration is a CITIZEN by default
  final String _selectedRole = 'citizen';

  bool _agreedToAlerts = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  final List<String> _sectors = [
    'Colombo Low-Lying Area (Kelani Bank Zone)',
    'Ratnapura Central (Kalu Ganga Basin)',
    'Gampaha Lowlands (Ja-Ela Flood Corridor)',
    'Kalutara Coastal Lowland Zone',
    'Kandy Slopes (Hill Country Runoff)',
    'Other (Type Custom Flood Zone)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _customSectorController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  UserRole _roleFromString(String role) {
    switch (role) {
      case 'citizen':
        return UserRole.citizen;
      case 'volunteer':
        return UserRole.volunteer;
      case 'campLeader':
        return UserRole.campLeader;
      default:
        return UserRole.responder;
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToAlerts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please accept the flood early warning agreement to proceed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final finalSector = _selectedSector == 'Other (Type Custom Flood Zone)'
        ? (_customSectorController.text.trim().isEmpty
            ? 'Custom Zone'
            : _customSectorController.text.trim())
        : _selectedSector;

    setState(() => _isSubmitting = true);

    try {
      // 1. Save directly to Cloud Firestore 'users' collection
      final userProfile = await AuthFirebaseService().registerUser(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        nic: _nicController.text.trim(),
        district: _districtController.text.trim(),
        city: _cityController.text.trim(),
        floodZone: finalSector,
        password: _passwordController.text,
        role: _selectedRole, // saved as 'citizen'
      );

      // 2. Set current user in app controller
      ResponderController().setCurrentUser(userProfile);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // 3. Show confirmation that data is saved in Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: Color(0xFF00E676)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saved to Firebase Firestore! Log in as ${_nameController.text}.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 3),
        ),
      );

      // 4. Flow: Register -> Login (passing registered email and CITIZEN role)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResponderLoginScreen(
            initialEmail: _emailController.text.trim(),
            initialRole: _roleFromString(_selectedRole),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase Registration Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomSector = _selectedSector == 'Other (Type Custom Flood Zone)';

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Custom App Bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const ResponderLoginScreen(),
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
                      'Citizen Registration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Top Info Card with Green Accent Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF1E293B),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
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
                                        Icons.flood,
                                        color: Color(0xFFFF6D00),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Early Warning Civilian Account',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Flood & Disaster Preparedness Network',
                                          style: TextStyle(
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
                          ),
                          Container(
                            width: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Field 1: FULL NAME
                _buildFieldLabel('FULL NAME'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(
                    hint: 'Enter your full name',
                    icon: Icons.person,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter your name' : null,
                ),

                const SizedBox(height: 16),

                // Field 2: EMAIL ADDRESS
                _buildFieldLabel('EMAIL ADDRESS'),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    hint: 'name@example.com',
                    icon: Icons.email,
                  ),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Please enter a valid email address'
                      : null,
                ),

                const SizedBox(height: 16),

                // Field 3 & 4: PHONE NUMBER & NATIONAL ID (NIC)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('PHONE NUMBER'),
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            keyboardType: TextInputType.phone,
                            decoration: _buildInputDecoration(
                              hint: '+94 7X XXX XXXX',
                              icon: Icons.phone,
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter phone number'
                                : null,
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
                          _buildFieldLabel('NATIONAL ID (NIC)'),
                          TextFormField(
                            controller: _nicController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            decoration: _buildInputDecoration(
                              hint: 'e.g. 982341092V',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter NIC' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Field: DISTRICT & CITY
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('DISTRICT'),
                          TextFormField(
                            controller: _districtController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            decoration: _buildInputDecoration(
                              hint: 'Enter district',
                              icon: Icons.map_outlined,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter district'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('CITY'),
                          TextFormField(
                            controller: _cityController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            decoration: _buildInputDecoration(
                              hint: 'Enter city',
                              icon: Icons.location_city_outlined,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter city'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Field 5: RESIDENTIAL FLOOD ZONE / SECTOR Dropdown
                _buildFieldLabel('RESIDENTIAL FLOOD ZONE / SECTOR'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSector,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFFFF6D00),
                        size: 24,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items: _sectors.map((sector) {
                        final isOther =
                            sector == 'Other (Type Custom Flood Zone)';
                        return DropdownMenuItem<String>(
                          value: sector,
                          child: Row(
                            children: [
                              if (isOther)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.edit_note,
                                      color: Color(0xFFFF6D00), size: 18),
                                ),
                              Expanded(
                                child: Text(
                                  sector,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isOther
                                        ? const Color(0xFFFF9100)
                                        : Colors.white,
                                    fontWeight: isOther
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSector = val;
                          });
                        }
                      },
                    ),
                  ),
                ),

                // DYNAMIC FIELD: Custom Flood Zone when "Other" is selected
                if (isCustomSector) ...[
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111C33),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.edit_location_alt_outlined,
                                color: Color(0xFFFF6D00), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'TYPE YOUR CUSTOM FLOOD ZONE / AREA',
                              style: TextStyle(
                                color: const Color(0xFFFF6D00)
                                    .withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customSectorController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            hintText:
                                'e.g. Wellampitiya GN Div 5 / Sedawatta Lowland',
                            hintStyle: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1E293B)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1E293B)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFFFF6D00), width: 1.5),
                            ),
                          ),
                          validator: (v) {
                            if (isCustomSector && (v == null || v.isEmpty)) {
                              return 'Please specify your custom flood zone';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Field 6: PASSWORD
                _buildFieldLabel('PASSWORD'),
                TextFormField(
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
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Password too short' : null,
                ),

                const SizedBox(height: 16),

                // Field 7: CONFIRM PASSWORD
                _buildFieldLabel('CONFIRM PASSWORD'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration(
                    hint: '••••••••••••',
                    icon: Icons.lock_open,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword =
                            !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Agreement Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _agreedToAlerts,
                        activeColor: const Color(0xFF0284C7),
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          setState(() => _agreedToAlerts = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'I agree to receive SMS & push emergency flood alerts for my residential sector and consent to location-based early warning broadcasts.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // Complete Registration Button
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
                    onPressed: _isSubmitting ? null : _submitRegistration,
                    child: _isSubmitting
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
                                'COMPLETE REGISTRATION',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.shield, size: 18, color: Colors.white),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Bottom Link: Already have an account? Log In here
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ResponderLoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Log In here',
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