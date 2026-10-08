import 'package:flutter/material.dart';
import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import 'alert_dashboard_screen.dart';

class ResolveAnalysisScreen extends StatefulWidget {
  final IncidentReport incident;

  const ResolveAnalysisScreen({super.key, required this.incident});

  @override
  State<ResolveAnalysisScreen> createState() => _ResolveAnalysisScreenState();
}

class _ResolveAnalysisScreenState extends State<ResolveAnalysisScreen> {
  final ResponderController _controller = ResponderController();

  String _resolutionType = 'Evacuated / Rescued';
  final TextEditingController _notesController = TextEditingController(
    text:
        'Colombo Rescue Squad A deployed 2 zodiac inflatable crafts. 14 stranded residents (including 3 children and 2 elderly citizens) safely extracted and transported to Rathnapura / Sector 4 Relief Camp. Water level receding to safe baseline. No casualties reported.',
  );

  int _evacuatedCount = 14;
  bool _checklistNotified = true;
  bool _checklistAreaSecured = true;
  bool _checklistStructuralEvaluated = true;
  bool _checklistCampNotified = true;

  final List<String> _resolutionOptions = [
    'Evacuated / Rescued',
    'Water Receded / Ground Safe',
    'Hazard Cleared / Road Reopened',
    'Relief Camp Handover Complete',
    'False Alarm / Duplicate Report',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _markIncidentResolved() {
    _controller.resolveIncident(
      incident: widget.incident,
      resolutionType: _resolutionType,
      notes: _notesController.text,
      evacuatedCount: _evacuatedCount,
    );

    // Show Resolution Success Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF00E676), size: 28),
            SizedBox(width: 10),
            Text(
              'Incident Resolved',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident #${widget.incident.id} has been formally closed and marked resolved in National DMC database.',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RESOLUTION OUTCOME: $_resolutionType',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Evacuated to Shelter: $_evacuatedCount Citizens',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lead Squad: ${widget.incident.assignedTeam?.name ?? "Rescue Squad A"}',
                    style: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const AlertDashboardScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('RETURN TO TRIAGE DASHBOARD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Close & Resolve Incident',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Incident Reference Card (Wireframe 6)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INCIDENT REFERENCE: #${incident.id}',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'READY TO RESOLVE',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      incident.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${incident.location}\nAssigned Unit: ${incident.assignedTeam?.name ?? "Colombo Rescue Squad A"}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Resolution Type Dropdown (Wireframe 6)
              _buildSectionTitle('RESOLUTION OUTCOME CLASSIFICATION'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _resolutionType,
                    dropdownColor: const Color(0xFF1E293B),
                    isExpanded: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    items: _resolutionOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt,
                        child: Text(opt),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _resolutionType = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Evacuee Count & Metrics
              _buildSectionTitle('CITIZEN CASUALTY / RESCUE METRICS'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evacuated Citizens',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Transferred to safe zone shelter',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Color(0xFFFF6D00)),
                          onPressed: () {
                            if (_evacuatedCount > 0) {
                              setState(() => _evacuatedCount--);
                            }
                          },
                        ),
                        Text(
                          '$_evacuatedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFFFF6D00)),
                          onPressed: () {
                            setState(() => _evacuatedCount++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Dispatcher Disposal Notes (Wireframe 6)
              _buildSectionTitle('DISPATCHER DISPOSAL NOTES'),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  hintText: 'Enter formal dispatch resolution notes...',
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Resolution Checklist (Wireframe 6)
              _buildSectionTitle('MANDATORY RESOLUTION CHECKLIST'),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    _buildChecklistTile(
                      title: 'All affected citizens in sector accounted for',
                      value: _checklistNotified,
                      onChanged: (v) =>
                          setState(() => _checklistNotified = v ?? false),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    _buildChecklistTile(
                      title: 'Area secured by local municipal / DMC teams',
                      value: _checklistAreaSecured,
                      onChanged: (v) =>
                          setState(() => _checklistAreaSecured = v ?? false),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    _buildChecklistTile(
                      title: 'Structural integrity of drain / road evaluated',
                      value: _checklistStructuralEvaluated,
                      onChanged: (v) => setState(
                          () => _checklistStructuralEvaluated = v ?? false),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    _buildChecklistTile(
                      title: 'Relief camp notified of arriving evacuees',
                      value: _checklistCampNotified,
                      onChanged: (v) =>
                          setState(() => _checklistCampNotified = v ?? false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // Final Action Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: const Text(
                  'MARK INCIDENT AS RESOLVED',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: _markIncidentResolved,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildChecklistTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      dense: true,
      title: Text(
        title,
        style: TextStyle(
          color: value ? Colors.white : const Color(0xFF64748B),
          fontSize: 12,
          fontWeight: value ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      value: value,
      activeColor: const Color(0xFF00E676),
      checkColor: Colors.black,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
