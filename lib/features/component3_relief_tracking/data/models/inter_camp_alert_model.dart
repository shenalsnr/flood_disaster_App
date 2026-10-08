import 'package:flutter/foundation.dart';

enum AlertType { request, dispatch, notification }
enum AlertStatus { pending, accepted, declined, completed }

class InterCampAlertModel {
  final String id;
  final String requestingCampId;
  final String requestingCampName;
  final String respondingCampId;
  final String requiredItems;
  final AlertType type;
  final AlertStatus status;
  final String timestamp;
  
  // Dispatch details (if type is dispatch)
  final String? driverName;
  final String? driverContact;
  final String? dispatchedItems;
  final int? dispatchedQuantity;
  final String? vehicleType;

  const InterCampAlertModel({
    required this.id,
    required this.requestingCampId,
    required this.requestingCampName,
    required this.respondingCampId,
    required this.requiredItems,
    required this.type,
    required this.status,
    required this.timestamp,
    this.driverName,
    this.driverContact,
    this.dispatchedItems,
    this.dispatchedQuantity,
    this.vehicleType,
  });

  InterCampAlertModel copyWith({
    String? id,
    String? requestingCampId,
    String? requestingCampName,
    String? respondingCampId,
    String? requiredItems,
    AlertType? type,
    AlertStatus? status,
    String? timestamp,
    String? driverName,
    String? driverContact,
    String? dispatchedItems,
    int? dispatchedQuantity,
    String? vehicleType,
  }) {
    return InterCampAlertModel(
      id: id ?? this.id,
      requestingCampId: requestingCampId ?? this.requestingCampId,
      requestingCampName: requestingCampName ?? this.requestingCampName,
      respondingCampId: respondingCampId ?? this.respondingCampId,
      requiredItems: requiredItems ?? this.requiredItems,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      driverName: driverName ?? this.driverName,
      driverContact: driverContact ?? this.driverContact,
      dispatchedItems: dispatchedItems ?? this.dispatchedItems,
      dispatchedQuantity: dispatchedQuantity ?? this.dispatchedQuantity,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestingCampId': requestingCampId,
      'requestingCampName': requestingCampName,
      'respondingCampId': respondingCampId,
      'requiredItems': requiredItems,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp,
      'driverName': driverName,
      'driverContact': driverContact,
      'dispatchedItems': dispatchedItems,
      'dispatchedQuantity': dispatchedQuantity,
      'vehicleType': vehicleType,
    };
  }

  factory InterCampAlertModel.fromMap(Map<String, dynamic> map) {
    return InterCampAlertModel(
      id: map['id'] ?? '',
      requestingCampId: map['requestingCampId'] ?? '',
      requestingCampName: map['requestingCampName'] ?? '',
      respondingCampId: map['respondingCampId'] ?? '',
      requiredItems: map['requiredItems'] ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.notification,
      ),
      status: AlertStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AlertStatus.pending,
      ),
      timestamp: map['timestamp'] ?? '',
      driverName: map['driverName'],
      driverContact: map['driverContact'],
      dispatchedItems: map['dispatchedItems'],
      dispatchedQuantity: map['dispatchedQuantity'],
      vehicleType: map['vehicleType'],
    );
  }
}
