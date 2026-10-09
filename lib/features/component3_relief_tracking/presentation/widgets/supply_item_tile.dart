import 'package:flutter/material.dart';
import '../../data/models/relief_item_model.dart';

class SupplyItemTile extends StatelessWidget {
  final ReliefItemModel item;
  final Function(double delta) onQuantityChanged;

  const SupplyItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color borderColor;
    String badgeText;

    switch (item.status) {
      case StockStatus.critical:
        statusColor = const Color(0xFFFF3B30);
        borderColor = const Color(0xFFFF3B30);
        badgeText = 'CRITICAL DEPLETED';
        break;
      case StockStatus.low:
        statusColor = const Color(0xFFFF9F0A);
        borderColor = const Color(0xFFFF9F0A);
        badgeText = 'LOW STOCK';
        break;
      case StockStatus.adequate:
        statusColor = const Color(0xFF30D158);
        borderColor = const Color(0xFF30D158);
        badgeText = 'ADEQUATE';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
