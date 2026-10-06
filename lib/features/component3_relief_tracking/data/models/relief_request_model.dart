enum RequestUrgency {
  immediate,
  high,
  routine,
}

enum RequestStatus {
  pending,
  dispatched,
  delivered,
}

class ReliefRequestModel {
  final String id;
  final String itemTitle;
  final String quantityRequested;
  final RequestUrgency urgency;
  final RequestStatus status;
  final String requestedBy;
  final String timestamp;
  final String eta;

  const ReliefRequestModel({
    required this.id,
    required this.itemTitle,
    required this.quantityRequested,
    required this.urgency,
    required this.status,
    required this.requestedBy,
    required this.timestamp,
    required this.eta,
  });

  ReliefRequestModel copyWith({
    String? id,
    String? itemTitle,
    String? quantityRequested,
    RequestUrgency? urgency,
    RequestStatus? status,
    String? requestedBy,
    String? timestamp,
    String? eta,
  }) {
    return ReliefRequestModel(
      id: id ?? this.id,
      itemTitle: itemTitle ?? this.itemTitle,
      quantityRequested: quantityRequested ?? this.quantityRequested,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      requestedBy: requestedBy ?? this.requestedBy,
      timestamp: timestamp ?? this.timestamp,
      eta: eta ?? this.eta,
    );
  }
}
