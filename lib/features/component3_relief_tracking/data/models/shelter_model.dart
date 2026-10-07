/// Represents a disaster relief shelter/camp.
class ShelterModel {
  final String id;
  final String name;
  final String location;
  final int totalBeds;
  final int occupiedBeds;
  final bool isClosed;

  const ShelterModel({
    required this.id,
    required this.name,
    required this.location,
    required this.totalBeds,
    required this.occupiedBeds,
    this.isClosed = false,
  });

  /// Returns the occupancy as a decimal ratio (0.0 to 1.0).
  /// Safe against division by zero if totalBeds is somehow 0.
  double get occupancyRatio {
    if (totalBeds <= 0) return 1.0; // Assume full if no beds available
    return (occupiedBeds / totalBeds).clamp(0.0, 1.0);
  }

  /// Returns the occupancy as a percentage (0 to 100).
  int get occupancyPercentage => (occupancyRatio * 100).round();

  /// Creates a copy of this model with the given fields replaced by new values.
  ShelterModel copyWith({
    String? id,
    String? name,
    String? location,
    int? totalBeds,
    int? occupiedBeds,
    bool? isClosed,
  }) {
    return ShelterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      totalBeds: totalBeds ?? this.totalBeds,
      occupiedBeds: occupiedBeds ?? this.occupiedBeds,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  /// Converts this model into a map for database storage (e.g., Firestore/SQLite).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'totalBeds': totalBeds,
      'occupiedBeds': occupiedBeds,
      'isClosed': isClosed,
    };
  }

  /// Creates a model instance from a database map.
  factory ShelterModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return ShelterModel(
      id: documentId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      totalBeds: (map['totalBeds'] as num?)?.toInt() ?? 0,
      occupiedBeds: (map['occupiedBeds'] as num?)?.toInt() ?? 0,
      isClosed: map['isClosed'] as bool? ?? false,
    );
  }
}
