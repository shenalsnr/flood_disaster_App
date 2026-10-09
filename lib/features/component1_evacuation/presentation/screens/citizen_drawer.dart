import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'citizen_profile_screen.dart';
import 'citizen_settings_screen.dart';
import 'c1_admin_metrics_screen.dart';
import '../../../component4_control_center/presentation/screens/responder_login_screen.dart';
import '../../../component4_control_center/presentation/controllers/responder_controller.dart';

class CitizenDrawer extends StatelessWidget {
  const CitizenDrawer({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await SessionService.clear();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ResponderLoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ResponderController().currentUser;
    final String displayName = user?.fullName ?? 'Citizen User';
    final String email = user?.email ?? 'citizen@example.com';

    // Extract initials for the premium avatar
    String initials = 'CU';
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }

    return Drawer(
      backgroundColor: Colors.transparent, // Rely on Container for styling
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF070B14),
          border: Border(right: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Custom Premium Header ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF112240).withValues(alpha: 0.8),
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
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(email).snapshots(),
                      builder: (context, snap) {
                        String? photoUrl;
                        if (snap.hasData && snap.data!.exists) {
                          final data = snap.data!.data() as Map<String, dynamic>;
                          photoUrl = data['photoUrl'] as String?;
                        }

                        Widget avatarContent;
                        if (photoUrl != null && photoUrl.isNotEmpty) {
                          if (photoUrl.startsWith('http')) {
                            avatarContent = Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Center(
                                child: Text(initials, style: const TextStyle(color: Color(0xFF070B14), fontSize: 22, fontWeight: FontWeight.w900)),
                              ),
                            );
                          } else {
                            avatarContent = Image.memory(
                              base64Decode(photoUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Center(
                                child: Text(initials, style: const TextStyle(color: Color(0xFF070B14), fontSize: 22, fontWeight: FontWeight.w900)),
                              ),
                            );
                          }
                        } else {
                          avatarContent = Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Color(0xFF070B14),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          );
                        }

                        return Container(
                          width: 60,
                          height: 60,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E676).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: avatarContent,
                        );
                      }
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'CITIZEN',
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
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
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

              const SizedBox(height: 12),

              // ── Navigation Items ────────────────────────────────────────────
              _DrawerItem(
                icon: Icons.person_outline_rounded,
                title: 'My Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CitizenProfileScreen(),
                    ),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CitizenSettingsScreen(),
                    ),
                  );
                },
              ),

              // ── Admin Tools Shortcut (For Presentation) ─────────────────────
              _DrawerItem(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin Dashboard',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const C1AdminMetricsScreen(),
                    ),
                  );
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Divider(color: Colors.white10),
              ),

              _DrawerItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                onTap: () {
                  Navigator.pop(context); // Add actual routing when built
                },
              ),
              _DrawerItem(
                icon: Icons.info_outline_rounded,
                title: 'About WeSafe',
                onTap: () {
                  Navigator.pop(context); // Add actual routing when built
                },
              ),

              const Spacer(),

              // ── Log Out Button & Footer ─────────────────────────────────────
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
                          backgroundColor: const Color(0xFFFF5252)
                              .withValues(alpha: 0.1),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
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
