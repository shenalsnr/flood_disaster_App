import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../domain/services/shelter_relief_service.dart';
import '../../data/models/ration_item_model.dart';
import 'add_edit_ration_screen.dart';

enum InventoryFilter { all, depleted, low, adequate }

/// Supplies Log Screen
class RationInventoryScreen extends StatefulWidget {
  final bool isEmbedded;
  const RationInventoryScreen({super.key, this.isEmbedded = false});

  @override
  State<RationInventoryScreen> createState() => _RationInventoryScreenState();
}

class _RationInventoryScreenState extends State<RationInventoryScreen> {
  final ShelterReliefService _service = ShelterReliefService.instance;
  InventoryFilter _selectedFilter = InventoryFilter.all;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdate);
  }
  
  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    super.dispose();
  }
  
  void _onUpdate() => setState(() {});

  List<RationItemModel> _getFilteredItems(String shelterId) {
    final allItems = _service.getItemsByShelter(shelterId);
    switch (_selectedFilter) {
      case InventoryFilter.depleted:
        return allItems.where((i) => i.status == SupplyStatus.depleted).toList();
      case InventoryFilter.low:
        return allItems.where((i) => i.status == SupplyStatus.low).toList();
      case InventoryFilter.adequate:
        return allItems.where((i) => i.status == SupplyStatus.adequate).toList();
      case InventoryFilter.all:
        return allItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeShelterId = _service.selectedShelterId;
    final allItems = activeShelterId != null ? _service.getItemsByShelter(activeShelterId) : <RationItemModel>[];
    final items = activeShelterId != null ? _getFilteredItems(activeShelterId) : <RationItemModel>[];

    final numDepleted = allItems.where((i) => i.status == SupplyStatus.depleted).length;
    final numLow = allItems.where((i) => i.status == SupplyStatus.low).length;
    final numAdequate = allItems.where((i) => i.status == SupplyStatus.adequate).length;

    return Scaffold(
      backgroundColor: ShelterTheme.backgroundDeepNavy,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('RATION & MEDICAL LOG', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditRationScreen()));
                    },
                    icon: const Icon(Icons.add, color: ShelterTheme.primaryActionOrange, size: 16),
                    label: const Text('Add Item', style: TextStyle(color: ShelterTheme.primaryActionOrange)),
                  ),
                ],
              ),
            ),
            
            // FILTER CHIPS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCustomChip('All (${allItems.length})', InventoryFilter.all, Colors.white, Colors.black),
                  const SizedBox(width: 8),
                  _buildCustomChip('Depleted ($numDepleted)', InventoryFilter.depleted, ShelterTheme.statusCriticalRed, Colors.white, true),
                  const SizedBox(width: 8),
                  _buildCustomChip('Low ($numLow)', InventoryFilter.low, ShelterTheme.statusWarningYellow, ShelterTheme.statusWarningYellow, true),
                  const SizedBox(width: 8),
                  _buildCustomChip('Adequate ($numAdequate)', InventoryFilter.adequate, ShelterTheme.statusSafeGreen, ShelterTheme.statusSafeGreen, true),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // LIST OF ITEMS
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildItemCard(item);
                },
              ),
            ),
            
            // FLOATING TRUCK CARD (Mock)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShelterTheme.surfaceDarkNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ShelterTheme.surfaceLightNavy),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, color: ShelterTheme.statusSafeGreen),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Relief Supply Truck', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Convoy #1', style: TextStyle(color: ShelterTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ShelterTheme.statusSafeGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('ETA: 15 MINS', style: TextStyle(color: ShelterTheme.statusSafeGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.call, color: Colors.white, size: 16),
                          label: const Text('Call Driver', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: ShelterTheme.surfaceLightNavy),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Confirm Restock', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.isEmbedded ? null : BottomNavigationBar(
        backgroundColor: ShelterTheme.surfaceDarkNavy,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ShelterTheme.primaryActionOrange,
        unselectedItemColor: ShelterTheme.textMuted,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Supplies'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Team'),
        ],
        currentIndex: 1, // Supplies tab is active
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildCustomChip(String label, InventoryFilter filter, Color color, Color textColor, [bool isOutlined = false]) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected && !isOutlined ? color : (isSelected ? color.withValues(alpha: 0.1) : Colors.transparent),
          border: Border.all(color: isSelected ? color : ShelterTheme.surfaceLightNavy),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (isOutlined ? color : textColor) : ShelterTheme.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(RationItemModel item) {
    final isDepleted = item.status == SupplyStatus.depleted;
    final isLow = item.status == SupplyStatus.low;
    
    Color badgeColor = ShelterTheme.statusSafeGreen;
    String badgeText = 'ADEQUATE';
    if (isDepleted) {
      badgeColor = ShelterTheme.statusCriticalRed;
      badgeText = 'CRITICAL DEPLETED';
    } else if (isLow) {
      badgeColor = ShelterTheme.statusWarningYellow;
      badgeText = 'LOW STOCK';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShelterTheme.surfaceDarkNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShelterTheme.surfaceLightNavy),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDepleted ? badgeColor.withValues(alpha: 0.2) : Colors.transparent,
              border: Border.all(color: badgeColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
