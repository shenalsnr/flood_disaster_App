import 'package:flutter/material.dart';
import '../../../../core/theme/appearance.dart';

class CitizenSettingsScreen extends StatefulWidget {
  const CitizenSettingsScreen({super.key});

  @override
  State<CitizenSettingsScreen> createState() => _CitizenSettingsScreenState();
}

class _CitizenSettingsScreenState extends State<CitizenSettingsScreen> {
  bool _pushNotifications = true;

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offline map cache cleared successfully.'),
        backgroundColor: Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            activeThumbColor: const Color(0xFF00E676),
            title: const Text(
              'Push Notifications',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Receive alerts for your registered zone',
              style: TextStyle(color: Colors.white54),
            ),
            value: _pushNotifications,
            onChanged: (val) {
              setState(() => _pushNotifications = val);
              // TODO: FirebaseMessaging.instance.subscribeToTopic / unsubscribeFromTopic
            },
          ),
          const Divider(color: Colors.white12, height: 32),

          _buildSectionHeader('Storage & Offline'),
          ListTile(
            title: const Text(
              'Clear Offline Map Cache',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Free up space by removing downloaded maps',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.delete_outline, color: Colors.white54),
            onTap: _clearCache,
          ),
          const Divider(color: Colors.white12, height: 32),

          _buildSectionHeader('Appearance & Battery'),
          // One switch for the whole app (all components).
          const ThemeToggleTile(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00E676),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
