import 'package:flutter/material.dart';
import '../../data/models/relief_request_model.dart';

class ReliefRequestCard extends StatelessWidget {
  final ReliefRequestModel request;

  const ReliefRequestCard({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    Color urgencyColor;
    String urgencyLabel;

    switch (request.urgency) {
      case RequestUrgency.immediate:
        urgencyColor = const Color(0xFFFF5252);
        urgencyLabel = 'IMMEDIATE';
        break;
      case RequestUrgency.high:
        urgencyColor = const Color(0xFFFFAB40);
        urgencyLabel = 'HIGH PRIORITY';
        break;
      case RequestUrgency.routine:
        urgencyColor = const Color(0xFF69F0AE);
        urgencyLabel = 'ROUTINE';
        break;
    }

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (request.status) {
      case RequestStatus.pending:
        statusColor = Colors.orangeAccent;
        statusLabel = 'Pending Dispatch';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case RequestStatus.dispatched:
        statusColor = Colors.blueAccent;
        statusLabel = 'In Transit';
        statusIcon = Icons.local_shipping_outlined;
        break;
      case RequestStatus.delivered:
        statusColor = Colors.greenAccent;
        statusLabel = 'Delivered & Received';
        statusIcon = Icons.check_circle_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title & Urgency Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.itemTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  urgencyLabel,
                  style: TextStyle(
                    color: urgencyColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Requested qty & Requester
          Text(
            'Quantity: ${request.quantityRequested} • Requested by: ${request.requestedBy} at ${request.timestamp}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Status Stepper / Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  'ETA: ${request.eta}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
