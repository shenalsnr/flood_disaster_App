
enum EquipmentStatus {
  available,
  assigned,
  inTransit,
  underMaintenance,
  decommissioned,
}

enum EquipmentCondition { excellent, good, fair, needsRepair, damaged }

class EquipmentLog {
  final String id;
  final String date;
  final String description;

  const EquipmentLog({
    required this.id,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'date': date, 'description': description};
  }

  factory EquipmentLog.fromMap(Map<String, dynamic> map) {
    return EquipmentLog(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

class EquipmentModel {
  final String id;
  final String name;
  final EquipmentStatus status;
  final EquipmentCondition condition;
  final String currentCampId;
  final List<EquipmentLog> historyLogs;
  final List<EquipmentLog> maintenanceRecords;

  const EquipmentModel({
    required this.id,
    required this.name,
    required this.status,
    required this.condition,
    required this.currentCampId,
    required this.historyLogs,
    required this.maintenanceRecords,
  });

  EquipmentModel copyWith({
    String? id,
    String? name,
    EquipmentStatus? status,
    EquipmentCondition? condition,
    String? currentCampId,
    List<EquipmentLog>? historyLogs,
    List<EquipmentLog>? maintenanceRecords,
  }) {
    return EquipmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      currentCampId: currentCampId ?? this.currentCampId,
      historyLogs: historyLogs ?? this.historyLogs,
      maintenanceRecords: maintenanceRecords ?? this.maintenanceRecords,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'condition': condition.name,
      'currentCampId': currentCampId,
      'historyLogs': historyLogs.map((e) => e.toMap()).toList(),
      'maintenanceRecords': maintenanceRecords.map((e) => e.toMap()).toList(),
    };
  }

  factory EquipmentModel.fromMap(Map<String, dynamic> map) {
    return EquipmentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      status: EquipmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EquipmentStatus.available,
      ),
      condition: EquipmentCondition.values.firstWhere(
        (e) => e.name == map['condition'],
        orElse: () => EquipmentCondition.excellent,
      ),
      currentCampId: map['currentCampId'] ?? '',
      historyLogs: List<EquipmentLog>.from(
        (map['historyLogs'] ?? []).map((e) => EquipmentLog.fromMap(e)),
      ),
      maintenanceRecords: List<EquipmentLog>.from(
        (map['maintenanceRecords'] ?? []).map((e) => EquipmentLog.fromMap(e)),
      ),
    );
  }
}
