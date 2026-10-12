import 'package:flutter/material.dart';
import '../../data/models/evacuee_model.dart';

import '../../../../core/localization/app_strings.dart';
class EvacueeTile extends StatelessWidget {
  final EvacueeModel evacuee;
  final Function(TriagePriority newTriage) onTriageChanged;

  const EvacueeTile({
    super.key,
    required this.evacuee,
    required this.onTriageChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String badgeLabel;

    switch (evacuee.triage) {
      case TriagePriority.red:
        badgeColor = const Color(0xFFF87171);
        badgeLabel = 'RED - IMMEDIATE CARE';
        break;
      case TriagePriority.yellow:
        badgeColor = const Color(0xFFFFAB40);
        badgeLabel = 'YELLOW - ATTENTION';
        break;
      case TriagePriority.green:
        badgeColor = const Color(0xFF6EE7B7);
        badgeLabel = 'GREEN - STABLE';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: evacuee.triage == TriagePriority.red
              ? badgeColor.withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name, Triage Badge & Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: badgeColor.withValues(alpha: 0.2),
                    child: Text(
                      evacuee.fullName.substring(0, 1),
                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(evacuee.fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        tr('{p0}, {p1} yrs • Check-in: {p2}', {'p0': (evacuee.gender).toString(), 'p1': (evacuee.age).toString(), 'p2': (evacuee.checkInTime).toString()}),
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<TriagePriority>(
                icon: const Icon(Icons.more_vert, color: Colors.white60),
                color: const Color(0xFF2C2C2C),
                onSelected: onTriageChanged,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: TriagePriority.red,
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFFF87171), size: 12),
                        SizedBox(width: 8),
                        Text(tr('Set Red (Critical Care)'), style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: TriagePriority.yellow,
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFFFFAB40), size: 12),
                        SizedBox(width: 8),
                        Text(tr('Set Yellow (Needs Care)'), style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: TriagePriority.green,
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFF6EE7B7), size: 12),
                        SizedBox(width: 8),
                        Text(tr('Set Green (Stable)'), style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Triage Tag & Zone
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tr(badgeLabel),
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.blueAccent, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      tr(evacuee.assignedZone),
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (evacuee.specialNeeds.isNotEmpty && evacuee.specialNeeds != 'None') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF262626),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_information_outlined, color: Colors.orangeAccent, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tr('Medical / Special Note: {p0}', {'p0': (evacuee.specialNeeds).toString()}),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
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
