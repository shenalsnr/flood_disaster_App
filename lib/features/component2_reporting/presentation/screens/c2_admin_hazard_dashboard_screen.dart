import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flood_disaster/features/component2_reporting/data/services/offline_report_service.dart';
import 'package:flood_disaster/features/component2_reporting/data/services/offline_hazard_database.dart';
import 'package:flood_disaster/features/component2_reporting/presentation/screens/offline_draft_management_screen.dart';

/// Component 2: Hazard Community Reporter - Admin Dashboard
/// Implements full Hazard Report Management CRUD:
/// - CREATE: Submit new hazard reports (+ New Report button & Quick Create form)
/// - READ: Real-time inspection of all live & offline hazard reports with search & severity filters
/// - UPDATE: Edit description, severity, hazard type, status (VERIFIED / RESOLVED)
/// - DELETE: Permanently delete reports with confirmation safety checks
class C2AdminHazardDashboardScreen extends StatefulWidget {
  const C2AdminHazardDashboardScreen({super.key});

  @override
  State<C2AdminHazardDashboardScreen> createState() =>
      _C2AdminHazardDashboardScreenState();
}

class _C2AdminHazardDashboardScreenState
    extends State<C2AdminHazardDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'ALL';
  String _searchQuery = '';

  final List<String> _filterTabs = [
    'ALL',
    'CRITICAL',
    'MEDIUM',
    'LOW',
    'VERIFIED',
    'RESOLVED',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Color and Icon Helpers ─────────────────────────────────────────────────
  IconData _iconForHazard(String hazard) {
    final lower = hazard.toLowerCase();
    if (lower.contains('flood')) return Icons.waves_rounded;
    if (lower.contains('landslide')) return Icons.landscape_rounded;
    if (lower.contains('tree')) return Icons.park_rounded;
    if (lower.contains('road') || lower.contains('blocked')) {
      return Icons.do_not_disturb_on_rounded;
    }
    return Icons.warning_amber_rounded;
  }

  Color _colorForHazard(String hazard) {
    final lower = hazard.toLowerCase();
    if (lower.contains('flood')) return const Color(0xFF38BDF8);
    if (lower.contains('landslide')) return const Color(0xFFFFB300);
    if (lower.contains('tree')) return const Color(0xFF22C55E);
    return const Color(0xFFFF5252);
  }

  Color _colorForSeverity(String severity) {
    final upper = severity.toUpperCase();
    if (upper.contains('CRITICAL') || upper.contains('HIGH')) {
      return const Color(0xFFFF3B3B);
    }
    if (upper.contains('MEDIUM')) return const Color(0xFFFF9800);
    return const Color(0xFF00E676);
  }

  // ===========================================================================
  // CRUD 1: CREATE (Quick Admin Create Modal)
  // ===========================================================================
  void _openCreateReportModal() {
    final formKey = GlobalKey<FormState>();
    String hazardType = 'Flash Flood';
    String severity = 'HIGH / CRITICAL';
    String status = 'VERIFIED';
    final locationCtrl = TextEditingController(text: 'Kolonnawa Basin, Kelani River Area');
    final descCtrl = TextEditingController(
      text: 'Water rising rapidly near bridge. Immediate emergency monitoring required.',
    );
    double lat = 6.9271;
    double lng = 79.8612;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.add_circle_rounded, color: Color(0xFFFF9100), size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Admin: Create Hazard Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Hazard Type Dropdown
                  const Text('HAZARD TYPE',
                      style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162032),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF223452)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: hazardType,
                        dropdownColor: const Color(0xFF162032),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: ['Flash Flood', 'Landslide', 'Fallen Tree', 'Road Blocked']
                            .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => hazardType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Severity Dropdown
                  const Text('SEVERITY LEVEL',
                      style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162032),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF223452)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: severity,
                        dropdownColor: const Color(0xFF162032),
                        isExpanded: true,
                        style: TextStyle(color: _colorForSeverity(severity), fontWeight: FontWeight.bold),
                        items: ['LOW SEVERITY', 'MEDIUM SEVERITY', 'HIGH / CRITICAL']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => severity = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Location
                  const Text('LOCATION / SECTOR',
                      style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: locationCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF162032),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  const Text('HAZARD DESCRIPTION',
                      style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF162032),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9100),
                        foregroundColor: const Color(0xFF140D07),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        final reporterName = user?.displayName ?? 'Admin Operator';

                        await FirebaseFirestore.instance.collection('hazard_reports').add({
                          'hazardType': hazardType,
                          'severity': severity,
                          'location': locationCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'status': status,
                          'isVerified': true,
                          'hasPhoto': false,
                          'reporterName': reporterName,
                          'reporterEmail': user?.email ?? 'admin.dmc@gov.lk',
                          'latitude': lat,
                          'longitude': lng,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Created and published new $hazardType report!'),
                            backgroundColor: const Color(0xFF00E676),
                          ),
                        );
                      },
                      child: const Text('BROADCAST HAZARD REPORT',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CRUD 2: READ (Inspection Modal with Details)
  // ===========================================================================
  void _openReportDetailsModal(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final hazard = data['hazardType'] as String? ?? 'Hazard';
    final severity = data['severity'] as String? ?? 'HIGH / CRITICAL';
    final status = data['status'] as String? ?? 'VERIFIED';
    final location = data['location'] as String? ?? 'Kolonnawa Sector';
    final desc = data['description'] as String? ?? 'No details provided';
    final reporter = data['reporterName'] as String? ?? 'Kapila Perera';
    final email = data['reporterEmail'] as String? ?? 'volunteer@dmc.org';
    final lat = (data['latitude'] as num?)?.toDouble() ?? 6.9271;
    final lng = (data['longitude'] as num?)?.toDouble() ?? 79.8612;
    final photoPath = data['photoPath'] as String?;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final timeStr = timestamp != null
        ? DateFormat('yyyy-MM-dd • hh:mm a').format(timestamp)
        : 'Recently logged';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF09101E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 18),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _colorForHazard(hazard).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconForHazard(hazard),
                    color: _colorForHazard(hazard),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hazard,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        timeStr,
                        style: const TextStyle(color: Color(0xFF8B9BB4), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _colorForSeverity(severity).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _colorForSeverity(severity).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      color: _colorForSeverity(severity),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(color: Color(0xFF1E2D4A)),
            const SizedBox(height: 10),

            // Location & GPS
            _buildDetailRow(Icons.location_on_rounded, 'Location', '$location (${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E)'),
            const SizedBox(height: 12),

            // Reporter
            _buildDetailRow(Icons.person_rounded, 'Reporter', '$reporter ($email)'),
            const SizedBox(height: 12),

            // Status
            _buildDetailRow(Icons.verified_rounded, 'Status', status),
            const SizedBox(height: 12),

            // Description
            _buildDetailRow(Icons.notes_rounded, 'Field Note', desc),

            if (photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync()) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photoPath),
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Actions: Update & Delete
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF152238),
                      foregroundColor: const Color(0xFF38BDF8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFF263A5E)),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('EDIT (UPDATE)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openUpdateReportModal(doc);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A1218),
                      foregroundColor: const Color(0xFFFF5252),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFF4C1D24)),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteReport(doc.id, hazard, location);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CRUD 3: UPDATE (Edit Description, Severity, Status)
  // ===========================================================================
  void _openUpdateReportModal(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String hazardType = data['hazardType'] as String? ?? 'Flash Flood';
    String severity = data['severity'] as String? ?? 'HIGH / CRITICAL';
    String status = data['status'] as String? ?? 'VERIFIED';
    final descCtrl = TextEditingController(text: data['description'] as String? ?? '');
    final locationCtrl = TextEditingController(text: data['location'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 26),
                    SizedBox(width: 10),
                    Text(
                      'Update Hazard Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Hazard Type
                const Text('HAZARD TYPE',
                    style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162032),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF223452)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: hazardType,
                      dropdownColor: const Color(0xFF162032),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      items: ['Flash Flood', 'Landslide', 'Fallen Tree', 'Road Blocked']
                          .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => hazardType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Severity
                const Text('SEVERITY LEVEL',
                    style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162032),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF223452)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: severity,
                      dropdownColor: const Color(0xFF162032),
                      isExpanded: true,
                      style: TextStyle(color: _colorForSeverity(severity), fontWeight: FontWeight.bold),
                      items: ['LOW SEVERITY', 'MEDIUM SEVERITY', 'HIGH / CRITICAL']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => severity = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Status
                const Text('REPORT STATUS',
                    style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162032),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF223452)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: status,
                      dropdownColor: const Color(0xFF162032),
                      isExpanded: true,
                      style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                      items: ['VERIFIED', 'PENDING REVIEW', 'RESOLVED', 'REJECTED']
                          .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Location
                const Text('LOCATION',
                    style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: locationCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF162032),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),

                // Description
                const Text('DESCRIPTION / NOTE',
                    style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF162032),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 22),

                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: const Color(0xFF060B14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('hazard_reports').doc(doc.id).update({
                        'hazardType': hazardType,
                        'severity': severity,
                        'status': status,
                        'location': locationCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hazard report updated successfully!'),
                          backgroundColor: Color(0xFF00E676),
                        ),
                      );
                    },
                    child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CRUD 4: DELETE (Confirmation Dialog & Firestore Delete)
  // ===========================================================================
  void _confirmDeleteReport(String docId, String hazard, String location) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 26),
            SizedBox(width: 10),
            Text('Confirm Deletion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the "$hazard" report at "$location"?\n\nThis action cannot be undone.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('hazard_reports').doc(docId).delete();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Hazard report permanently deleted.'),
                      backgroundColor: Color(0xFFFF5252),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete Report', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF8B9BB4), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF8B9BB4), fontSize: 11.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  border: Border.all(color: const Color(0xFF1E2D4A), width: 1.2),
                ),
                child: const Center(
                  child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hazard Operations Console',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                'Component 2 • Hazard Report Management (CRUD)',
                style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Offline & Draft Reports (SQLite)',
              icon: const Icon(Icons.storage_rounded, color: Color(0xFFFF9800)),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OfflineDraftManagementScreen(),
                  ),
                );
                setState(() {});
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Refresh & Auto-Sync',
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
                onPressed: () {
                  OfflineReportService.instance.autoSyncPendingReports();
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Live Metrics Bar ─────────────────────────────────────────────
            _buildLiveMetricsHeader(),

            // ── SQLite Offline Drafts Console Banner ─────────────────────────
            _buildOfflineDraftsConsoleBanner(),

            // ── Search & Filter Row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by hazard, location or notes...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8B9BB4), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF0F1728),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1E2B44)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1E2B44)),
                  ),
                ),
              ),
            ),

            // ── Filter Chips ─────────────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterTabs.length,
                itemBuilder: (context, i) {
                  final tab = _filterTabs[i];
                  final isSelected = _selectedFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tab),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = tab),
                      backgroundColor: const Color(0xFF0F1728),
                      selectedColor: const Color(0xFFFF9100).withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFFFF9100) : const Color(0xFF8B9BB4),
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFF9100) : const Color(0xFF1E2B44),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // ── Reports Stream (Read & Manage) ───────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('hazard_reports')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF9100)),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final hazard = (data['hazardType'] as String? ?? '').toLowerCase();
                    final location = (data['location'] as String? ?? '').toLowerCase();
                    final desc = (data['description'] as String? ?? '').toLowerCase();
                    final severity = (data['severity'] as String? ?? '').toUpperCase();
                    final status = (data['status'] as String? ?? '').toUpperCase();

                    // Search filter
                    if (_searchQuery.isNotEmpty) {
                      final match = hazard.contains(_searchQuery) ||
                          location.contains(_searchQuery) ||
                          desc.contains(_searchQuery);
                      if (!match) return false;
                    }

                    // Severity / Status filter
                    if (_selectedFilter == 'CRITICAL') {
                      return severity.contains('CRITICAL') || severity.contains('HIGH');
                    }
                    if (_selectedFilter == 'MEDIUM') return severity.contains('MEDIUM');
                    if (_selectedFilter == 'LOW') return severity.contains('LOW');
                    if (_selectedFilter == 'VERIFIED') return status.contains('VERIFIED');
                    if (_selectedFilter == 'RESOLVED') return status.contains('RESOLVED');

                    return true;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, color: Colors.white.withValues(alpha: 0.2), size: 64),
                          const SizedBox(height: 12),
                          const Text(
                            'No matching hazard reports found',
                            style: TextStyle(color: Color(0xFF8B9BB4), fontSize: 15),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9100),
                              foregroundColor: const Color(0xFF140D07),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Report'),
                            onPressed: _openCreateReportModal,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final hazard = data['hazardType'] as String? ?? 'Hazard';
                      final severity = data['severity'] as String? ?? 'HIGH / CRITICAL';
                      final location = data['location'] as String? ?? 'Sector';
                      final status = data['status'] as String? ?? 'VERIFIED';
                      final desc = data['description'] as String? ?? '';
                      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                      final timeStr = timestamp != null
                          ? DateFormat('hh:mm a').format(timestamp)
                          : 'Recent';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1728),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E2B44)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openReportDetailsModal(doc),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hazard Icon
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _colorForHazard(hazard).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _iconForHazard(hazard),
                                      color: _colorForHazard(hazard),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Report Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                hazard,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              timeStr,
                                              style: const TextStyle(color: Color(0xFF8B9BB4), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          location,
                                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                                        ),
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            desc,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                          ),
                                        ],
                                        const SizedBox(height: 8),

                                        // Badges: Severity + Status
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: _colorForSeverity(severity).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                severity,
                                                style: TextStyle(
                                                  color: _colorForSeverity(severity),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                status,
                                                style: const TextStyle(
                                                  color: Color(0xFF00E676),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quick Edit & Delete icons
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF8B9BB4), size: 20),
                                    color: const Color(0xFF162032),
                                    onSelected: (action) {
                                      if (action == 'view') {
                                        _openReportDetailsModal(doc);
                                      } else if (action == 'edit') {
                                        _openUpdateReportModal(doc);
                                      } else if (action == 'delete') {
                                        _confirmDeleteReport(doc.id, hazard, location);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility_rounded, color: Colors.white70, size: 18),
                                            SizedBox(width: 8),
                                            Text('Inspect (Read)', style: TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_rounded, color: Color(0xFF38BDF8), size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit (Update)', style: TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 18),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Color(0xFFFF5252))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── Floating Action Button: + CREATE REPORT ───────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF9100),
        foregroundColor: const Color(0xFF140D07),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'CREATE REPORT',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        onPressed: _openCreateReportModal,
      ),
    );
  }

  // ── Metrics Header ─────────────────────────────────────────────────────────
  Widget _buildLiveMetricsHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('hazard_reports').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        int total = docs.length;
        int critical = docs.where((d) {
          final s = ((d.data() as Map<String, dynamic>)['severity'] as String? ?? '').toUpperCase();
          return s.contains('CRITICAL') || s.contains('HIGH');
        }).length;
        int verified = docs.where((d) {
          final s = ((d.data() as Map<String, dynamic>)['status'] as String? ?? '').toUpperCase();
          return s.contains('VERIFIED');
        }).length;
        int offlinePending = OfflineReportService.instance.pendingCount;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1728),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E2B44)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric('$total', 'Total', const Color(0xFF38BDF8)),
              Container(width: 1, height: 30, color: const Color(0xFF1E2B44)),
              _buildMiniMetric('$critical', 'Critical', const Color(0xFFFF3B3B)),
              Container(width: 1, height: 30, color: const Color(0xFF1E2B44)),
              _buildMiniMetric('$verified', 'Verified', const Color(0xFF00E676)),
              Container(width: 1, height: 30, color: const Color(0xFF1E2B44)),
              _buildMiniMetric('$offlinePending', 'Offline Q', const Color(0xFFFF9800)),
            ],
          ),
        );
      },
    );
  }

  // ── Offline Drafts Console Banner ─────────────────────────────────────────
  Widget _buildOfflineDraftsConsoleBanner() {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        OfflineHazardDatabase.instance.getPendingCount(),
        OfflineHazardDatabase.instance.getDraftCount(),
      ]),
      builder: (context, snapshot) {
        final pending = snapshot.data != null ? snapshot.data![0] : 0;
        final drafts = snapshot.data != null ? snapshot.data![1] : 0;

        return InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OfflineDraftManagementScreen(),
              ),
            );
            setState(() {});
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: pending > 0
                    ? const Color(0xFFFF9800).withValues(alpha: 0.5)
                    : const Color(0xFF334155),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storage_rounded,
                    color: Color(0xFFFF9800),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Offline Drafts & Queue (SQLite)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (pending > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$pending PENDING',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$pending queued for cloud sync • $drafts saved drafts • SQLite Active',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'MANAGE',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF38BDF8), size: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniMetric(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8B9BB4), fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
