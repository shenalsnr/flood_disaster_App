import 'package:flutter/material.dart';
import '../../../../core/theme/shelter_theme.dart';
import '../../domain/services/shelter_relief_service.dart';
import '../../data/models/ration_item_model.dart';
import 'add_edit_ration_screen.dart';

enum InventoryFilter { all, depleted, low, adequate }

/// Screen to track and manage rations and supplies for the active shelter.
class RationInventoryScreen extends StatefulWidget {
  const RationInventoryScreen({super.key});

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

  Color _getStatusColor(SupplyStatus status) {
    switch (status) {
      case SupplyStatus.depleted: return ShelterTheme.statusCriticalRed;
      case SupplyStatus.low: return ShelterTheme.statusWarningYellow;
      case SupplyStatus.adequate: return ShelterTheme.statusSafeGreen;
    }
  }

  String _getStatusText(SupplyStatus status) {
    switch (status) {
      case SupplyStatus.depleted: return 'DEPLETED';
      case SupplyStatus.low: return 'LOW';
      case SupplyStatus.adequate: return 'ADEQUATE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeShelterId = _service.selectedShelterId;
    final items = activeShelterId != null ? _getFilteredItems(activeShelterId) : <RationItemModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ration & Supply Tracker'),
      ),
      body: activeShelterId == null 
          ? const Center(child: Text('No active shelter selected.', style: TextStyle(color: ShelterTheme.textHighContrastWhite)))
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: items.isEmpty 
                      ? const Center(child: Text('No items match this filter.', style: TextStyle(color: ShelterTheme.textMuted)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildDismissibleItem(item);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: activeShelterId != null ? FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditRationScreen()));
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: InventoryFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.name.toUpperCase()),
              selected: isSelected,
              selectedColor: ShelterTheme.primaryActionOrange,
              backgroundColor: ShelterTheme.surfaceDarkNavy,
              labelStyle: TextStyle(
                color: isSelected ? ShelterTheme.textHighContrastWhite : ShelterTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDismissibleItem(RationItemModel item) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ShelterTheme.statusSafeGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          children: [
            Icon(Icons.add_shopping_cart, color: Colors.white),
            SizedBox(width: 8),
            Text('QUICK RESTOCK +10', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ShelterTheme.statusCriticalRed,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right: Quick Restock
          _service.quickRestock(item.id, 10);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restocked 10 ${item.unit} of ${item.name}')));
          return false; // Don't actually dismiss the widget
        } else {
          // Swipe Left: Delete
          return true;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _service.deleteRationItem(item.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} deleted')));
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(item.name, style: const TextStyle(color: ShelterTheme.textHighContrastWhite, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(item.category, style: const TextStyle(color: ShelterTheme.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(item.status),
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.quantity}', style: const TextStyle(color: ShelterTheme.textHighContrastWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(item.unit, style: const TextStyle(color: ShelterTheme.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, color: ShelterTheme.textMuted),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditRationScreen(existingItem: item)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
