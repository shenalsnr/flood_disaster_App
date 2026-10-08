import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../data/models/relief_item_model.dart';
import '../../data/models/evacuee_model.dart';
import '../../data/services/firestore_service.dart';

class ReliefTrackingController extends ChangeNotifier {
  ReliefTrackingController() {
    _startSync();
  }

  // Dr. Rohan Silva - Camp Info State
  String leaderName = "Dr. Rohan Silva";
  String leaderTitle = "RELIEF TRIAGE LEAD #04";
  String campName = "Camp Nēraya";
  int evacueeCount = 275;
  int maxCapacity = 300;
  bool isShelterClosed = false;

  // --------------------------------------------------------
  // Real-time sync (FR9): headcount, open/closed and inventory
  // are mirrored to Firestore so every device sees the same data.
  // --------------------------------------------------------
  static const String campId = 'camp_neraya';

  /// True once the latest data came from the server (not only the local cache).
  bool isSynced = false;

  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _itemsSub;
  bool _itemsSeeded = false;
  final Map<String, int> _orderKeys = {};

  void _startSync() {
    try {
      final fs = FirestoreService.instance;

      _statusSub = fs.streamCampStatus(campId).listen((snap) {
        if (!snap.exists) {
          // First run: publish the starting values once.
          if (!snap.metadata.isFromCache) _pushStatus();
          return;
        }
        // Our own not-yet-confirmed write is already applied locally.
        if (snap.metadata.hasPendingWrites) return;
        final data = snap.data();
        if (data == null) return;
        evacueeCount = (data['evacueeCount'] as num?)?.toInt() ?? evacueeCount;
        maxCapacity = (data['maxCapacity'] as num?)?.toInt() ?? maxCapacity;
        isShelterClosed = (data['isShelterClosed'] as bool?) ?? isShelterClosed;
        isSynced = !snap.metadata.isFromCache;
        notifyListeners();
      }, onError: (Object e) {
        debugPrint('Camp status sync error: $e');
        isSynced = false;
        notifyListeners();
      });

      _itemsSub = fs.streamCampSupplyItems(campId).listen((snap) {
        if (snap.docs.isEmpty) {
          if (!snap.metadata.isFromCache) _seedItems();
          return;
        }
        if (snap.metadata.hasPendingWrites) return;
        final remote = snap.docs
            .map((d) => _itemFromMap(d.data(), d.id))
            .toList()
          ..sort((a, b) =>
              (_orderKeys[b.id] ?? 0).compareTo(_orderKeys[a.id] ?? 0));
        inventoryItems = remote;
        notifyListeners();
      }, onError: (Object e) {
        debugPrint('Supply items sync error: $e');
      });
    } catch (e) {
      // Firebase unavailable (e.g. not initialised): keep working locally.
      debugPrint('Sync not started: $e');
    }
  }

  void _seedItems() {
    if (_itemsSeeded) return;
    _itemsSeeded = true;
    final base = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < inventoryItems.length; i++) {
      _orderKeys[inventoryItems[i].id] = base - i;
      _pushItem(inventoryItems[i]);
    }
  }

  void _pushStatus() {
    try {
      FirestoreService.instance
          .saveCampStatus(
            campId,
            evacueeCount: evacueeCount,
            maxCapacity: maxCapacity,
            isShelterClosed: isShelterClosed,
          )
          .catchError((Object e) => debugPrint('Status save failed: $e'));
    } catch (e) {
      debugPrint('Status save failed: $e');
    }
  }

  void _pushItem(ReliefItemModel item) {
    try {
      FirestoreService.instance
          .saveCampSupplyItem(campId, item.id, _itemToMap(item))
          .catchError((Object e) => debugPrint('Item save failed: $e'));
    } catch (e) {
      debugPrint('Item save failed: $e');
    }
  }

  Map<String, dynamic> _itemToMap(ReliefItemModel item) => {
        'id': item.id,
        'name': item.name,
        'category': item.category.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'minThreshold': item.minThreshold,
        'lastUpdated': item.lastUpdated,
        'orderKey': _orderKeys[item.id] ?? 0,
      };

  ReliefItemModel _itemFromMap(Map<String, dynamic> m, String docId) {
    _orderKeys[docId] = (m['orderKey'] as num?)?.toInt() ?? 0;
    return ReliefItemModel(
      id: docId,
      name: m['name']?.toString() ?? '',
      category: SupplyCategory.values.firstWhere(
        (c) => c.name == m['category'],
        orElse: () => SupplyCategory.other,
      ),
      quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
      unit: m['unit']?.toString() ?? '',
      minThreshold: (m['minThreshold'] as num?)?.toDouble() ?? 0,
      lastUpdated: m['lastUpdated']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _itemsSub?.cancel();
    super.dispose();
  }

  // Rapid Headcount Actions (+1, +5, +10, -1)
  void updateHeadcount(int delta) {
    evacueeCount = (evacueeCount + delta).clamp(0, maxCapacity + 50);
    _pushStatus();
    notifyListeners();
  }

  void toggleShelterStatus() {
    isShelterClosed = !isShelterClosed;
    _pushStatus();
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
      final newQty = (current.quantity + delta).clamp(0.0, 9999.0).toDouble();
      _setItem(
        index,
        current.copyWith(quantity: newQty, lastUpdated: 'Just now'),
      );
      notifyListeners();
    }
  }

  void addInventoryItem(ReliefItemModel item) {
    _orderKeys[item.id] = DateTime.now().millisecondsSinceEpoch;
    inventoryItems.insert(0, item);
    _pushItem(item);
    if (item.status == StockStatus.critical) {
      _notifyDmc(item, trigger: 'auto');
    }
    notifyListeners();
  }

  // --------------------------------------------------------
  // Swipe actions on supply items (M3-06 / FR8)
  //   swipe left  -> mark EMPTY
  //   swipe right -> mark LOW
  // Both return the previous quantity so the UI can offer "Undo".
  // --------------------------------------------------------
  double markItemEmpty(String id) => _setQuantity(id, (_) => 0);

  double markItemLow(String id) => _setQuantity(id, (item) {
        switch (item.status) {
          case StockStatus.adequate:
            return item.minThreshold; // just inside the "low" band
          case StockStatus.critical:
            return item.minThreshold * 0.5; // some stock found, but still low
          case StockStatus.low:
            return item.quantity; // already low, nothing to change
        }
      });

  /// Restore an exact quantity (used by the Undo action).
  void restoreItemQuantity(String id, double quantity) =>
      _setQuantity(id, (_) => quantity);

  double _setQuantity(String id, double Function(ReliefItemModel) compute) {
    final index = inventoryItems.indexWhere((i) => i.id == id);
    if (index == -1) return 0;
    final before = inventoryItems[index];
    final newQty = compute(before).clamp(0.0, 9999.0).toDouble();
    _setItem(
      index,
      before.copyWith(quantity: newQty, lastUpdated: 'Just now'),
    );
    notifyListeners();
    return before.quantity;
  }

  /// Single place where an item changes: updates state, syncs it, and
  /// raises / clears the DMC resupply request when it enters / leaves
  /// the critical (depleted) band (FR12).
  void _setItem(int index, ReliefItemModel updated) {
    final before = inventoryItems[index];
    inventoryItems[index] = updated;
    _pushItem(updated);

    final wasCritical = before.status == StockStatus.critical;
    final isCritical = updated.status == StockStatus.critical;
    if (!wasCritical && isCritical) {
      _notifyDmc(updated, trigger: 'auto');
    } else if (wasCritical && !isCritical) {
      _resolveDmc(updated);
    }
  }

  // --------------------------------------------------------
  // DMC dispatch (M3-08 / FR12)
  // --------------------------------------------------------
  String _dmcDocId(ReliefItemModel item) => '${campId}_${item.id}';

  Map<String, dynamic> _dmcPayload(ReliefItemModel item, String trigger) => {
        'campId': campId,
        'campName': campName,
        'itemId': item.id,
        'itemName': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'minThreshold': item.minThreshold,
        'status': 'pending',
        'trigger': trigger, // 'auto' (shortage detected) or 'manual' (leader)
        'requestedBy': leaderName,
      };

  void _notifyDmc(ReliefItemModel item, {required String trigger}) {
    try {
      FirestoreService.instance
          .saveDmcDispatchRequest(_dmcDocId(item), _dmcPayload(item, trigger))
          .catchError((Object e) => debugPrint('DMC request failed: $e'));
    } catch (e) {
      debugPrint('DMC request failed: $e');
    }
  }

  void _resolveDmc(ReliefItemModel item) {
    try {
      FirestoreService.instance
          .resolveDmcDispatchRequest(_dmcDocId(item))
          .catchError((Object e) => debugPrint('DMC resolve skipped: $e'));
    } catch (e) {
      debugPrint('DMC resolve skipped: $e');
    }
  }

  /// Camp Leader presses "Dispatch Supply": send every depleted item to the
  /// DMC as an urgent resupply request. Returns how many items were sent.
  /// Throws if the request could not be saved, so the UI can tell the user.
  Future<int> sendUrgentDispatch() async {
    final urgent = inventoryItems
        .where((i) => i.status == StockStatus.critical)
        .toList();
    if (urgent.isEmpty) return 0;
    final fs = FirestoreService.instance;
    await Future.wait(urgent.map(
      (i) => fs.saveDmcDispatchRequest(_dmcDocId(i), _dmcPayload(i, 'manual')),
    ));
    return urgent.length;
  }

  // Evacuee Actions
  void registerEvacuee(EvacueeModel evacuee) {
    evacuees.insert(0, evacuee);
    evacueeCount += 1;
    _pushStatus();
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
