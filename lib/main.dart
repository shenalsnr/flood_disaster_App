import 'package:flutter/material.dart';
import 'features/component1_evacuation/presentation/screens/evacuation_map_screen.dart';
import 'features/component2_reporting/presentation/screens/quick_hazard_screen.dart';
import 'features/component3_relief_tracking/presentation/screens/camp_dashboard_screen.dart';
import 'features/component4_control_center/presentation/screens/dispatcher_split_view.dart';

void main() {
  runApp(const FloodDisasterApp());
}

class FloodDisasterApp extends StatelessWidget {
  const FloodDisasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeGuard Flood & Disaster App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const MainComponentHub(),
    );
  }
}

class MainComponentHub extends StatelessWidget {
  const MainComponentHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeGuard SOS - Component Hub'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildNavButton(
              context,
              title: 'Component 1: Evacuation & Warnings',
              subtitle: 'Safe routes, offline maps, watch/danger alerts',
              icon: Icons.navigation_outlined,
              screen: const EvacuationMapScreen(),
            ),
            _buildNavButton(
              context,
              title: 'Component 2: Hazard Reporting',
              subtitle: 'Zero typing, 1-tap buttons, auto-GPS, offline sync',
              icon: Icons.report_problem_outlined,
              screen: const QuickHazardScreen(),
            ),
            _buildNavButton(
              context,
              title: 'Component 3: Relief & Camp Logistics',
              subtitle: 'Shelter capacity, swipe stock updates, supplies',
              icon: Icons.inventory_2_outlined,
              screen: const CampDashboardScreen(),
            ),
            _buildNavButton(
              context,
              title: 'Component 4: Control Center Dispatcher',
              subtitle: 'Severity sorting, multi-agency feed, geo broadcast',
              icon: Icons.admin_panel_settings_outlined,
              screen: const DispatcherSplitView(),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildNavButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.lightBlueAccent, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }
}