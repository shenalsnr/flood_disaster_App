import 'package:flutter/foundation.dart';
import '../../data/models/relief_item_model.dart';
import '../../data/models/evacuee_model.dart';

class ReliefTrackingController extends ChangeNotifier {
  // Dr. Rohan Silva - Camp Info State
  String leaderName = "Dr. Rohan Silva";
  String leaderTitle = "RELIEF TRIAGE LEAD #04";
  String campName = "Camp Nēraya";
  int evacueeCount = 275;
  int maxCapacity = 300;
  bool isShelterClosed = false;

  // Rapid Headcount Actions (+1, +5, +10, -1)
  void updateHeadcount(int delta) {
    evacueeCount = (evacueeCount + delta).clamp(0, maxCapacity + 50);
    notifyListeners();
  }

  void toggleShelterStatus() {
    isShelterClosed = !isShelterClosed;
    notifyListeners();
  }

  // Inventory Items State (Matching Image 2 frame2)
  List<ReliefItemModel> inventoryItems = [
    const ReliefItemModel(
      id: 'inv_1',
      name: 'Infant Formula Milk Powder',
      category: SupplyCategory.food,
      quantity: 0,
      unit: 'Cans',
      minThreshold: 30,
      lastUpdated: 'Just now',
    ),
    const ReliefItemModel(
      id: 'inv_2',
      name: 'Drinking Water Jerry Cans (20L)',
      category: SupplyCategory.water,
      quantity: 15,
      unit: 'Cans',
      minThreshold: 50,
      lastUpdated: '10 mins ago',
    ),
    const ReliefItemModel(
      id: 'inv_3',
      name: 'Trauma & Suture Packs',
      category: SupplyCategory.medical,
      quantity: 45,
      unit: 'Packs',
      minThreshold: 15,
      lastUpdated: '25 mins ago',
    ),
    const ReliefItemModel(
      id: 'inv_4',
      name: 'Thermal Sleeping Blankets',
      category: SupplyCategory.shelter,
      quantity: 90,
      unit: 'Pieces',
      minThreshold: 40,
      lastUpdated: '3 hours ago',
    ),
  ];

  // Incoming Shipment Log (Matching Image 2 frame2)
  Map<String, dynamic> incomingShipment = {
    'title': 'Relief Supply Truck',
    'subtitle': 'Convoy B',
    'eta': 'ETA: 18 MINS',
    'progress': 0.65,
    'driverPhone': '+94 77 123 4567',
    'isRestocked': false,
  };

  void confirmRestock() {
    incomingShipment['isRestocked'] = true;
    // Boost stock values
    updateStockQuantity('inv_1', 40);
    updateStockQuantity('inv_2', 50);
    notifyListeners();
  }

  // Alerts List (Matching Image 3 alert d.)
  List<Map<String, dynamic>> alertList = [
    {
      'id': 'alt_1',
      'title': 'Infant Formula Milk Powder — Depleted',
      'subtitle': 'Camp Nēraya stock reached zero. Immediate resupply required.',
      'time': '2m ago',
      'type': 'critical',
      'actionText': 'DISPATCH SUPPLY',
      'isDismissed': false,
    },
    {
      'id': 'alt_2',
      'title': 'Shelter Capacity — Critical',
      'subtitle': 'Camp Dawn Ridge at 96% occupancy (288/300 beds).',
      'time': '18m ago',
      'type': 'critical',
      'actionText': 'VIEW SHELTER',
      'isDismissed': false,
    },
    {
      'id': 'alt_3',
      'title': 'Drinking Water Jerry Cans — Low Stock',
      'subtitle': 'Below 20L threshold at Camp Nēraya. Restock recommended.',
      'time': '41m ago',
      'type': 'low',
      'actionText': 'REQUEST SUPPLY',
      'isDismissed': false,
    },
    {
      'id': 'alt_4',
      'title': 'Resupply Dispatched — EMER-042',
      'subtitle': 'Transferred to DMC, medical crew notified. ETA 15 min.',
      'time': '1h ago',
      'type': 'logs',
      'actionText': 'VIEW LOG',
      'isDismissed': false,
    },
  ];

  void dismissAlert(String id) {
    alertList.removeWhere((a) => a['id'] == id);
    notifyListeners();
  }

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
  ];

  // Filtering State
  String selectedSupplyFilter = 'All'; // 'All' | 'Depleted' | 'Low' | 'Adequate'
  String selectedAlertFilter = 'All'; // 'All' | 'Critical' | 'Low Stock' | 'Logs'
  String inventorySearchQuery = '';

  List<ReliefItemModel> get filteredInventory {
    return inventoryItems.where((item) {
      bool matchesFilter = true;
      if (selectedSupplyFilter == 'Depleted') {
        matchesFilter = item.status == StockStatus.critical;
      } else if (selectedSupplyFilter == 'Low') {
        matchesFilter = item.status == StockStatus.low;
      } else if (selectedSupplyFilter == 'Adequate') {
        matchesFilter = item.status == StockStatus.adequate;
      }
      final matchesSearch = item.name.toLowerCase().contains(inventorySearchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get filteredAlerts {
    return alertList.where((alert) {
      if (selectedAlertFilter == 'Critical') {
        return alert['type'] == 'critical';
      } else if (selectedAlertFilter == 'Low Stock') {
        return alert['type'] == 'low';
      } else if (selectedAlertFilter == 'Logs') {
        return alert['type'] == 'logs';
      }
      return true;
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

  void setSupplyFilter(String filter) {
    selectedSupplyFilter = filter;
    notifyListeners();
  }

  void setAlertFilter(String filter) {
    selectedAlertFilter = filter;
    notifyListeners();
  }

  void setInventorySearchQuery(String query) {
    inventorySearchQuery = query;
    notifyListeners();
  }
}
