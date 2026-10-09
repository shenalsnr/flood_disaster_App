import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/responder_models.dart';
import '../controllers/responder_controller.dart';
import 'resolve_analysis_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  final IncidentReport incident;

  const LiveTrackingScreen({super.key, required this.incident});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  final ResponderController _controller = ResponderController();
  final MapController _mapController = MapController();

  late LatLng _incidentLocation;
  late LatLng _squadLocation;
  late List<LatLng> _routePoints;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Telemetry simulation
  double _speedKmh = 24.0;
  int _minutesLeft = 4;
  double _kmLeft = 1.1;

  @override
  void initState() {
    super.initState();
    _incidentLocation = widget.incident.coordinates;

    // Use assigned team location or default squad location nearby
    if (widget.incident.assignedTeam != null) {
      _squadLocation = widget.incident.assignedTeam!.location;
    } else {
      _squadLocation = LatLng(
        _incidentLocation.latitude - 0.009,
        _incidentLocation.longitude - 0.008,
      );
    }

    _routePoints = [
      _squadLocation,
      LatLng(_squadLocation.latitude + 0.003, _squadLocation.longitude + 0.002),
      LatLng(_squadLocation.latitude + 0.006, _squadLocation.longitude + 0.005),
      _incidentLocation,
    ];

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showRadioCallDialog() {
    final teamName =
        widget.incident.assignedTeam?.name ?? 'Colombo Rescue Squad A';
    final leader =
        widget.incident.assignedTeam?.leader ?? 'Capt. Kasun Fernando';
    final channel =
        widget.incident.assignedTeam?.radioChannel ?? 'VHF CH-04';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.radio, color: Color(0xFF38BDF8), size: 26),
            const SizedBox(width: 10),
            Text('Radio Comms: $channel',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connecting Dispatch Station to $teamName ($leader)...',
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mic, color: Color(0xFF00E676), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Radio Channel Active: Signal 98% (Secure Encryption)',
                      style: TextStyle(color: Color(0xFF00E676), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('END TRANSMISSION',
                style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Audio Dispatch Broadcast transmitted to Squad VHF receiver.'),
                  backgroundColor: Color(0xFF0284C7),
                ),
              );
            },
            child: const Text('PUSH TO TALK'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDispatchStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'UPDATE MISSION STAGE',
          style: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () {
              _controller.updateIncidentStatus(
                  widget.incident, IncidentStatus.onScene);
              setState(() {
                _minutesLeft = 0;
                _kmLeft = 0.0;
                _speedKmh = 0.0;
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Status updated: Squad is ON SCENE!'),
                  backgroundColor: Color(0xFF00E676),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.pin_drop, color: Color(0xFF00E676), size: 20),
                SizedBox(width: 10),
                Text('Mark as ARRIVED ON SCENE',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ResolveAnalysisScreen(incident: widget.incident),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: Color(0xFFFF6D00), size: 20),
                SizedBox(width: 10),
                Text('Proceed to CLOSE & RESOLVE INCIDENT',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamName =
        widget.incident.assignedTeam?.name ?? 'Colombo Rescue Squad A';

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Dispatch Tracking',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              '$teamName ➔ Incident #${widget.incident.id}',
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00E676)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'EN ROUTE',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _squadLocation,
              initialZoom: 14.2,
              backgroundColor: const Color(0xFF070B14),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flood_disaster',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: const Color(0xFF38BDF8),
                    strokeWidth: 4.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Squad Vehicle Marker
                  Marker(
                    point: _squadLocation,
                    width: 52,
                    height: 52,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.directions_boat,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),

                  // Incident Marker with pulse animation
                  Marker(
                    point: _incidentLocation,
                    width: 60,
                    height: 60,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.flood,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Map Control Floating Buttons
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'center_squad',
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFF38BDF8),
                  onPressed: () => _mapController.move(_squadLocation, 14.5),
                  child: const Icon(Icons.navigation),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'center_incident',
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFFEF4444),
                  onPressed: () => _mapController.move(_incidentLocation, 14.5),
                  child: const Icon(Icons.crisis_alert),
                ),
              ],
            ),
          ),

          // Bottom Telemetry Panel (Wireframe 5)
          Positioned(
            left: 14,
            right: 14,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teamName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ETA to Scene: $_minutesLeft Mins ($_kmLeft km left)',
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_speedKmh.toInt()} km/h\nHEADING: NE',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Progress line
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.72,
                      backgroundColor: Color(0xFF1E293B),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF6D00)),
                      minHeight: 6,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF38BDF8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.phone_in_talk, size: 16),
                          label: const Text('CONTACT TEAM',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: _showRadioCallDialog,
                        ),
                      ),
                      const SizedBox(width: 10),
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
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('UPDATE DISPATCH',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: _showUpdateDispatchStatusDialog,
                        ),
                      ),
                    ],
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
