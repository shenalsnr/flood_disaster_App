import 'package:flutter/foundation.dart';
import '../../data/models/shelter_model.dart';
import '../../data/models/ration_item_model.dart';

/// Singleton Service managing Shelter and Relief Data.
/// Implements ChangeNotifier for reactive State Management.
class ShelterReliefService extends ChangeNotifier {
  // ----------------------------------------
  // Singleton Implementation
  // ----------------------------------------
  ShelterReliefService._privateConstructor();
  static final ShelterReliefService _instance = ShelterReliefService._privateConstructor();
  
  /// Access the globally available instance of ShelterReliefService.
  static ShelterReliefService get instance => _instance;

  // ----------------------------------------
  // State: Shelters
  // ----------------------------------------
  
  String? _selectedShelterId;
  
  /// The currently active shelter ID in the dashboard.
  String? get selectedShelterId => _selectedShelterId;

  final List<ShelterModel> _shelters = [];
  
  /// Unmodifiable view of the shelters list.
  List<ShelterModel> get shelters => List.unmodifiable(_shelters);

  // ----------------------------------------
  // State: Ration & Supply
  // ----------------------------------------
  
  final List<RationItemModel> _rationItems = [
    // Initial mock items as requested
    const RationItemModel(
      id: 'r1',
      shelterId: 's1', // Assumes 's1' is a valid shelter ID added later
      name: 'Baby Milk Formula',
      category: 'Baby Care',
      quantity: 50,
      unit: 'packets',
      thresholdLow: 20,
    ),
    const RationItemModel(
      id: 'r2',
      shelterId: 's1',
      name: 'Trauma Kit',
      category: 'Medical',
      quantity: 5,
      unit: 'kits',
      thresholdLow: 10,
    ),
    const RationItemModel(
      id: 'r3',
      shelterId: 's1',
      name: 'Drinking Water',
      category: 'Water',
      quantity: 500,
      unit: 'liters',
      thresholdLow: 100,
    ),
    const RationItemModel(
      id: 'r4',
      shelterId: 's1',
      name: 'Rice Packs',
      category: 'Food',
      quantity: 200,
      unit: 'kg',
      thresholdLow: 50,
    ),
  ];
  
  /// Unmodifiable view of the overall inventory.
  List<RationItemModel> get rationItems => List.unmodifiable(_rationItems);

  // ========================================
  // 1. Shelter Management (CRUD 1)
  // ========================================

  /// Adds a new shelter to the system.
  void addShelter(ShelterModel shelter) {
    _shelters.add(shelter);
    // Auto-select if it's the first shelter
    _selectedShelterId ??= shelter.id;
    notifyListeners();
  }

  /// Updates an existing shelter matching the [updatedShelter.id].
  void updateShelter(ShelterModel updatedShelter) {
    final index = _shelters.indexWhere((s) => s.id == updatedShelter.id);
    if (index != -1) {
      _shelters[index] = updatedShelter;
      notifyListeners();
    }
  }

  /// Deletes a shelter by its [id].
  void deleteShelter(String id) {
    _shelters.removeWhere((s) => s.id == id);
    // Reset selection if the active shelter was removed
    if (_selectedShelterId == id) {
      _selectedShelterId = _shelters.isNotEmpty ? _shelters.first.id : null;
    }
    notifyListeners();
  }

  /// Switches the currently active/selected shelter.
  void switchActiveShelter(String id) {
    if (_shelters.any((s) => s.id == id)) {
      _selectedShelterId = id;
      notifyListeners();
    }
  }

  /// Rapidly adjusts the headcount of the currently selected shelter.
  /// Safe against bounds: [0, totalBeds].
  /// [delta] can be positive (inflow) or negative (outflow).
  void updateHeadcount(int delta) {
    if (_selectedShelterId == null) return;
    
    final shelterIndex = _shelters.indexWhere((s) => s.id == _selectedShelterId);
    if (shelterIndex == -1) return;

    final shelter = _shelters[shelterIndex];
    
    // Calculate new occupancy cleanly and safely
    int newOccupancy = shelter.occupiedBeds + delta;
    newOccupancy = newOccupancy.clamp(0, shelter.totalBeds);
    
    _shelters[shelterIndex] = shelter.copyWith(occupiedBeds: newOccupancy);
    notifyListeners();
  }

  /// Toggles the open/closed status of a specific shelter.
  void toggleShelterStatus(String id) {
    final index = _shelters.indexWhere((s) => s.id == id);
    if (index != -1) {
      final shelter = _shelters[index];
      _shelters[index] = shelter.copyWith(isClosed: !shelter.isClosed);
      notifyListeners();
    }
  }

  // ========================================
  // 2. Ration & Supply Management (CRUD 2)
  // ========================================

  /// Fetches the inventory strictly belonging to [shelterId].
  List<RationItemModel> getItemsByShelter(String shelterId) {
    return _rationItems.where((item) => item.shelterId == shelterId).toList();
  }

  /// Adds a new ration/supply item to the inventory.
  void addRationItem(RationItemModel item) {
    _rationItems.add(item);
    notifyListeners();
  }

  /// Updates an existing ration item.
  void updateRationItem(RationItemModel updatedItem) {
    final index = _rationItems.indexWhere((i) => i.id == updatedItem.id);
    if (index != -1) {
      _rationItems[index] = updatedItem;
      notifyListeners();
    }
  }

  /// Deletes a specific ration item by its [id].
  void deleteRationItem(String id) {
    _rationItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  /// Quickly restocks a specific item by adding the provided [amount].
  void quickRestock(String itemId, int amount) {
    if (amount <= 0) return; // Prevent negative or zero restocking logic here
    
    final index = _rationItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final item = _rationItems[index];
      _rationItems[index] = item.copyWith(quantity: item.quantity + amount);
      notifyListeners();
    }
  }
}
