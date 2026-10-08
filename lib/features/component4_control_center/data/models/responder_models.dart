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
  final String status; // Available, En Route, On Mission
  final String distance;
  final String eta;
  final String equipment;
  final int crewCount;
  final String leader;
  final String radioChannel;
  final LatLng location;
  final double speedKmh;

  const EmergencyTeam({
    required this.id,
    required this.name,
    required this.status,
    required this.distance,
    required this.eta,
    required this.equipment,
    required this.crewCount,
    required this.leader,
    required this.radioChannel,
    required this.location,
    this.speedKmh = 24.0,
  });

  bool get isAvailable => status == 'AVAILABLE';
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
  final String timeAgo;
  IncidentStatus status;
  EmergencyTeam? assignedTeam;
  String? resolutionNotes;
  String? resolutionType;
  int evacuatedCount;

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
    required this.timeAgo,
    this.status = IncidentStatus.incoming,
    this.assignedTeam,
    this.resolutionNotes,
    this.resolutionType,
    this.evacuatedCount = 0,
  });

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
