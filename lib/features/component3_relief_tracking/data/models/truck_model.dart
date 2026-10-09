
enum TruckStatus { standingBy, enRoute, atDestination, returning }

class Waypoint {
  final double latitude;
  final double longitude;
  final String timestamp;

  const Waypoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }

  factory Waypoint.fromMap(Map<String, dynamic> map) {
    return Waypoint(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] ?? '',
    );
  }
}

class TruckModel {
  final String id;
  final String vehicleNumber;
  final String truckType;
  final double currentLat;
  final double currentLng;
  final String destinationCampId;
  final TruckStatus status;
  final String assignedOperation;
  final String cargoPayloadDetails;
  final String departureTime;
  final String estimatedEta;
  final String? actualArrivalTime;
  final List<Waypoint> routeHistory;

  const TruckModel({
    required this.id,
    required this.vehicleNumber,
    required this.truckType,
    required this.currentLat,
    required this.currentLng,
    required this.destinationCampId,
    required this.status,
    required this.assignedOperation,
    required this.cargoPayloadDetails,
    required this.departureTime,
    required this.estimatedEta,
    this.actualArrivalTime,
    required this.routeHistory,
  });

  TruckModel copyWith({
    String? id,
    String? vehicleNumber,
    String? truckType,
    double? currentLat,
    double? currentLng,
    String? destinationCampId,
    TruckStatus? status,
    String? assignedOperation,
    String? cargoPayloadDetails,
    String? departureTime,
    String? estimatedEta,
    String? actualArrivalTime,
    List<Waypoint>? routeHistory,
  }) {
    return TruckModel(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      truckType: truckType ?? this.truckType,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      destinationCampId: destinationCampId ?? this.destinationCampId,
      status: status ?? this.status,
      assignedOperation: assignedOperation ?? this.assignedOperation,
      cargoPayloadDetails: cargoPayloadDetails ?? this.cargoPayloadDetails,
      departureTime: departureTime ?? this.departureTime,
      estimatedEta: estimatedEta ?? this.estimatedEta,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      routeHistory: routeHistory ?? this.routeHistory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleNumber': vehicleNumber,
      'truckType': truckType,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'destinationCampId': destinationCampId,
      'status': status.name,
      'assignedOperation': assignedOperation,
      'cargoPayloadDetails': cargoPayloadDetails,
      'departureTime': departureTime,
      'estimatedEta': estimatedEta,
      'actualArrivalTime': actualArrivalTime,
      'routeHistory': routeHistory.map((w) => w.toMap()).toList(),
    };
  }

  factory TruckModel.fromMap(Map<String, dynamic> map) {
    return TruckModel(
      id: map['id'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      truckType: map['truckType'] ?? '',
      currentLat: map['currentLat']?.toDouble() ?? 0.0,
      currentLng: map['currentLng']?.toDouble() ?? 0.0,
      destinationCampId: map['destinationCampId'] ?? '',
      status: TruckStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TruckStatus.standingBy,
      ),
      assignedOperation: map['assignedOperation'] ?? '',
      cargoPayloadDetails: map['cargoPayloadDetails'] ?? '',
      departureTime: map['departureTime'] ?? '',
      estimatedEta: map['estimatedEta'] ?? '',
      actualArrivalTime: map['actualArrivalTime'],
      routeHistory: List<Waypoint>.from(
        (map['routeHistory'] ?? []).map((w) => Waypoint.fromMap(w)),
      ),
    );
  }
}
