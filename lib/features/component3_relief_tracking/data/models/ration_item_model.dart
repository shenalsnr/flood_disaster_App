/// Represents the current status of a supply/ration item.
enum SupplyStatus {
  adequate,
  low,
  depleted,
}

/// Represents a specific ration/supply item stored at a shelter.
class RationItemModel {
  final String id;
  final String shelterId;
  final String name;
  final String category; // e.g., Medical, Food, Water, Baby Care
  final int quantity;
  final String unit; // e.g., kg, liters, packets
  final int thresholdLow; // Quantity at which stock is considered 'low'

  const RationItemModel({
    required this.id,
    required this.shelterId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.thresholdLow,
  });

  /// Evaluates the real-time status of the supply based on its current quantity.
  SupplyStatus get status {
    if (quantity <= 0) {
      return SupplyStatus.depleted;
    } else if (quantity <= thresholdLow) {
      return SupplyStatus.low;
    }
    return SupplyStatus.adequate;
  }

  /// Creates a copy of this model with the given fields replaced by new values.
  RationItemModel copyWith({
    String? id,
    String? shelterId,
    String? name,
    String? category,
    int? quantity,
    String? unit,
    int? thresholdLow,
  }) {
    return RationItemModel(
      id: id ?? this.id,
      shelterId: shelterId ?? this.shelterId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      thresholdLow: thresholdLow ?? this.thresholdLow,
    );
  }

  /// Converts this model into a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shelterId': shelterId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'thresholdLow': thresholdLow,
    };
  }

  /// Creates a model instance from a database map.
  factory RationItemModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return RationItemModel(
      id: documentId ?? map['id'] as String? ?? '',
      shelterId: map['shelterId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? '',
      thresholdLow: (map['thresholdLow'] as num?)?.toInt() ?? 0,
    );
  }
}
