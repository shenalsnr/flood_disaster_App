import 'package:cloud_firestore/cloud_firestore.dart';

/// Central Firestore service for Component 3: Relief Tracking.
/// Handles all reads and writes for Supplier Requests, Inter-Camp Alerts,
/// Equipment, and Trucks.
class FirestoreService {
  // --------------------------------------------------------
  // Singleton
  // --------------------------------------------------------
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --------------------------------------------------------
  // Collection references
  // --------------------------------------------------------
  CollectionReference<Map<String, dynamic>> get _supplierRequests =>
      _db.collection('supplierRequests');

  CollectionReference<Map<String, dynamic>> get _interCampAlerts =>
      _db.collection('interCampAlerts');

  CollectionReference<Map<String, dynamic>> get _equipments =>
      _db.collection('equipments');

  CollectionReference<Map<String, dynamic>> get _trucks =>
      _db.collection('trucks');

  // ========================================================
  // 1. Supplier Requests
  // ========================================================

  /// Save a new supplier request from the Profile page.
  Future<void> saveSupplierRequest({
    required String message,
    required String role,
    required String campId,
  }) async {
    await _supplierRequests.add({
      'message': message,
      'role': role,
      'campId': campId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of all supplier requests, newest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamSupplierRequests() {
    return _supplierRequests
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ========================================================
  // 2. Inter-Camp Alerts
  // ========================================================

  /// Save a new inter-camp supply request alert.
  Future<DocumentReference> saveInterCampAlert({
    required String requestingCampId,
    required String requestingCampName,
    required String requiredItems,
    required String status,
    required String type,
  }) async {
    return await _interCampAlerts.add({
      'requestingCampId': requestingCampId,
      'requestingCampName': requestingCampName,
      'requiredItems': requiredItems,
      'status': status,
      'type': type,
      'respondingCampId': '',
      'driverName': null,
      'driverContact': null,
      'dispatchedItems': null,
      'dispatchedQuantity': null,
      'vehicleType': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing inter-camp alert (e.g. accept/decline/dispatch).
  Future<void> updateInterCampAlert(
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _interCampAlerts.doc(docId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of all inter-camp alerts, newest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamInterCampAlerts() {
    return _interCampAlerts
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ========================================================
  // 3. Equipment
  // ========================================================

  /// Save a new equipment record.
  Future<void> saveEquipment({
    required String id,
    required String name,
    required String status,
    required String condition,
    required String currentCampId,
  }) async {
    await _equipments.doc(id).set({
      'id': id,
      'name': name,
      'status': status,
      'condition': condition,
      'currentCampId': currentCampId,
      'historyLogs': [],
      'maintenanceRecords': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update equipment status/condition.
  Future<void> updateEquipment(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _equipments.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete an equipment record.
  Future<void> deleteEquipment(String id) async {
    await _equipments.doc(id).delete();
  }

  /// Real-time stream of all equipment records.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamEquipments() {
    return _equipments.orderBy('createdAt', descending: false).snapshots();
  }

  // ========================================================
  // 4. Trucks
  // ========================================================

  /// Save a new truck record.
  Future<void> saveTruck({
    required String id,
    required String vehicleNumber,
    required String truckType,
    required double currentLat,
    required double currentLng,
    required String destinationCampId,
    required String status,
    required String assignedOperation,
    required String cargoPayloadDetails,
    required String departureTime,
    required String estimatedEta,
  }) async {
    await _trucks.doc(id).set({
      'id': id,
      'vehicleNumber': vehicleNumber,
      'truckType': truckType,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'destinationCampId': destinationCampId,
      'status': status,
      'assignedOperation': assignedOperation,
      'cargoPayloadDetails': cargoPayloadDetails,
      'departureTime': departureTime,
      'estimatedEta': estimatedEta,
      'actualArrivalTime': null,
      'routeHistory': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update truck fields (e.g. status change).
  Future<void> updateTruck(String id, Map<String, dynamic> data) async {
    await _trucks.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a truck record.
  Future<void> deleteTruck(String id) async {
    await _trucks.doc(id).delete();
  }

  /// Real-time stream of all truck records.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamTrucks() {
    return _trucks.orderBy('createdAt', descending: false).snapshots();
  }

  // ========================================================
  // 5. Camp Status (headcount, shelter open/closed) — FR9
  // ========================================================

  CollectionReference<Map<String, dynamic>> get _campStatus =>
      _db.collection('campStatus');

  /// Real-time stream of one camp's headcount / open-closed status.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamCampStatus(
    String campId,
  ) {
    return _campStatus.doc(campId).snapshots(includeMetadataChanges: true);
  }

  /// Save (merge) a camp's headcount and open/closed status.
  Future<void> saveCampStatus(
    String campId, {
    required int evacueeCount,
    required int maxCapacity,
    required bool isShelterClosed,
  }) async {
    await _campStatus.doc(campId).set({
      'evacueeCount': evacueeCount,
      'maxCapacity': maxCapacity,
      'isShelterClosed': isShelterClosed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ========================================================
  // 6. Camp Supply Items (inventory) — FR9
  // ========================================================

  /// Real-time stream of one camp's supply items.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCampSupplyItems(
    String campId,
  ) {
    return _campStatus
        .doc(campId)
        .collection('supplyItems')
        .snapshots(includeMetadataChanges: true);
  }

  /// Save (merge) one supply item under a camp.
  Future<void> saveCampSupplyItem(
    String campId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    await _campStatus.doc(campId).collection('supplyItems').doc(itemId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ========================================================
  // 7. DMC Dispatch Requests — FR12 / M3-08
  // ========================================================

  CollectionReference<Map<String, dynamic>> get _dmcDispatchRequests =>
      _db.collection('dmcDispatchRequests');

  /// Create or update an urgent resupply request addressed to the DMC.
  /// A fixed [docId] (campId_itemId) keeps one open request per shortage.
  Future<void> saveDmcDispatchRequest(
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _dmcDispatchRequests.doc(docId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Mark an existing DMC request as resolved (no-op if it does not exist).
  Future<void> resolveDmcDispatchRequest(String docId) async {
    await _dmcDispatchRequests.doc(docId).update({
      'status': 'resolved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of DMC dispatch requests, newest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDmcDispatchRequests() {
    return _dmcDispatchRequests
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
}
