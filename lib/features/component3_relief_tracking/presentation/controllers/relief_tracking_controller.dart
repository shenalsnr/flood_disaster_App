import 'package:flutter/foundation.dart';
import '../../data/models/relief_item_model.dart';
import '../../data/models/evacuee_model.dart';
import '../../data/models/relief_request_model.dart';

class ReliefTrackingController extends ChangeNotifier {
  // Camp Info State
  String campName = "Rathnapura Central Shelter";
  int evacueeCount = 185;
  int maxCapacity = 250;
  int medicalStaffCount = 6;

  // Inventory State
  List<ReliefItemModel> inventoryItems = [
    const ReliefItemModel(
      id: 'inv_1',
      name: 'Clean Drinking Water',
      category: SupplyCategory.water,
      quantity: 45,
      unit: 'Liters',
      minThreshold: 200,
      lastUpdated: '10 mins ago',
    ),
    const ReliefItemModel(
      id: 'inv_2',
      name: 'First Aid Medical Kits',
      category: SupplyCategory.medical,
      quantity: 12,
      unit: 'Units',
      minThreshold: 10,
      lastUpdated: '25 mins ago',
    ),
    const ReliefItemModel(
      id: 'inv_3',
      name: 'Baby Infant Formula',
      category: SupplyCategory.food,
      quantity: 5,
      unit: 'Cans',
      minThreshold: 30,
      lastUpdated: 'Just now',
    ),
    const ReliefItemModel(
      id: 'inv_4',
      name: 'Dry Rations / Rice Bags',
      category: SupplyCategory.food,
      quantity: 120,
      unit: 'Kg',
      minThreshold: 50,
      lastUpdated: '1 hour ago',
    ),
    const ReliefItemModel(
      id: 'inv_5',
      name: 'Thermal Blankets',
      category: SupplyCategory.shelter,
      quantity: 90,
      unit: 'Pieces',
      minThreshold: 40,
      lastUpdated: '3 hours ago',
    ),
    const ReliefItemModel(
      id: 'inv_6',
      name: 'Sanitary & Hygiene Packs',
      category: SupplyCategory.hygiene,
      quantity: 18,
      unit: 'Packs',
      minThreshold: 50,
      lastUpdated: '30 mins ago',
    ),
  ];

  // Evacuee State
  List<EvacueeModel> evacuees = [
    const EvacueeModel(
      id: 'evac_1',
      fullName: 'Kamal Perera',
      age: 62,
      gender: 'Male',
      triage: TriagePriority.red,
      specialNeeds: 'Insulin dependent & High Blood Pressure',
      checkInTime: '08:30 AM Today',
      assignedZone: 'Zone A - Medical Tent 2',
    ),
    const EvacueeModel(
      id: 'evac_2',
      fullName: 'Nimali Fernando',
      age: 28,
      gender: 'Female',
      triage: TriagePriority.yellow,
      specialNeeds: 'Infant care (3 months old baby)',
      checkInTime: '09:15 AM Today',
      assignedZone: 'Zone B - Family Hall 1',
    ),
    const EvacueeModel(
      id: 'evac_3',
      fullName: 'Sunil Jayasinghe',
      age: 45,
      gender: 'Male',
      triage: TriagePriority.green,
      specialNeeds: 'None',
      checkInTime: '10:00 AM Today',
      assignedZone: 'Zone C - Main Hall',
    ),
    const EvacueeModel(
      id: 'evac_4',
      fullName: 'Dilani Silva',
      age: 74,
      gender: 'Female',
      triage: TriagePriority.red,
      specialNeeds: 'Wheelchair assistance required',
      checkInTime: '11:20 AM Today',
      assignedZone: 'Zone A - Medical Tent 1',
    ),
    const EvacueeModel(
      id: 'evac_5',
      fullName: 'Kasun Wickramasinghe',
      age: 14,
      gender: 'Male',
      triage: TriagePriority.green,
      specialNeeds: 'None',
      checkInTime: '12:05 PM Today',
      assignedZone: 'Zone C - Main Hall',
    ),
  ];

  // Supply Requests State
  List<ReliefRequestModel> reliefRequests = [
    const ReliefRequestModel(
      id: 'req_101',
      itemTitle: 'Emergency Water Container Truck',
      quantityRequested: '1,000 Liters',
      urgency: RequestUrgency.immediate,
      status: RequestStatus.dispatched,
      requestedBy: 'Camp Logistics Officer',
      timestamp: '09:00 AM',
      eta: '20 Mins',
    ),
    const ReliefRequestModel(
      id: 'req_102',
      itemTitle: 'Infant Formula & Diapers Batch',
      quantityRequested: '50 Boxes',
      urgency: RequestUrgency.high,
      status: RequestStatus.pending,
      requestedBy: 'Medical Volunteer',
      timestamp: '11:15 AM',
      eta: 'Pending Dispatch',
    ),
    const ReliefRequestModel(
      id: 'req_103',
      itemTitle: 'First Aid Refill Bundles',
      quantityRequested: '20 Bundles',
      urgency: RequestUrgency.routine,
      status: RequestStatus.delivered,
      requestedBy: 'Dr. Bandara',
      timestamp: 'Yesterday',
      eta: 'Delivered',
    ),
  ];

  // Filtering State
  SupplyCategory? selectedInventoryCategory;
  TriagePriority? selectedTriageFilter;
  String inventorySearchQuery = '';
  String evacueeSearchQuery = '';

  // Getters for filtered items
  List<ReliefItemModel> get filteredInventory {
    return inventoryItems.where((item) {
      final matchesCategory = selectedInventoryCategory == null || item.category == selectedInventoryCategory;
      final matchesSearch = item.name.toLowerCase().contains(inventorySearchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<EvacueeModel> get filteredEvacuees {
    return evacuees.where((e) {
      final matchesTriage = selectedTriageFilter == null || e.triage == selectedTriageFilter;
      final matchesSearch = e.fullName.toLowerCase().contains(evacueeSearchQuery.toLowerCase()) ||
          e.assignedZone.toLowerCase().contains(evacueeSearchQuery.toLowerCase());
      return matchesTriage && matchesSearch;
    }).toList();
  }

  // Stock Actions
  void updateStockQuantity(String id, double delta) {
    final index = inventoryItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final current = inventoryItems[index];
      final newQty = (current.quantity + delta).clamp(0.0, 9999.0);
      inventoryItems[index] = current.copyWith(
        quantity: newQty,
        lastUpdated: 'Just now',
      );
      notifyListeners();
    }
  }

  void addInventoryItem(ReliefItemModel item) {
    inventoryItems.insert(0, item);
    notifyListeners();
  }

  // Evacuee Actions
  void registerEvacuee(EvacueeModel evacuee) {
    evacuees.insert(0, evacuee);
    evacueeCount += 1;
    notifyListeners();
  }

  void updateEvacueeTriage(String id, TriagePriority newTriage) {
    final index = evacuees.indexWhere((e) => e.id == id);
    if (index != -1) {
      evacuees[index] = evacuees[index].copyWith(triage: newTriage);
      notifyListeners();
    }
  }

  // Request Actions
  void addReliefRequest(ReliefRequestModel request) {
    reliefRequests.insert(0, request);
    notifyListeners();
  }

  // Filter setters
  void setInventoryCategory(SupplyCategory? category) {
    selectedInventoryCategory = category;
    notifyListeners();
  }

  void setTriageFilter(TriagePriority? priority) {
    selectedTriageFilter = priority;
    notifyListeners();
  }

  void setInventorySearchQuery(String query) {
    inventorySearchQuery = query;
    notifyListeners();
  }

  void setEvacueeSearchQuery(String query) {
    evacueeSearchQuery = query;
    notifyListeners();
  }
}
