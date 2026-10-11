import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../component1_evacuation/services/safe_zone_service.dart';
import '../../data/services/admin_user_service.dart';
import '../../../../core/theme/appearance.dart';

const Color _bg = Color(0xFF131B2B);
const Color _card = Color(0xFF131B2B);
const Color _border = Color(0xFF1E293B);
const Color _muted = Color(0xFF8E9BAE);
const Color _accent = Color(0xFFFF5252);
const Color _green = Color(0xFF00E676);
const Color _orange = Color(0xFFFF9F0A);

/// A camp leader account the administrator can assign to a safe zone.
class _Leader {
  const _Leader(this.email, this.name, this.zone);
  final String email;
  final String name;
  final String zone; // camp the leader is currently assigned to
}

List<_Leader> _leadersFrom(QuerySnapshot<Map<String, dynamic>>? snap) {
  if (snap == null) return const [];
  final out = <_Leader>[];
  for (final d in snap.docs) {
    final m = d.data();
    final role = AdminUserService.normalizeRole((m['role'] ?? '').toString());
    if (role != 'campLeader') continue;
    if (m['isActive'] == false) continue;
    final email = (m['email'] ?? d.id).toString();
    final name = (m['fullName'] ?? '').toString().trim();
    out.add(_Leader(
        email, name.isEmpty ? email : name, (m['floodZone'] ?? '').toString()));
  }
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}

/// Opens the safe zone editor (name, capacity, leader, tap-to-place map).
/// Used by the "Manage camps" dialog so every camp can be placed on the map
/// the citizens see. Pass [name] to open an existing camp or to pre-fill a new
/// one. Returns a short message when something was saved, otherwise null.
Future<String?> openSafeZoneEditor(BuildContext context, {String? name}) async {
  var zones = const <SafeZone>[];
  try {
    zones = await SafeZoneService.instance
        .watch()
        .first
        .timeout(const Duration(seconds: 6));
  } catch (_) {}
  SafeZone? existing;
  final clean = (name ?? '').trim();
  if (clean.isNotEmpty) {
    final id = AdminUserService.campIdFromName(clean);
    for (final z in zones) {
      if (z.id == id) existing = z;
    }
  }
  if (!context.mounted) return null;
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => _SafeZoneEditor(
        zone: existing,
        presetName: clean.isEmpty ? null : clean,
        existingIds: zones.map((z) => z.id).toSet(),
      ),
    ),
  );
}

/// Administrator: add, edit and remove safe zones (shelters). Citizens see the
/// open ones on their Safe Route map; camp leaders keep the headcount live.
class SafeZonesScreen extends StatelessWidget {
  const SafeZonesScreen({super.key});

  Future<void> _openEditor(
      BuildContext context, SafeZone? zone, List<SafeZone> zones) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _SafeZoneEditor(
          zone: zone,
          existingIds: zones.map((z) => z.id).toSet(),
        ),
      ),
    );
    if (saved != null) {
      messenger.showSnackBar(SnackBar(
          content: Text(saved), backgroundColor: _green, showCloseIcon: true));
    }
  }

  Future<void> _delete(BuildContext context, SafeZone zone,
      List<_Leader> leaders) async {
    final messenger = ScaffoldMessenger.of(context);
    final assigned = leaders
        .where((l) =>
            AdminUserService.campIdFromName(l.zone) == zone.id &&
            l.zone.isNotEmpty)
        .toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Delete safe zone?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '"${zone.name}" will disappear from the citizens\' Safe Route map.'
          '${assigned.isEmpty ? '' : '\n\nLeaders assigned to it will be left without a camp.'}',
          style: const TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: _accent))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminUserService.instance
          .deleteCamp(zone.name,
              unassignEmails: assigned.map((l) => l.email).toList())
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Saved on this phone, it will sync when the connection is back.
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      return;
    }
    messenger.showSnackBar(
        SnackBar(content: Text('${zone.name} deleted'), showCloseIcon: true));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminUserService.instance.watchUsers(),
      builder: (context, userSnap) {
        final leaders = _leadersFrom(userSnap.data);
        return StreamBuilder<List<SafeZone>>(
          stream: SafeZoneService.instance.watch(),
          builder: (context, snap) {
            final zones = snap.data ?? const <SafeZone>[];
            return Scaffold(
              backgroundColor: _bg,
              appBar: AppBar(
                backgroundColor: _bg,
                title: const Text('Safe Zones',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                onPressed: () => _openEditor(context, null, zones),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('ADD SAFE ZONE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              body: Builder(builder: (context) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load safe zones. Check the Firestore rules '
                        'for "camps" and "campStatus".\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted),
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: _accent));
                }
                if (zones.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No safe zones yet.\nTap ADD SAFE ZONE to place one on the map.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: zones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final z = zones[i];
                    final zoneLeaders = leaders
                        .where((l) =>
                            l.zone.isNotEmpty &&
                            AdminUserService.campIdFromName(l.zone) == z.id)
                        .toList();
                    return _ZoneCard(
                      zone: z,
                      leaderNames: zoneLeaders.map((l) => l.name).toList(),
                      onEdit: () => _openEditor(context, z, zones),
                      onDelete: () => _delete(context, z, leaders),
                    );
                  },
                );
              }),
            );
          },
        );
      },
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.leaderNames,
    required this.onEdit,
    required this.onDelete,
  });

  final SafeZone zone;
  final List<String> leaderNames;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    Color stateColor;
    switch (zone.state) {
      case SafeZoneState.open:
        stateColor = _green;
        break;
      case SafeZoneState.full:
        stateColor = _orange;
        break;
      case SafeZoneState.closed:
        stateColor = _accent;
        break;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on,
                    color: zone.hasLocation ? _green : _muted, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(zone.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(zone.stateLabel,
                      style: TextStyle(
                          color: stateColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
                PopupMenuButton<String>(
                  color: _card,
                  iconColor: _muted,
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: zone.fillRatio,
                minHeight: 6,
                backgroundColor: _border,
                valueColor: AlwaysStoppedAnimation<Color>(stateColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${zone.occupied} / ${zone.capacity} people  -  ${zone.fillPercent}% full',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              leaderNames.isEmpty
                  ? 'No camp leader assigned'
                  : 'Leader: ${leaderNames.join(', ')}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            if (!zone.hasLocation) ...[
              const SizedBox(height: 6),
              const Text(
                'Location not set - citizens cannot see this shelter yet. Tap to place it on the map.',
                style: TextStyle(color: _orange, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor: name, capacity and a map. The place can be searched by name or the
// map can be tapped. Camp leaders are assigned from ADD STAFF, not here.
// ---------------------------------------------------------------------------

class _Place {
  const _Place(this.name, this.label, this.point);
  final String name; // short name, e.g. "Rathnapura Central College"
  final String label; // full address line
  final LatLng point;
}

class _SafeZoneEditor extends StatefulWidget {
  const _SafeZoneEditor({
    required this.zone,
    required this.existingIds,
    this.presetName,
  });

  final String? presetName;
  final SafeZone? zone;
  final Set<String> existingIds;

  @override
  State<_SafeZoneEditor> createState() => _SafeZoneEditorState();
}

class _SafeZoneEditorState extends State<_SafeZoneEditor> {
  static const LatLng _defaultCenter = LatLng(6.6828, 80.3992); // Ratnapura

  late final TextEditingController _name = TextEditingController(
      text: widget.zone?.name ?? widget.presetName ?? '');
  late final TextEditingController _capacity = TextEditingController(
      text: (widget.zone?.capacity ?? 0) > 0
          ? widget.zone!.capacity.toString()
          : '');
  final TextEditingController _search = TextEditingController();
  final MapController _map = MapController();
  bool _mapReady = false;

  late LatLng? _point =
      widget.zone?.hasLocation == true ? widget.zone!.point : null;
  List<_Place> _results = const [];
  bool _searching = false;
  String? _searchMsg;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.zone != null;

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  // ── Place search (OpenStreetMap Nominatim) ────────────────────────────────
  Future<List<_Place>> _geocode(String q) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'jsonv2',
        'limit': '8',
        'countrycodes': 'lk',
      });
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'dev.lasha.flood_disaster');
      req.headers.set(HttpHeaders.acceptLanguageHeader, 'en');
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as List<dynamic>;
      final out = <_Place>[];
      for (final e in data) {
        final lat = double.tryParse(e['lat'].toString());
        final lon = double.tryParse(e['lon'].toString());
        if (lat == null || lon == null) continue;
        final label = (e['display_name'] ?? '').toString();
        var name = (e['name'] ?? '').toString().trim();
        if (name.isEmpty) name = label.split(',').first.trim();
        out.add(_Place(name, label, LatLng(lat, lon)));
      }
      return out;
    } finally {
      client.close();
    }
  }

  Future<void> _runSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty || _searching) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _results = const [];
      _searchMsg = null;
    });
    try {
      final r = await _geocode(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _searchMsg = r.isEmpty ? 'No place found. Try another name.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchMsg =
          'Search failed. Check the internet connection and try again.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _choose(_Place p) {
    setState(() {
      _point = p.point;
      _results = const [];
      _searchMsg = null;
      _error = null;
      if (!_isEdit && _name.text.trim().isEmpty) _name.text = p.name;
    });
    if (_mapReady) {
      try {
        _map.move(p.point, 16);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final cap = int.tryParse(_capacity.text.trim()) ?? 0;
    if (name.isEmpty) {
      setState(() => _error = 'Enter the safe zone name.');
      return;
    }
    if (cap <= 0) {
      setState(() => _error = 'Enter the capacity (number of people).');
      return;
    }
    if (_point == null) {
      setState(() => _error = 'Search a place or tap the map to place it.');
      return;
    }
    final id = AdminUserService.campIdFromName(name);
    if (!_isEdit && widget.existingIds.contains(id)) {
      setState(() => _error =
          '"$name" already exists. Open it from the list to edit it.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SafeZoneService.instance
          .saveZone(
            name: name,
            lat: _point!.latitude,
            lng: _point!.longitude,
            capacity: cap,
          )
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Saved on this phone, it syncs when the connection is back.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save: $e';
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context)
        .pop(_isEdit ? '$name updated' : '$name added as a safe zone');
  }

  InputDecoration _dec(String label, {String? hint, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        labelStyle: const TextStyle(color: _muted),
        hintStyle: const TextStyle(color: Color(0xFF5E6D82)),
        filled: true,
        fillColor: _card,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text(_isEdit ? 'Edit safe zone' : 'Add safe zone',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _name,
                        enabled: !_isEdit && !_saving,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dec('Safe zone name'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _capacity,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dec('Capacity'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  enabled: !_saving,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec(
                    'Search a place',
                    hint: 'e.g. Rathnapura Central College',
                    suffix: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _accent),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search, color: _accent),
                            onPressed: _runSearch,
                          ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.touch_app_outlined, color: _muted, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _searchMsg ??
                        (_point == null
                            ? 'Search a place above, or tap the map to place it'
                            : 'Location: ${_point!.latitude.toStringAsFixed(5)}, ${_point!.longitude.toStringAsFixed(5)}  (tap the map to adjust)'),
                    style: TextStyle(
                        color: _searchMsg == null ? _muted : _orange,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Unfiltered(child: FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: _point ?? _defaultCenter,
                      initialZoom: _point == null ? 13 : 15,
                      minZoom: 8,
                      maxZoom: 18,
                      onMapReady: () => _mapReady = true,
                      onTap: (tapPos, latLng) {
                        if (_saving) return;
                        setState(() {
                          _point = latLng;
                          _results = const [];
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'dev.lasha.flood_disaster',
                      ),
                      if (_point != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _point!,
                              width: 48,
                              height: 48,
                              alignment: Alignment.topCenter,
                              child: const Icon(Icons.location_pin,
                                  color: _green, size: 44),
                            ),
                          ],
                        ),
                    ],
                  )),
                ),
                if (_results.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 12,
                    right: 12,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: _border),
                        itemBuilder: (_, i) {
                          final r = _results[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined,
                                color: _accent, size: 20),
                            title: Text(r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            subtitle: Text(r.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: _muted, fontSize: 11)),
                            onTap: () => _choose(r),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(_error!,
                  style: const TextStyle(color: _accent, fontSize: 12)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'SAVE CHANGES' : 'ADD SAFE ZONE',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
