import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../../component4_control_center/data/services/admin_user_service.dart';

enum SafeZoneState { open, full, closed }

/// One shelter / safe zone, merged from two Firestore collections:
///   camps/{id}       - set by the administrator: name, lat, lng, capacity
///   campStatus/{id}  - kept live by the camp leader (Relief Tracker):
///                      evacueeCount, maxCapacity, isShelterClosed
class SafeZone {
  const SafeZone({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
    required this.capacity,
    required this.occupied,
    required this.closed,
  });

  final String id;
  final String name;
  final double? lat;
  final double? lng;
  final int capacity;
  final int occupied;
  final bool closed;

  bool get hasLocation => lat != null && lng != null;
  LatLng get point => LatLng(lat!, lng!);

  SafeZoneState get state {
    if (closed) return SafeZoneState.closed;
    if (capacity > 0 && occupied >= capacity) return SafeZoneState.full;
    return SafeZoneState.open;
  }

  bool get isOpen => state == SafeZoneState.open;

  double get fillRatio =>
      capacity <= 0 ? 0 : (occupied / capacity).clamp(0.0, 1.0);
  int get fillPercent => (fillRatio * 100).round();

  String get stateLabel {
    switch (state) {
      case SafeZoneState.open:
        return 'OPEN';
      case SafeZoneState.full:
        return 'FULL';
      case SafeZoneState.closed:
        return 'CLOSED';
    }
  }
}

class SafeZoneService {
  SafeZoneService._();
  static final SafeZoneService instance = SafeZoneService._();

  CollectionReference<Map<String, dynamic>> get _camps =>
      FirebaseFirestore.instance.collection('camps');
  CollectionReference<Map<String, dynamic>> get _status =>
      FirebaseFirestore.instance.collection('campStatus');

  /// Live list of every camp with its current headcount. Updates whenever the
  /// administrator edits a camp or a camp leader changes the headcount or
  /// closes / reopens the shelter.
  Stream<List<SafeZone>> watch() {
    late StreamController<List<SafeZone>> ctrl;
    QuerySnapshot<Map<String, dynamic>>? camps;
    QuerySnapshot<Map<String, dynamic>>? status;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? a;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? b;

    void emit() {
      final c = camps;
      if (c == null || ctrl.isClosed) return;
      ctrl.add(_merge(c, status));
    }

    ctrl = StreamController<List<SafeZone>>(
      onListen: () {
        a = _camps.snapshots().listen((s) {
          camps = s;
          emit();
        }, onError: (Object e, StackTrace st) {
          if (!ctrl.isClosed) ctrl.addError(e, st);
        });
        b = _status.snapshots().listen((s) {
          status = s;
          emit();
        }, onError: (Object e) {
          // Live headcount is optional: keep showing the camps.
        });
      },
      onCancel: () async {
        await a?.cancel();
        await b?.cancel();
      },
    );
    return ctrl.stream;
  }

  List<SafeZone> _merge(QuerySnapshot<Map<String, dynamic>> camps,
      QuerySnapshot<Map<String, dynamic>>? status) {
    final live = <String, Map<String, dynamic>>{
      if (status != null)
        for (final d in status.docs) d.id: d.data(),
    };
    final list = <SafeZone>[];
    for (final d in camps.docs) {
      final m = d.data();
      final s = live[d.id] ?? const <String, dynamic>{};
      list.add(SafeZone(
        id: d.id,
        name: (m['name'] ?? d.id).toString(),
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        capacity: (s['maxCapacity'] as num?)?.toInt() ??
            (m['capacity'] as num?)?.toInt() ??
            0,
        occupied: (s['evacueeCount'] as num?)?.toInt() ?? 0,
        closed: (s['isShelterClosed'] as bool?) ?? false,
      ));
    }
    list.sort((x, y) => x.name.toLowerCase().compareTo(y.name.toLowerCase()));
    return list;
  }

  /// Administrator: create or update a safe zone. The capacity is written to
  /// both collections so the camp leader's screen picks it up too. The live
  /// headcount is never touched here.
  Future<void> saveZone({
    required String name,
    required double lat,
    required double lng,
    required int capacity,
  }) {
    final clean = name.trim();
    if (clean.isEmpty) throw StateError('Enter the safe zone name.');
    final id = AdminUserService.campIdFromName(clean);
    final batch = FirebaseFirestore.instance.batch();
    batch.set(
        _camps.doc(id),
        {
          'name': clean,
          'lat': lat,
          'lng': lng,
          'capacity': capacity,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    batch.set(
        _status.doc(id),
        {
          'maxCapacity': capacity,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    return batch.commit();
  }

  /// Straight-line distance in kilometres.
  static double distanceKm(LatLng a, LatLng b) =>
      const Distance().as(LengthUnit.Kilometer, a, b);
}
