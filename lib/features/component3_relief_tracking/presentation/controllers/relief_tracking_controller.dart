import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/relief_item_model.dart';
import '../../data/models/evacuee_model.dart';
import '../../data/services/firestore_service.dart';
import '../../../component4_control_center/presentation/controllers/responder_controller.dart';

class ReliefTrackingController extends ChangeNotifier {
  ReliefTrackingController() {
    // The camp comes from the account the administrator assigned.
    final assigned = _auth.currentUser;
    final zone = assigned?.floodZone.trim() ?? '';
    if (assigned != null && assigned.role == 'campLeader' && zone.isNotEmpty) {
      campName = zone;
    }
    campId = campIdFromName(campName);
    _auth.addListener(_onAuthChanged);
    _startSync();
    _watchAssignment();
    _loadDismissed();
  }

  /// The logged-in user (set by the login screen). The leader's name, role
  /// and photo shown in this component come from here.
  final ResponderController _auth = ResponderController();

  void _onAuthChanged() {
    // Until the live account listener is running, follow the login profile
    // (it may finish loading after this screen was created).
    if (_userSub == null) {
      final u = _auth.currentUser;
      if (u != null) _applyZone(u.floodZone, u.role);
      _watchAssignment();
    }
    notifyListeners();
  }

  StreamSubscription<dynamic>? _userSub;
  String? _watchedEmail;

  /// Follows the leader's account in Firestore, so a camp the administrator
  /// assigns (or changes) shows up straight away, without logging in again.
  void _watchAssignment() {
    final email = (_auth.currentUser?.email ?? '').trim().toLowerCase();
    if (email.isEmpty || email == _watchedEmail) return;
    _watchedEmail = email;
    _userSub?.cancel();
    try {
      _userSub = FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .snapshots()
          .listen((snap) {
        final d = snap.data();
        if (d == null) return;
        _applyZone((d['floodZone'] ?? '').toString(), (d['role'] ?? '').toString());
      }, onError: (Object e) => debugPrint('Assignment sync error: $e'));
    } catch (e) {
      debugPrint('Assignment sync not started: $e');
    }
  }

  /// Switches the whole dashboard to the camp named [zone] (or to "No camp
  /// assigned") and restarts the camp-based live data.
  void _applyZone(String zone, String role) {
    final z = zone.trim();
    final newName = (role == 'campLeader' && z.isNotEmpty) ? z : 'No camp assigned';
    if (newName == campName) return;
    campName = newName;
    campId = campIdFromName(newName);
    chatCamp = newName;
    inventoryItems = [];
    evacueeCount = 0;
    maxCapacity = 0;
    isShelterClosed = false;
    activeRequest = null;
    showTruckCard = false;
    _statusSub?.cancel();
    _itemsSub?.cancel();
    _requestsSub?.cancel();
    _warnSub?.cancel();
    _incSub?.cancel();
    _startSync();
    notifyListeners();
  }

  // Dr. Rohan Silva - Camp Info State
  String get leaderName {
    final name = _auth.currentUser?.fullName.trim() ?? '';
    return name.isEmpty ? 'Camp Leader' : name;
  }

  String get leaderTitle =>
      _auth.currentUser?.roleTitle ?? 'RELIEF CAMP LEADER • LOGISTICS';

  String? get leaderPhotoUrl => _auth.currentUser?.photoUrl;

  /// Name of the camp assigned to the logged-in leader (set by the admin).
  String campName = 'No camp assigned';
  int evacueeCount = 0;
  int maxCapacity = 0;
  bool isShelterClosed = false;

  /// False until an administrator has assigned a camp to this account.
  bool get hasCamp => campName != 'No camp assigned';

  // --------------------------------------------------------
  // Leaders chat identity: the logged-in account tells "my" messages apart
  // from other leaders'; the display name can be changed in the chat.
  // --------------------------------------------------------
  final String _sessionChatId =
      'leader_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 31)}';

  /// Messages are matched to their sender by the logged-in account, so a
  /// leader keeps ownership of their messages (and can still edit or delete
  /// them) after restarting the app. Falls back to a per-launch id.
  String get chatClientId {
    final uid = _auth.currentUser?.uid ?? '';
    return uid.isEmpty ? _sessionChatId : uid;
  }
  String? _chatNameOverride;
  String get chatName => _chatNameOverride ?? leaderName;
  late String chatCamp = campName;

  void setChatIdentity(String name, String camp) {
    _chatNameOverride = name;
    chatCamp = camp;
    notifyListeners();
  }

  // --------------------------------------------------------
  // Real-time sync (FR9): headcount, open/closed and inventory
  // are mirrored to Firestore so every device sees the same data.
  // --------------------------------------------------------
  /// Stable id derived from the camp's name, so every leader assigned to the
  /// same camp shares the same data (e.g. "Camp Nēraya" -> camp_neraya).
  late String campId;

  static String campIdFromName(String name) {
    const map = {
      'ā': 'a', 'ē': 'e', 'ī': 'i', 'ō': 'o', 'ū': 'u',
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
    };
    final lower = name.trim().toLowerCase();
    final b = StringBuffer();
    for (final ch in lower.split('')) {
      b.write(map[ch] ?? ch);
    }
    final slug = b
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'unassigned' : slug;
  }

  /// True once the latest data came from the server (not only the local cache).
  bool isSynced = false;

  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _itemsSub;
  StreamSubscription<dynamic>? _requestsSub;
  StreamSubscription<dynamic>? _warnSub;
  StreamSubscription<dynamic>? _incSub;

  /// The camp's newest supply request that is not finished yet (null when
  /// there is none). Its `status` moves pending -> dispatched (truck assigned,
  /// driver details set) -> arrived (truck reached the camp) -> resolved
  /// (restock confirmed). It also carries the request's `docId`.
  /// Drives the truck card on the Supplies page.
  Map<String, dynamic>? activeRequest;

  /// Whether the truck card is shown on the Supplies page. It disappears
  /// once the leader confirms the restock, and comes back as PENDING when
  /// a new supply request is made.
  bool showTruckCard = false;

  /// Requests whose restock was already confirmed (never shown again).
  final Set<String> _finishedRequestIds = {};

  // Items that already have an open request from this camp (pending, truck
  // on the way, or arrived and not yet confirmed). Such an item cannot be
  // requested again and does not appear in the shortage alerts.
  final Set<String> _openRequestItemIds = {};
  final Set<String> _openRequestItemNames = {};

  String _nameKey(String name) => name.trim().toLowerCase();

  bool hasOpenRequest(ReliefItemModel item) =>
      _openRequestItemIds.contains(item.id) ||
      _openRequestItemNames.contains(_nameKey(item.name));

  /// Items a leader may request: marked LOW or EMPTY, with no open request.
  List<ReliefItemModel> get requestableItems => inventoryItems
      .where((i) => i.status != StockStatus.adequate && !hasOpenRequest(i))
      .toList();

  /// Empty (depleted) items for the dashboard's shortage alerts; an item
  /// leaves the list as soon as it has been requested.
  List<ReliefItemModel> get shortageAlertItems => inventoryItems
      .where((i) => i.status == StockStatus.critical && !hasOpenRequest(i))
      .toList();
  bool _itemsSeeded = false;
  final Map<String, int> _orderKeys = {};

  void _startSync() {
    try {
      final fs = FirestoreService.instance;

      _statusSub = fs.streamCampStatus(campId).listen((snap) {
        if (!snap.exists) {
          // First run of an assigned camp: publish the starting values once.
          if (hasCamp && !snap.metadata.isFromCache) _pushStatus();
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

      _requestsSub = fs.streamDmcDispatchRequests().listen((snap) {
        Map<String, dynamic>? found;
        _openRequestItemIds.clear();
        _openRequestItemNames.clear();
        for (final d in snap.docs) {
          final m = d.data();
          final status = m['status'];
          final isOpen =
              status == 'pending' || status == 'dispatched' || status == 'arrived';
          // Only a leader's own request blocks a new one (an automatic
          // shortage alert is not a request).
          if (m['campId'] == campId &&
              isOpen &&
              m['trigger'] == 'request' &&
              !_finishedRequestIds.contains(d.id)) {
            final id = m['itemId']?.toString();
            if (id != null && id.isNotEmpty) _openRequestItemIds.add(id);
            final name = (m['itemName'] ?? '').toString();
            if (name.isNotEmpty) _openRequestItemNames.add(_nameKey(name));
          }
          // A leader's own request counts from the start; an automatic
          // shortage alert only once the admin has put a truck on it.
          final counts = (status == 'pending' && m['trigger'] == 'request') ||
              status == 'dispatched' ||
              status == 'arrived';
          if (m['campId'] == campId &&
              counts &&
              !_finishedRequestIds.contains(d.id)) {
            found = {...m, 'docId': d.id}; // newest first
            break;
          }
        }
        activeRequest = found;
        if (found != null) showTruckCard = true;
        notifyListeners();
      }, onError: (Object e) {
        debugPrint('Supply requests sync error: $e');
      });
      _startWarningSync();
      _startIncidentSync();
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
    if (!hasCamp) return;
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
    if (!hasCamp) return;
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
    _auth.removeListener(_onAuthChanged);
    _statusSub?.cancel();
    _itemsSub?.cancel();
    _requestsSub?.cancel();
    _warnSub?.cancel();
    _incSub?.cancel();
    _userSub?.cancel();
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

  // Inventory items of the assigned camp (loaded from Firestore).
  List<ReliefItemModel> inventoryItems = [];

  // Placeholder used by the Supplies tab while no real supply request is open
  // (the truck card itself is hidden in that case).
  Map<String, dynamic> incomingShipment = {
    'title': 'Relief Supply Truck',
    'subtitle': '',
    'eta': '',
    'progress': 0.0,
    'driverPhone': '',
    'isRestocked': true,
  };

  void confirmRestock() {
    final req = activeRequest;
    if (req != null) {
      _restockFromRequest(req);
      return;
    }
    showTruckCard = false;
    notifyListeners();
  }

  /// The leader confirms the truck's delivery: the delivered amount is added
  /// to the matching inventory item and the request is closed.
  void _restockFromRequest(Map<String, dynamic> req) {
    final name = (req['itemName'] ?? '').toString().trim().toLowerCase();
    final itemId = req['itemId']?.toString();
    final index = inventoryItems.indexWhere(
      (i) => (itemId != null && i.id == itemId) || i.name.trim().toLowerCase() == name,
    );
    if (index != -1) {
      final item = inventoryItems[index];
      final delivered = (req['quantityRequested'] as num?)?.toDouble() ??
          (item.minThreshold * 2);
      updateStockQuantity(item.id, delivered);
    }
    final docId = req['docId']?.toString();
    if (docId != null) {
      _finishedRequestIds.add(docId);
      try {
        FirestoreService.instance
            .resolveDmcDispatchRequest(docId)
            .catchError((Object e) => debugPrint('Restock confirm failed: $e'));
      } catch (e) {
        debugPrint('Restock confirm failed: $e');
      }
    }
    // Hide the truck card straight away (the stream confirms it later).
    activeRequest = null;
    showTruckCard = false;
    notifyListeners();
  }

  // Alerts shown on the Alerts tab (filled from real events only).
  List<Map<String, dynamic>> alertList = [];

  /// Official warnings broadcast from the Control Center (Component 4) or the
  /// Component 1 admin, read live from the Firestore `warnings` collection.
  List<Map<String, dynamic>> warningAlerts = [];
  final Set<String> _dismissedWarnings = {};
  List<Map<String, dynamic>> _warningsRaw = [];

  /// Everything shown on the Alerts tab: broadcast warnings first, then the
  /// camp's own alerts.
  List<Map<String, dynamic>> get allAlerts =>
      [...warningAlerts, ...incidentAlerts, ...stockAlerts, ...alertList];

  final Set<String> _dismissedStock = {};

  /// Real stock alerts of this camp: empty items (critical) and low items,
  /// except items that already have an open supply request.
  List<Map<String, dynamic>> get stockAlerts {
    final out = <Map<String, dynamic>>[];
    for (final i in inventoryItems) {
      if (i.status == StockStatus.adequate || hasOpenRequest(i)) continue;
      final id = 'stock_${i.id}';
      if (_dismissedStock.contains(id)) continue;
      final empty = i.status == StockStatus.critical;
      out.add({
        'id': id,
        'itemId': i.id,
        'type': empty ? 'critical' : 'low',
        'title': empty ? '${i.name} - Depleted' : '${i.name} - Low Stock',
        'subtitle': empty
            ? '$campName: ${i.name} is almost finished. Immediate resupply required.'
            : '$campName: ${i.name} is below its minimum level. Restock recommended.',
        'time': i.lastUpdated.isEmpty ? '' : i.lastUpdated,
        'actionText': empty ? 'DISPATCH SUPPLY' : 'REQUEST SUPPLY',
      });
    }
    return out;
  }

  void _startWarningSync() {
    _warnSub = FirebaseFirestore.instance
        .collection('warnings')
        .snapshots()
        .listen((snap) {
      final list = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final m = d.data();
        // Only warnings broadcast from the Control Center (Component 4).
        if (m['source'] != 'dispatcher') continue;
        final ts = (m['issuedTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        list.add({...m, '_id': d.id, '_ts': ts});
      }
      list.sort((a, b) =>
          (b['_ts'] as DateTime).compareTo(a['_ts'] as DateTime));
      _warningsRaw = list.take(20).toList();
      _rebuildWarningAlerts();
      _notifyNewWarnings();
    }, onError: (Object e) => debugPrint('Warnings sync error: $e'));
  }

  // ---- Incidents approved / dispatched in the Control Center (C4) --------
  List<Map<String, dynamic>> incidentAlerts = [];
  List<Map<String, dynamic>> _incidentsRaw = [];
  final Set<String> _dismissedIncidents = {};
  int? _lastSeenIncidentMs;

  /// Hazard reports the Control Center has taken up (a response team was
  /// dispatched / is on scene). Resolved or archived ones disappear.
  void _startIncidentSync() {
    _incSub = FirebaseFirestore.instance
        .collection('hazard_reports')
        .snapshots()
        .listen((snap) {
      final list = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final m = d.data();
        final st = m['dispatchStatus'];
        if (st != 'dispatched' && st != 'onScene') continue;
        if (m['archived'] == true) continue;
        final ts = (m['dispatchedAt'] as Timestamp?)?.toDate() ??
            (m['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.now();
        list.add({...m, '_id': d.id, '_ts': ts});
      }
      list.sort((a, b) =>
          (b['_ts'] as DateTime).compareTo(a['_ts'] as DateTime));
      _incidentsRaw = list.take(20).toList();
      _rebuildIncidentAlerts();
      _notifyNewIncidents();
    }, onError: (Object e) => debugPrint('Incident sync error: $e'));
  }

  String _incidentTitle(Map<String, dynamic> m) {
    final sev = (m['severity'] ?? '').toString();
    final hazard = (m['hazardType'] ?? 'Incident').toString();
    final prefix = sev.isEmpty ? '' : '${sev.toUpperCase()} · ';
    return '$prefix$hazard incident';
  }

  String _incidentBody(Map<String, dynamic> m) {
    final loc = (m['location'] ?? '').toString().trim();
    final team = (m['assignedUnitName'] ?? '').toString().trim();
    final onScene = m['dispatchStatus'] == 'onScene';
    final parts = <String>[
      if (loc.isNotEmpty) 'Location: $loc',
      if (team.isNotEmpty) onScene ? '$team is on scene' : '$team dispatched',
    ];
    return parts.isEmpty ? 'Approved by the Control Center.' : parts.join('\n');
  }

  void _rebuildIncidentAlerts() {
    String two(int n) => n.toString().padLeft(2, '0');
    incidentAlerts = _incidentsRaw
        .where((m) => !_dismissedIncidents.contains(m['_id']))
        .map((m) {
      final sev = (m['severity'] ?? '').toString().toLowerCase();
      final ts = m['_ts'] as DateTime;
      final color = sev.contains('critical')
          ? const Color(0xFFFF1744)
          : sev.contains('high')
              ? const Color(0xFFFF6D00)
              : const Color(0xFFFF9F0A);
      return <String, dynamic>{
        'id': 'inc_${m['_id']}',
        'type': 'incident',
        'color': color,
        'title': _incidentTitle(m),
        'subtitle': _incidentBody(m),
        'time': '${two(ts.day)}/${two(ts.month)} ${two(ts.hour)}:${two(ts.minute)}',
        'actionText': '',
      };
    }).toList();
    notifyListeners();
  }

  Future<void> _notifyNewIncidents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastSeenIncidentMs ??= prefs.getInt('c3_last_incident_ms') ??
          DateTime.now().millisecondsSinceEpoch;
      final since = _lastSeenIncidentMs!;
      var newest = since;
      final fresh = _incidentsRaw
          .where((m) => (m['_ts'] as DateTime).millisecondsSinceEpoch > since)
          .toList()
          .reversed;
      for (final m in fresh) {
        final ts = (m['_ts'] as DateTime).millisecondsSinceEpoch;
        if (ts > newest) newest = ts;
        await NotificationService.instance.showBroadcastAlert(
          id: (ts ~/ 1000) + 7,
          title: '\u{1F6A8} ${_incidentTitle(m)}',
          body: _incidentBody(m).replaceAll('\n', ' · '),
        );
      }
      _lastSeenIncidentMs = newest;
      await prefs.setInt('c3_last_incident_ms', newest);
    } catch (e) {
      debugPrint('Incident notify failed: $e');
    }
  }

  static const _lastSeenKey = 'c3_last_warning_ms';
  int? _lastSeenMs;

  /// Sound + phone notification for every broadcast that arrived since the
  /// last one this phone was told about (also catches ones that came while
  /// the app was closed, the next time it opens).
  Future<void> _notifyNewWarnings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastSeenMs ??= prefs.getInt(_lastSeenKey) ?? DateTime.now().millisecondsSinceEpoch;
      final since = _lastSeenMs!;
      var newest = since;
      final fresh = _warningsRaw
          .where((m) => (m['_ts'] as DateTime).millisecondsSinceEpoch > since)
          .toList()
          .reversed; // oldest first
      for (final m in fresh) {
        final ts = (m['_ts'] as DateTime).millisecondsSinceEpoch;
        if (ts > newest) newest = ts;
        final sev = (m['severity'] ?? 'Warning').toString();
        final hazard = (m['hazardType'] ?? 'Warning').toString();
        final place = (m['areaName'] ?? m['locationZone'] ?? '').toString().trim();
        final desc = (m['description'] ?? '').toString().trim();
        await NotificationService.instance.showBroadcastAlert(
          id: ts ~/ 1000,
          title: '\u{1F6A8} ${sev.toUpperCase()} - $hazard',
          body: place.isEmpty ? desc : '$desc (Area: $place)',
        );
      }
      _lastSeenMs = newest;
      await prefs.setInt(_lastSeenKey, newest);
    } catch (e) {
      debugPrint('Warning notify failed: $e');
    }
  }

  void _rebuildWarningAlerts() {
    String two(int n) => n.toString().padLeft(2, '0');
    warningAlerts = _warningsRaw
        .where((m) => !_dismissedWarnings.contains(m['_id']))
        .map((m) {
      final sev = (m['severity'] ?? 'Warning').toString();
      final ts = m['_ts'] as DateTime;
      final hazard = (m['hazardType'] ?? 'Warning').toString();
      final place = (m['areaName'] ?? m['locationZone'] ?? '').toString().trim();
      final desc = (m['description'] ?? '').toString().trim();
      final color = sev.toLowerCase() == 'critical'
          ? const Color(0xFFFF1744)
          : sev.toLowerCase() == 'watch'
              ? const Color(0xFF40C4FF)
              : const Color(0xFFFF9F0A);
      return <String, dynamic>{
        'id': 'warn_${m['_id']}',
        'type': 'broadcast',
        'severity': sev.toLowerCase(),
        'color': color,
        'title': '${sev.toUpperCase()} · $hazard',
        'subtitle': place.isEmpty ? desc : (desc.isEmpty ? place : '$desc\nArea: $place'),
        'time': '${two(ts.day)}/${two(ts.month)} ${two(ts.hour)}:${two(ts.minute)}',
        'actionText': '',
      };
    }).toList();
    notifyListeners();
  }

  static const _dismissedKey = 'c3_dismissed_alerts';

  /// Dismissed broadcasts / incidents stay hidden after the app restarts.
  Future<void> _loadDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final v in prefs.getStringList(_dismissedKey) ?? const <String>[]) {
        if (v.startsWith('w:')) _dismissedWarnings.add(v.substring(2));
        if (v.startsWith('i:')) _dismissedIncidents.add(v.substring(2));
      }
      _rebuildWarningAlerts();
      _rebuildIncidentAlerts();
    } catch (e) {
      debugPrint('Load dismissed failed: $e');
    }
  }

  Future<void> _saveDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_dismissedKey, [
        for (final w in _dismissedWarnings) 'w:$w',
        for (final i in _dismissedIncidents) 'i:$i',
      ].take(300).toList());
    } catch (_) {}
  }

  /// Removes every alert from the Alerts tab ("Clear all").
  void clearAllAlerts() {
    for (final a in List<Map<String, dynamic>>.from(allAlerts)) {
      final id = a['id'].toString();
      if (id.startsWith('warn_')) {
        _dismissedWarnings.add(id.substring(5));
      } else if (id.startsWith('inc_')) {
        _dismissedIncidents.add(id.substring(4));
      } else if (id.startsWith('stock_')) {
        _dismissedStock.add(id);
      }
    }
    alertList.clear();
    _saveDismissed();
    _rebuildWarningAlerts();
    _rebuildIncidentAlerts();
  }

  void dismissAlert(String id) {
    if (id.startsWith('warn_')) {
      _dismissedWarnings.add(id.substring(5));
      _saveDismissed();
      _rebuildWarningAlerts();
      return;
    }
    if (id.startsWith('inc_')) {
      _dismissedIncidents.add(id.substring(4));
      _saveDismissed();
      _rebuildIncidentAlerts();
      return;
    }
    if (id.startsWith('stock_')) {
      _dismissedStock.add(id);
      notifyListeners();
      return;
    }
    alertList.removeWhere((a) => a['id'] == id);
    notifyListeners();
  }

  // Evacuees registered at this camp.
  List<EvacueeModel> evacuees = [];

  // Filtering State
  String selectedSupplyFilter = 'All'; // 'All' | 'Depleted' | 'Low' | 'Adequate'
  String selectedAlertFilter = 'All'; // 'All' | 'Warnings' | 'Critical' | 'Low Stock' | 'Logs'
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
    return allAlerts.where((alert) {
      switch (selectedAlertFilter) {
        case 'Warnings':
          return alert['type'] == 'broadcast';
        case 'Incidents':
          return alert['type'] == 'incident';
        case 'Critical':
          return alert['type'] == 'critical';
        case 'Low Stock':
          return alert['type'] == 'low';
        case 'Logs':
          return alert['type'] == 'logs';
      }
      return true;
    }).toList();
  }

  int alertCount(String type) =>
      allAlerts.where((a) => a['type'] == type).length;

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

  /// Adds a supply item to the camp's inventory and saves it to Firestore.
  /// Returns null when it worked, or a readable message when it could not be
  /// saved (no camp assigned, or the database refused the write).
  Future<String?> addInventoryItem(ReliefItemModel item) async {
    if (!hasCamp) {
      return 'No camp is assigned to this account yet. Ask the administrator '
          'to assign you to a camp, then add items.';
    }
    _orderKeys[item.id] = DateTime.now().millisecondsSinceEpoch;
    inventoryItems.insert(0, item);
    notifyListeners();
    try {
      // Without internet the write is queued and completes later, so do not
      // wait for it forever.
      await FirestoreService.instance
          .saveCampSupplyItem(campId, item.id, _itemToMap(item))
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Saved locally; it will sync when the connection returns.
    } catch (e) {
      inventoryItems.removeWhere((i) => i.id == item.id);
      notifyListeners();
      return 'Could not save the item: $e';
    }
    if (item.status == StockStatus.critical) {
      _notifyDmc(item, trigger: 'auto');
    }
    return null;
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
    // A leader's request for this item is already open: do not overwrite it.
    if (hasOpenRequest(item)) return;
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
        .where((i) => i.status == StockStatus.critical && !hasOpenRequest(i))
        .toList();
    if (urgent.isEmpty) return 0;
    final fs = FirestoreService.instance;
    await Future.wait(urgent.map(
      (i) => fs.saveDmcDispatchRequest(_dmcDocId(i), _dmcPayload(i, 'manual')),
    ));
    return urgent.length;
  }

  /// Camp Leader asks the DMC for a supply. Only an item that is marked LOW
  /// or EMPTY, and has no open request yet, can be requested. There is one
  /// request document per camp and item, so a second leader of the same camp
  /// cannot create a duplicate. [urgency] is 'normal', 'urgent' or 'critical'.
  /// Throws a [StateError] with a readable message if the item may not be
  /// requested.
  Future<void> sendSupplyRequest({
    required ReliefItemModel item,
    required double quantity,
    required String urgency,
    String note = '',
  }) {
    if (item.status == StockStatus.adequate) {
      throw StateError('${item.name} is available. Only LOW or EMPTY items can be requested.');
    }
    if (hasOpenRequest(item)) {
      throw StateError('${item.name} has already been requested.');
    }
    final docId = _dmcDocId(item);
    _finishedRequestIds.remove(docId); // a new request starts the process again
    showTruckCard = true;
    // Show the item as requested straight away (the server confirms later).
    _openRequestItemIds.add(item.id);
    _openRequestItemNames.add(_nameKey(item.name));
    notifyListeners();
    return FirestoreService.instance.saveDmcDispatchRequest(docId, {
      'campId': campId,
      'campName': campName,
      'itemId': item.id,
      'itemName': item.name,
      'quantity': item.quantity,
      'minThreshold': item.minThreshold,
      'quantityRequested': quantity,
      'unit': item.unit,
      'urgency': urgency,
      'note': note,
      'status': 'pending',
      'trigger': 'request',
      'requestedBy': leaderName,
      // clear details left over from an earlier delivery of the same item
      'driverName': null,
      'driverPhone': null,
      'vehicleNumber': null,
      'dispatchedAt': null,
      'arrivedAt': null,
      'hiddenByCamp': false,
    });
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
