import 'package:flutter/foundation.dart';
import '../../data/models/shelter_model.dart';
import '../../data/models/ration_item_model.dart';
import '../../data/models/equipment_model.dart';
import '../../data/models/truck_model.dart';
import '../../data/models/inter_camp_alert_model.dart';
import '../../data/models/chat_message_model.dart';

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

  // State: Equipment
  final List<EquipmentModel> _equipments = [
    EquipmentModel(
      id: 'eq1',
      name: 'Water Pump 500W',
      status: EquipmentStatus.available,
      condition: EquipmentCondition.good,
      currentCampId: 's1',
      historyLogs: [],
      maintenanceRecords: [],
    ),
    EquipmentModel(
      id: 'eq2',
      name: 'Heavy Duty Generator',
      status: EquipmentStatus.assigned,
      condition: EquipmentCondition.excellent,
      currentCampId: 's2',
      historyLogs: [],
      maintenanceRecords: [],
    ),
  ];
  List<EquipmentModel> get equipments => List.unmodifiable(_equipments);

  // State: Trucks
  final List<TruckModel> _trucks = [
    TruckModel(
      id: 'tr1',
      vehicleNumber: 'WP-LL-4598',
      truckType: '4x4 Heavy Truck',
      currentLat: 6.9271,
      currentLng: 79.8612,
      destinationCampId: 's1',
      status: TruckStatus.enRoute,
      assignedOperation: 'Relief Convoy #1',
      cargoPayloadDetails: '500L Water, Medical Kits',
      departureTime: '12:00 PM',
      estimatedEta: '18 Mins',
      routeHistory: [],
    )
  ];
  List<TruckModel> get trucks => List.unmodifiable(_trucks);

  // State: Alerts
  final List<InterCampAlertModel> _interCampAlerts = [];
  List<InterCampAlertModel> get interCampAlerts => List.unmodifiable(_interCampAlerts);

  // State: Chat
  final List<ChatMessageModel> _chatMessages = [
    const ChatMessageModel(
      id: 'c1', senderName: 'Nadeesha1', senderCampId: 'camp2', text: 'Water levels rising near Gate B. We need sandbags urgently.', timestamp: '12:41', isSelf: false, avatarInitials: 'N', status: MessageStatus.delivered
    ),
    const ChatMessageModel(
      id: 'c2', senderName: 'Priyala', senderCampId: 'camp3', text: 'Convoy 3 is 10 mins out with water + formula. Hang tight.', timestamp: '12:42', isSelf: false, avatarInitials: 'P', status: MessageStatus.delivered
    ),
  ];
  List<ChatMessageModel> get chatMessages => List.unmodifiable(_chatMessages);

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

  // ========================================
  // 3. Equipment Tracking
  // ========================================
  void addEquipment(EquipmentModel equipment) {
    _equipments.add(equipment);
    notifyListeners();
  }

  void updateEquipment(EquipmentModel updated) {
    final index = _equipments.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _equipments[index] = updated;
      notifyListeners();
    }
  }

  void deleteEquipment(String id) {
    _equipments.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ========================================
  // 4. Truck Tracking
  // ========================================
  void addTruck(TruckModel truck) {
    _trucks.add(truck);
    notifyListeners();
  }

  void updateTruck(TruckModel updated) {
    final index = _trucks.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _trucks[index] = updated;
      notifyListeners();
    }
  }

  void deleteTruck(String id) {
    _trucks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ========================================
  // 5. Inter-Camp Alerts & Dispatches
  // ========================================
  void addAlert(InterCampAlertModel alert) {
    _interCampAlerts.insert(0, alert);
    notifyListeners();
  }

  void updateAlertStatus(String id, AlertStatus status) {
    final index = _interCampAlerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _interCampAlerts[index] = _interCampAlerts[index].copyWith(status: status);
      notifyListeners();
    }
  }
  
  void handleDispatchAction(InterCampAlertModel alert, InterCampAlertModel dispatchDetails) {
    final index = _interCampAlerts.indexWhere((a) => a.id == alert.id);
    if (index != -1) {
      _interCampAlerts[index] = dispatchDetails;
      notifyListeners();
    }
  }

  // ========================================
  // 6. Chat Messages
  // ========================================
  void addChatMessage(ChatMessageModel message) {
    _chatMessages.add(message);
    notifyListeners();
  }
}

