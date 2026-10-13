import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import 'resolve_analysis_screen.dart';
import '../../../../core/theme/appearance.dart';

class LiveTrackingScreen extends StatefulWidget {
  final IncidentReport incident;

  const LiveTrackingScreen({super.key, required this.incident});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  final ResponderController _controller = ResponderController();
  final MapController _mapController = MapController();

  late LatLng _incidentLocation;
  late LatLng _squadLocation;
  late List<LatLng> _routePoints;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _beaconController;
  late Animation<double> _beaconAnimation;

  Timer? _telemetryTimer;

  // Telemetry simulation
  double _speedKmh = 28.0;
  int _minutesLeft = 4;
  double _kmLeft = 1.1;
  double _routeProgress = 0.35;
  String _dispatchStatus = 'EN ROUTE'; // EN ROUTE or ON SCENE

  // Map layer style
  final int _mapStyleIndex = 0; // 0: Carto Dark/Tactical, 1: Standard OSM

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);

    _initCoordinates();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _beaconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _beaconAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _beaconController, curve: Curves.easeOut),
    );

    _startTelemetrySimulation();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _initCoordinates() {
    _incidentLocation = widget.incident.coordinates;
    if (widget.incident.assignedTeam != null) {
      _squadLocation = widget.incident.assignedTeam!.location;
      _dispatchStatus = widget.incident.assignedTeam!.status;
      if (_dispatchStatus != 'EN ROUTE' && _dispatchStatus != 'ON SCENE') {
        _dispatchStatus = 'EN ROUTE';
      }
    } else {
      _squadLocation = LatLng(
        _incidentLocation.latitude - 0.009,
        _incidentLocation.longitude - 0.008,
      );
      _dispatchStatus = 'EN ROUTE';
    }

    _routePoints = [
      _squadLocation,
      LatLng(_squadLocation.latitude + 0.003, _squadLocation.longitude + 0.002),
      LatLng(_squadLocation.latitude + 0.006, _squadLocation.longitude + 0.005),
      _incidentLocation,
    ];
  }

  void _startTelemetrySimulation() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_dispatchStatus == 'ON SCENE') return;

      setState(() {
        // Minor natural speed variance
        _speedKmh = 26.0 + (timer.tick % 5);
        if (_routeProgress < 0.92) {
          _routeProgress += 0.04;
          if (_kmLeft > 0.3) {
            _kmLeft = double.parse((_kmLeft - 0.1).toStringAsFixed(1));
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _telemetryTimer?.cancel();
    _mapController.dispose();
    _pulseController.dispose();
    _beaconController.dispose();
    super.dispose();
  }

  EmergencyTeam get _assignedTeam {
    return widget.incident.assignedTeam ??
        _controller.teams.firstWhere(
          (t) => t.id == 'TEAM-01',
          orElse: () => _controller.teams.first,
        );
  }

  // ---------------------------------------------------------------------------
  // UPDATE 1: TACTICAL COMMS / CONTACT TEAM
  // ---------------------------------------------------------------------------
  void _showTacticalCommsSheet() {
    final team = _assignedTeam;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TacticalCommsSheet(
        team: team,
        incident: widget.incident,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UPDATE 2: UPDATE DISPATCH MODAL (Status badge + Team Picker Again + Notes)
  // ---------------------------------------------------------------------------
  void _showUpdateDispatchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpdateDispatchSheet(
        incident: widget.incident,
        currentTeam: _assignedTeam,
        currentStatus: _dispatchStatus,
        availableTeams: _controller.sortedTeamsByEta,
        onStatusChanged: (newStatus) {
          setState(() {
            _dispatchStatus = newStatus;
            if (newStatus == 'ON SCENE') {
              _minutesLeft = 0;
              _kmLeft = 0.0;
              _speedKmh = 0.0;
              _routeProgress = 1.0;
            }
          });
          _controller.updateDispatchStatus(widget.incident, newStatus);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dispatch status changed to $newStatus!'),
              backgroundColor: const Color(0xFF00E676),
            ),
          );
        },
        onTeamReassigned: (newTeam, reason) {
          _controller.reassignTeam(
            incident: widget.incident,
            newTeam: newTeam,
            reason: reason,
          );
          setState(() {
            _initCoordinates();
            _minutesLeft = newTeam.etaMinutes;
            _kmLeft = 1.4;
            _routeProgress = 0.2;
            _dispatchStatus = 'EN ROUTE';
          });
          _mapController.move(_squadLocation, 14.5);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Team Reassigned! ${newTeam.name} (${newTeam.callSign}) is now EN ROUTE.'),
              backgroundColor: const Color(0xFF40C4FF),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE: CANCEL DISPATCH (Confirm dialog + reason select -> Team Available)
  // ---------------------------------------------------------------------------
  void _showCancelDispatchDialog() {
    String selectedReason = 'Squad busy / redirected to critical emergency';
    final customNotesController = TextEditingController();

    final cancellationReasons = [
      'Squad busy / redirected to critical emergency',
      'Road washed away / vehicle route impassable',
      'Wrong response unit assignment by operator',
      'Citizen reported situation cleared / false alarm',
      'Civilian rescued by local volunteers',
      'Other operational cancellation',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cancel_rounded,
                    color: Color(0xFFFF5252), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Cancel Active Dispatch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFF5252), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cancelling dispatch will recall ${_assignedTeam.name} and mark the squad AVAILABLE. Incident #${widget.incident.id} returns to PENDING TRIAGE.',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'SELECT CANCELLATION REASON:',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedReason,
                      dropdownColor: const Color(0xFF131B2B),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: cancellationReasons.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedReason = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'OPERATOR AUDIT REMARKS:',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: customNotesController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Enter optional operator notes...',
                    hintStyle: const TextStyle(color: Color(0xFF475569)),
                    filled: true,
                    fillColor: const Color(0xFF131B2B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('DISMISS',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final fullReason = customNotesController.text.trim().isNotEmpty
                    ? '$selectedReason (${customNotesController.text.trim()})'
                    : selectedReason;

                _controller.cancelDispatch(
                  incident: widget.incident,
                  cancellationReason: fullReason,
                );

                Navigator.of(ctx).pop(); // close dialog
                Navigator.of(context).pop(); // pop tracking screen

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF070B14),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFFF5252)),
                    ),
                    content: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFFFF5252), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Dispatch Cancelled. ${_assignedTeam.name} is now AVAILABLE on station grid.',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Text(
                'CONFIRM CANCELLATION',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = _assignedTeam;
    final isOnScene = _dispatchStatus == 'ON SCENE';

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF40C4FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF40C4FF), width: 0.8),
                  ),
                  child: const Text(
                    'M4-07',
                    style: TextStyle(
                      color: Color(0xFF40C4FF),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'Live Tracking Map',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${team.name} ➔ Incident #${widget.incident.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Dynamic Status Badge (EN ROUTE / ON SCENE)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isOnScene
                  ? const Color(0xFF40C4FF).withValues(alpha: 0.2)
                  : const Color(0xFF00E676).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isOnScene
                    ? const Color(0xFF40C4FF)
                    : const Color(0xFF00E676),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOnScene
                        ? const Color(0xFF40C4FF)
                        : const Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _dispatchStatus,
                  style: TextStyle(
                    color: isOnScene
                        ? const Color(0xFF40C4FF)
                        : const Color(0xFF00E676),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // FlutterMap
          Unfiltered(child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _squadLocation,
              initialZoom: 14.2,
              backgroundColor: const Color(0xFF070B14),
            ),
            children: [
              TileLayer(
                urlTemplate: _mapStyleIndex == 0
                    ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flood_disaster',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: const Color(0xFF40C4FF),
                    strokeWidth: 4.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // SQUAD VEHICLE MARKER (with animated beacon ring)
                  Marker(
                    point: _squadLocation,
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Beacon Ripple
                        ScaleTransition(
                          scale: _beaconAnimation,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            team.vehicleType.toLowerCase().contains('boat')
                                ? Icons.directions_boat_rounded
                                : Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // INCIDENT TARGET MARKER (with pulse hazard ring)
                  Marker(
                    point: _incidentLocation,
                    width: 64,
                    height: 64,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5252)
                                  .withValues(alpha: 0.6),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.crisis_alert_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),

          // Top Floating Tactical HUD Compass & Coords
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore_rounded,
                      color: Color(0xFF40C4FF), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'HDG: 042° NE • GPS: ${_squadLocation.latitude.toStringAsFixed(3)}°N, ${_squadLocation.longitude.toStringAsFixed(3)}°E',
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Control Floating Buttons (Right Side)
          Positioned(
            top: 12,
            right: 14,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'center_squad',
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFF40C4FF),
                  tooltip: 'Center on Response Squad',
                  onPressed: () => _mapController.move(_squadLocation, 14.5),
                  child: const Icon(Icons.navigation_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'center_incident',
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFFFF5252),
                  tooltip: 'Center on Incident',
                  onPressed: () => _mapController.move(_incidentLocation, 14.5),
                  child: const Icon(Icons.crisis_alert_rounded),
                ),
              ],
            ),
          ),

          // READ: "ETA 4 MINS" FLOATING HUD CARD
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Squad Header & ETA Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  team.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF40C4FF)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    team.callSign,
                                    style: const TextStyle(
                                      color: Color(0xFF40C4FF),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${team.leader} • Radio ${team.radioChannel}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // READ: "ETA 4 MINS" CARD
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B2B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isOnScene
                                ? const Color(0xFF40C4FF)
                                : const Color(0xFF00E676),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isOnScene ? 'ON SCENE' : 'ETA $_minutesLeft MINS',
                              style: TextStyle(
                                color: isOnScene
                                    ? const Color(0xFF40C4FF)
                                    : const Color(0xFF00E676),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              isOnScene
                                  ? 'Stationed'
                                  : '$_kmLeft km • ${_speedKmh.toInt()} km/h',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Route Progress Bar with water depth indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.water,
                              color: Color(0xFF40C4FF), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Water Level on Route: ${widget.incident.waterDepth}',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 10),
                          ),
                        ],
                      ),
                      Text(
                        '${(_routeProgress * 100).toInt()}% En Route',
                        style: const TextStyle(
                          color: Color(0xFF40C4FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _routeProgress,
                      backgroundColor: const Color(0xFF1E293B),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOnScene
                            ? const Color(0xFF40C4FF)
                            : const Color(0xFFFF6D00),
                      ),
                      minHeight: 6,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action Buttons Row: UPDATE DISPATCH + CONTACT TEAM
                  Row(
                    children: [
                      // UPDATE: Contact Team
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF40C4FF),
                            side: const BorderSide(color: Color(0xFF40C4FF)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.radio_rounded, size: 16),
                          label: const Text(
                            'CONTACT TEAM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          onPressed: _showTacticalCommsSheet,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // UPDATE: Update Dispatch (Status, Reassign Team)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6D00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: const Text(
                            'UPDATE DISPATCH',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          onPressed: _showUpdateDispatchSheet,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // DELETE: CANCEL DISPATCH BUTTON
                  InkWell(
                    onTap: _showCancelDispatchDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined,
                              color: const Color(0xFFFF5252)
                                  .withValues(alpha: 0.8),
                              size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'CANCEL DISPATCH (STAND DOWN / REASSIGN)',
                            style: TextStyle(
                              color: const Color(0xFFFF5252)
                                  .withValues(alpha: 0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TACTICAL COMMS SHEET (Push to Talk, VHF Radio, Phone Call)
// ---------------------------------------------------------------------------
class _TacticalCommsSheet extends StatefulWidget {
  final EmergencyTeam team;
  final IncidentReport incident;

  const _TacticalCommsSheet({required this.team, required this.incident});

  @override
  State<_TacticalCommsSheet> createState() => _TacticalCommsSheetState();
}

class _TacticalCommsSheetState extends State<_TacticalCommsSheet>
    with SingleTickerProviderStateMixin {
  bool _isTalking = false;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131B2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF40C4FF), width: 2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.radio_rounded, color: Color(0xFF40C4FF), size: 24),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Radio Comms: ${widget.team.radioChannel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.team.name} • Lead: ${widget.team.leader}',
                    style:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ENC-98%',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Animated Audio Visualizer Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF070B14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isTalking
                    ? const Color(0xFF00E676)
                    : const Color(0xFF1E293B),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(16, (i) {
                    final height = _isTalking
                        ? (12 + (i % 5) * 6).toDouble()
                        : (4 + (i % 2) * 3).toDouble();
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 4,
                      height: height,
                      decoration: BoxDecoration(
                        color: _isTalking
                            ? const Color(0xFF00E676)
                            : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  _isTalking
                    ? 'TRANSMITTING VOICE AUDIO (PTT ACTIVE)...'
                    : 'CHANNEL STANDBY • HOLD BUTTON TO TALK',
                  style: TextStyle(
                    color: _isTalking
                        ? const Color(0xFF00E676)
                        : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // PUSH TO TALK BUTTON
          GestureDetector(
            onTapDown: (_) => setState(() => _isTalking = true),
            onTapUp: (_) => setState(() => _isTalking = false),
            onTapCancel: () => setState(() => _isTalking = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _isTalking
                    ? const Color(0xFF00E676)
                    : const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _isTalking
                        ? const Color(0xFF00E676).withValues(alpha: 0.4)
                        : const Color(0xFF0284C7).withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isTalking ? Icons.mic : Icons.mic_none,
                    color: _isTalking ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isTalking ? 'RELEASE TO END TRANSMISSION' : 'PUSH TO TALK (PTT)',
                    style: TextStyle(
                      color: _isTalking ? Colors.black : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Direct Phone Call Option
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF40C4FF),
              side: const BorderSide(color: Color(0xFF40C4FF)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.phone_rounded, size: 16),
            label: Text(
              'CALL COMMANDER PHONE (${widget.team.phoneNumber})',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Dialing ${widget.team.leader} at ${widget.team.phoneNumber}...'),
                  backgroundColor: const Color(0xFF0284C7),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// UPDATE DISPATCH SHEET (Update Status, Team Picker Again, Notes)
// ---------------------------------------------------------------------------
class _UpdateDispatchSheet extends StatefulWidget {
  final IncidentReport incident;
  final EmergencyTeam currentTeam;
  final String currentStatus;
  final List<EmergencyTeam> availableTeams;
  final ValueChanged<String> onStatusChanged;
  final void Function(EmergencyTeam newTeam, String reason) onTeamReassigned;

  const _UpdateDispatchSheet({
    required this.incident,
    required this.currentTeam,
    required this.currentStatus,
    required this.availableTeams,
    required this.onStatusChanged,
    required this.onTeamReassigned,
  });

  @override
  State<_UpdateDispatchSheet> createState() => _UpdateDispatchSheetState();
}

class _UpdateDispatchSheetState extends State<_UpdateDispatchSheet> {
  int _activeTab = 0; // 0: Status & Notes, 1: Team Picker Again (Reassign)
  late String _selectedStatus;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _notesController = TextEditingController(
      text: widget.incident.dispatchNotes ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showReassignConfirmDialog(EmergencyTeam newTeam) {
    String reassignReason = 'Heavy flood water requires boat unit';
    final reasons = [
      'Heavy flood water requires boat unit',
      'Squad vehicle unable to cross bridge',
      'Original squad delayed by secondary rescue',
      'Closer emergency unit became available',
      'Tactical command adjustment',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: Color(0xFFFF6D00), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirm Team Reassignment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reassign from ${widget.currentTeam.name} to ${newTeam.name}?',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.currentTeam.name} will be marked AVAILABLE again.',
                style: const TextStyle(color: Color(0xFF00E676), fontSize: 11),
              ),
              const SizedBox(height: 12),
              const Text(
                'REASSIGNMENT REASON:',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: reassignReason,
                    dropdownColor: const Color(0xFF131B2B),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    items: reasons.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setDlgState(() => reassignReason = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // close update sheet
                widget.onTeamReassigned(newTeam, reassignReason);
              },
              child: const Text('REASSIGN SQUAD'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131B2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFFF6D00), width: 2)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UPDATE DISPATCH MISSION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          // Sub tabs: 1. Status & Notes, 2. Team Picker Again
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeTab == 0
                              ? const Color(0xFFFF6D00)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'STATUS & NOTES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _activeTab == 0
                            ? const Color(0xFFFF6D00)
                            : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeTab == 1
                              ? const Color(0xFFFF6D00)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'TEAM PICKER AGAIN (REASSIGN)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _activeTab == 1
                            ? const Color(0xFFFF6D00)
                            : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (_activeTab == 0) ...[
            // Status Badge Selection
            const Text(
              'UPDATE MISSION STAGE (STATUS BADGE):',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatusChoiceButton(
                    'EN ROUTE',
                    Icons.directions_boat_rounded,
                    _selectedStatus == 'EN ROUTE',
                    const Color(0xFF00E676),
                    () => setState(() => _selectedStatus = 'EN ROUTE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatusChoiceButton(
                    'ON SCENE',
                    Icons.pin_drop_rounded,
                    _selectedStatus == 'ON SCENE',
                    const Color(0xFF40C4FF),
                    () => setState(() => _selectedStatus = 'ON SCENE'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Tactical Notes
            const Text(
              'UPDATE TACTICAL DISPATCH NOTES:',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF131B2B),
                hintText: 'Enter mission briefing updates...',
                hintStyle: const TextStyle(color: Color(0xFF475569)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Save Status & Notes Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                widget.incident.dispatchNotes = _notesController.text.trim();
                widget.onStatusChanged(_selectedStatus);
                Navigator.of(context).pop();
              },
              child: const Text('SAVE DISPATCH UPDATES',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 8),

            // Resolve incident shortcut
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E676),
                side: const BorderSide(color: Color(0xFF00E676)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('CLOSE & PROCEED TO RESOLVE INCIDENT (M4-08)'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ResolveAnalysisScreen(incident: widget.incident),
                  ),
                );
              },
            ),
          ] else ...[
            // Tab 1: TEAM PICKER AGAIN
            const Text(
              'SELECT A DIFFERENT AVAILABLE RESPONSE TEAM:',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: (MediaQuery.sizeOf(context).height * 0.32)
                  .clamp(140.0, 240.0)
                  .toDouble(),
              child: ListView(
                children: widget.availableTeams
                    .where((t) => t.id != widget.currentTeam.id)
                    .map((team) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: team.isAvailable
                            ? const Color(0xFF334155)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          team.vehicleType.toLowerCase().contains('boat')
                              ? Icons.directions_boat
                              : Icons.local_shipping,
                          color: team.isAvailable
                              ? const Color(0xFF40C4FF)
                              : Colors.white24,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: TextStyle(
                                  color: team.isAvailable
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'ETA: ${team.eta} • ${team.vehicleType}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: team.isAvailable
                                ? const Color(0xFFFF6D00)
                                : Colors.white12,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 10),
                          ),
                          onPressed: team.isAvailable
                              ? () => _showReassignConfirmDialog(team)
                              : null,
                          child: const Text('REASSIGN'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChoiceButton(
    String label,
    IconData icon,
    bool isSelected,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.2)
              : const Color(0xFF131B2B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF334155),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? activeColor : const Color(0xFF64748B),
                size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}