import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/responder_models.dart';

class ResponderController extends ChangeNotifier {
  static final ResponderController _instance = ResponderController._internal();
  factory ResponderController() => _instance;

  ResponderController._internal() {
    _initMockData();
  }

  // Active Logged-in User
  UserProfile? _currentUser = const UserProfile(
    uid: 'n.perera@dispatched.gov.lk',
    fullName: 'Nadeeka Perera',
    email: 'n.perera@dispatched.gov.lk',
    phoneNumber: '+94 77 482 1029',
    nic: '982341092V',
    floodZone: 'Colombo Sector 4 (Low-Lying Area)',
    role: 'responder',
  );

  UserProfile? get currentUser => _currentUser;

  void setCurrentUser(UserProfile user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateCurrentUserPhoto(String photoUrl) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(photoUrl: photoUrl);
      notifyListeners();
    }
  }

  // Active filter for triage list
  String _selectedSeverityFilter = 'ALL';
  String get selectedSeverityFilter => _selectedSeverityFilter;

  // Selected Incident for details/actions
  IncidentReport? _activeIncident;
  IncidentReport? get activeIncident => _activeIncident;

  // Duty status
  bool _isOnDuty = true;
  bool get isOnDuty => _isOnDuty;

  void toggleDutyStatus(bool value) {
    _isOnDuty = value;
    notifyListeners();
  }

  // List of incidents
  final List<IncidentReport> _incidents = [];
  List<IncidentReport> get incidents => List.unmodifiable(_incidents);

  // Available Teams (Mutable list so status updates dynamically)
  final List<EmergencyTeam> _teams = [
    const EmergencyTeam(
      id: 'TEAM-01',
      name: 'Colombo Rescue Squad A',
      status: 'AVAILABLE',
      distance: '1.2 km Away',
      eta: '4 Mins',
      etaMinutes: 4,
      equipment: '2x Zodiac Inflatable Boats & Water Rescue Gear',
      crewCount: 4,
      leader: 'Capt. Kasun Fernando',
      radioChannel: 'VHF CH-04',
      location: LatLng(6.9200, 79.8550),
      speedKmh: 28.0,
      vehicleType: 'Zodiac Rescue Boat',
      callSign: 'ALPHA-01',
      phoneNumber: '+94 77 482 1029',
      fuelLevel: 96,
    ),
    const EmergencyTeam(
      id: 'TEAM-02',
      name: 'Disaster Response Unit 02',
      status: 'AVAILABLE',
      distance: '3.5 km Away',
      eta: '9 Mins',
      etaMinutes: 9,
      equipment: '4x4 High-Clearance Troop Carrier & Chainsaws',
      crewCount: 6,
      leader: 'Lieut. M. Perera',
      radioChannel: 'VHF CH-06',
      location: LatLng(6.9350, 79.8700),
      speedKmh: 32.0,
      vehicleType: '4x4 Troop Carrier Truck',
      callSign: 'BRAVO-02',
      phoneNumber: '+94 71 892 3344',
      fuelLevel: 88,
    ),
    const EmergencyTeam(
      id: 'TEAM-03',
      name: 'Red Cross Auxiliary EMT Group',
      status: 'AVAILABLE',
      distance: '4.8 km Away',
      eta: '12 Mins',
      etaMinutes: 12,
      equipment: 'Mobile Clinic, Stretcher Kit & 4 Medics',
      crewCount: 4,
      leader: 'Dr. S. Alwis (EMT Lead)',
      radioChannel: 'VHF CH-09',
      location: LatLng(6.9100, 79.8650),
      speedKmh: 30.0,
      vehicleType: 'Ambulance EMT Clinic',
      callSign: 'MEDIC-03',
      phoneNumber: '+94 76 345 6789',
      fuelLevel: 92,
    ),
    const EmergencyTeam(
      id: 'TEAM-04',
      name: 'Kelani Basin Water Patrol',
      status: 'AVAILABLE',
      distance: '6.1 km Away',
      eta: '16 Mins',
      etaMinutes: 16,
      equipment: 'Rigid Hull Inflatable & Sonar Depth Finder',
      crewCount: 5,
      leader: 'Chief Diver Samantha',
      radioChannel: 'VHF CH-07',
      location: LatLng(6.9450, 79.8820),
      speedKmh: 26.0,
      vehicleType: 'Rigid Hull Watercraft',
      callSign: 'DELTA-04',
      phoneNumber: '+94 70 987 6543',
      fuelLevel: 85,
    ),
    const EmergencyTeam(
      id: 'TEAM-05',
      name: 'Colombo Fire Service Unit B',
      status: 'ON MISSION',
      distance: '0.8 km Away',
      eta: 'In Mission',
      etaMinutes: 99,
      equipment: 'High-Volume Drainage Pump Truck',
      crewCount: 5,
      leader: 'Station Officer Wickrama',
      radioChannel: 'VHF CH-02',
      location: LatLng(6.9290, 79.8580),
      speedKmh: 0.0,
      vehicleType: 'Heavy Drainage Pump Truck',
      callSign: 'SIERRA-05',
      phoneNumber: '+94 11 242 2222',
      fuelLevel: 74,
    ),
  ];

  List<EmergencyTeam> get teams => List.unmodifiable(_teams);

  // Teams sorted by ETA (Available first, then ascending etaMinutes)
  List<EmergencyTeam> get sortedTeamsByEta {
    final list = List<EmergencyTeam>.from(_teams);
    list.sort((a, b) {
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      return a.etaMinutes.compareTo(b.etaMinutes);
    });
    return list;
  }

  void setFilter(String filter) {
    _selectedSeverityFilter = filter;
    notifyListeners();
  }

  void setActiveIncident(IncidentReport incident) {
    _activeIncident = incident;
    notifyListeners();
  }

  List<IncidentReport> get filteredIncidents {
    if (_selectedSeverityFilter == 'ALL') {
      return _incidents;
    }
    return _incidents.where((i) {
      if (_selectedSeverityFilter == 'CRITICAL') {
        return i.severity == IncidentSeverity.critical;
      }
      if (_selectedSeverityFilter == 'HIGH') {
        return i.severity == IncidentSeverity.high;
      }
      if (_selectedSeverityFilter == 'MED') {
        return i.severity == IncidentSeverity.medium;
      }
      if (_selectedSeverityFilter == 'LOW') {
        return i.severity == IncidentSeverity.low;
      }
      return true;
    }).toList();
  }

  int countFor(String filter) {
    if (filter == 'ALL') return _incidents.length;
    if (filter == 'CRITICAL') {
      return _incidents
          .where((i) => i.severity == IncidentSeverity.critical)
          .length;
    }
    if (filter == 'HIGH') {
      return _incidents
          .where((i) => i.severity == IncidentSeverity.high)
          .length;
    }
    if (filter == 'MED') {
      return _incidents
          .where((i) => i.severity == IncidentSeverity.medium)
          .length;
    }
    if (filter == 'LOW') {
      return _incidents
          .where((i) => i.severity == IncidentSeverity.low)
          .length;
    }
    return 0;
  }

  // --- CRUD 2: DISPATCH OPERATIONS ---

  // CREATE: Assign squad to incident
  void assignTeamToIncident(
    IncidentReport incident,
    EmergencyTeam team, {
    String? dispatchNotes,
    String? priority,
  }) {
    final teamIndex = _teams.indexWhere((t) => t.id == team.id);
    final updatedTeam = team.copyWith(status: 'EN ROUTE');
    if (teamIndex != -1) {
      _teams[teamIndex] = updatedTeam;
    }

    incident.assignedTeam = updatedTeam;
    incident.status = IncidentStatus.dispatched;
    if (dispatchNotes != null) incident.dispatchNotes = dispatchNotes;
    if (priority != null) incident.priorityLevel = priority;
    incident.dispatchedAt = DateTime.now();

    _activeIncident = incident;
    notifyListeners();
  }

  // UPDATE: Reassign incident to a different team
  void reassignTeam({
    required IncidentReport incident,
    required EmergencyTeam newTeam,
    required String reason,
  }) {
    // 1. Release previously assigned team back to AVAILABLE
    if (incident.assignedTeam != null) {
      final oldIndex =
          _teams.indexWhere((t) => t.id == incident.assignedTeam!.id);
      if (oldIndex != -1) {
        _teams[oldIndex] = _teams[oldIndex].copyWith(status: 'AVAILABLE');
      }
    }

    // 2. Mark newly selected team as EN ROUTE
    final newIndex = _teams.indexWhere((t) => t.id == newTeam.id);
    final assignedNewTeam = newTeam.copyWith(status: 'EN ROUTE');
    if (newIndex != -1) {
      _teams[newIndex] = assignedNewTeam;
    }

    // 3. Update incident record
    incident.assignedTeam = assignedNewTeam;
    incident.status = IncidentStatus.dispatched;
    incident.dispatchNotes =
        '${incident.dispatchNotes ?? ""}\n[REASSIGNED]: $reason (Now: ${newTeam.name})'
            .trim();

    _activeIncident = incident;
    notifyListeners();
  }

  // UPDATE: Change dispatch status (EN ROUTE <-> ON SCENE)
  void updateDispatchStatus(IncidentReport incident, String newStatus) {
    if (incident.assignedTeam != null) {
      final updatedTeam =
          incident.assignedTeam!.copyWith(status: newStatus.toUpperCase());
      incident.assignedTeam = updatedTeam;

      final index = _teams.indexWhere((t) => t.id == updatedTeam.id);
      if (index != -1) {
        _teams[index] = updatedTeam;
      }
    }

    if (newStatus.toUpperCase() == 'ON SCENE') {
      incident.status = IncidentStatus.onScene;
    } else if (newStatus.toUpperCase() == 'EN ROUTE') {
      incident.status = IncidentStatus.dispatched;
    }

    notifyListeners();
  }

  // UPDATE: Change mission notes or priority
  void updateDispatchDetails({
    required IncidentReport incident,
    String? notes,
    String? priority,
  }) {
    if (notes != null) incident.dispatchNotes = notes;
    if (priority != null) incident.priorityLevel = priority;
    notifyListeners();
  }

  // DELETE: Cancel active dispatch (team busy, wrong assignment, stand down)
  void cancelDispatch({
    required IncidentReport incident,
    required String cancellationReason,
  }) {
    // 1. Set assigned team back to AVAILABLE
    if (incident.assignedTeam != null) {
      final teamIndex =
          _teams.indexWhere((t) => t.id == incident.assignedTeam!.id);
      if (teamIndex != -1) {
        _teams[teamIndex] = _teams[teamIndex].copyWith(status: 'AVAILABLE');
      }
    }

    // 2. Revert incident status back to incoming / pending triage
    incident.assignedTeam = null;
    incident.status = IncidentStatus.incoming;
    incident.cancellationReason = cancellationReason;

    notifyListeners();
  }

  void updateIncidentStatus(IncidentReport incident, IncidentStatus status) {
    incident.status = status;
    notifyListeners();
  }

  void resolveIncident({
    required IncidentReport incident,
    required String resolutionType,
    required String notes,
    required int evacuatedCount,
  }) {
    // Free team if assigned
    if (incident.assignedTeam != null) {
      final teamIndex =
          _teams.indexWhere((t) => t.id == incident.assignedTeam!.id);
      if (teamIndex != -1) {
        _teams[teamIndex] = _teams[teamIndex].copyWith(status: 'AVAILABLE');
      }
    }

    incident.status = IncidentStatus.resolved;
    incident.resolutionType = resolutionType;
    incident.resolutionNotes = notes;
    incident.evacuatedCount = evacuatedCount;
    notifyListeners();
  }

  void broadcastZoneAlert({
    required String zone,
    required String title,
    required String message,
  }) {
    // Adds a newly spawned critical broadcast report
    _incidents.insert(
      0,
      IncidentReport(
        id: 'BRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        title: 'BROADCAST: $title',
        hazardType: 'Zone Evacuation',
        severity: IncidentSeverity.critical,
        location: zone,
        coordinates: const LatLng(6.9271, 79.8612),
        waterDepth: 'N/A (Evacuation Order)',
        description: message,
        corroboratingCount: 1,
        reporterName: 'Dispatcher Station #04 (DMC Official)',
        reporterPhone: '117 (DMC)',
        isVerified: true,
        timeAgo: 'Just Now',
        status: IncidentStatus.dispatched,
      ),
    );
    notifyListeners();
  }

  void _initMockData() {
    _incidents.clear();
    _incidents.addAll([
      IncidentReport(
        id: 'FLD-2026-089',
        title: 'Severe Flash Flood (Level 4)',
        hazardType: 'Flood',
        severity: IncidentSeverity.critical,
        location: 'Colombo Sector 4 (Low-Lying Area - Temple Rd)',
        coordinates: const LatLng(6.9271, 79.8612),
        waterDepth: '1.5m Rising Fast (Submerged Roads)',
        description:
            'Water level has risen above 1.5 meters on the main residential street. Two cars are partially submerged. Citizens are retreating to second-story houses. Rain continues heavily.',
        corroboratingCount: 5,
        reporterName: 'D. S. Silva (Verified Citizen)',
        reporterPhone: '+94 77 482 1029',
        isVerified: true,
        timeAgo: '1 Min Ago',
        status: IncidentStatus.incoming,
      ),
      IncidentReport(
        id: 'LND-2026-042',
        title: 'Landslide Blockage & Debris',
        hazardType: 'Landslide',
        severity: IncidentSeverity.critical,
        location: 'Kandy Road — Km Marker 42 (Hill Cut)',
        coordinates: const LatLng(6.9400, 79.8800),
        waterDepth: 'Mud & Rockfall (Road Inaccessible)',
        description:
            'Heavy mudflow blocked both lanes. Two commercial trucks stranded. Risk of further earth slip from upper terrace.',
        corroboratingCount: 4,
        reporterName: 'Police Patrol Unit 3',
        reporterPhone: '+94 11 243 3333',
        isVerified: true,
        timeAgo: '5 Mins Ago',
        status: IncidentStatus.incoming,
      ),
      IncidentReport(
        id: 'FLD-2026-077',
        title: 'Canal Overflow & Sluice Gate Jam',
        hazardType: 'Flood',
        severity: IncidentSeverity.critical,
        location: 'Kelani Basin — Sector 2 Bund',
        coordinates: const LatLng(6.9520, 79.8900),
        waterDepth: '2.1m (Warning Level Exceeded)',
        description:
            'Canal embankment overflowing into surrounding residential settlements. Immediate sandbagging or evacuation required.',
        corroboratingCount: 8,
        reporterName: 'Irrigation Dept Inspector',
        reporterPhone: '+94 71 229 9840',
        isVerified: true,
        timeAgo: '8 Mins Ago',
        status: IncidentStatus.incoming,
      ),
      IncidentReport(
        id: 'TRE-2026-031',
        title: 'Large Tree Fall on Main Road',
        hazardType: 'Blockage',
        severity: IncidentSeverity.high,
        location: 'Colombo Sector 2 (Outer Ring)',
        coordinates: const LatLng(6.9150, 79.8690),
        waterDepth: '0.3m Localized Puddle',
        description:
            'Large banyan tree fallen across power lines and road. Electricity severed for sector 2.',
        corroboratingCount: 3,
        reporterName: 'Sunil Wickramasinghe (Volunteer)',
        reporterPhone: '+94 70 331 4455',
        isVerified: true,
        timeAgo: '12 Mins Ago',
        status: IncidentStatus.incoming,
      ),
      IncidentReport(
        id: 'BRG-2026-019',
        title: 'Suspension Bridge Foundation Weakened',
        hazardType: 'Structure',
        severity: IncidentSeverity.high,
        location: 'Ganga Addara Footbridge',
        coordinates: const LatLng(6.9310, 79.8640),
        waterDepth: 'Turbulent River Current',
        description:
            'High water current eroding the western concrete foundation. Pedestrian crossing should be cordoned off immediately.',
        corroboratingCount: 2,
        reporterName: 'Grama Niladhari Officer',
        reporterPhone: '+94 77 901 2345',
        isVerified: true,
        timeAgo: '18 Mins Ago',
        status: IncidentStatus.incoming,
      ),
      IncidentReport(
        id: 'DRN-2026-014',
        title: 'Minor Drain Overflow on Lane B',
        hazardType: 'Drainage',
        severity: IncidentSeverity.low,
        location: 'Sector 1 Residential Lane B',
        coordinates: const LatLng(6.9050, 79.8580),
        waterDepth: '0.2m (Ankle Depth)',
        description:
            'Storm drain backed up due to leaf debris. Water flowing on sidewalk but residences are dry.',
        corroboratingCount: 1,
        reporterName: 'K. Perera (Citizen)',
        reporterPhone: '+94 76 555 4321',
        isVerified: false,
        timeAgo: '25 Mins Ago',
        status: IncidentStatus.incoming,
      ),
    ]);

    _activeIncident = _incidents.first;
  }
}
