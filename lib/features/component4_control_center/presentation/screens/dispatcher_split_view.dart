import 'package:flutter/material.dart';

class DispatcherSplitView extends StatelessWidget {
  const DispatcherSplitView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Emergency Dispatch Station',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.cell_tower, size: 18),
            label: const Text('BROADCAST ZONE ALERT'),
            onPressed: () => _openBroadcastDialog(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // Left Pane: Incoming Incident Triage Stream
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text(
                  'INCOMING CITIZEN HAZARDS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildIncidentCard(
                  title: 'Sudden Mudslide',
                  location: 'Kiriella - GN Div 4',
                  severity: 'LIFE THREATENING',
                  severityColor: Colors.redAccent,
                  isVerified: true,
                ),
                _buildIncidentCard(
                  title: 'Culvert Blocked / Water 3ft',
                  location: 'Main St Bridge',
                  severity: 'MODERATE',
                  severityColor: Colors.orangeAccent,
                  isVerified: false,
                ),
                _buildIncidentCard(
                  title: 'Fallen Electric Pole',
                  location: 'Hospital Road',
                  severity: 'HIGH',
                  severityColor: Colors.amber,
                  isVerified: false,
                ),
              ],
            ),
          ),

          // Divider
          const VerticalDivider(color: Colors.white12, width: 1),

          // Right Pane: Dispatch Map View
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF181818),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.dashboard_customize_outlined,
                      size: 64,
                      color: Colors.white24,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Live Multi-Agency Coordinate Feed',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildIncidentCard({
    required String title,
    required String location,
    required String severity,
    required Color severityColor,
    required bool isVerified,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isVerified)
                  const Row(
                    children: [
                      Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Verified by GN',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              location,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static void _openBroadcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Broadcast Targeted Evacuation Alert',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Select zone radius to dispatch early warning sirens and push notifications to all citizen devices.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'BROADCAST NOW',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
