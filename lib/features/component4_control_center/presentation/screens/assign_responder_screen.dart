import 'package:flutter/material.dart';
import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import 'live_tracking_screen.dart';

class AssignResponderScreen extends StatefulWidget {
  final IncidentReport incident;

  const AssignResponderScreen({super.key, required this.incident});

  @override
  State<AssignResponderScreen> createState() => _AssignResponderScreenState();
}

class _AssignResponderScreenState extends State<AssignResponderScreen> {
  final ResponderController _controller = ResponderController();
  late EmergencyTeam _selectedTeam;
  final TextEditingController _dispatchNotesController = TextEditingController(
    text:
        'Priority Evacuation Order. Prepare inflatable watercraft and life jackets. Target two submerged residential structures on Sector 4 Low-Lying road.',
  );
  String _priorityLevel = 'CODE RED (CRITICAL EVACUATION)';

  @override
  void initState() {
    super.initState();
    // Default to first available team
    _selectedTeam = _controller.teams.firstWhere(
      (t) => t.isAvailable,
      orElse: () => _controller.teams.first,
    );
  }

  @override
  void dispose() {
    _dispatchNotesController.dispose();
    super.dispose();
  }

  void _confirmAndDispatch() {
    _controller.assignTeamToIncident(widget.incident, _selectedTeam);

    // Show quick confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${_selectedTeam.name} dispatched to Incident #${widget.incident.id}!'),
        backgroundColor: const Color(0xFF00E676),
      ),
    );

    // Navigate to Live Tracking Map
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(incident: widget.incident),
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
          'Dispatch Field Teams',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Target Incident Info Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFF6D00).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_turned_in,
                            color: Color(0xFFFF6D00), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'ASSIGNING RESPONDER TO INCIDENT:',
                          style: TextStyle(
                            color: Color(0xFFFF6D00),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            incident.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            incident.severityLabel,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${incident.location} • GPS: ${incident.coordinates.latitude.toStringAsFixed(4)}° N, ${incident.coordinates.longitude.toStringAsFixed(4)}° E',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Available Emergency Teams Header
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AVAILABLE EMERGENCY TEAMS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'SORTED BY ETA',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Team Cards
              ..._controller.teams.map((team) => _buildTeamCard(team)),

              const SizedBox(height: 16),

              // Priority Level
              const Text(
                'DISPATCH MISSION PRIORITY',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _priorityLevel,
                    dropdownColor: const Color(0xFF1E293B),
                    isExpanded: true,
                    style: const TextStyle(
                      color: Color(0xFFFF5252),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'CODE RED (CRITICAL EVACUATION)',
                        child: Text('🔴 CODE RED (CRITICAL EVACUATION)'),
                      ),
                      DropdownMenuItem(
                        value: 'CODE AMBER (HAZARD MITIGATION)',
                        child: Text('🟠 CODE AMBER (HAZARD MITIGATION)'),
                      ),
                      DropdownMenuItem(
                        value: 'CODE YELLOW (AREA RECONNAISSANCE)',
                        child: Text('🟡 CODE YELLOW (AREA RECONNAISSANCE)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _priorityLevel = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Dispatcher Special Instructions
              const Text(
                'DISPATCHER TACTICAL NOTES',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _dispatchNotesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  hintText: 'Enter mission briefing notes for squad...',
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

              const SizedBox(height: 24),

              // Confirm Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
                icon: const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  'CONFIRM ASSIGNMENT & DISPATCH (${_selectedTeam.name})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                onPressed: _selectedTeam.isAvailable ? _confirmAndDispatch : null,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(EmergencyTeam team) {
    final isSelected = _selectedTeam.id == team.id;
    final isAvailable = team.isAvailable;

    return GestureDetector(
      onTap: isAvailable ? () => setState(() => _selectedTeam = team) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E293B)
              : isAvailable
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF090D17),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6D00)
                : isAvailable
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF1E293B).withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Radio indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF6D00)
                          : isAvailable
                              ? const Color(0xFF64748B)
                              : const Color(0xFF334155),
                      width: 2,
                    ),
                    color: isSelected
                        ? const Color(0xFFFF6D00)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check, size: 12, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: TextStyle(
                          color: isAvailable ? Colors.white : Colors.white38,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Leader: ${team.leader} • Crew of ${team.crewCount} • Radio: ${team.radioChannel}',
                        style: TextStyle(
                          color: isAvailable
                              ? const Color(0xFF94A3B8)
                              : Colors.white24,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? const Color(0xFF00E676).withValues(alpha: 0.15)
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isAvailable
                          ? const Color(0xFF00E676)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    team.status,
                    style: TextStyle(
                      color: isAvailable
                          ? const Color(0xFF00E676)
                          : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Equipment & Distance Row
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF070B14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed, color: Color(0xFF38BDF8), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'ETA: ${team.eta} (${team.distance})',
                    style: TextStyle(
                      color: isAvailable ? Colors.white70 : Colors.white24,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.build_circle_outlined,
                      color: Color(0xFFFF6D00), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      team.equipment,
                      style: TextStyle(
                        color: isAvailable
                            ? const Color(0xFF94A3B8)
                            : Colors.white24,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
