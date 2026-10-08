enum SupplyCategory {
  water,
  food,
  medical,
  shelter,
  hygiene,
  other,
}

enum StockStatus {
  critical,
  low,
  adequate,
}

class ReliefItemModel {
  final String id;
  final String name;
  final SupplyCategory category;
  final double quantity;
  final String unit;
  final double minThreshold;
  final String lastUpdated;

  const ReliefItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.minThreshold,
    required this.lastUpdated,
  });

  StockStatus get status {
    if (quantity <= minThreshold * 0.3) {
      return StockStatus.critical;
    } else if (quantity <= minThreshold) {
      return StockStatus.low;
    }
    return StockStatus.adequate;
  }

  ReliefItemModel copyWith({
    String? id,
    String? name,
    SupplyCategory? category,
    double? quantity,
    String? unit,
    double? minThreshold,
    String? lastUpdated,
  }) {
    return ReliefItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minThreshold: minThreshold ?? this.minThreshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
