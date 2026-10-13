import 'dart:convert';

/// Data model representing a local Hazard Report stored in SQLite.
/// Supports complete CRUD operations for offline drafts and pending queue items.
class OfflineHazardReport {
  final String id;
  final String hazardType;
  final String severity;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final String reporterName;
  final String reporterEmail;
  final String? photoPath;
  final bool hasPhoto;
  final String status; // 'DRAFT', 'PENDING_SYNC', 'SYNCED'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  OfflineHazardReport({
    required this.id,
    required this.hazardType,
    required this.severity,
    required this.description,
    required this.location,
    this.latitude = 6.9271,
    this.longitude = 79.8612,
    this.reporterName = 'Kapila Perera',
    this.reporterEmail = 'volunteer.kapila@dmc.org',
    this.photoPath,
    this.hasPhoto = false,
    this.status = 'PENDING_SYNC',
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  OfflineHazardReport copyWith({
    String? id,
    String? hazardType,
    String? severity,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? reporterName,
    String? reporterEmail,
    String? photoPath,
    bool? hasPhoto,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
  }) {
    return OfflineHazardReport(
      id: id ?? this.id,
      hazardType: hazardType ?? this.hazardType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      reporterName: reporterName ?? this.reporterName,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      photoPath: photoPath ?? this.photoPath,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Converts model to Map for SQLite database insertion/updating.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hazard_type': hazardType,
      'severity': severity,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'reporter_name': reporterName,
      'reporter_email': reporterEmail,
      'photo_path': photoPath,
      'has_photo': hasPhoto ? 1 : 0,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  /// Factory constructor to deserialize from SQLite database map.
  factory OfflineHazardReport.fromMap(Map<String, dynamic> map) {
    return OfflineHazardReport(
      id: map['id'] as String,
      hazardType: map['hazard_type'] as String? ?? 'Hazard',
      severity: map['severity'] as String? ?? 'MEDIUM',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? 'Field Location',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 6.9271,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 79.8612,
      reporterName: map['reporter_name'] as String? ?? 'Volunteer',
      reporterEmail: map['reporter_email'] as String? ?? '',
      photoPath: map['photo_path'] as String?,
      hasPhoto: (map['has_photo'] as int? ?? 0) == 1,
      status: map['status'] as String? ?? 'DRAFT',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
      syncedAt: map['synced_at'] != null
          ? DateTime.tryParse(map['synced_at'] as String)
          : null,
    );
  }

  /// Convert to Firestore submission payload.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'hazardType': hazardType,
      'severity': severity,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'hasPhoto': hasPhoto,
      'photoPath': photoPath ?? '',
      'status': 'VERIFIED',
      'isVerified': true,
      'source': 'OFFLINE_SYNC_SQLITE',
      'localId': id,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory OfflineHazardReport.fromJson(String source) =>
      OfflineHazardReport.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
