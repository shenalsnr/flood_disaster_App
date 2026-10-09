import 'package:flutter/material.dart';

import '../../../component1_evacuation/presentation/screens/citizen_dashboard_screen.dart';
import '../../../component2_reporting/presentation/screens/quick_hazard_screen.dart';
import '../../../component3_relief_tracking/presentation/screens/camp_dashboard_screen.dart';
import '../../../component3_relief_tracking/presentation/screens/supply_admin_dashboard_screen.dart';
import 'admin_panel_screen.dart';
import 'alert_dashboard_screen.dart';

/// The dashboard an account lands on, chosen from its role.
Widget dashboardForRole(String rawRole) {
  final role = rawRole.toLowerCase();
  if (role == 'admin') return const AdminPanelScreen();
  if (role.contains('dmc')) return const SupplyAdminDashboardScreen();
  if (role.contains('citizen')) return const CitizenDashboardScreen();
  if (role.contains('volunteer')) return const QuickHazardScreen();
  if (role.contains('camp') || role.contains('leader')) {
    return const CampDashboardScreen();
  }
  return const AlertDashboardScreen();
}
