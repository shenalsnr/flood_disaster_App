import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import 'shelter_dashboard_screen.dart';
import 'ration_inventory_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'team_chat_screen.dart';

class ShelterMainLayout extends StatefulWidget {
  const ShelterMainLayout({super.key});

  @override
  State<ShelterMainLayout> createState() => _ShelterMainLayoutState();
}

class _ShelterMainLayoutState extends State<ShelterMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ShelterDashboardScreen(isEmbedded: true),
    const RationInventoryScreen(isEmbedded: true),
    const AlertsScreen(),
    const ProfileScreen(),
    const TeamChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: ShelterTheme.surfaceDarkNavy,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ShelterTheme.primaryActionOrange,
        unselectedItemColor: ShelterTheme.textMuted,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Supplies'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Team'),
        ],
      ),
    );
  }
}
