import 'package:latlong2/latlong.dart';

enum IncidentSeverity { critical, high, medium, low }

enum IncidentStatus { incoming, dispatched, onScene, resolved }

enum UserRole {
  citizen,
  volunteer,
  campLeader,
  responder,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Affected Citizen';
      case UserRole.volunteer:
        return 'Community Volunteer';
      case UserRole.campLeader:
        return 'Relief Camp Leader';
      case UserRole.responder:
        return 'Emergency Dispatcher & Responder';
    }
  }

  String get description {
    switch (this) {
      case UserRole.citizen:
        return 'Safe walking routes, real-time alerts & shelter check-in';
      case UserRole.volunteer:
        return '1-tap hazard reporting with GPS & photo verification';
      case UserRole.campLeader:
        return 'Shelter capacity management & relief supply tracking';
      case UserRole.responder:
        return 'Incident triage, responder assignment & live tracking';
    }
  }
}

class EmergencyTeam {
  final String id;
  final String name;
  final String status; // AVAILABLE, EN ROUTE, ON SCENE, ON MISSION
  final String distance;
  final String eta;
  final int etaMinutes;
  final String equipment;
  final int crewCount;
  final String leader;
  final String radioChannel;
  final LatLng location;
  final double speedKmh;
  final String vehicleType;
  final String callSign;
  final String phoneNumber;
  final int fuelLevel;

  const EmergencyTeam({
    required this.id,
    required this.name,
    required this.status,
    required this.distance,
    required this.eta,
    this.etaMinutes = 4,
    required this.equipment,
    required this.crewCount,
    required this.leader,
    required this.radioChannel,
    required this.location,
    this.speedKmh = 24.0,
    this.vehicleType = 'Zodiac Rescue Boat',
    this.callSign = 'ALPHA-1',
    this.phoneNumber = '+94 77 482 1029',
    this.fuelLevel = 94,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
        'distance': distance,
        'eta': eta,
        'etaMinutes': etaMinutes,
        'equipment': equipment,
        'crewCount': crewCount,
        'leader': leader,
        'radioChannel': radioChannel,
        'lat': location.latitude,
        'lng': location.longitude,
        'speedKmh': speedKmh,
        'vehicleType': vehicleType,
        'callSign': callSign,
        'phoneNumber': phoneNumber,
        'fuelLevel': fuelLevel,
      };

  factory EmergencyTeam.fromMap(String id, Map<String, dynamic> m) {
    double d(dynamic v, double f) => v is num ? v.toDouble() : f;
    int i(dynamic v, int f) => v is num ? v.toInt() : f;
    return EmergencyTeam(
      id: id,
      name: m['name'] as String? ?? id,
      status: m['status'] as String? ?? 'AVAILABLE',
      distance: m['distance'] as String? ?? '-',
      eta: m['eta'] as String? ?? '-',
      etaMinutes: i(m['etaMinutes'], 10),
      equipment: m['equipment'] as String? ?? '',
      crewCount: i(m['crewCount'], 1),
      leader: m['leader'] as String? ?? '',
      radioChannel: m['radioChannel'] as String? ?? '',
      location: LatLng(d(m['lat'], 6.9271), d(m['lng'], 79.8612)),
      speedKmh: d(m['speedKmh'], 24.0),
      vehicleType: m['vehicleType'] as String? ?? 'Rescue Vehicle',
      callSign: m['callSign'] as String? ?? id,
      phoneNumber: m['phoneNumber'] as String? ?? '',
      fuelLevel: i(m['fuelLevel'], 100),
    );
  }

  bool get isAvailable => status == 'AVAILABLE';
  bool get isEnRoute => status == 'EN ROUTE';
  bool get isOnScene => status == 'ON SCENE';

  EmergencyTeam copyWith({
    String? id,
    String? name,
    String? status,
    String? distance,
    String? eta,
    int? etaMinutes,
    String? equipment,
    int? crewCount,
    String? leader,
    String? radioChannel,
    LatLng? location,
    double? speedKmh,
    String? vehicleType,
    String? callSign,
    String? phoneNumber,
    int? fuelLevel,
  }) {
    return EmergencyTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      distance: distance ?? this.distance,
      eta: eta ?? this.eta,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      equipment: equipment ?? this.equipment,
      crewCount: crewCount ?? this.crewCount,
      leader: leader ?? this.leader,
      radioChannel: radioChannel ?? this.radioChannel,
      location: location ?? this.location,
      speedKmh: speedKmh ?? this.speedKmh,
      vehicleType: vehicleType ?? this.vehicleType,
      callSign: callSign ?? this.callSign,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fuelLevel: fuelLevel ?? this.fuelLevel,
    );
  }
}

class IncidentReport {
  final String id;
  final String title;
  final String hazardType;
  final IncidentSeverity severity;
  final String location;
  final LatLng coordinates;
  final String waterDepth;
  final String description;
  final int corroboratingCount;
  final String reporterName;
  final String reporterPhone;
  final bool isVerified;
  final String _timeAgo;
  final String? localId;
  final String reporterEmail;
  final String? photoUrl;
  DateTime? createdAt;
  bool archived;
  IncidentStatus status;
  EmergencyTeam? assignedTeam;
  String? resolutionNotes;
  String? resolutionType;
  int evacuatedCount;
  String? dispatchNotes;
  String? priorityLevel;
  String? cancellationReason;
  DateTime? dispatchedAt;

  IncidentReport({
    required this.id,
    required this.title,
    required this.hazardType,
    required this.severity,
    required this.location,
    required this.coordinates,
    required this.waterDepth,
    required this.description,
    required this.corroboratingCount,
    required this.reporterName,
    required this.reporterPhone,
    required this.isVerified,
    String timeAgo = '',
    this.localId,
    this.reporterEmail = '',
    this.photoUrl,
    this.createdAt,
    this.archived = false,
    this.status = IncidentStatus.incoming,
    this.assignedTeam,
    this.resolutionNotes,
    this.resolutionType,
    this.evacuatedCount = 0,
    this.dispatchNotes,
    this.priorityLevel,
    this.cancellationReason,
    this.dispatchedAt,
  }) : _timeAgo = timeAgo;

  /// Short readable id for UI (report code if present, else trimmed doc id).
  String get shortId {
    final l = localId;
    if (l != null && l.isNotEmpty) return l;
    return id.length > 8 ? id.substring(0, 8).toUpperCase() : id;
  }

  bool get isPlaceholder => id == 'NONE';

  /// Live "x mins ago" text computed from [createdAt] (falls back to text).
  String get timeAgo {
    final c = createdAt;
    if (c == null) return _timeAgo.isEmpty ? 'Just now' : _timeAgo;
    final diff = DateTime.now().difference(c);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} Mins Ago';
    if (diff.inHours < 24) return '${diff.inHours} Hrs Ago';
    return '${diff.inDays} Days Ago';
  }

  /// Sort weight: lower = more urgent (FR10).
  int get severityRank {
    switch (severity) {
      case IncidentSeverity.critical:
        return 0;
      case IncidentSeverity.high:
        return 1;
      case IncidentSeverity.medium:
        return 2;
      case IncidentSeverity.low:
        return 3;
    }
  }

  String get severityLabel {
    switch (severity) {
      case IncidentSeverity.critical:
        return 'CRITICAL';
      case IncidentSeverity.high:
        return 'HIGH';
      case IncidentSeverity.medium:
        return 'MED';
      case IncidentSeverity.low:
        return 'LOW';
    }
  }

  String get statusLabel {
    switch (status) {
      case IncidentStatus.incoming:
        return 'PENDING TRIAGE';
      case IncidentStatus.dispatched:
        return 'DISPATCHED';
      case IncidentStatus.onScene:
        return 'ON SCENE';
      case IncidentStatus.resolved:
        return 'RESOLVED';
    }
  }
}

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String nic;
  final String district;
  final String city;
  final String floodZone;
  final String role; // responder, citizen, volunteer, campLeader
  final String? photoUrl;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.nic,
    this.district = '',
    this.city = '',
    required this.floodZone,
    required this.role,
    this.photoUrl,
  });

  Map<String, dynamic> toMap([String? password]) {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email.toLowerCase().trim(),
      'phoneNumber': phoneNumber,
      'nic': nic,
      'district': district,
      'city': city,
      'floodZone': floodZone,
      'role': role,
      'password': ?password,
      'photoUrl': ?photoUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      uid: id,
      fullName: map['fullName'] as String? ?? 'User',
      email: map['email'] as String? ?? id,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      nic: map['nic'] as String? ?? '',
      district: map['district'] as String? ?? '',
      city: map['city'] as String? ?? '',
      floodZone: map['floodZone'] as String? ?? '',
      role: map['role'] as String? ?? 'responder',
      photoUrl: map['photoUrl'] as String?,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? nic,
    String? district,
    String? city,
    String? floodZone,
    String? role,
    String? photoUrl,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nic: nic ?? this.nic,
      district: district ?? this.district,
      city: city ?? this.city,
      floodZone: floodZone ?? this.floodZone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  String get roleTitle {
    switch (role) {
      case 'citizen':
        return 'CIVILIAN CITIZEN • EARLY WARNING';
      case 'volunteer':
        return 'COMMUNITY VOLUNTEER • GROUND SCOUT';
      case 'campLeader':
        return 'RELIEF CAMP LEADER • LOGISTICS';
      case 'responder':
      default:
        return 'DISPATCHER #04 • DMC CONTROL';
    }
  }
}

