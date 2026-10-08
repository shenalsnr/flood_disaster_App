import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      appBar: AppBar(
        backgroundColor: ShelterTheme.backgroundDeepNavy,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // PROFILE AVATAR & INFO
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ShelterTheme.surfaceDarkNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: ShelterTheme.surfaceLightNavy,
                    child: Text('RS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Dr. Rohan Silva', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Relief Team Lead - Camp Niruya', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: ShelterTheme.statusSafeGreen.withValues(alpha: 0.1),
                      border: Border.all(color: ShelterTheme.statusSafeGreen),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('+ ON DUTY', style: TextStyle(color: ShelterTheme.statusSafeGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: ShelterTheme.surfaceLightNavy),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('14', 'SHELTER'),
                      _buildStatColumn('3.2K', 'PEOPLE LOGGED'),
                      _buildStatColumn('98%', 'SYNC UPTIME'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // ACCOUNT MENU
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('ACCOUNT', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: ShelterTheme.surfaceDarkNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMenuRow(Icons.person_outline, 'Personal Information', 'Name, ID, Contact details'),
                  const Divider(color: ShelterTheme.surfaceLightNavy, height: 1),
                  _buildMenuRow(Icons.apartment_outlined, 'Assigned Shelters', 'Camp Niruya, Camp Galen Ridge'),
                  const Divider(color: ShelterTheme.surfaceLightNavy, height: 1),
                  _buildMenuRow(Icons.vpn_key_outlined, 'Role & Permissions', 'Relief Team Lead', badgeText: 'ADMIN'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShelterTheme.statusCriticalRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Log out', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildMenuRow(IconData icon, String title, String subtitle, {String? badgeText}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ShelterTheme.surfaceLightNavy,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ShelterTheme.statusSafeGreen.withValues(alpha: 0.1),
                border: Border.all(color: ShelterTheme.statusSafeGreen),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(badgeText, style: const TextStyle(color: ShelterTheme.statusSafeGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          const Icon(Icons.chevron_right, color: ShelterTheme.textMuted),
        ],
      ),
    );
  }
}
