import 'package:flutter/material.dart';
import '../../data/models/relief_item_model.dart';

class SupplyItemTile extends StatelessWidget {
  final ReliefItemModel item;
  final Function(double delta) onQuantityChanged;
  final Function(bool inStock)? onToggleStock;

  const SupplyItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    this.onToggleStock,
  });

  IconData _getCategoryIcon(SupplyCategory category) {
    switch (category) {
      case SupplyCategory.water:
        return Icons.water_drop_outlined;
      case SupplyCategory.food:
        return Icons.fastfood_outlined;
      case SupplyCategory.medical:
        return Icons.medication_outlined;
      case SupplyCategory.shelter:
        return Icons.bed_outlined;
      case SupplyCategory.hygiene:
        return Icons.sanitizer_outlined;
      case SupplyCategory.other:
        return Icons.inventory_2_outlined;
    }
  }

  Color _getCategoryColor(SupplyCategory category) {
    switch (category) {
      case SupplyCategory.water:
        return Colors.blueAccent;
      case SupplyCategory.food:
        return Colors.orangeAccent;
      case SupplyCategory.medical:
        return Colors.redAccent;
      case SupplyCategory.shelter:
        return Colors.amberAccent;
      case SupplyCategory.hygiene:
        return Colors.tealAccent;
      case SupplyCategory.other:
        return Colors.purpleAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(item.category);
    Color statusColor;
    String statusLabel;

    switch (item.status) {
      case StockStatus.critical:
        statusColor = const Color(0xFFFF5252);
        statusLabel = 'CRITICAL EMPTY';
        break;
      case StockStatus.low:
        statusColor = const Color(0xFFFFAB40);
        statusLabel = 'LOW STOCK';
        break;
      case StockStatus.adequate:
        statusColor = const Color(0xFF69F0AE);
        statusLabel = 'IN STOCK';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.status == StockStatus.critical
              ? statusColor.withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          // Category Icon Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getCategoryIcon(item.category), color: catColor, size: 22),
          ),
          const SizedBox(width: 10),

          // Supply Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Min: ${item.minThreshold.toInt()} ${item.unit}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // FR8 Coarse Toggle Switch & Quantity Modifiers
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.remove_circle_outline, color: Colors.white54, size: 20),
                onPressed: () => onQuantityChanged(-5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 20),
                onPressed: () => onQuantityChanged(5),
              ),
              if (onToggleStock != null) ...[
                const SizedBox(width: 4),
                Switch(
                  value: item.status != StockStatus.critical,
                  activeThumbColor: Colors.greenAccent,
                  activeTrackColor: Colors.greenAccent.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.redAccent,
                  inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.3),
                  onChanged: onToggleStock,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
