import 'package:flutter/material.dart';
import '../controllers/relief_tracking_controller.dart';
import '../../data/models/relief_item_model.dart';
import '../../data/models/evacuee_model.dart';

class CampCapacityCard extends StatelessWidget {
  final ReliefTrackingController controller;

  const CampCapacityCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final double capacityRatio = (controller.evacueeCount / controller.maxCapacity).clamp(0.0, 1.0);
    final int criticalItemsCount = controller.inventoryItems.where((i) => i.status == StockStatus.critical).length;
    final int redTriageCount = controller.evacuees.where((e) => e.triage == TriagePriority.red).length;

    Color progressColor;
    if (capacityRatio > 0.9) {
      progressColor = const Color(0xFFFF5252);
    } else if (capacityRatio > 0.75) {
      progressColor = const Color(0xFFFFAB40);
    } else {
      progressColor = const Color(0xFF69F0AE);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Camp Name & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.night_shelter_outlined, color: Colors.blueAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.campName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Relief Camp ID: #RC-042',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: progressColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: progressColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(capacityRatio * 100).toInt()}% Capacity',
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Capacity Bar & Numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shelter Headcount',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${controller.evacueeCount}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextSpan(
                      text: ' / ${controller.maxCapacity} Max',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: capacityRatio,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 16),

          // Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.personal_injury_outlined,
                  iconColor: Colors.redAccent,
                  title: 'Critical Triage',
                  value: '$redTriageCount Evacuees',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.warning_amber_rounded,
                  iconColor: Colors.orangeAccent,
                  title: 'Low Supplies',
                  value: '$criticalItemsCount Depleted',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.medical_services_outlined,
                  iconColor: Colors.greenAccent,
                  title: 'Medical Staff',
                  value: '${controller.medicalStaffCount} On Duty',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
