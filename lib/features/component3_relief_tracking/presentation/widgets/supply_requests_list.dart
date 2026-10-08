import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/services/firestore_service.dart';

/// Shows the latest requests and alerts this camp has sent to the DMC,
/// with their status, so the Camp Leader can see that a request went through.
class SupplyRequestsList extends StatefulWidget {
  final String campId;

  const SupplyRequestsList({super.key, required this.campId});

  @override
  State<SupplyRequestsList> createState() => _SupplyRequestsListState();
}

class _SupplyRequestsListState extends State<SupplyRequestsList> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    try {
      _stream = FirestoreService.instance.streamDmcDispatchRequests();
    } catch (_) {
      _stream = null; // Firebase unavailable: simply show nothing
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    if (stream == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final mine = snapshot.data!.docs
            .where((d) => d.data()['campId'] == widget.campId)
            .take(5)
            .toList();
        if (mine.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SENT TO DMC',
              style: TextStyle(
                color: Color(0xFF7E8B9B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            ...mine.map((d) => _buildTile(d.data())),
          ],
        );
      },
    );
  }

  Widget _buildTile(Map<String, dynamic> data) {
    final trigger = (data['trigger'] ?? '').toString();
    final itemName = (data['itemName'] ?? 'Supply').toString();
    final unit = (data['unit'] ?? '').toString();
    final resolved = data['status'] == 'resolved';

    String detail;
    if (trigger == 'request') {
      final qty = data['quantityRequested'];
      final urgency = (data['urgency'] ?? '').toString();
      final qtyText = qty is num ? _trim(qty) : '';
      detail = 'Request: need $qtyText $unit'.trim() +
          (urgency.isEmpty ? '' : ' • ${urgency.toUpperCase()}');
    } else if (trigger == 'auto') {
      detail = 'Auto alert: stock ran out';
    } else {
      detail = 'Urgent dispatch: stock ran out';
    }

    final statusColor = resolved ? const Color(0xFF30D158) : const Color(0xFFFF9F0A);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E283D)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(detail, style: const TextStyle(color: Color(0xFF8E9BAE), fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              resolved ? 'DONE' : 'PENDING',
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// 50.0 -> "50", 2.5 -> "2.5"
  String _trim(num n) =>
      n == n.roundToDouble() ? n.round().toString() : n.toString();
}
