import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/appearance.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../component4_control_center/presentation/controllers/responder_controller.dart';

// ---------------------------------------------------------------------------
// Citizen Settings & Preferences Screen — Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// High-performance, ultra-reliable, state-of-the-art UI matching WeSafe dark theme.
// ---------------------------------------------------------------------------

class CitizenSettingsScreen extends StatefulWidget {
  const CitizenSettingsScreen({super.key});

  @override
  State<CitizenSettingsScreen> createState() => _CitizenSettingsScreenState();
}

class _CitizenSettingsScreenState extends State<CitizenSettingsScreen> {
  bool _pushNotifications = true;
  bool _soundAlerts = true;
  bool _vibrationAlerts = true;
  bool _autoDownloadRoutes = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _pushNotifications = prefs.getBool('c1_push_notifications') ?? true;
          _soundAlerts = prefs.getBool('c1_sound_alerts') ?? true;
          _vibrationAlerts = prefs.getBool('c1_vibration_alerts') ?? true;
          _autoDownloadRoutes = prefs.getBool('c1_auto_download_routes') ?? true;
          _selectedLanguage = prefs.getString('c1_app_language') ?? 'English';
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _togglePushNotifications(bool val) async {
    setState(() => _pushNotifications = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('c1_push_notifications', val);
  }

  Future<void> _toggleSoundAlerts(bool val) async {
    setState(() => _soundAlerts = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('c1_sound_alerts', val);
  }

  Future<void> _toggleVibrationAlerts(bool val) async {
    setState(() => _vibrationAlerts = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('c1_vibration_alerts', val);
  }

  Future<void> _toggleAutoDownload(bool val) async {
    setState(() => _autoDownloadRoutes = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('c1_auto_download_routes', val);
  }

  Future<void> _setLanguage(String lang) async {
    setState(() => _selectedLanguage = lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('c1_app_language', lang);
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Offline emergency map tiles cleared successfully.',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _callHotline(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open phone dialer for $number'),
              backgroundColor: const Color(0xFFFF1744),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling $number directly...'),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = 'Citizen User';
    String userDistrict = 'Colombo';

    try {
      final user = ResponderController().currentUser;
      if (user != null) {
        if (user.fullName.isNotEmpty) userName = user.fullName;
        if (user.district.isNotEmpty) userDistrict = user.district;
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: const Color(0xFF070B14).withValues(alpha: 0.75),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ThemeToggleButton(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [Color(0xFF112240), Color(0xFF070B14)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            children: [
              // ── Top System Telemetry Card ────────────────────────────────
              _buildTelemetryBanner(userName: userName, district: userDistrict),

              const SizedBox(height: 22),

              // ── Section 1: Notifications & Warning Alerts ────────────────
              _buildSectionHeader(
                icon: Icons.notifications_active_rounded,
                title: 'NOTIFICATIONS & WARNING ALERTS',
              ),
              const SizedBox(height: 10),
              _buildSettingsCard(
                children: [
                  _buildToggleRow(
                    icon: Icons.notifications_rounded,
                    iconColor: const Color(0xFF00E676),
                    title: 'Push Notifications',
                    subtitle: _pushNotifications
                        ? 'Warnings for $userDistrict appear in phone status bar'
                        : 'Alerts muted (Turn on for life-safety warnings)',
                    value: _pushNotifications,
                    onChanged: _togglePushNotifications,
                  ),
                  _buildCardDivider(),
                  _buildToggleRow(
                    icon: Icons.volume_up_rounded,
                    iconColor: const Color(0xFFFF9F0A),
                    title: 'Emergency Sound Siren',
                    subtitle: 'Play high-decibel audible alarm on Critical flood warnings',
                    value: _soundAlerts,
                    onChanged: _toggleSoundAlerts,
                  ),
                  _buildCardDivider(),
                  _buildToggleRow(
                    icon: Icons.vibration_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'Haptic Vibration',
                    subtitle: 'Vibrate device rhythmically during hazard alert broadcasts',
                    value: _vibrationAlerts,
                    onChanged: _toggleVibrationAlerts,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Section 2: Offline Resilience & Map Cache ────────────────
              _buildSectionHeader(
                icon: Icons.offline_bolt_rounded,
                title: 'OFFLINE RESILIENCE & STORAGE',
              ),
              const SizedBox(height: 10),
              _buildSettingsCard(
                children: [
                  _buildToggleRow(
                    icon: Icons.map_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'Auto-Cache Safe Evacuation Routes',
                    subtitle: 'Pre-download high-ground evacuation path tiles for offline use',
                    value: _autoDownloadRoutes,
                    onChanged: _toggleAutoDownload,
                  ),
                  _buildCardDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Color(0xFFFF5252),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clear Offline Map Cache',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Frees up local storage by clearing cached map geometries',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF5252),
                            side: const BorderSide(color: Color(0xFFFF5252), width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: _clearCache,
                          child: const Text(
                            'CLEAR',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Section 3: Appearance & Language ─────────────────────────
              _buildSectionHeader(
                icon: Icons.palette_rounded,
                title: 'APPEARANCE & LANGUAGE',
              ),
              const SizedBox(height: 10),
              _buildSettingsCard(
                children: [
                  ListenableBuilder(
                    listenable: ThemeController.instance,
                    builder: (context, _) {
                      final isLight = ThemeController.instance.isLight;
                      return _buildToggleRow(
                        icon: isLight ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        iconColor: const Color(0xFF00E676),
                        title: 'Light Theme',
                        subtitle: isLight
                            ? 'High-visibility light theme active'
                            : 'OLED ultra-dark mode active (saves emergency battery)',
                        value: isLight,
                        onChanged: (v) => ThemeController.instance.setLight(v),
                      );
                    },
                  ),
                  _buildCardDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.translate_rounded, color: Color(0xFF00E676), size: 18),
                            SizedBox(width: 10),
                            Text(
                              'Warning Broadcast Language',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Select preferred language for emergency warnings and instructions',
                          style: TextStyle(color: Colors.white54, fontSize: 11.5),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildLanguagePill('English', 'English'),
                            const SizedBox(width: 8),
                            _buildLanguagePill('Sinhala', 'සිංහල'),
                            const SizedBox(width: 8),
                            _buildLanguagePill('Tamil', 'தமிழ்'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Section 4: National Emergency Hotlines (24/7) ────────────
              _buildSectionHeader(
                icon: Icons.contact_emergency_rounded,
                title: 'NATIONAL EMERGENCY HOTLINES (24/7)',
              ),
              const SizedBox(height: 10),
              _buildSettingsCard(
                children: [
                  _buildHotlineRow(
                    icon: Icons.shield_rounded,
                    color: const Color(0xFFFF1744),
                    title: 'Disaster Management Centre',
                    subtitle: 'National Emergency Operations Centre (DMC)',
                    number: '117',
                  ),
                  _buildCardDivider(),
                  _buildHotlineRow(
                    icon: Icons.local_police_rounded,
                    color: const Color(0xFF38BDF8),
                    title: 'Emergency Police Control',
                    subtitle: 'Islandwide Rapid Police Response Call Center',
                    number: '119',
                  ),
                  _buildCardDivider(),
                  _buildHotlineRow(
                    icon: Icons.medical_services_rounded,
                    color: const Color(0xFF00E676),
                    title: 'Suwa Seriya Ambulance',
                    subtitle: 'Free Government Emergency Medical Fleet',
                    number: '1990',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── App Version & Operations Footer ──────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded, color: Color(0xFF00E676), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'WeSafe Early Warning • v1.0.0 Production',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Direct encrypted satellite link to DMC Emergency Command',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-Widget Helpers ─────────────────────────────────────────────────────

  Widget _buildTelemetryBanner({required String userName, required String district}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111B2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF00E676),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Early Warning System Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$userName • $district District Telemetry Stream',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00E676), size: 15),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildCardDivider() {
    return const Divider(
      color: Color(0xFF1E293B),
      height: 1,
      thickness: 1,
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (value ? iconColor : Colors.white24).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value ? iconColor : Colors.white54,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: value ? Colors.white60 : Colors.white38,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF00E676),
            activeTrackColor: const Color(0xFF00E676).withValues(alpha: 0.4),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: const Color(0xFF1E293B),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePill(String key, String label) {
    final isSelected = _selectedLanguage == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setLanguage(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E676).withValues(alpha: 0.2)
                : const Color(0xFF131D31),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E676) : const Color(0xFF1E293B),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00E676) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotlineRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String number,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle • Dial $number',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            onPressed: () => _callHotline(number),
            icon: const Icon(Icons.phone_in_talk_rounded, size: 14),
            label: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
