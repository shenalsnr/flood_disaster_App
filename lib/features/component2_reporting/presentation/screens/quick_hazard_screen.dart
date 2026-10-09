import 'package:flutter/material.dart';

class QuickHazardScreen extends StatelessWidget {
  const QuickHazardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Report Ground Hazard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-GPS & Offline Status Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GPS Locked: 6.6828° N, 80.4036° E (Auto-tagged)',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    Icon(Icons.cloud_queue, color: Colors.orangeAccent, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'TAP HAZARD TYPE (Zero Typing Needed)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),

              // Oversized Category Buttons for Wet Hands
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildHazardTile(
                      icon: Icons.water_drop,
                      label: 'Flash Flood',
                      color: Colors.blue,
                      onTap: () => _confirmReport(context, 'Flash Flood'),
                    ),
                    _buildHazardTile(
                      icon: Icons.landslide,
                      label: 'Landslide',
                      color: Colors.brown.shade400,
                      onTap: () => _confirmReport(context, 'Landslide'),
                    ),
                    _buildHazardTile(
                      icon: Icons.park,
                      label: 'Fallen Tree',
                      color: Colors.orange,
                      onTap: () => _confirmReport(context, 'Fallen Tree'),
                    ),
                    _buildHazardTile(
                      icon: Icons.block,
                      label: 'Road Blocked',
                      color: Colors.redAccent,
                      onTap: () => _confirmReport(context, 'Road Blocked'),
                    ),
                  ],
                ),
              ),

              // Camera Attachment
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.camera_alt, color: Colors.white70),
                  label: const Text('Attach Quick Photo (Optional)'),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildHazardTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _confirmReport(BuildContext context, String hazard) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('Report queued: $hazard. Syncing when connected.'),
      ),
    );
  }
}