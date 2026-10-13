import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/auth_firebase_service.dart';

import '../controllers/responder_controller.dart';
import 'responder_login_screen.dart';
import '../../data/services/session_service.dart';
import '../../../component1_evacuation/presentation/screens/citizen_dashboard_screen.dart';
import '../../../component2_reporting/presentation/screens/quick_hazard_screen.dart';
import '../../../component3_relief_tracking/presentation/screens/camp_dashboard_screen.dart';
import '../../../../core/theme/appearance.dart';

class ResponderProfileScreen extends StatefulWidget {
  const ResponderProfileScreen({super.key});

  @override
  State<ResponderProfileScreen> createState() => _ResponderProfileScreenState();
}

class _ResponderProfileScreenState extends State<ResponderProfileScreen> {
  final ResponderController _controller = ResponderController();
  bool _audioSirenAlerts = true;
  bool _offlineCaching = true;
  bool _isSavingPhoto = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isOnDuty = _controller.isOnDuty;
    final user = _controller.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
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
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _showAddPhotoDialog,
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF6D00),
                                width: 2.5,
                              ),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF131B2B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: _isSavingPhoto
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFFF6D00),
                                    ),
                                  )
                                : _buildAvatarImage(user?.photoUrl),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isOnDuty
                                  ? const Color(0xFF00E676)
                                  : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF070B14),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        // Camera Edit Badge Icon
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showAddPhotoDialog,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6D00),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF070B14), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6D00)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Action button
                    GestureDetector(
                      onTap: _showAddPhotoDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151E32),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF6D00).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 14, color: Color(0xFFFF6D00)),
                            SizedBox(width: 6),
                            Text(
                              'Add / Change Photo',
                              style: TextStyle(
                                color: Color(0xFFFF9F0A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'Nadeeka Perera',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.roleTitle ??
                          'Senior Emergency Dispatcher • Unit #04',
                      style: const TextStyle(
                        color: Color(0xFF40C4FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.floodZone.isNotEmpty == true
                          ? user!.floodZone
                          : 'Sri Lanka Disaster Management Centre (DMC)',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Authenticated Firebase Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: Color(0xFF00E676), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'FIREBASE FIRESTORE SYNCED PROFILE',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ONLINE',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildProfileDetailRow(
                      icon: Icons.email_outlined,
                      label: 'Account Email',
                      value: user?.email ?? 'n.perera@dispatched.gov.lk',
                    ),
                    const SizedBox(height: 8),
                    _buildProfileDetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone Contact',
                      value: user?.phoneNumber.isNotEmpty == true
                          ? user!.phoneNumber
                          : '+94 77 482 1029',
                    ),
                    const SizedBox(height: 8),
                    _buildProfileDetailRow(
                      icon: Icons.badge_outlined,
                      label: 'National ID (NIC)',
                      value: user?.nic.isNotEmpty == true
                          ? user!.nic
                          : '982341092V',
                    ),
                    const SizedBox(height: 8),
                    _buildProfileDetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Flood Sector',
                      value: user?.floodZone.isNotEmpty == true
                          ? user!.floodZone
                          : 'Colombo Sector 4 (Low-Lying Area)',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Duty Status Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2B),
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
                        color: isOnDuty ? const Color(0xFF00E676) : Colors.grey,
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
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOnDuty,
                      activeThumbColor: const Color(0xFF00E676),
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
                      color: const Color(0xFF40C4FF),
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
                  color: const Color(0xFF131B2B),
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
                            builder: (_) => const CitizenDashboardScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    _buildRoleSwitchTile(
                      title: 'Volunteer Hazard Reporter (Component 2)',
                      subtitle: 'Ground truth photo & hazard submission',
                      icon: Icons.add_location_alt_outlined,
                      color: const Color(0xFF40C4FF),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QuickHazardScreen(),
                          ),
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
                            builder: (_) => const CampDashboardScreen(),
                          ),
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
                  color: const Color(0xFF131B2B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    const ThemeToggleTile(activeColor: Color(0xFFFF6D00)),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    SwitchListTile(
                      dense: true,
                      title: const Text(
                        'Audible Emergency Siren',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Play critical frequency tone on Level 4 floods',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                      value: _audioSirenAlerts,
                      activeThumbColor: const Color(0xFFFF6D00),
                      onChanged: (v) => setState(() => _audioSirenAlerts = v),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    SwitchListTile(
                      dense: true,
                      title: const Text(
                        'Offline GIS Tile Caching (10km)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Pre-cached offline maps for cellular blackouts',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                      value: _offlineCaching,
                      activeThumbColor: const Color(0xFF00E676),
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
                onPressed: () async {
                  await SessionService.clear();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const ResponderLoginScreen()),
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
        color: const Color(0xFF131B2B),
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
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.white38,
      ),
      onTap: onTap,
    );
  }

  Widget _buildProfileDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFFF6D00)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return const Icon(
        Icons.shield_rounded,
        size: 44,
        color: Color(0xFFFF9F0A),
      );
    }

    if (photoUrl.startsWith('data:image')) {
      try {
        final commaIndex = photoUrl.indexOf(',');
        final base64Str = commaIndex != -1
            ? photoUrl.substring(commaIndex + 1)
            : photoUrl;
        final bytes = base64Decode(base64Str);
        return ClipOval(
          child: Unfiltered(child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 92,
            height: 92,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.shield_rounded,
              size: 44,
              color: Color(0xFFFF9F0A),
            ),
          )),
        );
      } catch (_) {
        return const Icon(
          Icons.shield_rounded,
          size: 44,
          color: Color(0xFFFF9F0A),
        );
      }
    }

    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return ClipOval(
        child: Unfiltered(child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          width: 92,
          height: 92,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.shield_rounded,
            size: 44,
            color: Color(0xFFFF9F0A),
          ),
        )),
      );
    }

    return const Icon(
      Icons.shield_rounded,
      size: 44,
      color: Color(0xFFFF9F0A),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      setState(() => _isSavingPhoto = true);

      final bytes = await pickedFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final email =
          _controller.currentUser?.email ?? 'n.perera@dispatched.gov.lk';

      // 1. Save directly to Cloud Firestore database
      await AuthFirebaseService().updateProfilePhoto(
        email: email,
        photoUrl: base64Image,
      );

      // 2. Update app state
      _controller.updateCurrentUserPhoto(base64Image);

      if (!mounted) return;
      setState(() => _isSavingPhoto = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: Color(0xFF00E676)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profile photo saved to database successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF1E293B),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update photo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _savePresetOrUrlPhoto(String photoUrl) async {
    try {
      setState(() => _isSavingPhoto = true);
      final email =
          _controller.currentUser?.email ?? 'n.perera@dispatched.gov.lk';

      // 1. Save directly to Cloud Firestore database
      await AuthFirebaseService().updateProfilePhoto(
        email: email,
        photoUrl: photoUrl,
      );

      // 2. Update app state
      _controller.updateCurrentUserPhoto(photoUrl);

      if (!mounted) return;
      setState(() => _isSavingPhoto = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: Color(0xFF00E676)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profile photo updated and saved to database!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF1E293B),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update photo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showAddPhotoDialog() {
    final user = _controller.currentUser;
    final hasPhoto = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;

    final presetAvatars = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&fit=crop&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&fit=crop&q=80',
      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&fit=crop&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&fit=crop&q=80',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF070B14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.account_circle_rounded,
                      color: Color(0xFFFF6D00), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Profile Photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Choose an image to save to your database profile',
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
              const SizedBox(height: 18),
              // Option 1: Gallery
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF40C4FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF40C4FF), size: 22),
                ),
                title: const Text(
                  'Choose from Gallery / Files',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Upload image from your local device storage',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.white38),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              const Divider(color: Color(0xFF1E293B)),
              // Option 2: Camera
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF00E676), size: 22),
                ),
                title: const Text(
                  'Take Photo (Camera)',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Capture live photo using camera',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.white38),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              const Divider(color: Color(0xFF1E293B)),
              // Option 3: URL input
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link_rounded,
                      color: Color(0xFFFF9F0A), size: 22),
                ),
                title: const Text(
                  'Enter Image URL',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Paste a direct HTTPS web link to an image',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.white38),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showUrlInputDialog();
                },
              ),
              const SizedBox(height: 14),
              // Option 4: Presets Row
              const Text(
                'OR SELECT PRESET AVATAR',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(presetAvatars.length, (idx) {
                  final preset = presetAvatars[idx];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _savePresetOrUrlPhoto(preset);
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF6D00).withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Unfiltered(child: Image.network(
                          preset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.person,
                            color: Colors.white54,
                          ),
                        )),
                      ),
                    ),
                  );
                }),
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1E293B)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 22),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Reset profile photo back to default badge icon',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _savePresetOrUrlPhoto('');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlInputDialog() {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF070B14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Enter Photo URL',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a valid HTTPS image URL:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                hintText: 'https://example.com/avatar.jpg',
                hintStyle:
                    const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6000),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty &&
                  (url.startsWith('http://') || url.startsWith('https://'))) {
                Navigator.of(dialogCtx).pop();
                _savePresetOrUrlPhoto(url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid HTTP/HTTPS image URL'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Save Photo'),
          ),
        ],
      ),
    );
  }
}
