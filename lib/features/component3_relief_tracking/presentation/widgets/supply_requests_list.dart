import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/services/firestore_service.dart';

import '../../../../core/localization/app_strings.dart';
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
        final allMine = snapshot.data!.docs
            .where((d) =>
                d.data()['campId'] == widget.campId &&
                d.data()['hiddenByCamp'] != true)
            .toList();
        final mine = allMine.take(5).toList();
        if (mine.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(
                  tr('SENT TO DMC'),
                  style: TextStyle(
                    color: Color(0xFF8A98B0),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                )),
                Flexible(child: GestureDetector(
                  onTap: () => _confirmClear(allMine.map((d) => d.id).toList()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: Color(0xFFF87171), size: 16),
                      SizedBox(width: 4),
                      Text(
                        tr('CLEAR'),
                        style: TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
            const SizedBox(height: 10),
            ...mine.map((d) => _buildTile(d.data())),
          ],
        );
      },
    );
  }

  Future<void> _confirmClear(List<String> docIds) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1220),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1C2740)),
        ),
        title: Text(
          tr('Clear this list?'),
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Text(
          tr('The requests are removed from this list only. The DMC keeps its own records, and any truck on the way will still be shown.'),
          style: TextStyle(color: Color(0xFFB6C2D6), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel'), style: TextStyle(color: Color(0xFFB6C2D6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44), 
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(tr('Clear')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      // The list updates at once from the local copy; the server catches up
      // in the background when there is a connection.
      FirestoreService.instance
          .hideDmcRequestsForCamp(docIds)
          .catchError((Object e) => debugPrint('Clear failed: $e'));
    } catch (e) {
      debugPrint('Clear failed: $e');
    }
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

    final statusColor = resolved ? const Color(0xFF34D399) : const Color(0xFFFB923C);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C2740)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(itemName),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(tr(detail), style: const TextStyle(color: Color(0xFFB6C2D6), fontSize: 11)),
              ],
            ),
          ),
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              resolved ? tr('DONE') : tr('PENDING'),
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )),
        ],
      ),
    );
  }

  /// 50.0 -> "50", 2.5 -> "2.5"
  String _trim(num n) =>
      n == n.roundToDouble() ? n.round().toString() : n.toString();
}
