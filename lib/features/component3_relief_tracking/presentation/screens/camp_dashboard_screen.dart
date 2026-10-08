import 'package:flutter/material.dart';

class CampDashboardScreen extends StatefulWidget {
  const CampDashboardScreen({super.key});

  @override
  State<CampDashboardScreen> createState() => _CampDashboardScreenState();
}

class _CampDashboardScreenState extends State<CampDashboardScreen> {
  // Sample local state for shelter readiness
  int evacueeCount = 185;
  final int maxCapacity = 250;

  @override
  Widget build(BuildContext context) {
    final double capacityRatio = evacueeCount / maxCapacity;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Camp Relief & Triage',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.blueAccent),
            tooltip: 'Live WebSocket Connected',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Camp Capacity Glance Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Shelter Headcount',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '$evacueeCount / $maxCapacity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: capacityRatio,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    capacityRatio > 0.8
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                  ),
                  minHeight: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'CRITICAL SUPPLIES STATUS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          // Glanceable stock status tiles
          _buildSupplyItem(
            'Clean Drinking Water',
            '45 Liters Left',
            Colors.redAccent,
            false,
          ),
          _buildSupplyItem(
            'First Aid Kits',
            '12 Units Available',
            Colors.green,
            true,
          ),
          _buildSupplyItem(
            'Baby Formula',
            'CRITICAL DEPLETION',
            Colors.redAccent,
            false,
          ),
          _buildSupplyItem(
            'Dry Rations / Rice',
            'Plenty in Stock',
            Colors.green,
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyItem(
    String title,
    String status,
    Color statusColor,
    bool inStock,
  ) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          status,
          style: TextStyle(color: statusColor, fontSize: 12),
        ),
        trailing: Switch(
          value: inStock,
          activeThumbColor: Colors.greenAccent,
          onChanged: (val) {
            setState(() {
              // Toggles supply state directly
            });
          },
        ),
      ),
    );
  }
}
