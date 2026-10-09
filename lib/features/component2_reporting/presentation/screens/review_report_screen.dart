import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:flood_disaster/features/component2_reporting/data/services/offline_report_service.dart';
import 'package:flood_disaster/features/component2_reporting/presentation/screens/report_submission_status_screen.dart';

/// Review Your Report Screen.
/// Exactly matches the user's Figma/Mobile specification:
/// - Dark tactical theme with status bar indicators
/// - Top AppBar: Chevron back button & "Review Your Report" title
/// - Side-by-side Cards: HAZARD & SEVERITY
/// - LOCATION & GPS card with map thumbnail
/// - RECORDED AT card with live timestamp
/// - ATTACHED MEDIA card with image thumbnail and green file name
/// - Vibrant Green "SUBMIT REPORT" button
/// - Orange "Edit Details" button
class ReviewReportScreen extends StatefulWidget {
  final String hazard;
  final String severity;
  final File? imageFile;
  final String note;
  final LatLng coordinates;

  const ReviewReportScreen({
    super.key,
    required this.hazard,
    required this.severity,
    this.imageFile,
    required this.note,
    required this.coordinates,
  });

  @override
  State<ReviewReportScreen> createState() => _ReviewReportScreenState();
}

class _ReviewReportScreenState extends State<ReviewReportScreen> {
  bool _isSubmitting = false;
  late final DateTime _recordedTime;

  @override
  void initState() {
    super.initState();
    _recordedTime = DateTime.now();
  }

  IconData _getHazardIcon(String hazard) {
    final lower = hazard.toLowerCase();
    if (lower.contains('flood')) return Icons.waves_rounded;
    if (lower.contains('landslide')) return Icons.landscape_rounded;
    if (lower.contains('tree')) return Icons.park_rounded;
    if (lower.contains('road') || lower.contains('blocked')) {
      return Icons.do_not_disturb_on_rounded;
    }
    return Icons.warning_amber_rounded;
  }

  Color _getHazardColor(String hazard) {
    final lower = hazard.toLowerCase();
    if (lower.contains('flood')) return const Color(0xFF38BDF8);
    if (lower.contains('landslide')) return const Color(0xFFFFB300);
    if (lower.contains('tree')) return const Color(0xFF22C55E);
    return const Color(0xFFFF5252);
  }

  String _getDisplayHazardName(String hazard) {
    if (hazard.toLowerCase() == 'flash flood') return 'Flood';
    return hazard;
  }

  String _getDisplaySeverityName(String severity) {
    if (severity.toUpperCase().contains('HIGH') ||
        severity.toUpperCase().contains('CRITICAL')) {
      return 'CRITICAL / HIGH';
    }
    return severity.toUpperCase();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;
    final reporterName = user?.displayName ?? 'Kapila Perera';
    final reportCode = '#FLD-${1000 + Random().nextInt(9000)}';

    final reportData = {
      'localId': reportCode,
      'hazardType': widget.hazard,
      'severity': widget.severity,
      'location': 'Kolonnawa, 6.9271° N, 79.8612° E',
      'description': widget.note,
      'hasPhoto': widget.imageFile != null,
      'photoPath': widget.imageFile?.path ?? '',
      'reporterName': reporterName,
      'reporterEmail': user?.email ?? 'volunteer.kapila@dmc.org',
      'isVerified': true,
      'status': 'VERIFIED',
      'latitude': widget.coordinates.latitude,
      'longitude': widget.coordinates.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final isOnline = await OfflineReportService.instance.checkOnline();

    if (isOnline) {
      try {
        final onlinePayload = Map<String, dynamic>.from(reportData);
        onlinePayload.remove('localId');
        onlinePayload['timestamp'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance
            .collection('hazard_reports')
            .add(onlinePayload)
            .timeout(const Duration(seconds: 4));

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        // Navigate directly to Online "Report Submitted!" Screen (Screenshot 1)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReportSubmissionStatusScreen(
              isOnline: true,
              reportId: reportCode,
              hazard: widget.hazard,
            ),
          ),
        );
        return;
      } catch (e) {
        debugPrint('Online submission failed, falling back to offline queue: $e');
      }
    }

    // Offline state: Store report safely in phone local storage (Screenshot 2)
    await OfflineReportService.instance.queueReport(reportData);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Navigate directly to Offline "Report Saved." Screen (Screenshot 2)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReportSubmissionStatusScreen(
          isOnline: false,
          pendingCount: OfflineReportService.instance.pendingCount,
          hazard: widget.hazard,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(_recordedTime);
    final fileName = widget.imageFile != null
        ? widget.imageFile!.path.split(Platform.pathSeparator).last
        : 'flood_evidence_0941.jpg';

    return Scaffold(
      backgroundColor: const Color(0xFF070E1B),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: AppBar(
          backgroundColor: const Color(0xFF070E1B),
          elevation: 0,
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10192A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1E2D4A),
                    width: 1.2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          titleSpacing: 10,
          title: const Text(
            'Review Your Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Row 1: Side-by-Side HAZARD & SEVERITY Cards ────────────────
              Row(
                children: [
                  // Hazard Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1728),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF1E2B44),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HAZARD',
                            style: TextStyle(
                              color: Color(0xFF8B9BB4),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                _getHazardIcon(widget.hazard),
                                color: _getHazardColor(widget.hazard),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getDisplayHazardName(widget.hazard),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Severity Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1728),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF1E2B44),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SEVERITY',
                            style: TextStyle(
                              color: Color(0xFF8B9BB4),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E1218),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFF3B3B).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getDisplaySeverityName(widget.severity),
                                style: const TextStyle(
                                  color: Color(0xFFFF3B3B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Card 2: LOCATION & GPS ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1728),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF1E2B44),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // Mini Map Preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF152238),
                          border: Border.all(color: const Color(0xFF243654)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: widget.coordinates,
                                initialZoom: 12.5,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.wesafe.flooddisaster',
                                ),
                                Container(
                                  color: const Color(0xFF0A1E2E)
                                      .withValues(alpha: 0.35),
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: widget.coordinates,
                                      width: 20,
                                      height: 20,
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFFFF9100),
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LOCATION & GPS',
                            style: TextStyle(
                              color: Color(0xFF8B9BB4),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kolonnawa, ${widget.coordinates.latitude.toStringAsFixed(4)}° N, ${widget.coordinates.longitude.toStringAsFixed(4)}° E',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Card 3: RECORDED AT ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1728),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF1E2B44),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF152238),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF283A58),
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RECORDED AT',
                            style: TextStyle(
                              color: Color(0xFF8B9BB4),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Today, $timeStr (Local Time)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Card 4: ATTACHED MEDIA ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1728),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF1E2B44),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // Media Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52,
                        height: 52,
                        color: const Color(0xFF162032),
                        child: widget.imageFile != null
                            ? Image.file(
                                widget.imageFile!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: const Color(0xFF1B263B),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF00E676),
                                    size: 26,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ATTACHED MEDIA',
                            style: TextStyle(
                              color: Color(0xFF8B9BB4),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fileName,
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 34),

              // ── Button: SUBMIT REPORT (Vivid Green) ────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E), // Solid Vivid Green
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF22C55E).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SUBMIT REPORT',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Link: Edit Details (Vibrant Orange) ─────────────────────────
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF9100),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Edit Details',
                    style: TextStyle(
                      color: Color(0xFFFF9100),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
