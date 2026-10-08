import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      appBar: AppBar(
        backgroundColor: ShelterTheme.backgroundDeepNavy,
        elevation: 0,
        title: const Text('Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FILTERS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All (14)', 0, true),
                const SizedBox(width: 8),
                _buildFilterChip('Critical', 1, false),
                const SizedBox(width: 8),
                _buildFilterChip('Low Stock', 2, false),
                const SizedBox(width: 8),
                _buildFilterChip('Logs', 3, false),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // LIST
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('TODAY', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildAlertCard(
                  title: 'Infant Formula Milk Powder — Depleted',
                  time: '4m ago',
                  desc: 'Camp Niruya stock reached zero. Immediate resupply required.',
                  color: ShelterTheme.statusCriticalRed,
                  icon: Icons.warning_amber_rounded,
                  primaryActionText: 'DISPATCH SUPPLY',
                ),
                _buildAlertCard(
                  title: 'Shelter Capacity — Critical',
                  time: '18m ago',
                  desc: 'Camp Galen Ridge at 90% occupancy (288/300 beds).',
                  color: ShelterTheme.statusCriticalRed,
                  icon: Icons.personal_injury,
                  primaryActionText: 'VIEW SHELTER',
                ),
                _buildAlertCard(
                  title: 'Drinking Water Jerry Cans — Low Stock',
                  time: '1h ago',
                  desc: 'Below 25L threshold at Camp Niruya. Restock recommended.',
                  color: ShelterTheme.statusWarningYellow,
                  icon: Icons.inventory_2_outlined,
                  primaryActionText: 'REQUEST SUPPLY',
                  isPrimaryOutlined: true,
                ),
                const SizedBox(height: 16),
                const Text('EARLIER', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildAlertCard(
                  title: 'Resupply Dispatched — EMER 042',
                  time: '2h ago',
                  desc: 'Transferred to DMC, medical resupply dispatched, ETA 18 min.',
                  color: ShelterTheme.statusSafeGreen,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, bool isSelectedRed) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isSelectedRed ? ShelterTheme.statusCriticalRed : ShelterTheme.surfaceLightNavy) : ShelterTheme.surfaceDarkNavy,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : ShelterTheme.surfaceLightNavy),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ShelterTheme.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String time,
    required String desc,
    required Color color,
    required IconData icon,
    String? primaryActionText,
    bool isPrimaryOutlined = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShelterTheme.surfaceDarkNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Text(time, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(desc, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 12)),
          ),
          if (primaryActionText != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Row(
                children: [
                  Expanded(
                    child: isPrimaryOutlined
                        ? OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: color),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(primaryActionText, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                          )
                        : ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(primaryActionText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ShelterTheme.surfaceLightNavy),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Dismiss', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
