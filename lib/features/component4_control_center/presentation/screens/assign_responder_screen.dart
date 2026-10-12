import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import 'live_tracking_screen.dart';
import '../widgets/c4_ui.dart';

import '../../../../core/localization/app_strings.dart';
class AssignResponderScreen extends StatefulWidget {
  final IncidentReport incident;

  const AssignResponderScreen({super.key, required this.incident});

  @override
  State<AssignResponderScreen> createState() => _AssignResponderScreenState();
}

class _AssignResponderScreenState extends State<AssignResponderScreen>
    with TickerProviderStateMixin {
  final ResponderController _controller = ResponderController();
  late EmergencyTeam _selectedTeam;
  String _selectedVehicleFilter = 'ALL';

  final TextEditingController _dispatchNotesController = TextEditingController(
    text:
        'Priority Evacuation Order. Prepare inflatable watercraft and life jackets. Target submerged residential structures on Sector 4 Low-Lying road.',
  );
  String _priorityLevel = 'CODE RED (CRITICAL EVACUATION)';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChange);
    // Default to first available team sorted by ETA
    _selectedTeam = _pickDefaultTeam();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  static const EmergencyTeam _noTeam = EmergencyTeam(
    id: '',
    name: 'No unit selected',
    status: 'NONE',
    distance: '-',
    eta: '-',
    equipment: '-',
    crewCount: 0,
    leader: '-',
    radioChannel: '-',
    location: LatLng(7.8731, 80.7718),
    vehicleType: '-',
    callSign: '-',
    phoneNumber: '',
    fuelLevel: 0,
  );

  EmergencyTeam _pickDefaultTeam() {
    final list = _controller.sortedTeamsByEta;
    for (final t in list) {
      if (t.isAvailable) return t;
    }
    return list.isEmpty ? _noTeam : list.first;
  }

  void _onStateChange() {
    if (!mounted) return;
    setState(() {
      // Units arrive live from Firestore: pick one once they load.
      if (_selectedTeam.id.isEmpty) _selectedTeam = _pickDefaultTeam();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    _dispatchNotesController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<EmergencyTeam> get _filteredTeams {
    final sorted = _controller.sortedTeamsByEta;
    if (_selectedVehicleFilter == 'ALL') return sorted;
    if (_selectedVehicleFilter == 'BOATS') {
      return sorted
          .where((t) =>
              t.vehicleType.toLowerCase().contains('boat') ||
              t.vehicleType.toLowerCase().contains('watercraft'))
          .toList();
    }
    if (_selectedVehicleFilter == 'TRUCKS') {
      return sorted
          .where((t) =>
              t.vehicleType.toLowerCase().contains('truck') ||
              t.vehicleType.toLowerCase().contains('carrier'))
          .toList();
    }
    if (_selectedVehicleFilter == 'MEDICS') {
      return sorted
          .where((t) =>
              t.vehicleType.toLowerCase().contains('clinic') ||
              t.vehicleType.toLowerCase().contains('ambulance') ||
              t.name.toLowerCase().contains('red cross'))
          .toList();
    }
    return sorted;
  }

  void _openDispatchConfirmationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DispatchConfirmationModal(
        incident: widget.incident,
        team: _selectedTeam,
        priorityLevel: _priorityLevel,
        tacticalNotes: _dispatchNotesController.text,
        onConfirmed: () {
          Navigator.of(ctx).pop();
          _executeDispatch();
        },
      ),
    );
  }

  void _executeDispatch() {
    _controller.assignTeamToIncident(
      widget.incident,
      _selectedTeam,
      dispatchNotes: _dispatchNotesController.text,
      priority: _priorityLevel,
    );

    // Show tactical confirmation toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0B1220),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF34D399), width: 1.5),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF34D399),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('DISPATCH ORDER TRANSMITTED'),
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    tr('{p0} is EN ROUTE to Incident #{p1}', {'p0': (_selectedTeam.name).toString(), 'p1': (widget.incident.shortId).toString()}),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Navigate to Live Tracking Map
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResponsiveFrame(
          child: LiveTrackingScreen(incident: widget.incident),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Column(mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
                  ),
                  child: Text(
                    tr('CREATE'),
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(
                  tr('Assign Response Unit'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )),
              ],
            ),
            Text(
              tr('CRUD: Create • Emergency Dispatch & Unit Allocation'),
              style: TextStyle(color: Color(0xFFB6C2D6), fontSize: 11),
            ),
          ],
        )),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Target Incident Info Banner
                _buildIncidentDossierBanner(incident),

                const SizedBox(height: 18),

                // Filter Category Chips
                _buildVehicleFilterBar(),

                const SizedBox(height: 14),

                // Available Emergency Teams Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Row(mainAxisSize: MainAxisSize.min, 
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF34D399),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF34D399).withValues(alpha: _pulseAnimation.value),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: Text(
                          tr('TEAM RADIO LIST'),
                          style: TextStyle(
                            color: Color(0xFFB6C2D6),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        )),
                      ],
                    )),
                    Flexible(child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, 
                        children: [
                          Icon(Icons.sort_rounded,
                              size: 12, color: Color(0xFF38BDF8)),
                          SizedBox(width: 4),
                          Flexible(child: Text(
                            tr('SORTED BY ETA (FASTEST)'),
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          )),
                        ],
                      ),
                    )),
                  ],
                ),

                const SizedBox(height: 10),

                if (_filteredTeams.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        tr('No response units found.\nAdd units in Manage Units.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFB6C2D6)),
                      ),
                    ),
                  ),

                // Team Cards with staggered animation
                ...List.generate(_filteredTeams.length, (index) {
                  return _AnimatedTeamCard(
                    index: index,
                    child: _buildTeamCard(_filteredTeams[index]),
                  );
                }),

                const SizedBox(height: 16),

                // Priority Level
                Text(
                  tr('DISPATCH MISSION PRIORITY'),
                  style: TextStyle(
                    color: Color(0xFFB6C2D6),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131C2E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2B3A55)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _priorityLevel,
                      dropdownColor: const Color(0xFF1C2740),
                      isExpanded: true,
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8A98B0)),
                      items: [
                        DropdownMenuItem(
                          value: 'CODE RED (CRITICAL EVACUATION)',
                          child: Text(tr('🔴 CODE RED (CRITICAL EVACUATION)')),
                        ),
                        DropdownMenuItem(
                          value: 'CODE AMBER (HAZARD MITIGATION)',
                          child: Text(tr('🟠 CODE AMBER (HAZARD MITIGATION)')),
                        ),
                        DropdownMenuItem(
                          value: 'CODE YELLOW (AREA RECONNAISSANCE)',
                          child: Text(tr('🟡 CODE YELLOW (AREA RECONNAISSANCE)')),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(
                      tr('DISPATCHER TACTICAL NOTES'),
                      style: TextStyle(
                        color: Color(0xFFB6C2D6),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    )),
                    Flexible(child: Text(
                      tr('RADIO BRIEFING'),
                      style: TextStyle(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _dispatchNotesController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF131C2E),
                    hintText: tr('Enter mission briefing notes for squad...'),
                    hintStyle: const TextStyle(color: Color(0xFF475569)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2B3A55)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2B3A55)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Quick preset chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildQuickNoteChip('2x Zodiac Boats Required'),
                    _buildQuickNoteChip('Shallow Water Access Only'),
                    _buildQuickNoteChip('Bring Extra Stretchers'),
                    _buildQuickNoteChip('Evacuate to Sector 4 Camp'),
                  ],
                ),

                const SizedBox(height: 24),

                // Confirm Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTeam.isAvailable
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF2B3A55),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _selectedTeam.isAvailable ? 6 : 0,
                    shadowColor: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    tr('CONFIRM ASSIGNMENT & DISPATCH ({p0})', {'p0': (_selectedTeam.name).toString()}),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  onPressed: _selectedTeam.isAvailable
                      ? _openDispatchConfirmationSheet
                      : null,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNoteChip(String label) {
    final isAdded = _dispatchNotesController.text.contains(label);
    return InkWell(
      onTap: () {
        setState(() {
          if (!isAdded) {
            _dispatchNotesController.text =
                '${_dispatchNotesController.text.trim()} • $label';
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isAdded
              ? const Color(0xFF34D399).withValues(alpha: 0.15)
              : const Color(0xFF1C2740),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAdded
                ? const Color(0xFF34D399).withValues(alpha: 0.5)
                : const Color(0xFF2B3A55),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdded ? Icons.check : Icons.add,
              size: 12,
              color: isAdded ? const Color(0xFF34D399) : const Color(0xFFB6C2D6),
            ),
            const SizedBox(width: 4),
            Text(
              tr(label),
              style: TextStyle(
                color: isAdded ? const Color(0xFF34D399) : const Color(0xFFB6C2D6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentDossierBanner(IncidentReport incident) {
    Color severityColor;
    switch (incident.severity) {
      case IncidentSeverity.critical:
        severityColor = const Color(0xFFF87171);
        break;
      case IncidentSeverity.high:
        severityColor = const Color(0xFFFBBF24);
        break;
      case IncidentSeverity.medium:
        severityColor = const Color(0xFFFBBF24);
        break;
      case IncidentSeverity.low:
        severityColor = const Color(0xFF10B981);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF38BDF8).withValues(alpha: 0.06),
            const Color(0xFF131C2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_late_rounded,
                    color: Color(0xFF38BDF8), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('TARGET INCIDENT FOR FIELD DEPLOYMENT:'),
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Flexible(child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: severityColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  tr(incident.severityLabel),
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(incident.title),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(incident.location),
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.water, color: Color(0xFF38BDF8), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tr('Water Level: {p0}', {'p0': (incident.waterDepth).toString()}),
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11,
                    ),
                  ),
                ),
                const Icon(Icons.gps_fixed, color: Color(0xFF8A98B0), size: 13),
                const SizedBox(width: 4),
                Flexible(child: Text(
                  '${incident.coordinates.latitude.toStringAsFixed(3)}°, ${incident.coordinates.longitude.toStringAsFixed(3)}°',
                  style: const TextStyle(
                    color: Color(0xFFB6C2D6),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleFilterBar() {
    final filters = [
      {'key': 'ALL', 'label': 'All Units', 'icon': Icons.grid_view_rounded},
      {'key': 'BOATS', 'label': 'Rescue Boats', 'icon': Icons.directions_boat_rounded},
      {'key': 'TRUCKS', 'label': '4x4 Trucks', 'icon': Icons.local_shipping_rounded},
      {'key': 'MEDICS', 'label': 'EMT Medics', 'icon': Icons.medical_services_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedVehicleFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ChoiceChip(
                avatar: Icon(
                  f['icon'] as IconData,
                  size: 14,
                  color: isSelected ? Colors.white : const Color(0xFFB6C2D6),
                ),
                label: Text(f['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedVehicleFilter = f['key'] as String);
                  }
                },
                selectedColor: const Color(0xFF0284C7),
                backgroundColor: const Color(0xFF0B1220),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFB6C2D6),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF2B3A55),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamCard(EmergencyTeam team) {
    final isSelected = _selectedTeam.id == team.id;
    final isAvailable = team.isAvailable;

    IconData vehicleIcon;
    if (team.vehicleType.toLowerCase().contains('boat') ||
        team.vehicleType.toLowerCase().contains('watercraft')) {
      vehicleIcon = Icons.directions_boat_rounded;
    } else if (team.vehicleType.toLowerCase().contains('truck') ||
        team.vehicleType.toLowerCase().contains('carrier')) {
      vehicleIcon = Icons.local_shipping_rounded;
    } else if (team.vehicleType.toLowerCase().contains('ambulance') ||
        team.vehicleType.toLowerCase().contains('clinic')) {
      vehicleIcon = Icons.medical_services_rounded;
    } else {
      vehicleIcon = Icons.emergency_rounded;
    }

    return GestureDetector(
      onTap: isAvailable ? () => setState(() => _selectedTeam = team) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.08),
                    const Color(0xFF1C2740),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : isAvailable
                  ? const Color(0xFF131C2E)
                  : const Color(0xFF090D17),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : isAvailable
                    ? const Color(0xFF1C2740)
                    : const Color(0xFF1C2740).withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio indicator button with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(top: 2),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF38BDF8)
                          : isAvailable
                              ? const Color(0xFF8A98B0)
                              : const Color(0xFF2B3A55),
                      width: 2,
                    ),
                    color: isSelected
                        ? const Color(0xFF38BDF8)
                        : Colors.transparent,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check, size: 14, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr(team.name),
                              style: TextStyle(
                                color:
                                    isAvailable ? Colors.white : Colors.white38,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Flexible(child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              tr(team.callSign),
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tr('{p0} • Crew of {p1} • {p2}', {'p0': (team.leader).toString(), 'p1': (team.crewCount).toString(), 'p2': (team.radioChannel).toString()}),
                        style: TextStyle(
                          color: isAvailable
                              ? const Color(0xFFB6C2D6)
                              : Colors.white24,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Pill
                Flexible(child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? const Color(0xFF34D399).withValues(alpha: 0.15)
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isAvailable
                          ? const Color(0xFF34D399)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAvailable) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        tr(team.status),
                        style: TextStyle(
                          color: isAvailable
                              ? const Color(0xFF34D399)
                              : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
            const SizedBox(height: 10),
            // Equipment & Distance telemetry row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(vehicleIcon, color: const Color(0xFF38BDF8), size: 16),
                  const SizedBox(width: 6),
                  Flexible(child: Text(
                    tr('ETA: {p0}', {'p0': (team.eta).toString()}),
                    style: TextStyle(
                      color: isAvailable
                          ? const Color(0xFF34D399)
                          : Colors.white24,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  )),
                  Flexible(child: Text(
                    ' (${team.distance})',
                    style: TextStyle(
                      color: isAvailable ? Colors.white70 : Colors.white24,
                      fontSize: 11,
                    ),
                  )),
                  const Spacer(),
                  Icon(Icons.bolt,
                      color: isAvailable
                          ? const Color(0xFFFBBF24)
                          : Colors.white24,
                      size: 14),
                  Flexible(child: Text(
                    tr(' {p0} km/h', {'p0': (team.speedKmh.toInt()).toString()}),
                    style: TextStyle(
                      color: isAvailable
                          ? const Color(0xFFB6C2D6)
                          : Colors.white24,
                      fontSize: 10,
                    ),
                  )),
                  const SizedBox(width: 8),
                  // Fuel level bar
                  SizedBox(
                    width: 30,
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: team.fuelLevel / 100.0,
                        backgroundColor: const Color(0xFF1C2740),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          team.fuelLevel > 50
                              ? const Color(0xFF34D399)
                              : team.fuelLevel > 25
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFFF87171),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(child: Text(
                    '${team.fuelLevel}%',
                    style: TextStyle(
                      color: isAvailable
                          ? const Color(0xFFB6C2D6)
                          : Colors.white24,
                      fontSize: 10,
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                tr('Gear: {p0}', {'p0': (team.equipment).toString()}),
                style: TextStyle(
                  color: isAvailable ? const Color(0xFF8A98B0) : Colors.white24,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Staggered animation for team cards
class _AnimatedTeamCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedTeamCard({required this.index, required this.child});

  @override
  State<_AnimatedTeamCard> createState() => _AnimatedTeamCardState();
}

class _AnimatedTeamCardState extends State<_AnimatedTeamCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DISPATCH CONFIRMATION MODAL / SHEET
// ---------------------------------------------------------------------------
class _DispatchConfirmationModal extends StatefulWidget {
  final IncidentReport incident;
  final EmergencyTeam team;
  final String priorityLevel;
  final String tacticalNotes;
  final VoidCallback onConfirmed;

  const _DispatchConfirmationModal({
    required this.incident,
    required this.team,
    required this.priorityLevel,
    required this.tacticalNotes,
    required this.onConfirmed,
  });

  @override
  State<_DispatchConfirmationModal> createState() =>
      _DispatchConfirmationModalState();
}

class _DispatchConfirmationModalState
    extends State<_DispatchConfirmationModal> {
  bool _chkRadioSync = true;
  bool _chkGearInspected = true;
  bool _chkGpsLocked = true;
  bool _chkMedicalKit = true;
  bool _isTransmitting = false;

  void _transmitDispatchOrder() async {
    setState(() => _isTransmitting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      widget.onConfirmed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF38BDF8), width: 2),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Flexible(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF34D399)),
                ),
                child: Text(
                  tr('CONFIRM'),
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Dispatch Mission Confirmation'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Dossier Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1C2740)),
            ),
            child: Column(
              children: [
                _buildDossierRow(
                  'TARGET INCIDENT',
                  '#${widget.incident.shortId} • ${widget.incident.title}',
                  const Color(0xFF38BDF8),
                ),
                const Divider(color: Color(0xFF1C2740), height: 16),
                _buildDossierRow(
                  'ASSIGNED UNIT',
                  '${widget.team.name} (${widget.team.callSign})',
                  const Color(0xFF38BDF8),
                ),
                const Divider(color: Color(0xFF1C2740), height: 16),
                _buildDossierRow(
                  'SQUAD LEADER',
                  '${widget.team.leader} • Crew of ${widget.team.crewCount}',
                  Colors.white,
                ),
                const Divider(color: Color(0xFF1C2740), height: 16),
                _buildDossierRow(
                  'RADIO COMMS',
                  '${widget.team.radioChannel} • Signal 98%',
                  const Color(0xFF34D399),
                ),
                const Divider(color: Color(0xFF1C2740), height: 16),
                _buildDossierRow(
                  'ESTIMATED ARRIVAL',
                  'ETA: ${widget.team.eta} (${widget.team.distance})',
                  const Color(0xFFFBBF24),
                ),
                const Divider(color: Color(0xFF1C2740), height: 16),
                _buildDossierRow(
                  'PRIORITY ORDER',
                  widget.priorityLevel,
                  const Color(0xFFF87171),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Pre-Deployment Verification Protocol
          Text(
            tr('PRE-DEPLOYMENT PROTOCOL VERIFICATION:'),
            style: TextStyle(
              color: Color(0xFFB6C2D6),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildCheckItem('VHF Sync', Icons.radio, _chkRadioSync, (v) {
                  setState(() => _chkRadioSync = v ?? true);
                }),
              ),
              Expanded(
                child: _buildCheckItem('Gear Stowed', Icons.inventory_2, _chkGearInspected, (v) {
                  setState(() => _chkGearInspected = v ?? true);
                }),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildCheckItem('GPS Locked', Icons.gps_fixed, _chkGpsLocked, (v) {
                  setState(() => _chkGpsLocked = v ?? true);
                }),
              ),
              Expanded(
                child: _buildCheckItem('Medical Kit', Icons.medical_services, _chkMedicalKit, (v) {
                  setState(() => _chkMedicalKit = v ?? true);
                }),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34D399),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF34D399).withValues(alpha: 0.5),
            ),
            icon: _isTransmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.flash_on_rounded, size: 20),
            label: Text(
              _isTransmitting
                  ? tr('TRANSMITTING DISPATCH ORDER...')
                  : tr('CONFIRM & TRANSMIT DISPATCH ORDER'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            onPressed: _isTransmitting ? null : _transmitDispatchOrder,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(
      String label, IconData icon, bool value, ValueChanged<bool?> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF34D399),
              checkColor: Colors.black,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Icon(
              icon,
              size: 14,
              color: value ? const Color(0xFF34D399) : const Color(0xFF475569),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                tr(label),
                style: TextStyle(
                  color: value ? const Color(0xFFCBD5E1) : const Color(0xFF8A98B0),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDossierRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(
          tr(label),
          style: const TextStyle(
            color: Color(0xFF8A98B0),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        )),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tr(value),
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
