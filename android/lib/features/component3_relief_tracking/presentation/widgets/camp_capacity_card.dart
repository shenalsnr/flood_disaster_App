import 'package:flutter/material.dart';
import '../controllers/relief_tracking_controller.dart';

class CampCapacityCard extends StatelessWidget {
  final ReliefTrackingController controller;

  const CampCapacityCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final double capacityRatio = (controller.evacueeCount / controller.maxCapacity).clamp(0.0, 1.0);
    final int occupancyPercentage = (capacityRatio * 100).toInt();

    Color progressColor;
    if (capacityRatio > 0.85) {
      progressColor = const Color(0xFFFF453A); // Red accent
    } else if (capacityRatio > 0.70) {
      progressColor = const Color(0xFFFF9F0A); // Orange accent
    } else {
      progressColor = const Color(0xFF30D158); // Green accent
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Row: User Avatar, Name & WS Sync Pill (Matching Image 1 Iframe)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF1F2C46),
                  child: const Text(
                    'RS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.leaderName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.leaderTitle,
                      style: const TextStyle(
                        color: Color(0xFF8E9BAE),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Builder(builder: (context) {
              // Shows the real sync state instead of a fixed "OK".
              final synced = controller.isSynced;
              final pillColor = synced ? const Color(0xFF30D158) : const Color(0xFFFF9F0A);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: synced ? const Color(0xFF063327) : const Color(0xFF3A2A06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: pillColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: pillColor, size: 8),
                    const SizedBox(width: 6),
                    Text(
                      synced ? 'WS SYNC: OK' : 'SYNC: OFFLINE',
                      style: TextStyle(
                        color: pillColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 18),

        // Shelter Capacity Overview Card (Matching Image 1 Iframe)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF131A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E283D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SHELTER CAPACITY OVERVIEW',
                style: TextStyle(
                  color: Color(0xFF7E8B9B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${controller.evacueeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/${controller.maxCapacity}',
                    style: const TextStyle(
                      color: Color(0xFF63738A),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Beds Occupied - $occupancyPercentage%',
                    style: const TextStyle(
                      color: Color(0xFF8E9BAE),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: capacityRatio,
                  minHeight: 10,
                  backgroundColor: const Color(0xFF261D23),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 14),

              // Alert Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      capacityRatio > 0.85 ? 'CRITICAL CAPACITY' : 'STABLE CAPACITY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Rapid Headcount Section (Matching Image 1 Iframe)
        const Text(
          'RAPID HEADCOUNT',
          style: TextStyle(
            color: Color(0xFF7E8B9B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildHeadcountBtn(context, '+1', () => controller.updateHeadcount(1)),
            const SizedBox(width: 8),
            _buildHeadcountBtn(context, '+5', () => controller.updateHeadcount(5)),
            const SizedBox(width: 8),
            _buildHeadcountBtn(context, '+10', () => controller.updateHeadcount(10)),
            const SizedBox(width: 8),
            _buildHeadcountBtn(context, '-1', () => controller.updateHeadcount(-1)),
          ],
        ),
        const SizedBox(height: 10),

        // Close Shelter Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF23161A),
              side: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => controller.toggleShelterStatus(),
            icon: Icon(
              Icons.warning_amber_rounded,
              color: controller.isShelterClosed ? Colors.grey : const Color(0xFFFF3B30),
              size: 18,
            ),
            label: Text(
              controller.isShelterClosed ? 'RE-OPEN SHELTER' : 'CLOSE SHELTER',
              style: TextStyle(
                color: controller.isShelterClosed ? Colors.grey : const Color(0xFFFF3B30),
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Shortage Alerts Section (Matching Image 1 Iframe)
        const Text(
          'SHORTAGE ALERTS',
          style: TextStyle(
            color: Color(0xFF7E8B9B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF131A2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E283D)),
          ),
          child: Column(
            children: [
              _buildShortageTile('Infant Formula', 'EMPTY', const Color(0xFF3B1E22), const Color(0xFFFF3B30)),
              const Divider(color: Color(0xFF1E283D), height: 1),
              _buildShortageTile('Drinking Water', 'LOW STOCK', const Color(0xFF382C1B), const Color(0xFFFF9F0A)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadcountBtn(BuildContext context, String label, VoidCallback onPressed) {
    return Expanded(
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A2438),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortageTile(String title, String badgeText, Color badgeBg, Color badgeTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
