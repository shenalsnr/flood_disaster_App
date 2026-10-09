import 'package:flutter/material.dart';
import 'package:flood_disaster/features/component2_reporting/presentation/screens/hazard_report_wizard_screen.dart';
import 'package:flood_disaster/features/component2_reporting/presentation/screens/offline_draft_management_screen.dart';

/// Screen displayed after submitting a hazard report.
/// Matches the two user screenshots:
/// - Online state: "Report Submitted!" with green check badge & Report ID (#FLD-2847).
/// - Offline state: "Report Saved." with database icon, "NO SIGNAL DETECTED" badge,
///   and "1 Report Pending Upload" offline queue status.
class ReportSubmissionStatusScreen extends StatelessWidget {
  final bool isOnline;
  final String reportId;
  final int pendingCount;
  final String hazard;

  const ReportSubmissionStatusScreen({
    super.key,
    required this.isOnline,
    this.reportId = '#FLD-2847',
    this.pendingCount = 1,
    this.hazard = 'flood',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070E1B),
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Header / Status Bar with Online or Offline Badge ───────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '9:41',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF0B2418)
                                : const Color(0xFF2B1D0F),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isOnline
                                  ? const Color(0xFF00E676).withValues(alpha: 0.6)
                                  : const Color(0xFFFF9800).withValues(alpha: 0.5),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            isOnline ? 'ONLINE' : 'OFFLINE QUEUE',
                            style: TextStyle(
                              color: isOnline
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFFF9800),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.signal_cellular_alt_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 5),
                        Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 5),
                        Icon(Icons.battery_full_rounded,
                            color: Colors.white, size: 17),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Center Body Content ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),

                      // Circular Hero Icon Badge
                      isOnline
                          ? _buildOnlineHeroBadge()
                          : _buildOfflineHeroBadge(),

                      const SizedBox(height: 26),

                      // Screen Title
                      Text(
                        isOnline ? 'Report Submitted!' : 'Report Saved.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (!isOnline) ...[
                        const SizedBox(height: 12),
                        // "NO SIGNAL DETECTED" Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22160A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                color: Color(0xFFFF9800),
                                size: 15,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'NO SIGNAL DETECTED',
                                style: TextStyle(
                                  color: Color(0xFFFF9800),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Description Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          isOnline
                              ? 'Your ${hazard.toLowerCase()} report has been sent to Sri Lanka Disaster Management Centre (DMC) for verification.'
                              : 'Your report is safely stored offline. It will upload automatically as soon as your device reconnects to a signal.',
                          style: const TextStyle(
                            color: Color(0xFF8B9BB4),
                            fontSize: 14.5,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Dynamic Info Card
                      isOnline ? _buildOnlineReportIdCard() : _buildOfflineQueueCard(context),

                      const SizedBox(height: 24),

                      // Footer Subtext
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          isOnline
                              ? 'Responders and emergency services have been notified of this critical hazard.'
                              : 'Do not worry. Your hazard details are locked in with the precise GPS timestamp.',
                          style: const TextStyle(
                            color: Color(0xFF70809A),
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // ── Bottom Action Buttons ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    // Primary Orange Button: SUBMIT ANOTHER REPORT
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9100),
                          foregroundColor: const Color(0xFF140D07),
                          elevation: 4,
                          shadowColor: const Color(0xFFFF9100).withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          // Return to Step 1 to report another hazard
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HazardReportWizardScreen(),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text(
                          'SUBMIT ANOTHER REPORT',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Secondary White Button: Back to Home
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        // Pop all the way back to the volunteer dashboard
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Online State: Glowing Green Check Badge ────────────────────────────────
  Widget _buildOnlineHeroBadge() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1A2A3E),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.12),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00E676),
              width: 2.2,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: Color(0xFF00E676),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  // ── Offline State: Orange Database / Cylinders Badge ──────────────────────
  Widget _buildOfflineHeroBadge() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF191B24),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF2A2834),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.12),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.dns_rounded,
          color: Color(0xFFFF9800),
          size: 40,
        ),
      ),
    );
  }

  // ── Online State Card: REPORT ID #FLD-2847 ─────────────────────────────────
  Widget _buildOnlineReportIdCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E2B44),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'REPORT ID',
            style: TextStyle(
              color: Color(0xFF8B9BB4),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reportId,
            style: const TextStyle(
              color: Color(0xFFFF9100),
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Offline State Card: 1 Report Pending Upload ───────────────────────────
  // ── Offline State Card: 1 Report Pending Upload ───────────────────────────
  Widget _buildOfflineQueueCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1728),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OfflineDraftManagementScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF192338),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2B3A54),
                      width: 1.2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storage_rounded,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$pendingCount Report${pendingCount > 1 ? 's' : ''} Saved (SQLite)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Saved permanently • Tap to manage drafts',
                        style: TextStyle(
                          color: Color(0xFF8B9BB4),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFFF9800),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
