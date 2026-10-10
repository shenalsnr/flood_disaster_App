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

class _ResolveAnalysisScreenState extends State<ResolveAnalysisScreen>
    with TickerProviderStateMixin {
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
  bool _isSubmitting = false;

  final List<String> _resolutionOptions = [
    'Evacuated / Rescued',
    'Water Receded / Ground Safe',
    'Hazard Cleared / Road Reopened',
    'Relief Camp Handover Complete',
    'False Alarm / Duplicate Report',
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkmarkAnimation = CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _fadeController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  bool get _allChecked =>
      _checklistNotified &&
      _checklistAreaSecured &&
      _checklistStructuralEvaluated &&
      _checklistCampNotified;

  void _markIncidentResolved() async {
    setState(() => _isSubmitting = true);

    // Simulate transmission delay
    await Future.delayed(const Duration(milliseconds: 800));

    _controller.resolveIncident(
      incident: widget.incident,
      resolutionType: _resolutionType,
      notes: _notesController.text,
      evacuatedCount: _evacuatedCount,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Show Resolution Success Dialog with animation
    _checkmarkController.forward();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ScaleTransition(
        scale: _checkmarkAnimation,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified, color: Color(0xFF00E676), size: 28),
              ),
              const SizedBox(width: 10),
              const Text(
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
                'Incident #${widget.incident.shortId} has been formally closed and marked resolved in National DMC database.',
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Close & Resolve Incident',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'CRUD: Delete • Formal Incident Closure',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Incident Reference Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.06),
                        const Color(0xFF0F172A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.assignment, color: Color(0xFF38BDF8), size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '#${incident.shortId}',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'READY TO RESOLVE',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        incident.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFFF6D00), size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              incident.location,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.groups_rounded, color: Color(0xFF64748B), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Assigned: ${incident.assignedTeam?.name ?? "Colombo Rescue Squad A"}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Resolution Type Dropdown
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
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                      items: _resolutionOptions.map((opt) {
                        IconData icon;
                        switch (opt) {
                          case 'Evacuated / Rescued':
                            icon = Icons.people;
                            break;
                          case 'Water Receded / Ground Safe':
                            icon = Icons.water_drop;
                            break;
                          case 'Hazard Cleared / Road Reopened':
                            icon = Icons.construction;
                            break;
                          case 'Relief Camp Handover Complete':
                            icon = Icons.night_shelter;
                            break;
                          default:
                            icon = Icons.info;
                        }
                        return DropdownMenuItem(
                          value: opt,
                          child: Row(
                            children: [
                              Icon(icon, color: const Color(0xFF38BDF8), size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(opt)),
                            ],
                          ),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.people_alt_rounded, color: Color(0xFF00E676), size: 20),
                          ),
                          const SizedBox(width: 12),
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
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Color(0xFFFF6D00), size: 22),
                              onPressed: () {
                                if (_evacuatedCount > 0) {
                                  setState(() => _evacuatedCount--);
                                }
                              },
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(scale: animation, child: child),
                              child: Text(
                                '$_evacuatedCount',
                                key: ValueKey<int>(_evacuatedCount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Color(0xFFFF6D00), size: 22),
                              onPressed: () {
                                setState(() => _evacuatedCount++);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Dispatcher Disposal Notes
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

                // Resolution Checklist
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
                        icon: Icons.people_outline,
                        value: _checklistNotified,
                        onChanged: (v) =>
                            setState(() => _checklistNotified = v ?? false),
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 1),
                      _buildChecklistTile(
                        title: 'Area secured by local municipal / DMC teams',
                        icon: Icons.security,
                        value: _checklistAreaSecured,
                        onChanged: (v) =>
                            setState(() => _checklistAreaSecured = v ?? false),
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 1),
                      _buildChecklistTile(
                        title: 'Structural integrity of drain / road evaluated',
                        icon: Icons.engineering,
                        value: _checklistStructuralEvaluated,
                        onChanged: (v) => setState(
                            () => _checklistStructuralEvaluated = v ?? false),
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 1),
                      _buildChecklistTile(
                        title: 'Relief camp notified of arriving evacuees',
                        icon: Icons.night_shelter,
                        value: _checklistCampNotified,
                        onChanged: (v) =>
                            setState(() => _checklistCampNotified = v ?? false),
                      ),
                    ],
                  ),
                ),

                // Checklist completion indicator
                if (_allChecked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00E676).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF00E676), size: 14),
                              SizedBox(width: 6),
                              Text(
                                'All protocol checks complete',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
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

                const SizedBox(height: 26),

                // Final Action Button with loading state
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                    shadowColor: const Color(0xFF00E676).withValues(alpha: 0.4),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 22),
                  label: Text(
                    _isSubmitting
                        ? 'SUBMITTING RESOLUTION...'
                        : 'MARK INCIDENT AS RESOLVED',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _markIncidentResolved,
                ),

                const SizedBox(height: 16),
              ],
            ),
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
    required IconData icon,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: value,
              activeColor: const Color(0xFF00E676),
              checkColor: Colors.black,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Icon(
              icon,
              color: value ? const Color(0xFF00E676) : const Color(0xFF475569),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: value ? Colors.white : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                  decoration: value ? TextDecoration.none : null,
                ),
              ),
            ),
            if (value)
              const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 16),
          ],
        ),
      ),
    );
  }
}
