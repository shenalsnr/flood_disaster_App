import 'package:flood_disaster/core/services/offline_sync.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/responder_models.dart';

/// Component 4 controller.
///
/// Public API is unchanged for the screens, but everything is now backed by
/// Firestore instead of mock data:
///
///  * `hazard_reports`  (written by Component 2)  -> incident queue (READ)
///        + dispatch fields written back by the dispatcher (UPDATE):
///          dispatchStatus, assignedUnitId, assignedUnitName, dispatchNotes,
///          priorityLevel, dispatchedAt, cancellationReason, resolutionType,
///          resolutionNotes, evacuatedCount, resolvedAt, archived
///        Component 2's own `status` field is never touched.
///  * `responseUnits`   -> rescue units (full CRUD)
///  * `warnings`        -> zone broadcasts to citizens (full CRUD)
class ResponderController extends ChangeNotifier {
  static final ResponderController _instance = ResponderController._internal();
  factory ResponderController() => _instance;
  ResponderController._internal();

  // ---------------------------------------------------------------------------
  // Logged-in user
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  String _selectedSeverityFilter = 'ALL';
  String get selectedSeverityFilter => _selectedSeverityFilter;

  IncidentReport? _activeIncident;
  IncidentReport? get activeIncident => _activeIncident;

  bool _isOnDuty = true;
  bool get isOnDuty => _isOnDuty;

  void toggleDutyStatus(bool value) {
    _isOnDuty = value;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedSeverityFilter = filter;
    notifyListeners();
  }

  void setActiveIncident(IncidentReport incident) {
    _activeIncident = incident;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Firestore wiring (lazy: starts the first time data is requested)
  // ---------------------------------------------------------------------------
  bool _started = false;
  bool _liveOk = false;
  String? _syncError;
  bool get isLive => _liveOk;
  String? get syncError => _syncError;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _repSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _unitSub;

  CollectionReference<Map<String, dynamic>> get _reports =>
      FirebaseFirestore.instance.collection('hazard_reports');
  CollectionReference<Map<String, dynamic>> get _units =>
      FirebaseFirestore.instance.collection('responseUnits');
  CollectionReference<Map<String, dynamic>> get _warnings =>
      FirebaseFirestore.instance.collection('warnings');

  void _ensureStarted() {
    if (_started) return;
    _started = true;
    try {
      _unitSub = _units.snapshots().listen(_onUnits, onError: _onErr);
      _repSub = _reports.snapshots().listen(_onReports, onError: _onErr);
    } catch (e) {
      _onErr(e);
    }
  }

  /// Call after sign-out so the next login starts fresh streams.
  Future<void> stopSync() async {
    await _repSub?.cancel();
    await _unitSub?.cancel();
    _repSub = null;
    _unitSub = null;
    _started = false;
    _liveOk = false;
  }

  void _onErr(Object e) {
    _syncError = e.toString();
    _liveOk = false;
    debugPrint('[ResponderController] Firestore error: $e');
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Incidents
  // ---------------------------------------------------------------------------
  final List<IncidentReport> _all = [];

  static final IncidentReport _placeholder = IncidentReport(
    id: 'NONE',
    title: 'No active incidents',
    hazardType: 'None',
    severity: IncidentSeverity.low,
    location: 'Waiting for new field reports...',
    coordinates: const LatLng(6.9271, 79.8612),
    waterDepth: 'N/A',
    description: 'No incident reports are available right now.',
    corroboratingCount: 0,
    reporterName: '-',
    reporterPhone: '',
    isVerified: false,
  );

  List<IncidentReport> get _active =>
      _all.where((i) => !i.archived && i.status != IncidentStatus.resolved).toList();

  /// All open incidents, auto-ranked by severity (FR10).
  List<IncidentReport> get incidents {
    _ensureStarted();
    final list = _active;
    list.sort(_compareIncidents);
    return List.unmodifiable(list);
  }

  /// Resolved but not archived (history list).
  List<IncidentReport> get resolvedIncidents {
    _ensureStarted();
    final list = _all
        .where((i) => !i.archived && i.status == IncidentStatus.resolved)
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000)));
    return List.unmodifiable(list);
  }

  /// Incident to show when a screen needs "the current one". Never throws,
  /// returns a placeholder when the queue is empty.
  IncidentReport get focusIncident {
    final a = _activeIncident;
    if (a != null && !a.archived) return a;
    final list = incidents;
    return list.isEmpty ? _placeholder : list.first;
  }

  static int _compareIncidents(IncidentReport a, IncidentReport b) {
    final r = a.severityRank.compareTo(b.severityRank);
    if (r != 0) return r;
    final sa = a.status == IncidentStatus.incoming ? 0 : 1;
    final sb = b.status == IncidentStatus.incoming ? 0 : 1;
    if (sa != sb) return sa.compareTo(sb);
    return (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000));
  }

  List<IncidentReport> get filteredIncidents {
    final all = incidents;
    if (_selectedSeverityFilter == 'ALL') return all;
    return all.where((i) {
      switch (_selectedSeverityFilter) {
        case 'CRITICAL':
          return i.severity == IncidentSeverity.critical;
        case 'HIGH':
          return i.severity == IncidentSeverity.high;
        case 'MED':
          return i.severity == IncidentSeverity.medium;
        case 'LOW':
          return i.severity == IncidentSeverity.low;
      }
      return true;
    }).toList();
  }

  int countFor(String filter) {
    final all = incidents;
    switch (filter) {
      case 'ALL':
        return all.length;
      case 'CRITICAL':
        return all.where((i) => i.severity == IncidentSeverity.critical).length;
      case 'HIGH':
        return all.where((i) => i.severity == IncidentSeverity.high).length;
      case 'MED':
        return all.where((i) => i.severity == IncidentSeverity.medium).length;
      case 'LOW':
        return all.where((i) => i.severity == IncidentSeverity.low).length;
    }
    return 0;
  }

  // --- snapshot -> model ------------------------------------------------------

  void _onReports(QuerySnapshot<Map<String, dynamic>> snap) {
    _liveOk = true;
    _syncError = null;

    final seen = <String>{};
    for (final doc in snap.docs) {
      final fresh = _fromDoc(doc.id, doc.data());
      seen.add(doc.id);
      final idx = _all.indexWhere((i) => i.id == doc.id);
      if (idx == -1) {
        _all.add(fresh);
      } else {
        final old = _all[idx];
        final sameCore = old.severity == fresh.severity &&
            old.location == fresh.location &&
            old.description == fresh.description &&
            old.hazardType == fresh.hazardType &&
            old.photoUrl == fresh.photoUrl;
        if (sameCore) {
          // Keep the same object so open screens stay in sync.
          _copyMutable(fresh, old);
        } else {
          _all[idx] = fresh;
          if (_activeIncident?.id == fresh.id) _activeIncident = fresh;
        }
      }
    }
    _all.removeWhere((i) => !seen.contains(i.id));
    if (_activeIncident != null && !seen.contains(_activeIncident!.id)) {
      _activeIncident = null;
    }
    _computeCorroboration();
    notifyListeners();
  }

  void _copyMutable(IncidentReport from, IncidentReport to) {
    to.status = from.status;
    to.assignedTeam = from.assignedTeam;
    to.resolutionNotes = from.resolutionNotes;
    to.resolutionType = from.resolutionType;
    to.evacuatedCount = from.evacuatedCount;
    to.dispatchNotes = from.dispatchNotes;
    to.priorityLevel = from.priorityLevel;
    to.cancellationReason = from.cancellationReason;
    to.dispatchedAt = from.dispatchedAt;
    to.archived = from.archived;
    to.createdAt = from.createdAt;
  }

  IncidentSeverity _parseSeverity(String raw) {
    final u = raw.toUpperCase();
    if (u.contains('CRITICAL')) return IncidentSeverity.critical;
    if (u.contains('HIGH')) return IncidentSeverity.high;
    if (u.contains('MED') || u.contains('MODERATE')) {
      return IncidentSeverity.medium;
    }
    if (u.contains('LOW')) return IncidentSeverity.low;
    return IncidentSeverity.medium;
  }

  IncidentStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'dispatched':
        return IncidentStatus.dispatched;
      case 'onScene':
        return IncidentStatus.onScene;
      case 'resolved':
        return IncidentStatus.resolved;
      default:
        return IncidentStatus.incoming;
    }
  }

  String _statusKey(IncidentStatus s) {
    switch (s) {
      case IncidentStatus.incoming:
        return 'incoming';
      case IncidentStatus.dispatched:
        return 'dispatched';
      case IncidentStatus.onScene:
        return 'onScene';
      case IncidentStatus.resolved:
        return 'resolved';
    }
  }

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  IncidentReport _fromDoc(String id, Map<String, dynamic> d) {
    final hazard = (d['hazardType'] as String?) ?? 'Hazard';
    final location = (d['location'] as String?) ?? 'Unknown location';
    final lat = (d['latitude'] as num?)?.toDouble() ?? 6.9271;
    final lng = (d['longitude'] as num?)?.toDouble() ?? 79.8612;
    final depth = d['waterDepth'];
    final photo = (d['photoUrl'] as String?);

    final unitId = d['assignedUnitId'] as String?;
    EmergencyTeam? team;
    if (unitId != null && unitId.isNotEmpty) {
      final i = _teams.indexWhere((t) => t.id == unitId);
      if (i != -1) {
        team = _teams[i];
      } else {
        team = EmergencyTeam(
          id: unitId,
          name: (d['assignedUnitName'] as String?) ?? unitId,
          status: 'EN ROUTE',
          distance: '-',
          eta: '-',
          equipment: '',
          crewCount: 1,
          leader: '',
          radioChannel: '',
          location: LatLng(lat, lng),
        );
      }
    }

    return IncidentReport(
      id: id,
      localId: d['localId'] as String?,
      title: '$hazard Report',
      hazardType: hazard,
      severity: _parseSeverity((d['severity'] as String?) ?? ''),
      location: location,
      coordinates: LatLng(lat, lng),
      waterDepth: depth is num ? '${depth}m reported' : 'Not reported',
      description: (d['description'] as String?)?.trim().isNotEmpty == true
          ? d['description'] as String
          : 'No description provided by the reporter.',
      corroboratingCount: 1,
      reporterName: (d['reporterName'] as String?) ?? 'Volunteer',
      reporterPhone: (d['reporterPhone'] as String?) ?? '',
      reporterEmail: (d['reporterEmail'] as String?) ?? '',
      isVerified: (d['isVerified'] as bool?) ?? false,
      photoUrl: (photo != null && photo.startsWith('http')) ? photo : null,
      createdAt: _toDate(d['timestamp']),
      archived: (d['archived'] as bool?) ?? false,
      status: _parseStatus(d['dispatchStatus'] as String?),
      assignedTeam: team,
      resolutionNotes: d['resolutionNotes'] as String?,
      resolutionType: d['resolutionType'] as String?,
      evacuatedCount: (d['evacuatedCount'] as num?)?.toInt() ?? 0,
      dispatchNotes: d['dispatchNotes'] as String?,
      priorityLevel: d['priorityLevel'] as String?,
      cancellationReason: d['cancellationReason'] as String?,
      dispatchedAt: _toDate(d['dispatchedAt']),
    );
  }

  /// Corroborating count = this report + other reports of the same hazard
  /// type within 1 km in the last 24 h (computed from real data).
  void _computeCorroboration() {
    const dist = Distance();
    final now = DateTime.now();
    for (var k = 0; k < _all.length; k++) {
      final a = _all[k];
      var n = 1;
      for (final b in _all) {
        if (identical(a, b) || b.archived) continue;
        if (b.hazardType != a.hazardType) continue;
        final t = b.createdAt;
        if (t != null && now.difference(t).inHours > 24) continue;
        if (dist.as(LengthUnit.Meter, a.coordinates, b.coordinates) <= 1000) {
          n++;
        }
      }
      if (n != a.corroboratingCount) {
        _all[k] = IncidentReport(
          id: a.id,
          localId: a.localId,
          title: a.title,
          hazardType: a.hazardType,
          severity: a.severity,
          location: a.location,
          coordinates: a.coordinates,
          waterDepth: a.waterDepth,
          description: a.description,
          corroboratingCount: n,
          reporterName: a.reporterName,
          reporterPhone: a.reporterPhone,
          reporterEmail: a.reporterEmail,
          isVerified: a.isVerified,
          photoUrl: a.photoUrl,
          createdAt: a.createdAt,
          archived: a.archived,
          status: a.status,
          assignedTeam: a.assignedTeam,
          resolutionNotes: a.resolutionNotes,
          resolutionType: a.resolutionType,
          evacuatedCount: a.evacuatedCount,
          dispatchNotes: a.dispatchNotes,
          priorityLevel: a.priorityLevel,
          cancellationReason: a.cancellationReason,
          dispatchedAt: a.dispatchedAt,
        );
        if (_activeIncident?.id == a.id) _activeIncident = _all[k];
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Response units (CRUD)
  // ---------------------------------------------------------------------------
  static const List<EmergencyTeam> _defaultTeams = [
    EmergencyTeam(
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
    EmergencyTeam(
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
    EmergencyTeam(
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
    EmergencyTeam(
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
    EmergencyTeam(
      id: 'TEAM-05',
      name: 'Colombo Fire Service Unit B',
      status: 'AVAILABLE',
      distance: '0.8 km Away',
      eta: '6 Mins',
      etaMinutes: 6,
      equipment: 'High-Volume Drainage Pump Truck',
      crewCount: 5,
      leader: 'Station Officer Wickrama',
      radioChannel: 'VHF CH-02',
      location: LatLng(6.9290, 79.8580),
      speedKmh: 30.0,
      vehicleType: 'Heavy Drainage Pump Truck',
      callSign: 'SIERRA-05',
      phoneNumber: '+94 11 242 2222',
      fuelLevel: 74,
    ),
  ];

  // Shown until the first Firestore snapshot arrives.
  final List<EmergencyTeam> _teams = List.of(_defaultTeams);
  bool _seeding = false;

  List<EmergencyTeam> get teams {
    _ensureStarted();
    return List.unmodifiable(_teams);
  }

  List<EmergencyTeam> get sortedTeamsByEta {
    _ensureStarted();
    final list = List<EmergencyTeam>.from(_teams);
    list.sort((a, b) {
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      return a.etaMinutes.compareTo(b.etaMinutes);
    });
    return list;
  }

  void _onUnits(QuerySnapshot<Map<String, dynamic>> snap) {
    if (snap.docs.isEmpty) {
      _seedDefaultUnits();
      return;
    }
    _teams
      ..clear()
      ..addAll(snap.docs.map((d) => EmergencyTeam.fromMap(d.id, d.data())));
    // Re-link teams on already loaded incidents.
    for (final i in _all) {
      final t = i.assignedTeam;
      if (t == null) continue;
      final idx = _teams.indexWhere((x) => x.id == t.id);
      if (idx != -1) i.assignedTeam = _teams[idx];
    }
    notifyListeners();
  }

  Future<void> _seedDefaultUnits() async {
    if (_seeding) return;
    _seeding = true;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final t in _defaultTeams) {
        batch.set(_units.doc(t.id), t.toMap());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[ResponderController] seed units failed: $e');
    } finally {
      _seeding = false;
    }
  }

  /// CREATE a response unit.
  Future<void> addUnit(EmergencyTeam team) async {
    final id = team.id.isEmpty
        ? 'UNIT-${DateTime.now().millisecondsSinceEpoch}'
        : team.id;
    await _units.doc(id).set({
      ...team.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    }).queued();
  }

  /// UPDATE a response unit's details.
  Future<void> updateUnit(EmergencyTeam team) async {
    await _units.doc(team.id).set({
      ...team.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).queued();
  }

  /// DELETE a response unit. Returns an error message, or null on success.
  Future<String?> deleteUnit(String id) async {
    final idx = _teams.indexWhere((t) => t.id == id);
    if (idx != -1 && !_teams[idx].isAvailable) {
      return 'This unit is on a mission. Resolve or cancel its dispatch first.';
    }
    if (_teams.length <= 1) {
      return 'At least one response unit must remain.';
    }
    await _units.doc(id).delete();
    return null;
  }

  Future<void> _setUnit(String id, Map<String, dynamic> data) async {
    try {
      await _units.doc(id).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).queued();
    } catch (e) {
      debugPrint('[ResponderController] unit write failed: $e');
    }
  }

  void _setLocalTeam(EmergencyTeam team) {
    final i = _teams.indexWhere((t) => t.id == team.id);
    if (i != -1) _teams[i] = team;
  }

  // ---------------------------------------------------------------------------
  // Dispatch operations (write to hazard_reports + responseUnits)
  // ---------------------------------------------------------------------------
  Future<void> _writeIncident(
      IncidentReport incident, Map<String, dynamic> data) async {
    if (incident.isPlaceholder) return;
    try {
      await _reports.doc(incident.id).set({
        ...data,
        'dispatchUpdatedAt': FieldValue.serverTimestamp(),
        'dispatcherEmail': _currentUser?.email ?? '',
      }, SetOptions(merge: true)).queued();
    } catch (e) {
      _onErr(e);
    }
  }

  // CREATE: assign a unit to an incident
  void assignTeamToIncident(
    IncidentReport incident,
    EmergencyTeam team, {
    String? dispatchNotes,
    String? priority,
  }) {
    final updatedTeam = team.copyWith(status: 'EN ROUTE');
    _setLocalTeam(updatedTeam);

    incident.assignedTeam = updatedTeam;
    incident.status = IncidentStatus.dispatched;
    if (dispatchNotes != null) incident.dispatchNotes = dispatchNotes;
    if (priority != null) incident.priorityLevel = priority;
    incident.dispatchedAt = DateTime.now();
    incident.cancellationReason = null;

    _activeIncident = incident;
    notifyListeners();

    _writeIncident(incident, {
      'dispatchStatus': _statusKey(IncidentStatus.dispatched),
      'assignedUnitId': updatedTeam.id,
      'assignedUnitName': updatedTeam.name,
      'dispatchNotes': incident.dispatchNotes ?? '',
      'priorityLevel': incident.priorityLevel ?? '',
      'dispatchedAt': FieldValue.serverTimestamp(),
      'cancellationReason': FieldValue.delete(),
    });
    _setUnit(updatedTeam.id, {
      'status': 'EN ROUTE',
      'assignedIncidentId': incident.id,
    });
  }

  // UPDATE: reassign incident to a different unit
  void reassignTeam({
    required IncidentReport incident,
    required EmergencyTeam newTeam,
    required String reason,
  }) {
    final old = incident.assignedTeam;
    if (old != null) {
      final released = old.copyWith(status: 'AVAILABLE');
      _setLocalTeam(released);
      _setUnit(old.id, {
        'status': 'AVAILABLE',
        'assignedIncidentId': FieldValue.delete(),
      });
    }

    final assigned = newTeam.copyWith(status: 'EN ROUTE');
    _setLocalTeam(assigned);

    incident.assignedTeam = assigned;
    incident.status = IncidentStatus.dispatched;
    incident.dispatchNotes =
        '${incident.dispatchNotes ?? ""}\n[REASSIGNED]: $reason (Now: ${newTeam.name})'
            .trim();

    _activeIncident = incident;
    notifyListeners();

    _writeIncident(incident, {
      'dispatchStatus': _statusKey(IncidentStatus.dispatched),
      'assignedUnitId': assigned.id,
      'assignedUnitName': assigned.name,
      'dispatchNotes': incident.dispatchNotes ?? '',
    });
    _setUnit(assigned.id, {
      'status': 'EN ROUTE',
      'assignedIncidentId': incident.id,
    });
  }

  // UPDATE: EN ROUTE <-> ON SCENE
  void updateDispatchStatus(IncidentReport incident, String newStatus) {
    final up = newStatus.toUpperCase();
    final t = incident.assignedTeam;
    if (t != null) {
      final updatedTeam = t.copyWith(status: up);
      incident.assignedTeam = updatedTeam;
      _setLocalTeam(updatedTeam);
      _setUnit(updatedTeam.id, {'status': up});
    }

    if (up == 'ON SCENE') {
      incident.status = IncidentStatus.onScene;
    } else if (up == 'EN ROUTE') {
      incident.status = IncidentStatus.dispatched;
    }
    notifyListeners();

    _writeIncident(incident, {
      'dispatchStatus': _statusKey(incident.status),
      if (up == 'ON SCENE') 'onSceneAt': FieldValue.serverTimestamp(),
    });
  }

  // UPDATE: notes / priority
  void updateDispatchDetails({
    required IncidentReport incident,
    String? notes,
    String? priority,
  }) {
    if (notes != null) incident.dispatchNotes = notes;
    if (priority != null) incident.priorityLevel = priority;
    notifyListeners();
    _writeIncident(incident, {
      if (notes != null) 'dispatchNotes': notes,
      if (priority != null) 'priorityLevel': priority,
    });
  }

  // DELETE: cancel an active dispatch
  void cancelDispatch({
    required IncidentReport incident,
    required String cancellationReason,
  }) {
    final t = incident.assignedTeam;
    if (t != null) {
      _setLocalTeam(t.copyWith(status: 'AVAILABLE'));
      _setUnit(t.id, {
        'status': 'AVAILABLE',
        'assignedIncidentId': FieldValue.delete(),
      });
    }

    incident.assignedTeam = null;
    incident.status = IncidentStatus.incoming;
    incident.cancellationReason = cancellationReason;
    notifyListeners();

    _writeIncident(incident, {
      'dispatchStatus': _statusKey(IncidentStatus.incoming),
      'assignedUnitId': FieldValue.delete(),
      'assignedUnitName': FieldValue.delete(),
      'cancellationReason': cancellationReason,
    });
  }

  void updateIncidentStatus(IncidentReport incident, IncidentStatus status) {
    incident.status = status;
    notifyListeners();
    _writeIncident(incident, {'dispatchStatus': _statusKey(status)});
  }

  // UPDATE: resolve (leaves the active queue, unit becomes available)
  void resolveIncident({
    required IncidentReport incident,
    required String resolutionType,
    required String notes,
    required int evacuatedCount,
  }) {
    final t = incident.assignedTeam;
    if (t != null) {
      _setLocalTeam(t.copyWith(status: 'AVAILABLE'));
      _setUnit(t.id, {
        'status': 'AVAILABLE',
        'assignedIncidentId': FieldValue.delete(),
      });
    }

    incident.status = IncidentStatus.resolved;
    incident.resolutionType = resolutionType;
    incident.resolutionNotes = notes;
    incident.evacuatedCount = evacuatedCount;
    notifyListeners();

    _writeIncident(incident, {
      'dispatchStatus': _statusKey(IncidentStatus.resolved),
      'resolutionType': resolutionType,
      'resolutionNotes': notes,
      'evacuatedCount': evacuatedCount,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // UPDATE: reopen a resolved incident
  void reopenIncident(IncidentReport incident) {
    incident.status = IncidentStatus.incoming;
    incident.assignedTeam = null;
    notifyListeners();
    _writeIncident(incident, {
      'dispatchStatus': _statusKey(IncidentStatus.incoming),
      'assignedUnitId': FieldValue.delete(),
      'assignedUnitName': FieldValue.delete(),
      'resolvedAt': FieldValue.delete(),
    });
  }

  // DELETE (soft): remove from the dispatcher's lists. The volunteer's report
  // itself is kept (Component 2 data is never hard-deleted from here).
  void archiveIncident(IncidentReport incident) {
    incident.archived = true;
    if (_activeIncident?.id == incident.id) _activeIncident = null;
    notifyListeners();
    _writeIncident(incident, {'archived': true});
  }

  // ---------------------------------------------------------------------------
  // Zone broadcast -> `warnings` (what Component 1 citizens read)  [CREATE]
  // ---------------------------------------------------------------------------
  Future<void> broadcastZoneAlert({
    required String zone,
    required String title,
    required String message,
    String district = 'All',
    String city = 'All',
    String severity = 'Critical', // Watch | Warning | Critical
    String hazardType = 'Evacuation',
    LatLng? center,
    double radiusKm = 2,
    String? areaName,
    List<double>? bbox,
  }) async {
    await _warnings.add({
      'district': district.trim().isEmpty ? 'All' : district.trim(),
      'city': city.trim().isEmpty ? 'All' : city.trim(),
      'locationZone': zone,
      'hazardType': hazardType,
      'waterLevelMeters': 0.0,
      'rainfallMm': 0.0,
      'windSpeedKmh': 0.0,
      'severity': severity,
      'description': title.trim().isEmpty ? message : '$title - $message',
      'issuedTimestamp': FieldValue.serverTimestamp(),
      // extra fields for the map-based broadcast (ignored by Component 1)
      'centerLat': center?.latitude,
      'centerLng': center?.longitude,
      'radiusKm': radiusKm,
      'areaName': areaName,
      'bbox': bbox,
      'issuedBy': _currentUser?.email ?? '',
      'source': 'dispatcher',
    }).queued();
  }

  /// UPDATE a broadcast.
  Future<void> updateBroadcast(String id, Map<String, dynamic> data) async {
    await _warnings.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }).queued();
  }

  /// DELETE (withdraw) a broadcast.
  Future<void> deleteBroadcast(String id) => _warnings.doc(id).delete();

  /// Stream of broadcasts issued from the control center (READ).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchBroadcasts() =>
      _warnings.where('source', isEqualTo: 'dispatcher').snapshots();

  // small helper for screens
  static double kmBetween(LatLng a, LatLng b) {
    const d = Distance();
    return d.as(LengthUnit.Meter, a, b) / 1000.0;
  }
}
