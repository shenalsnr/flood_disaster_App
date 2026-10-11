import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/offline_hazard_report.dart';
import '../../data/services/offline_hazard_database.dart';
import '../../data/services/offline_report_service.dart';

/// Screen for managing Offline & Draft Hazard Reports with complete SQLite CRUD:
/// - CREATE: Save reports as offline drafts when disconnected from the internet
/// - READ: Real-time inspection of all stored drafts with filter tabs & search
/// - UPDATE: Edit draft details (hazard type, severity, description, location)
/// - DELETE: Permanently delete unwanted drafts from local SQLite storage
/// - SYNC: Manually or automatically broadcast verified drafts to Firebase Firestore
class OfflineDraftManagementScreen extends StatefulWidget {
  const OfflineDraftManagementScreen({super.key});

  @override
  State<OfflineDraftManagementScreen> createState() =>
      _OfflineDraftManagementScreenState();
}

class _OfflineDraftManagementScreenState
    extends State<OfflineDraftManagementScreen> {
  List<OfflineHazardReport> _reports = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // ALL, PENDING_SYNC, DRAFT, SYNCED
  bool _isOnline = false;
  bool _isSyncing = false;

  int _totalCount = 0;
  int _pendingCount = 0;
  int _draftCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkNetwork();
  }

  Future<void> _checkNetwork() async {
    final online = await OfflineReportService.instance.checkOnline();
    if (mounted) {
      setState(() => _isOnline = online);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reports = await OfflineHazardDatabase.instance.getAllReports(
        statusFilter: _selectedFilter == 'ALL' ? null : _selectedFilter,
      );
      final total = await OfflineHazardDatabase.instance.getTotalCount();
      final pending = await OfflineHazardDatabase.instance.getPendingCount();
      final drafts = await OfflineHazardDatabase.instance.getDraftCount();

      if (mounted) {
        setState(() {
          _reports = reports;
          _totalCount = total;
          _pendingCount = pending;
          _draftCount = drafts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading offline drafts from SQLite: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Color & Icon Helpers ───────────────────────────────────────────────────
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
    if (lower.contains('flood')) return const Color(0xFF40C4FF);
    if (lower.contains('landslide')) return const Color(0xFFFFB300);
    if (lower.contains('tree')) return const Color(0xFF22C55E);
    return const Color(0xFFFF5252);
  }

  Color _colorForSeverity(String severity) {
    final upper = severity.toUpperCase();
    if (upper.contains('CRITICAL') || upper.contains('HIGH')) {
      return const Color(0xFFFF3B3B);
    }
    if (upper.contains('MEDIUM')) return const Color(0xFFFF9F0A);
    return const Color(0xFF00E676);
  }

  Color _colorForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING_SYNC':
        return const Color(0xFFFF9F0A);
      case 'DRAFT':
        return const Color(0xFF40C4FF);
      case 'SYNCED':
        return const Color(0xFF00E676);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  // ===========================================================================
  // CRUD 1: CREATE (Create New Offline Draft Modal)
  // ===========================================================================
  void _openCreateDraftModal() {
    final formKey = GlobalKey<FormState>();
    String hazardType = 'Flash Flood';
    String severity = 'HIGH / CRITICAL';
    String status = 'PENDING_SYNC';
    final locationCtrl = TextEditingController(
        text: 'Kolonnawa Lowland Basin, Kelani River');
    final descCtrl = TextEditingController(
      text: 'Water level rising quickly near canal culvert. Access road submerged.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF070B14),
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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.post_add_rounded,
                              color: Color(0xFF00E676),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Save Offline Draft (SQLite)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This report will be saved permanently in SQLite storage on this device, accessible without any internet signal.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Hazard Type Dropdown
                  const Text(
                    'HAZARD CATEGORY',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: hazardType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                        items: [
                          'Flash Flood',
                          'Landslide Risk',
                          'Fallen Tree Obstruction',
                          'Road Inundation',
                        ].map((h) {
                          return DropdownMenuItem(value: h, child: Text(h));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => hazardType = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Severity & Queue Status
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SEVERITY',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFF334155)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: severity,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                  items: [
                                    'HIGH / CRITICAL',
                                    'MEDIUM',
                                    'LOW',
                                  ].map((s) {
                                    return DropdownMenuItem(
                                        value: s, child: Text(s));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => severity = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STORAGE INTENT',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFF334155)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: status,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                  items: [
                                    DropdownMenuItem(
                                        value: 'PENDING_SYNC',
                                        child: Text('Auto-Sync Queue')),
                                    DropdownMenuItem(
                                        value: 'DRAFT',
                                        child: Text('Local Draft Only')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => status = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Location
                  const Text(
                    'LOCATION / SECTOR',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: locationCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Description
                  const Text(
                    'SITUATION OBSERVATION / NOTE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 22),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: const Text(
                        'SAVE TO SQLITE STORAGE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final now = DateTime.now();
                        final reportId = '#OFF-${1000 + Random().nextInt(9000)}';

                        final newReport = OfflineHazardReport(
                          id: reportId,
                          hazardType: hazardType,
                          severity: severity,
                          description: descCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
                          status: status,
                          createdAt: now,
                          updatedAt: now,
                        );

                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);

                        await OfflineHazardDatabase.instance
                            .insertReport(newReport);
                        nav.pop();
                        if (!mounted) return;
                        _loadData();

                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF070B14),
                            behavior: SnackBarBehavior.floating,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF00E676), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Offline draft $reportId saved in SQLite storage!',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
  // CRUD 3: UPDATE (Edit Draft Details Modal)
  // ===========================================================================
  void _openEditDraftModal(OfflineHazardReport report) {
    final formKey = GlobalKey<FormState>();
    String hazardType = report.hazardType;
    String severity = report.severity;
    String status = report.status;
    final locationCtrl = TextEditingController(text: report.location);
    final descCtrl = TextEditingController(text: report.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF070B14),
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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF40C4FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              color: Color(0xFF40C4FF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Offline Draft',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                report.id,
                                style: const TextStyle(
                                  color: Color(0xFFFF9F0A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Hazard Type
                  const Text(
                    'HAZARD TYPE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: [
                          'Flash Flood',
                          'Landslide Risk',
                          'Fallen Tree Obstruction',
                          'Road Inundation',
                        ].contains(hazardType)
                            ? hazardType
                            : 'Flash Flood',
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                        items: [
                          'Flash Flood',
                          'Landslide Risk',
                          'Fallen Tree Obstruction',
                          'Road Inundation',
                        ].map((h) {
                          return DropdownMenuItem(value: h, child: Text(h));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => hazardType = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Severity & Status
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SEVERITY',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFF334155)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: ['HIGH / CRITICAL', 'MEDIUM', 'LOW']
                                          .contains(severity)
                                      ? severity
                                      : 'MEDIUM',
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                  items: [
                                    'HIGH / CRITICAL',
                                    'MEDIUM',
                                    'LOW',
                                  ].map((s) {
                                    return DropdownMenuItem(
                                        value: s, child: Text(s));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => severity = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QUEUE STATUS',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFF334155)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: status,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                  items: [
                                    DropdownMenuItem(
                                        value: 'PENDING_SYNC',
                                        child: Text('Auto-Sync')),
                                    DropdownMenuItem(
                                        value: 'DRAFT', child: Text('Draft')),
                                    DropdownMenuItem(
                                        value: 'SYNCED',
                                        child: Text('Synced')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => status = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Location
                  const Text(
                    'LOCATION',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: locationCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Description
                  const Text(
                    'DESCRIPTION NOTE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40C4FF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'UPDATE SQLITE DRAFT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final updated = report.copyWith(
                          hazardType: hazardType,
                          severity: severity,
                          status: status,
                          location: locationCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                        );

                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);

                        await OfflineHazardDatabase.instance
                            .updateReport(updated);
                        nav.pop();
                        if (!mounted) return;
                        _loadData();

                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF070B14),
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Draft ${report.id} updated successfully!',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
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
  // CRUD 4: DELETE (Confirm & Delete from SQLite)
  // ===========================================================================
  void _confirmDeleteDraft(OfflineHazardReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF070B14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B3B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFFF3B3B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Draft?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete draft "${report.id}" (${report.hazardType})? This record will be permanently wiped from local SQLite storage.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B3B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await OfflineHazardDatabase.instance.deleteReport(report.id);
              _loadData();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF070B14),
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Draft ${report.id} removed from SQLite.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  // ── Sync Single Report Now ─────────────────────────────────────────────────
  Future<void> _syncSingleDraft(OfflineHazardReport report) async {
    final online = await OfflineReportService.instance.checkOnline();
    if (!online) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF7F1D1D),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Cannot sync: No active internet connection detected.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);
    final success =
        await OfflineReportService.instance.syncSingleReport(report);
    setState(() => _isSyncing = false);

    if (mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success
              ? const Color(0xFF064E3B)
              : const Color(0xFF7F1D1D),
          behavior: SnackBarBehavior.floating,
          content: Text(
            success
                ? 'Report ${report.id} uploaded to Disaster Operations Room!'
                : 'Failed to sync report. Kept safely in SQLite.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  // ── Sync All Pending Reports ───────────────────────────────────────────────
  Future<void> _syncAllPending() async {
    setState(() => _isSyncing = true);
    final count =
        await OfflineReportService.instance.autoSyncPendingReports();
    setState(() => _isSyncing = false);

    if (mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: count > 0
              ? const Color(0xFF064E3B)
              : const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          content: Text(
            count > 0
                ? '$count reports successfully synchronized to Cloud!'
                : 'No internet connection or no pending reports to sync.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070E1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offline & Draft Reports',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF9F0A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isOnline
                      ? 'ONLINE • Ready to Sync'
                      : 'OFFLINE • SQLite Storage Active',
                  style: TextStyle(
                    color: _isOnline
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF9F0A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isSyncing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00E676),
                  ),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Sync All Pending Now',
              icon: const Icon(Icons.sync_rounded, color: Color(0xFF00E676)),
              onPressed: _syncAllPending,
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              _checkNetwork();
              _loadData();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'NEW DRAFT',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        onPressed: _openCreateDraftModal,
      ),
      body: Column(
        children: [
          // ── Stat Counters ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF131B2B),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B), width: 1.2),
              ),
            ),
            child: Row(
              children: [
                _buildStatBadge(
                  label: 'TOTAL SAVED',
                  count: _totalCount,
                  color: Colors.white,
                  icon: Icons.storage_rounded,
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  label: 'PENDING SYNC',
                  count: _pendingCount,
                  color: const Color(0xFFFF9F0A),
                  icon: Icons.cloud_upload_outlined,
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  label: 'DRAFTS',
                  count: _draftCount,
                  color: const Color(0xFF40C4FF),
                  icon: Icons.edit_note_rounded,
                ),
              ],
            ),
          ),

          // ── Filter Chips ───────────────────────────────────────────────────
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('ALL', 'All'),
                _buildFilterChip('PENDING_SYNC', 'Pending Sync ($_pendingCount)'),
                _buildFilterChip('DRAFT', 'Drafts ($_draftCount)'),
                _buildFilterChip('SYNCED', 'Synced'),
              ],
            ),
          ),

          // ── List of Reports ────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00E676),
                    ),
                  )
                : _reports.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _checkNetwork();
                          await _loadData();
                        },
                        color: const Color(0xFF00E676),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: _reports.length,
                          itemBuilder: (ctx, index) {
                            return _buildReportCard(_reports[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF00E676),
        backgroundColor: const Color(0xFF1E293B),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : const Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF00E676)
              : const Color(0xFF334155),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (val) {
          if (val) {
            setState(() => _selectedFilter = value);
            _loadData();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Icon(
              Icons.storage_rounded,
              color: Color(0xFF64748B),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Offline Drafts Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "+ NEW DRAFT" below to create an offline report\nstored securely in SQLite database.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // ── Report Item Card ───────────────────────────────────────────────────────
  Widget _buildReportCard(OfflineHazardReport report) {
    final hazardColor = _colorForHazard(report.hazardType);
    final sevColor = _colorForSeverity(report.severity);
    final statColor = _colorForStatus(report.status);
    final timeStr = DateFormat('MMM dd, hh:mm a').format(report.updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: report.status == 'PENDING_SYNC'
              ? const Color(0xFFFF9F0A).withValues(alpha: 0.4)
              : const Color(0xFF1E293B),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditDraftModal(report),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Hazard Icon, Title, ID, Status
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: hazardColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hazardColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      _iconForHazard(report.hazardType),
                      color: hazardColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              report.hazardType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              report.id,
                              style: const TextStyle(
                                color: Color(0xFFFF9F0A),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Color(0xFF64748B), size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statColor.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      report.status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: statColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),

              if (report.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  report.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(color: Color(0xFF1E293B), height: 1),
              const SizedBox(height: 10),

              // Bottom Actions: Severity, Time, Edit & Delete Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: sevColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          report.severity,
                          style: TextStyle(
                            color: sevColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (report.status != 'SYNCED')
                        IconButton(
                          tooltip: 'Sync Now',
                          icon: const Icon(Icons.cloud_upload_outlined,
                              color: Color(0xFF00E676), size: 19),
                          onPressed: () => _syncSingleDraft(report),
                        ),
                      IconButton(
                        tooltip: 'Edit Draft',
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xFF40C4FF), size: 19),
                        onPressed: () => _openEditDraftModal(report),
                      ),
                      IconButton(
                        tooltip: 'Delete Draft',
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFFF5252), size: 19),
                        onPressed: () => _confirmDeleteDraft(report),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
