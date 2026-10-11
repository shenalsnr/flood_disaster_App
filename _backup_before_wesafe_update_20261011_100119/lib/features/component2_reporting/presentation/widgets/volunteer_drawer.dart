import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../component4_control_center/presentation/screens/responder_login_screen.dart';
import '../screens/c2_admin_hazard_dashboard_screen.dart';
import '../screens/offline_draft_management_screen.dart';
import '../../../../core/theme/appearance.dart';

/// Navigation Drawer for District Volunteer (Component 2: Hazard Reporting).
/// Matches the design in Screenshot 3, customized for the Volunteer workflow.
class VolunteerDrawer extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onReportsTap;
  final VoidCallback? onMapTap;

  const VolunteerDrawer({
    super.key,
    this.onProfileTap,
    this.onReportsTap,
    this.onMapTap,
  });

  Future<void> _signOut(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF070B14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF5252), size: 24),
            SizedBox(width: 10),
            Text(
              'Confirm Log Out',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out from the Volunteer Reporting console?',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ResponderLoginScreen()),
        (route) => false,
      );
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF070B14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: Color(0xFF00E676), size: 24),
            SizedBox(width: 10),
            Text(
              'Emergency Volunteer Help',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Dispatch Hotline: 117 (DMC)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              'Medical / Ambulance: 1990 (Suwa Seriya)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'For technical reporting support or offline synchronization issues, contact the District Disaster Management Operations Unit.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: const Color(0xFF070B14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF070B14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF00E676), size: 24),
            SizedBox(width: 10),
            Text(
              'About WeSafe',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WeSafe — Flood Relief & Early Warning System',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Component 2: Ground Hazard Reporting & Volunteer Dispatch Console.\n\nEnables real-time ground truth verification, geo-tagged hazard alerts, water-level surveillance, and automated community protection.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Version 1.0.0 (Release Build)',
              style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: const Color(0xFF070B14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'Kapila Perera';
    final String email = user?.email ?? 'volunteer.kapila@dmc.org';

    // Fallback initials
    String initials = 'KP';
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF070B14),
          border: Border(right: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Custom Premium Header matching Screenshot 3 ─────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF112240).withValues(alpha: 0.85),
                      const Color(0xFF070B14),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: const Border(
                    bottom: BorderSide(color: Colors.white10, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar container
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9F0A), Color(0xFFFF5722)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9F0A).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Unfiltered(child: Image.asset(
                          'assets/images/volunteer_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            );
                          },
                        )),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Role tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00E676).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'VOLUNTEER',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Menu Items matching Screenshot 3 ─────────────────────────
              _DrawerItem(
                icon: Icons.person_outline_rounded,
                title: 'My Profile',
                onTap: () {
                  Navigator.pop(context);
                  if (onProfileTap != null) {
                    onProfileTap!();
                  }
                },
              ),
              _DrawerItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  _showSettingsBottomSheet(context);
                },
              ),
              _DrawerItem(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin Dashboard',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const C2AdminHazardDashboardScreen(),
                    ),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.storage_rounded,
                title: 'Offline Drafts (SQLite)',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OfflineDraftManagementScreen(),
                    ),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.assignment_outlined,
                title: 'Hazard Reports',
                onTap: () {
                  Navigator.pop(context);
                  if (onReportsTap != null) {
                    onReportsTap!();
                  }
                },
              ),
              _DrawerItem(
                icon: Icons.map_outlined,
                title: 'Live Incident Map',
                onTap: () {
                  Navigator.pop(context);
                  if (onMapTap != null) {
                    onMapTap!();
                  }
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Divider(color: Colors.white10),
              ),

              _DrawerItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                onTap: () {
                  Navigator.pop(context);
                  _showHelpDialog(context);
                },
              ),
              _DrawerItem(
                icon: Icons.info_outline_rounded,
                title: 'About WeSafe',
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog(context);
                },
              ),

              const Spacer(),

              // ── Log Out Button & Footer matching Screenshot 3 ────────────
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5252),
                          side: const BorderSide(
                            color: Color(0xFFFF5252),
                            width: 1.5,
                          ),
                          backgroundColor: const Color(0xFFFF5252).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _signOut(context),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'WeSafe v1.0.0',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF070B14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Volunteer Preferences',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const ThemeToggleTile(contentPadding: EdgeInsets.zero),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: const Color(0xFF00E676),
                  title: const Text('High Accuracy GPS Tracking', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: const Text('Auto-capture exact hazard coordinates', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: true,
                  onChanged: (v) {},
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: const Color(0xFF00E676),
                  title: const Text('Offline Local Caching', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: const Text('Queue hazard reports when signal is lost', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: true,
                  onChanged: (v) {},
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: const Color(0xFF00E676),
                  title: const Text('Urgent Emergency Sirens', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: const Text('Audible warning when river level breaches red zone', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: true,
                  onChanged: (v) {},
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 3),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white.withValues(alpha: 0.2),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
