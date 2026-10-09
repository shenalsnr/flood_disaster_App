import 'package:flutter/material.dart';

class HazardReportItem {
  final String id;
  final String title;
  final String location;
  final String timeAgo;
  final String status; // 'VERIFIED', 'PENDING', 'RESOLVED'
  final String hazardType;
  final String description;
  final String reporter;
  final IconData icon;
  final Color iconColor;
  final double? waterLevel;

  const HazardReportItem({
    required this.id,
    required this.title,
    required this.location,
    required this.timeAgo,
    required this.status,
    required this.hazardType,
    required this.description,
    required this.reporter,
    required this.icon,
    required this.iconColor,
    this.waterLevel,
  });
}

/// Detailed bottom sheet shown when a report card is tapped
class HazardReportDetailsSheet extends StatelessWidget {
  final HazardReportItem report;

  const HazardReportDetailsSheet({super.key, required this.report});

  static void show(BuildContext context, HazardReportItem report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HazardReportDetailsSheet(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = report.status == 'VERIFIED';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: report.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: report.iconColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(report.icon, color: report.iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.location} • ${report.timeAgo}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isVerified
                      ? const Color(0xFF00E676).withValues(alpha: 0.15)
                      : const Color(0xFFFFB300).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isVerified
                        ? const Color(0xFF00E676).withValues(alpha: 0.4)
                        : const Color(0xFFFFB300).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  report.status,
                  style: TextStyle(
                    color: isVerified
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFFB300),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 14),

          // Ground details
          const Text(
            'Ground Hazard Assessment',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 16),

          // Metrics chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DetailChip(
                icon: Icons.person_pin_circle_rounded,
                label: 'Reporter: ${report.reporter}',
              ),
              if (report.waterLevel != null)
                _DetailChip(
                  icon: Icons.water_drop_rounded,
                  label: 'Depth: ${report.waterLevel}m',
                ),
              const _DetailChip(
                icon: Icons.satellite_alt_rounded,
                label: 'GPS Tag: High Precision',
              ),
            ],
          ),

          const SizedBox(height: 26),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: const Text(
                'Close Assessment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF162544),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF263552)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
