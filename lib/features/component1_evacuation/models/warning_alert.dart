import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// WarningAlert — Data Model for Component 1: Early Warning & Evacuation
// ---------------------------------------------------------------------------
// Represents a single live disaster warning document stored in Firestore
// under the top-level `warnings` collection.
// ---------------------------------------------------------------------------

class WarningAlert {
  final String id;
  final String district;
  final String city;
  final String locationZone;
  final String hazardType;
  final double waterLevelMeters;
  final double rainfallMm;
  final double windSpeedKmh;
  final String severity; // "Watch" | "Warning" | "Critical"
  final String description;
  final DateTime issuedTimestamp;

  const WarningAlert({
    required this.id,
    required this.district,
    required this.city,
    required this.locationZone,
    required this.hazardType,
    required this.waterLevelMeters,
    required this.rainfallMm,
    required this.windSpeedKmh,
    required this.severity,
    required this.description,
    required this.issuedTimestamp,
  });

  // ── Firestore → Model ──────────────────────────────────────────────────────

  factory WarningAlert.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WarningAlert(
      id: doc.id,
      district: data['district'] as String? ?? 'All',
      city: data['city'] as String? ?? 'All',
      locationZone: data['locationZone'] as String? ?? '',
      hazardType: data['hazardType'] as String? ?? '',
      waterLevelMeters: (data['waterLevelMeters'] as num?)?.toDouble() ?? 0.0,
      rainfallMm: (data['rainfallMm'] as num?)?.toDouble() ?? 0.0,
      windSpeedKmh: (data['windSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      severity: data['severity'] as String? ?? 'Watch',
      description: data['description'] as String? ?? '',
      issuedTimestamp: data['issuedTimestamp'] is Timestamp
          ? (data['issuedTimestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ── Model → Firestore ──────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'district': district,
      'city': city,
      'locationZone': locationZone,
      'hazardType': hazardType,
      'waterLevelMeters': waterLevelMeters,
      'rainfallMm': rainfallMm,
      'windSpeedKmh': windSpeedKmh,
      'severity': severity,
      'description': description,
      'issuedTimestamp': FieldValue.serverTimestamp(),
    };
  }

  // ── Convenience copy-with ──────────────────────────────────────────────────

  WarningAlert copyWith({
    String? id,
    String? district,
    String? city,
    String? locationZone,
    String? hazardType,
    double? waterLevelMeters,
    double? rainfallMm,
    double? windSpeedKmh,
    String? severity,
    String? description,
    DateTime? issuedTimestamp,
  }) {
    return WarningAlert(
      id: id ?? this.id,
      district: district ?? this.district,
      city: city ?? this.city,
      locationZone: locationZone ?? this.locationZone,
      hazardType: hazardType ?? this.hazardType,
      waterLevelMeters: waterLevelMeters ?? this.waterLevelMeters,
      rainfallMm: rainfallMm ?? this.rainfallMm,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      issuedTimestamp: issuedTimestamp ?? this.issuedTimestamp,
    );
  }
}
